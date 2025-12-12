# Grafana

::::warning
Manual editing is usually not required; you typically only need to fill in the main variables because there is a [file that generates .env files for services](/en/deployment/docker/deploy#filling-the-primary-env-file).
::::

::::warning
The full list of environment variables is available in the [Grafana documentation](https://grafana.com/docs/).
::::

Variable | Example | Purpose
-- | -- | --
`GF_SECURITY_ADMIN_USER` | `admin` | Username for the service admin account
`GF_SECURITY_ADMIN_PASSWORD` | `grafanapassword` | Password for the service admin account
`GF_USERS_ALLOW_SIGN_UP` | `false` | Whether regular users are allowed to sign up via login/password
`GF_SERVER_DOMAIN` | `unit.example.com` | Domain on which [Grafana](/en/deployment/dependencies/grafana) will run
`GF_SERVER_ROOT_URL` | `%(protocol)s://%(domain)s/grafana/` | Root URL for [Grafana](/en/deployment/dependencies/grafana), used to shift the path with a prefix (e.g. `grafana/`)
`GF_SERVER_SERVE_FROM_SUB_PATH` | `true` | Tells [Grafana](/en/deployment/dependencies/grafana) that it runs under a URL prefix
`GF_LOG_LEVEL` | `error` | Minimum log level to write
`GF_INSTALL_PLUGINS` | `yesoreyeram-infinity-datasource,marcusolsson-hourly-heatmap-panel` | Plugins to install by default


