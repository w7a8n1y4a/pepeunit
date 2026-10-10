# MessageProcessor

The DataPipe scenario is extended with various counters and becomes MessageProcessor

## Instance resources over time

1. Logporter provides runtime cpu, ram, and network
1. Prometheus turns Logporter data into windows — `[month, week, day, hour]`
1. Persistent storage used can be taken from postgres and clickhouse directly
1. To learn how much memory is left on the host system, some exporter is needed
1. The maximum external network value must be entered in the instance settings; the default is 100 MB/s

- this builds a basic overall picture
- the instance will be able to forecast how long it can keep running stably

## Unit resources over time

1. Subscription to `+/+/pepeunit` and `+/+`
1. All incoming and outgoing MPS are counted for each UnitNode (for a Unit, a join with summation)
1. Average number of messages from/to the home instance `[month, week, day, hour]`
1. Average number of messages from/to external instances `[month, week, day, hour]`
1. Memory size dynamics based on `DataPipe` rows `[month, week, day, hour]`
1. Refuses service when limits are exceeded

- from this we will see the percentage of who consumes which resources

## Moving the subscription from the backend to MessageProcessor

1. Subscription to `domain.com/+/+/+/pepeunit`
1. Handling of incoming `state/pepeunit` and `log/pepeunit`

- The Backend no longer subscribes to anything over mqtt
- The Backend keeps only EMQX configuration and access issuance
- The Backend mqtt connections can then be refactored
