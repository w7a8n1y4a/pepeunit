# MessageProcessor

The DataPipe scenario is extended with counters of various kinds, and the result is MessageProcessor

## Instance resources over time

1. Logporter gives the runtime cpu, ram and network
1. Prometheus will take Logporter data and give windows - `[month, week, day, hour]`
1. The persistent storage taken up can be read from postgres and clickhouse directly
1. To find out how much memory the host system has left in total, some exporter is needed
1. The maximum external network value must be entered in the instance settings, 100 MB/s by default

- from this a basic overall picture is built
- the instance will be able to forecast the dynamics of how long it can keep running stably

## Unit resources over time

1. Subscription to `+/+/pepeunit` and `+/+`
1. All incoming and outgoing MPS are counted for each UnitNode (for a Unit simply through a join with summation)
1. Average number of messages from/to the home instance `[month, week, day, hour]`
1. Average number of messages from/to external instances `[month, week, day, hour]`
1. Dynamics of memory size based on `DataPipe` rows `[month, week, day, hour]`
1. Denies service when limits are exceeded

- from this we will see the percentage of who consumes which resources

## Moving the subscription from backend to MessageProcessor

1. Subscription to `domain.com/+/+/+/pepeunit`
1. Processing of incoming `state/pepeunit` and `log/pepeunit`

- Backend no longer subscribes to anything over mqtt
- Backend keeps only the EMQX setup and the issuing of access
- The mqtt connections in Backend can be refactored

## Integration with backend

- The datapipe binary will run inside the backend container.
- On the dev stand everything will stay as before
- The container will be removed from deploy
- In the tags job of the backend, pulling of the banners by the identical tag will be integrated
- First the tag of the data pipe repository is built and only then backend