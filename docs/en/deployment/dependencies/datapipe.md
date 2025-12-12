# DataPipe

## DataPipe as a Backend service

The `DataPipe service` is a high-performance data processing service written in [Golang](/en/definitions#golang). It is responsible for consuming data from topics with the pattern `example.com/+/pepeunit`, filtering it, and then saving it into [ClickHouse](/en/deployment/dependencies/clickhouse) and [PostgreSQL](/en/deployment/dependencies/postgresql).

::::info
[More about environment variables](/en/deployment/env-variables/data-pipe)
::::


## DataPipe as a data processing paradigm

`DataPipe` is a data processing instruction described in [YML](#yml) format and is designed for efficient accumulation of data from [UnitNode](/en/definitions#unitnode) topics.

In [Pepeunit](/en/conception/overview), there is a deep integration with [Grafana](/en/deployment/dependencies/grafana) to visualize data collected by `DataPipe`.

::::info
[DataPipe configuration](/en/user/datapipe/datapipe)

[DataPipe examples](/en/user/datapipe/example)

[Data import into DataPipe](/en/user/datapipe/import)
::::

