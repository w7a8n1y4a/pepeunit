# ClickHouse

:::danger
New versions of `ClickHouse` do not start on old processors: they need `x86-64-v3` support for `amd64` or `ARMv8.2-A` for `arm`. Because of this, Pepeunit will not work on `Raspberry Pi 4` and older. If your processor is not suitable, pin an old image version in `docker-compose.yml`, for example `clickhouse:25.8.32`.
:::

[ClickHouse](https://clickhouse.com/) is a column-oriented DBMS for analytics. Container `clickhouse`, data in the `clickhouse_data` volume. [Environment variables](/deployment/env-variables/clickhouse)

[Backend](/deployment/dependencies/backend) stores Unit logs and [DataPipe](/deployment/dependencies/datapipe) data in it. It creates the database and tables by itself on start. `ClickHouse` system tables are kept for one day so they do not take up disk space.
