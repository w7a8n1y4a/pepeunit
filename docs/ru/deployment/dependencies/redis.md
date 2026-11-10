# Redis

[Redis](https://redis.io/) - хранилище `key-value`. Контейнер `redis`. Тома у него нет, в [резервные копии](/deployment/docker/backup-update) он не входит: всё, что в нём лежит, временное и пересоздаётся само.

:::info
Используется [Backend](/deployment/dependencies/backend), [DataPipe](/deployment/dependencies/datapipe) и [EMQX](/deployment/dependencies/emqx) для:
1. Прав на MQTT топики: `backend` записывает их, `emqx` проверяет при каждом подключении
1. Кодов привязки Telegram и состояния Telegram Bot
1. Одноразовых билетов входа в [Grafana](/deployment/dependencies/grafana)
1. Живых уведомлений в клиенте
1. Команд для [DataPipe](/deployment/dependencies/datapipe)
:::

:::warning
`PU_REDIS_URL` и `PU_MQTT_REDIS_AUTH_URL` должны указывать на один и тот же `Redis`, иначе авторизация в [EMQX](/deployment/dependencies/emqx) не сработает.
:::
