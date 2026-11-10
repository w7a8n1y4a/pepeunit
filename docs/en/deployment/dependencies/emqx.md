# EMQX

[EMQX](https://docs.emqx.com/en/emqx/latest/) is an MQTT broker: Unit, [Backend](/deployment/dependencies/backend) and [DataPipe](/deployment/dependencies/datapipe) exchange messages through it. Container `emqx`, port `1883`. [Environment variables](/deployment/env-variables/emqx)

Who accesses which topics (`example.com` is `PU_DOMAIN`):

- Unit publishes and reads its own topics
- Backend reads all topics and, at the request of a [User](/development-pepeunit/mechanics/roles#user), sends commands to the Unit `Input` topics
- DataPipe reads the topics with Unit data

## How Backend configures EMQX

On every start, Backend logs in to the broker's REST API with `PU_MQTT_USERNAME` and `PU_MQTT_PASSWORD` and:
1. Sets up authorization of Unit and Backend through [Redis](/deployment/dependencies/redis)
1. Applies the limits from the [instance settings](/deployment/instance-settings#mqtt)
1. Disables the `retainer`

That is why `EMQX` limits are changed in the client, not in `docker-compose.yml`, and take effect after a [server restart](/deployment/instance-settings#applying-changes).

:::warning
How Backend finds the broker's REST API depends on `PU_MQTT_SECURE`:
- `False` - at `http://PU_MQTT_HOST:PU_MQTT_API_PORT`
- `True` - at `https://PU_MQTT_HOST`, port `443`

For a public instance this means that `PU_MQTT_HOST` must have a domain name with a certificate, and the external [Nginx](/deployment/nginx#emqx-api-over-https) must forward requests to port `18083`. The MQTT messages themselves still go unencrypted.
:::

[Prometheus](/deployment/dependencies/prometheus) reads metrics from the broker without a password; this is already configured in `docker-compose.yml`.

About MQTT:
- [Default MQTT commands](/developer/mqtt/default-mqtt-command)
- [Default MQTT state topics](/developer/mqtt/state-mqtt-send)
- [Structure of messages in MQTT topics](/developer/mqtt/struct-topic-messages)
