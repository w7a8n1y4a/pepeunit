# MessageProcessor

DataPipe in Go becomes just one stage of MessageProcessor.

## MessageProcessor stages

0. All subscriptions converge on `domain.com/+` through typing
1. Count incoming messages and bytes
2. Validate against the schemas from [New schemas](./type-for-schemas.md)
3. Convert units of measurement according to [New schemas](./type-for-schemas.md)
4. Forward to other UnitIO topics
5. DataPipe processing

## Moving subscriptions from Backend to MessageProcessor

- Backend no longer subscribes to anything over MQTT
- Backend configures EMQX, grants access, and publishes commands to base Inputs.
- Backend sends `SchemaUpdate` only on request.
    - During an update, the Unit downloads `io_topics.yml` itself.
    - Link changes do not require the Unit to download the file again.
    - MessageProcessor synchronizes the links it uses to forward messages to other UnitIO topics.
- EMQX enforces MQTT traffic limits. MessageProcessor counts the messages it receives from the broker, including those it subsequently rejects during validation.
- Backend MQTT connections can be refactored

## Processing base topics

```yaml
output:
  state: {}
  log: {}
```

- Standard Output UnitIO processing takes place entirely in MessageProcessor. The reserved name and direction in the contract dictionary identify its purpose; there is no separate `base` marker.
- `pepeunit_server` does not participate, except for topic authorization
- Backend can send a command to a base Input in response to a REST request.

## Storing UnitIO load data

For each UnitIO of either type, we need to know:

1. Average requests per second, regardless of outcome: success, rejection, etc.
2. Average bytes per second
3. Growth in DataPipe storage volume

The `unit_io_resources_aggregation` table in ClickHouse:

1. `start_window_datetime` — the start of the window, at the start of an hour, e.g. 15:00
2. `end_window_datetime` — the end of the window, e.g. 16:00
3. `unit_io_uuid` — a reference to UnitIO
4. `total_requests` — the total number of requests received or sent by UnitIO during the window
5. `total_bytes` — the total number of bytes received or sent by UnitIO during the window
6. `total_datapipe_bytes_increment` — how much data was added to DataPipe (the number of records multiplied by the size of one record in the target ClickHouse table)
7. TTL — 90 days

- `end_window_datetime - start_window_datetime` is always one hour
- Each UnitIO will have approximately 2160 history records over 90 days
- The current hour is populated gradually, so the latest record allows current usage to be calculated from the start of the hour to the present. Accurate reads require `SUM(...) GROUP BY`, since merging is not guaranteed.
- If UnitIO load is zero, no record is created

### Populating the current hour

A shared buffer, similar to DataPipe's, uses `settings.BufferFlushInterval` (default: 5 seconds) and `settings.BufferMaxSize` (default: 1000).

Increments for all UnitIO are added to this buffer. When the buffer determines that it needs to flush, it inserts the changes into ClickHouse as a batch.

## Storing Instance load data

- All basic metrics come from Logporter. Even if they are not the most accurate, this keeps collection consistent across all instances.

The instance must monitor:

1. CPU — utilization percentage across all cores
2. RAM — utilization percentage
3. Network bandwidth utilization — a percentage
    - Relative to the speed limit set by the Owner
4. Total PostgreSQL data size — can be obtained through queries
    - Relative to the available PostgreSQL capacity
    - Configured in instance settings as `pu_instance_pg_size_limit`
    - A possible default is 1 GB
5. Total ClickHouse data size — can be obtained through queries
    - Relative to the available ClickHouse capacity
    - Configured in instance settings as `pu_instance_cc_size_limit`
    - A possible default is 1 GB

The `instance_resources_samples` table in ClickHouse:

1. `create_datetime` — measurement time
2. `cpu_percent`
3. `ram_percent`
4. `network_width_percent`
5. `pu_instance_network_speed_limit` — the speed limit in bytes per second at measurement time, allowing approximate traffic consumption to be calculated
6. `pg_disk_percent`
7. `cc_disk_percent`
8. TTL — 90 days

### Data collection

- Collect all metrics once a minute using Python code
- If any metric exceeds 90%, notify the Owner without flooding them every minute; for example, send no more than one notification every 15 minutes across all metrics
- Approximately 129600 records will be retained over 90 days

### Network traffic

- An important metric that often limits what a VM can do under a hosting provider's plan
- The Owner can set a monthly traffic limit, for example 3 TB
- The instance can estimate consumption using `instance_resources_samples.network_width_percent` and `instance_resources_samples.pu_instance_network_speed_limit`
- Checking traffic consumption therefore requires a separate query

## New instance_settings variables

1. `pu_instance_pg_size_limit`
    - In bytes, greater than 0
    - Default: `2**30` — 1 GiB
2. `pu_instance_cc_size_limit`
    - In bytes, greater than 0
    - Default: `2**30` — 1 GiB
3. `pu_instance_network_speed_limit`
    - In bytes per second, greater than 0
    - Default: `2**24` — 16 MiB/s
4. `pu_instance_network_monthly_traffic_limit`
    - In bytes, greater than 0
    - Default: `3 * 2**40` — 3 TiB
5. `pu_instance_network_traffic_reset_day`
    - Values from 1 to 31
    - Default: 1
    - If the month does not have that day, use its last day

## Schema synchronization

The Go module `pepeunit_server/data_pipe` already synchronizes pipeline configurations. In `internal/datapipe/data_pipe_config_sync.go`, `LoadNodeConfigs` reads the configurations of active pipelines from PostgreSQL. `StartConfigSync` reloads all of them on a timer and after a batch of notifications from the `backend_data_pipe_nodes` Redis stream.

The proposed MessageProcessor keeps a single in-memory snapshot of the schemas and links for every Input and Output on the instance, including base IOs. The DataPipe flag controls only the pipeline processing stage.

### Snapshot contents

- PostgreSQL stores UnitIO UUIDs, directions and `topic_name`, and each Unit's `repo_uuid` and `target_commit` matching its IO set. Schemas are not copied into UnitIO rows. Backend reads `unit.yml` at that exact commit, resolves standard IOs by reserved name and applies defaults from `dictionary.yml` with the same `contract_version`.
- The snapshot sends resolved definitions once per `(repo_uuid, target_commit)`. Each `unit_io_uuid` references that pair, its direction and IO name, owning Unit and enabled DataPipe configuration. Go builds in-memory UUID lookups for validation rules, units of measurement, codec, QoS and routing mode. Standard `state` and `log` outputs are identified by direction and exact name; there is no separate `base` identifier.
- For each Output, MessageProcessor reads the set of linked Input UUIDs from the `links` table. In `broadcast` mode, every Input in that set is a destination. In `selected-link` mode, MessageProcessor forwards only `data` to the Input identified by `input_uuid`. It rejects the message if that UUID is outside the sending Output's set.

### When the snapshot is refreshed

1. Before subscribing to `domain.com/+`, MessageProcessor requests a full snapshot from Backend through an HTTP endpoint requiring MessageProcessor service authorization. Backend reads the revision, Units with pinned target commits, UnitIO entries, links and pipeline configurations in one PostgreSQL `REPEATABLE READ` transaction. It then loads the immutable manifests at the captured commits and resolves schemas through the shared `UnitManifestService`. The result carries the revision of the captured data even if another transaction commits during assembly. Secrets and `env` are excluded. Go neither reads Git nor reimplements dictionary resolution.
2. When Backend changes a Unit's selected commit, UnitIO set, links or pipeline configurations, it increments the revision in the same transaction. Updating `target_commit`, execution type and UnitIO entries is atomic. This also applies to cascading Unit deletion. After the transaction commits, Backend sends the new revision to the `backend_message_processor` Redis stream. Synchronizing Git without switching a Unit does not change the active snapshot revision.
3. A dedicated goroutine reads the Redis stream and passes notifications to the synchronization goroutine. The latter collects a batch until the next `BufferFlushInterval` tick (5 seconds by default) or until it has `BufferMaxSize` events (1000). Once per batch, it compares the PostgreSQL revision with the revision of the active snapshot. It also checks every `ConfigSyncInterval` (60 seconds) independently of Redis to catch changes when a notification is lost.
4. If the revisions differ, the synchronization goroutine requests another full snapshot from Backend and publishes it through `atomic.Pointer` only after successful assembly and checking that every UnitIO entry matches its manifest. On any error, including an unavailable Git commit, it keeps the previous snapshot, logs the cause and retries on the next timer tick. On initial startup, MQTT subscription waits until a snapshot is ready. The MQTT handler reads the pointer once per message and uses that snapshot at every processing stage.

For example, if a sensor sends to two Inputs and one link is deleted, the new snapshot lists only the remaining Input. Messages may still reach both Inputs between the commit and the snapshot switch. The Unit listens on its own Input, and MessageProcessor updates the list of destinations.
