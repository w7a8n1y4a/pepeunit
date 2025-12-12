# EMQX

::::warning
Manual editing is usually not required; you typically only need to fill in the main variables because there is a [file that generates .env files for services](/en/deployment/docker/deploy#filling-the-primary-env-file).
::::

::::warning
The full list of environment variables is available in the [EMQX documentation](https://docs.emqx.com/en/emqx/latest/).
::::

Variable | Example | Purpose
-- | -- | --
`EMQX_DASHBOARD__DEFAULT_USERNAME` | `admin` | Username for the service account
`EMQX_DASHBOARD__DEFAULT_PASSWORD` | `password` | Password for the service account
`EMQX_PROMETHEUS__METRICS__ENABLED` | `true` | Flag that enables load metrics


