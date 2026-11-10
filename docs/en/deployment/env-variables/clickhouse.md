# ClickHouse

:::info
These variables are not written to the settings file: `make_env.py` takes them from `PU_CLICKHOUSE_DATABASE_URL` and passes them to the `clickhouse` container.
:::

Full list of variables: [ClickHouse documentation](https://clickhouse.com/docs).

Variable | Where it comes from | What is it for?
-- | -- | --
CLICKHOUSE_USER | User name from the address | Database user name
CLICKHOUSE_PASSWORD | Password from the address | Database user password
CLICKHOUSE_DB | Database name from the address, defaults to default | Database name

:::warning
The values are applied only when the `clickhouse_data` volume is created. Changing them later does not change the password in the database, see [Settings file](/deployment/docker/deploy#settings-file).
:::
