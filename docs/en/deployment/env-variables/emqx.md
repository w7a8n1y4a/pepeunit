# EMQX

:::info
These variables are not written to the settings file: `docker-compose.yml` takes the name and password from `PU_MQTT_USERNAME` and `PU_MQTT_PASSWORD`, and the rest is already set in it.
:::

Full list of variables: [EMQX documentation](https://docs.emqx.com/en/emqx/latest/).

Variable | Value | What is it for?
-- | -- | --
EMQX_DASHBOARD__DEFAULT_USERNAME | PU_MQTT_USERNAME | [EMQX](/deployment/dependencies/emqx) administrator name, used by [Backend](/deployment/dependencies/backend) to configure the broker
EMQX_DASHBOARD__DEFAULT_PASSWORD | PU_MQTT_PASSWORD | Administrator password
EMQX_PROMETHEUS__ENABLE_BASIC_AUTH | false | Turns off the password on metrics so that [Prometheus](/deployment/dependencies/prometheus) can read them

:::danger
The administrator password is set when the `emqx_data` volume is created. Later, change it in `EMQX` itself and in `PU_MQTT_PASSWORD` at the same time.
:::
