# Backend

## Backend в широком смысле 

`Backend в широком смысле` - представляет из себя набор из `6` сервисов: `Backend`, [PostgreSQL](/deployment/dependencies/postgresql), [ClickHouse](/deployment/dependencies/clickhouse), [Redis](/deployment/dependencies/redis), [EMQX](/deployment/dependencies/emqx), [DataPipe](/deployment/dependencies/datapipe). Указанные сервисы вместе обеспечивают реализацию бизнес-логики [Pepeunit](/conception/overview), а также взаимодействие всех внешних агентов:

- [Пользователей](/development-pepeunit/mechanics/roles.html#user)
- [Frontend](/deployment/dependencies/frontend)
- [Unit](/definitions#unit)
- [GitLab](/definitions#gitlab)
- [GitHub](/definitions#github)
- [Telegram](/definitions#telegram)

## Backend-сервис

`Backend сервис` - главный из `6` компонентов `Backend в широком смысле`. Размещается на сервере и обеспечивает обработку, хранение и анализ информации. Реализует интеграции с остальными `5` сервисами, а также взаимодействует с другими агентами с использованием [API](/definitions#api):
- [MQTT](/definitions#mqtt) - `fastapi-mqtt`
- [REST](/definitions#rest) - `swagger`
- [GQL](/definitions#gql) - `strawberry`
- [Telegram Bot](/definitions#telegram-bot) - `AioGram`

:::info
[Подробнее о переменных окружения](/deployment/env-variables/backend)
:::
