# Pepeunit

::::info
`Pepeunit` is an open‑source platform based on the principles of the [Fediverse](/en/definitions#fediverse) and [IoT](/en/definitions#iot), designed to organize devices into a single, manageable information system.
::::

![img](/schemas/work_schema.svg)

## CI/CD for Units

`Pepeunit` can create ready‑to‑use programs from external [Git](/en/definitions#git) repositories hosted on [GitLab](/en/definitions#gitlab) and [GitHub](/en/definitions#github).  
These programs can be built using either [Interpretable](/en/definitions#interpretable) or [Compilable](/en/definitions#compilable) programming languages.

::::info
[Update system](/en/development-pepeunit/mechanics/update-system)
::::

## Data processing pipelines

`Pepeunit` can efficiently accumulate pre‑cleaned and transformed data in [ClickHouse](/en/deployment/dependencies/clickhouse) and [PostgreSQL](/en/deployment/dependencies/postgresql).

Processing is defined by pipeline configurations written in [YML](/en/definitions#yml).  
High throughput is provided by a microservice implemented in [Golang](/en/definitions#golang).  
There are four main data accumulation modes:
- `Last Value` — store only the last value
- `N Records` — store the last `N` records
- `Time Window` — store all records within a configured time window
- `Aggregation` — store aggregated data over a chosen time window using functions such as `avg`, `sum`, `min`, `max`

::::info
[DataPipe](/en/deployment/dependencies/datapipe)
::::

## Integration with Grafana

`Pepeunit` allows you to create custom [Dashboards](/en/definitions#dashboard) composed of [Visualizations](/en/definitions#visualization).  
The underlying data is provided by [UnitNodes](/en/definitions#unitnode) with configured [DataPipes](/en/deployment/dependencies/datapipe).

::::info
[Creating a Dashboard](/en/user/grafana/create)
::::

## Managing IoT devices

`Pepeunit` provides several ways to interact with a [Unit](/en/definitions#unit):
- [MQTT](/en/definitions#mqtt) — via [EMQX](/en/deployment/dependencies/emqx)
- [Frontend](/en/deployment/dependencies/frontend) — `React`
- [REST](/en/definitions#rest) — `Swagger`
- [GQL](/en/definitions#gql) — `Strawberry`
- [Telegram Bot](/en/definitions#telegram-bot) — `AioGram`

## Topic management

`Pepeunit` lets you track the state of [Units](/en/definitions#unit) using a topic‑naming system.  
[UnitNodes](/en/definitions#unitnode) can form `Output->Input` links to pass information between different [Units](/en/definitions#unit).

::::info
[Output->Input links](/en/user/unit/edge-unit-node)

[Standard MQTT commands](/en/developer/mqtt/default-mqtt-command)

[Standard MQTT state topics](/en/developer/mqtt/state-mqtt-send)

[Message structure in MQTT topics](/en/developer/mqtt/struct-topic-messages)
::::


## Access policy configuration

`Pepeunit` allows you to configure [access](/en/development-pepeunit/mechanics/permission) levels for [Users](/en/development-pepeunit/mechanics/roles#user) and `Unit‑Unit` interactions.  
The depth of interaction with the platform is determined by the [User](/en/development-pepeunit/mechanics/roles) role and the [visibility](/en/development-pepeunit/mechanics/visibility) of individual entities: [Repo](/en/definitions#repo), [Unit](/en/definitions#unit), [UnitNode](/en/definitions#unitnode).

::::info
[Access management](/en/development-pepeunit/mechanics/permission)
::::

## Client libraries

`Pepeunit` provides libraries that simplify the creation of [Units](/en/definitions#unit), each supporting the full functionality of the [Pepeunit Framework](/en/developer/libraries/framework).  
Currently available:
- [Micropython](/en/developer/libraries/micropython)
- [Python](/en/developer/libraries/python)
- [Golang](/en/developer/libraries/golang)

## Instance comparison

[Will be available starting from one of the versions > 1.0.0](/en/roadmap/comparison)

## Federation

[Will be available in version 2.0.0](/en/roadmap/federation)

## Monetization

[Will be available in version 2.0.0](/en/roadmap/monetisation)


