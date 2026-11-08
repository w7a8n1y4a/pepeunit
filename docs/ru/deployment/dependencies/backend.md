# Backend

## Backend в широком смысле 

`Backend в широком смысле` - представляет из себя набор из `6` сервисов: `Backend`, [PostgreSQL](/deployment/dependencies/postgresql), [ClickHouse](/deployment/dependencies/clickhouse), [Redis](/deployment/dependencies/redis), [EMQX](/deployment/dependencies/emqx), [DataPipe](/deployment/dependencies/datapipe). Указанные сервисы вместе обеспечивают реализацию `бизнес-логики` Pepeunit, а также взаимодействие всех внешних агентов:

- [Пользователей](/development-pepeunit/mechanics/roles#user)
- [Frontend](/deployment/dependencies/frontend)
- Unit
- GitLab
- GitHub
- Telegram

## Backend-сервис

`Backend-сервис` - главный из `6` компонентов `Backend в широком смысле`. Размещается на сервере и обеспечивает обработку, хранение и анализ информации. Реализует интеграции с остальными `5` сервисами, а также взаимодействует с другими агентами с использованием API:
- MQTT - `fastapi-mqtt`
- REST - `swagger`
- GQL - `strawberry`
- Telegram Bot - `AioGram`

:::info
[Подробнее о переменных окружения](/deployment/env-variables/backend)
:::
