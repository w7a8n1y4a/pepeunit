# Backend

## Backend in a broad sense

`Backend in a broad sense` is a set of `6` services: `Backend`, [PostgreSQL](/en/deployment/dependencies/postgresql), [ClickHouse](/en/deployment/dependencies/clickhouse), [Redis](/en/deployment/dependencies/redis), [EMQX](/en/deployment/dependencies/emqx), [DataPipe](/en/deployment/dependencies/datapipe). These services together implement the `business logic` of [Pepeunit](/en/conception/overview), as well as interaction with all external agents:

- [Users](/en/development-pepeunit/mechanics/roles.html#user)
- [Frontend](/en/deployment/dependencies/frontend)
- [Unit](/en/definitions#unit)
- [GitLab](/en/definitions#gitlab)
- [GitHub](/en/definitions#github)
- [Telegram](/en/definitions#telegram)

## Backend service

The `Backend service` is the main one of the `6` components of the `Backend in a broad sense`. It is deployed on the server and is responsible for processing, storing and analyzing information. It provides integrations with the remaining `5` services and interacts with other agents using the [API](/en/definitions#api):
- [MQTT](/en/definitions#mqtt) - `fastapi-mqtt`
- [REST](/en/definitions#rest) - `swagger`
- [GQL](/en/definitions#gql) - `strawberry`
- [Telegram Bot](/en/definitions#telegram-bot) - `AioGram`

::::info
[More about environment variables](/en/deployment/env-variables/backend)
::::

