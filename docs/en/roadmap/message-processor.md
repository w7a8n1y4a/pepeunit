# MessageProcessor

DataPipe becomes a separate stage of MessageProcessor

The main goal at this stage is two base tables in ClickHouse:

1. Hourly use of VM resources by the instance
1. Hourly resource usage by each Unit

The current hour is updated once a minute. These tables provide usage totals for a period, consumption trends and the current instance status. Hourly totals do not preserve the history of each minute: monitoring remains responsible for detailed charts and short spikes

## MessageProcessor stages

0. All subscriptions converge on `domain.com/+` through typing and the new approaches
1. Count incoming messages and bytes, check limits
2. Validate against the schema
3. Convert units of measurement
4. Forward to other UnitIO topics
5. Pass the original message to DataPipe

- Stage outcomes are counted separately: accepted, rejected, forwarded, written
- Limits are checked while processing a message, without waiting for statistics to be written to ClickHouse

## Accumulation and writes

1. A shared instance buffer accumulates usage by Unit and hour, similarly to DataPipe batches
1. Each event updates numeric counters in memory; the accounting buffer does not store the messages themselves
1. Changed records are sent in a single batch every 5 seconds or when the record count limit is reached. The batch is shared across the entire Pepeunit instance
1. ClickHouse receives a new version of the accumulated total since the start of the hour, rather than an in-place row update: `100 → 230 → 310`, with `310` as the total
1. Both tables use `ReplacingMergeTree` with a record version. Reads select the latest version of each key without waiting for background merges. Resending the same version does not increase usage
1. A new accumulator is created at the start of each hour, and the previous hour's final total must be saved. The payer and accounting rules version are recorded; changes to either split the accumulated usage
1. If several processes count Unit usage, the key includes the source and its epoch: the latest versions of their non-overlapping contributions are summed. A restart must not replace an existing total with a reset counter
1. An unacknowledged batch is retained for retry, while new events continue to accumulate separately. A write failure does not clear the buffer

- Messages, bytes and operations are stored as sums; average rates are calculated when reading
- Counters are stored as columns in a single Unit record; a separate row for each metric is unnecessary
- If the instance is down or a failure occurs, the hour is treated as an hour with no load, and users are not charged
- Hourly history is retained for 90 days
- Charge history is retained longer, but this is a future task; charges might be applied once a day, for example

## Instance resources over time

1. One active collector per instance updates its state once a minute and writes the accumulated total for the current hour to the VM resources table
1. Logporter provides container CPU, RAM and network metrics; a separate VM exporter provides total capacity, usage and available resources under the effective limits
1. Metrics include CPU-seconds, RAM, used and free disk space, disk operations and I/O bytes, and incoming and outgoing network bytes
1. PostgreSQL and ClickHouse data sizes are obtained from the databases themselves. Connection pool, worker and queue occupancy, processing latency and errors are tracked separately
1. Network speed limits by direction, the traffic quota and its billing period are configured in the instance settings or obtained from the provider
1. Resource occupancy records retain the latest value, minimum, maximum and time integral; counters retain the increase over the hour. Observation duration and gaps are recorded so that missing data is not treated as zero load

- VM integrals and peaks are estimates at the collection interval's resolution; averages are calculated using observation duration
- The latest values allow instance status updates every minute, while history supports resource exhaustion forecasts
- Prometheus remains the monitoring system; the ClickHouse tables are the source for usage calculations

## Unit resources over time

1. UnitIO events accumulate in the Unit's hourly counters: incoming messages and bytes, accepted and rejected messages, and completed transformations
1. Outgoing messages and bytes are counted separately for each recipient after transformation. Broker acceptance is not equivalent to processing by the device
1. Exchanges within the instance and with external instances are distinguished. External network traffic is accounted for at the network boundary, separately by direction and cost category
1. DataPipe tracks confirmed writes and logical bytes written, current logical storage size and storage byte-seconds
1. Storage size changes on writes, replacements, deletions and expiry. Byte-seconds accumulate even without new messages and are split at hour boundaries
1. The payer is determined by the operation's rules. Internal platform retries must not increase billable usage again

- Logical data size is calculated using fixed rules; physical database size belongs to instance resource usage
- An owner's historical usage is calculated using the payer recorded at the time, rather than the Unit's current owner
- Limits apply to both the Unit and its owner so that creating new Units cannot bypass restrictions

## General approach to future monetization

1. We know how hourly consumption is distributed across Units
1. We know how many instance resources are occupied. This determines the pricing rate: the less total VM capacity is occupied, the lower the rate. The rate is calculated per hour
1. The instance also knows users' resource allocations to avoid situations where they would allow users to occupy 120% of VM capacity
1. The instance rate is calculated dynamically
1. The instance always aims to keep 10% of capacity available to handle spikes and is willing to increase the rate to preserve that reserve
1. The rate acts as a load regulator. It can be recalculated once a minute, with a guaranteed cap on its increase of N% over a specified time interval

## Moving subscriptions from Backend to MessageProcessor

- Backend no longer subscribes to anything over MQTT
- Backend no longer triggers Unit schema updates itself
- Backend retains only EMQX configuration and access provisioning
- Backend MQTT connections can be refactored
