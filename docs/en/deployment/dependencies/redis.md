# Redis

[Redis](https://redis.io/) is a `key-value` store. Container `redis`. It has no volume and is not part of [backups](/deployment/docker/backup-update): everything in it is temporary and is recreated by itself.

:::info
Used by [Backend](/deployment/dependencies/backend), [DataPipe](/deployment/dependencies/datapipe) and [EMQX](/deployment/dependencies/emqx) for:
1. Permissions for MQTT topics: `backend` writes them, `emqx` checks them on every connection
1. Telegram binding codes and Telegram Bot state
1. One-time sign-in tickets for [Grafana](/deployment/dependencies/grafana)
1. Live notifications in the client
1. Commands for [DataPipe](/deployment/dependencies/datapipe)
:::

:::warning
`PU_REDIS_URL` and `PU_MQTT_REDIS_AUTH_URL` must point to the same `Redis`, otherwise authorization in [EMQX](/deployment/dependencies/emqx) will not work.
:::
