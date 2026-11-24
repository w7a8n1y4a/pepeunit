# MessageProcessor

DataPipe in Go becomes just one stage of MessageProcessor.

## MessageProcessor stages

0. All subscriptions converge on `domain.com/+` through typing
1. Count incoming messages and bytes
2. Validate against the schemas from [New schemas](./type-for-schemas.md)
3. Convert units of measurement according to [New schemas](./type-for-schemas.md)
4. Forward to other UnitIO topics
5. DataPipe processing, when enabled for the UnitIO. DataPipe can be enabled for any Input or Output, including standard IOs.

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

Backend adds standard IOs, including `state` and `log`, from the selected contract's `dictionary.yml` when assembling the Unit schema. Each Input and Output has its own `domain.com/<unit_io_uuid>` address. The MessageProcessor subscription `domain.com/+` covers all these addresses.

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

In the `pepeunit_server/data_pipe` Go module, MessageProcessor assembles an in-memory snapshot of schemas and links for every Input and Output on the instance. The existing DataPipe reads its configuration from PostgreSQL independently of schema loading.

### How schemas are loaded

1. Go reads Unit version settings, UnitIO entries and links from one PostgreSQL snapshot. Go starts one local Python process per refresh and passes it the settings for all Units. The process uses the existing `GitRepoRepository` rules to select commits from the shared Git cache. Manual mode uses the validated `target_commit` and automatic mode computes `resolved_commit` from the branch and update settings.
2. Go reads `unit.yml` directly from the shared Git cache once per `(repo_uuid, selected_commit)` and applies standard IOs and defaults from `dictionary.yml` for the same `contract_version`. It maps schemas to UnitIO UUIDs by direction and `topic_name` and resolves links by UUID. Standard `state` and `log` outputs are identified by direction and exact name.

In `broadcast` mode, every linked Input is a destination. In `selected-link` mode, MessageProcessor forwards only `data` to the Input identified by `input_uuid` after checking that the Input is linked to the sender.

### When schemas are refreshed

At `:30`, Backend refreshes local repositories. At `:00`, the regular automatic update computes `selected_commit`, validates its `unit.yml` and synchronizes UnitIO. If the manifest fails validation, the existing UnitIO set is preserved. If the local branch has moved and IO names and directions still match, MessageProcessor can apply the new schema on a timer before the automatic Unit update runs.

After committing changes to Units, links or DataPipe, Backend signals the `backend_message_processor` Redis stream. A successful Unit update also signals when the IO names stay the same. `StartConfigSync` triggers a refresh at startup, once per batch of notifications, and on the `ConfigSyncInterval` timer.

Go publishes the snapshot through `atomic.Pointer` after all schemas have been matched to UnitIO entries and links. On error it keeps the previous snapshot until the next refresh. The subscription for schema-based processing starts after the first successful load, and the handler uses one snapshot per message.

While the device is updating, it may still send values of the previous type. After the snapshot switches, MessageProcessor validates them against the new schema and rejects incompatible values. The contract dictionary defines the formats for declared standard commands and messages, including `update` and `state`. Changes to application IOs preserve those formats.

For example, if a sensor sends to two Inputs and one link is deleted, the new snapshot lists only the remaining Input. Messages may still reach both Inputs between the commit and the snapshot switch. The Unit listens on its own Input, and MessageProcessor updates the list of destinations.
