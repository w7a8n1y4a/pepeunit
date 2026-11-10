# Grafana

:::info
These variables are not written to the settings file: `docker-compose.yml` takes the login and password from `PU_GRAFANA_ADMIN_USER` and `PU_GRAFANA_ADMIN_PASSWORD` and the domain from `PU_DOMAIN`, and the rest is already set in it. Sign-in through `Pepeunit` is configured in `data/grafana/grafana.ini`, which is built by `make_env.py`.
:::

Full list of variables: [Grafana documentation](https://grafana.com/docs/).

Variable | Value | What is it for?
-- | -- | --
GF_SECURITY_ADMIN_USER | PU_GRAFANA_ADMIN_USER | Administrator login
GF_SECURITY_ADMIN_PASSWORD | PU_GRAFANA_ADMIN_PASSWORD | Administrator password
GF_USERS_ALLOW_SIGN_UP | false | Forbids self-registration: users sign in through `Pepeunit`
GF_SERVER_DOMAIN | PU_DOMAIN | Grafana domain
GF_SERVER_ROOT_URL | %(protocol)s://%(domain)s/grafana/ | Root address with the `/grafana/` prefix
GF_SERVER_SERVE_FROM_SUB_PATH | true | Tells Grafana that it runs under a prefix
GF_LOG_LEVEL | error | Minimum log level
GF_PLUGINS_PREINSTALL_SYNC | yesoreyeram-infinity-datasource,marcusolsson-hourly-heatmap-panel | Plugins that are installed on start
