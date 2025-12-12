# ClickHouse

::::warning
Manual editing is usually not required; you typically only need to fill in the main variables because there is a [file that generates .env files for services](/en/deployment/docker/deploy#filling-the-primary-env-file).
::::

::::warning
The full list of environment variables is available in the [ClickHouse documentation](https://clickhouse.com/docs).
::::

Variable | Example | Purpose
-- | -- | --
`CLICKHOUSE_USER` | `admin` | Database username
`CLICKHOUSE_PASSWORD` | `mypassword` | Database user password
`CLICKHOUSE_DB` | `default` | Database name


