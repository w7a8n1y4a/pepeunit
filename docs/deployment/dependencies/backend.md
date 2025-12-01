# Backend

## Backend в широком смысле 

Набор из `6` сервисов: `Backend`, [Postgresql](/deployment/dependencies/postgresql), [Clickhouse](/deployment/dependencies/clickhouse), [Redis](/deployment/dependencies/redis), [EMQX](/deployment/dependencies/emqx), [DataPipe](/deployment/dependencies/datapipe) - вместе обеспечивающих реализацию бизнеслогики [Pepeunit](/conception/overview), а также взаимодействие всех внешних агентов:

- [Пользователей](/development-pepeunit/mechanics/roles.html#user)
- [Frontend](/deployment/dependencies/frontend)
- [Unit](/definitions#unit)
- [Gitlab](/definitions#gitlab)
- [Github](/definitions#github)
- [Telegram](/definitions#telegram)

## Backend сервис

Главный из `6` компанентов `Backend` в широком смысле. Размещается на сервере и обеспечивает: обработку, хранение и анализ информации. Реализует интеграции с остальными `5` сервисами, а также взаимодействует с другими агентами по средствам [API](/definitions#api):
- [MQTT](/definitions#mqtt) - `fastapi-mqtt`
- [REST](/definitions#rest) - `swagger`
- [GQL](/definitions#gql) - `strawberry`
- [Telegram Bot](/definitions#telegram-bot) - `AioGram`

:::info
[Подробнее о переменных окружения](/deployment/env-variables/backend)
:::
