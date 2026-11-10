# ClickHouse

:::danger
Новые версии `ClickHouse` не запускаются на старых процессорах: нужна поддержка `x86-64-v3` для `amd64` или `ARMv8.2-A` для `arm`. Поэтому Pepeunit не заработает на `Raspberry Pi 4` и старше. Если процессор не подходит, закрепите в `docker-compose.yml` старую версию образа, например `clickhouse:25.8.32`.
:::

[ClickHouse](https://clickhouse.com/) - колоночная СУБД для аналитики. Контейнер `clickhouse`, данные в томе `clickhouse_data`. [Переменные окружения](/deployment/env-variables/clickhouse)

:::info
[Backend](/deployment/dependencies/backend) хранит в ней:
1. Логи Unit
1. Данные [DataPipe](/deployment/dependencies/datapipe)
:::

Базу и таблицы [Backend](/deployment/dependencies/backend) создаёт сам при старте. Системные таблицы `ClickHouse` хранятся один день, чтобы не занимать диск.
