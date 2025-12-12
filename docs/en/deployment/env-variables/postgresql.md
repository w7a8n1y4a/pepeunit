# PostgreSQL

::::warning
Manual editing is usually not required; you typically only need to fill in the main variables because there is a [file that generates .env files for services](/en/deployment/docker/deploy#filling-the-primary-env-file).
::::

::::warning
The full list of environment variables is available in the [PostgreSQL documentation](https://www.postgresql.org/docs).
::::

Variable | Example | Purpose
-- | -- | --
`POSTGRES_USER` | `myuser` | Database username
`POSTGRES_PASSWORD` | `mypassword` | Database user password
`POSTGRES_DB` | `pepeunit` | Database name
`POSTGRES_HOST_AUTH_METHOD` | `md5` | Host authentication method


