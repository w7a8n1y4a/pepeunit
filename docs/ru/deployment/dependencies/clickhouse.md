# ClickHouse

:::danger
Стандартный контейнер `Clickhouse` запускается не на всех `arm` системах, т.к. требует инструкции `ARMv8.2-A`. Из-за этого [Pepeunit](/conception/overview) нельзя запустить на `ЭВМ` серии `rpi` версии `4` и ниже.

Прорабатывается, создание альтернативного контейнера на основе бинарной версии `Clickhouse` для поддержики `rpi3b+` и выше.
:::

[ClickHouse](https://clickhouse.com/) - колончатая аналитическая СУБД с открытым исходным кодом, позволяющая выполнять аналитические запросы на структурированных данных при помощи языка [SQL](/definitions#sql). [Подробнее о переменных окружения](/deployment/env-variables/clickhouse)

:::info
[Backend](/deployment/dependencies/backend) хранит в ней следующую информацию:
1. Логи [Unit](/definitions#unit)
1. Данные [DataPipe](/deployment/dependencies/datapipe)
:::
