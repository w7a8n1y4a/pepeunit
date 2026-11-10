# PostgreSQL

:::info
These variables are not written to the settings file: `make_env.py` takes them from `PU_SQLALCHEMY_DATABASE_URL` and passes them to the `postgres` container.
:::

Full list of variables: [PostgreSQL documentation](https://www.postgresql.org/docs).

Variable | Where it comes from | What is it for?
-- | -- | --
POSTGRES_USER | User name from the address | Database user name
POSTGRES_PASSWORD | Password from the address | Database user password
POSTGRES_DB | Database name from the address | Database name
POSTGRES_HOST_AUTH_METHOD | Set in `docker-compose.yml`: md5 | Authentication method

:::warning
The values are applied only when the `postgres_data` volume is created. Changing them later does not change the password in the database, see [Settings file](/deployment/docker/deploy#settings-file).
:::
