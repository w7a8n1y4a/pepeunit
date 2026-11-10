# env_example.json

:::warning What is env_example.json for?
It is a contract between the [Unit Developer](/development-pepeunit/mechanics/roles#unit-developer) and Pepeunit:
1. The Developer guarantees that the Unit uses all or some of the standard Pepeunit variables to communicate with it
1. Pepeunit guarantees that [Users](/development-pepeunit/mechanics/roles#user) will be able to set the variables the Developer specified
1. Pepeunit guarantees that it will fill in the standard variables itself when a User saves the env for the first time
:::

## Structure

```json
{
    "PIN_FAN": 0,
    "PIN_FAN_PWM_FREQUENCY": 10000,
    "PIN_DS18B20": 4,
    "REGULATOR_OPERATING_RANGE": 1000,
    "REGULATOR_TEMP_MIN": 30,
    "REGULATOR_TEMP_MAX": 60,
    "REGULATOR_DUTY_MIN": 8192,
    "REGULATOR_DUTY_MAX": 65535,
    "PUBLISH_SEND_INTERVAL": 1000,
    "PUC_WIFI_SSID": "ssid",
    "PUC_WIFI_PASS": "password",
    "PU_DOMAIN": "unit.example.com",
    "PU_HTTP_TYPE": "https",
    "PU_APP_PREFIX": "/pepeunit",
    "PU_API_ACTUAL_PREFIX": "/api/v1",
    "PU_MQTT_HOST": "emqx.example.com",
    "PU_MQTT_PORT": 1883,
    "PU_MQTT_PING_INTERVAL": 20,
    "PU_MQTT_KEEPALIVE": 60,
    "PU_AUTH_TOKEN": "jwt_token",
    "PU_SECRET_KEY": "32_bit_secret_key",
    "PU_ENCRYPT_KEY": "32_bit_encrypt_key",
    "PU_STATE_SEND_INTERVAL": 300,
    "PU_MIN_LOG_LEVEL": "Debug",
    "PU_MAX_LOG_LENGTH": 64
}
```

The variables are divided into standard ones (with the PU_ prefix) and Developer variables.

:::info
Standard variables may be omitted from the file: Pepeunit will add them to env.json itself. But development is easier with them, for example running a Unit on a computer without an instance. The values here are only a sample: the file lives in a public repository, so the values must be anonymized.
:::

## Standard Pepeunit variables

Pepeunit reserves these variables. The values in env.json are created by [Backend](/deployment/dependencies/backend):

Variable | Value in env.json | Purpose
-- | -- | --
PU_DOMAIN | PU_DOMAIN from the [Backend variables](/deployment/env-variables/backend) | Domain or ip of the instance
PU_HTTP_TYPE | https if PU_SECURE is True, otherwise http | Type of connection to Backend
PU_APP_PREFIX | PU_APP_PREFIX from the Backend variables | Backend prefix
PU_API_ACTUAL_PREFIX | PU_API_V1_PREFIX from the Backend variables | Prefix of the current API version
PU_MQTT_HOST | PU_MQTT_HOST from the Backend variables | Domain or ip of [EMQX](/deployment/dependencies/emqx)
PU_MQTT_PORT | PU_MQTT_PORT from the Backend variables | EMQX port, 1883 by default
PU_MQTT_PING_INTERVAL | 20 | How often the Unit sends an MQTT ping, in seconds
PU_MQTT_KEEPALIVE | pu_mqtt_keepalive from the [instance settings](/deployment/instance-settings#mqtt), 60 by default | How many seconds the MQTT connection is considered alive
PU_AUTH_TOKEN | jwt token | Permanent Unit token. With it the Unit is authorized in Backend and in EMQX
PU_SECRET_KEY | 32 bytes in base64 | Unique for every Unit. Convenient for signing or generating jwt
PU_ENCRYPT_KEY | 32 bytes in base64 | Unique for every Unit. Convenient for aes-gcm-256 encryption
PU_STATE_SEND_INTERVAL | pu_instance_unit_state_send_interval from the [instance settings](/deployment/instance-settings#unit), 60 by default | How often the Unit sends the [state](/developer/mqtt/state-mqtt-send#message-format-for-the-statepepeunit-topic), in seconds. It is accepted no more often than once per this interval, [details](/developer/mqtt/state-mqtt-send#statepepeunit-output_base_topic)
PU_MIN_LOG_LEVEL | Debug | The lowest log level that is sent over MQTT and written to [log.json](/developer/libraries/framework#logjson). If you set Warning, Debug and Info are not sent
PU_MAX_LOG_LENGTH | 64 | How many lines [log.json](/developer/libraries/framework#logjson) keeps. Old lines are deleted
PU_COMMIT_VERSION | Commit hash | The current [target version](/development-pepeunit/mechanics/update-system#algorithm-for-calculating-the-current-unit-version) of the Unit. It cannot be changed by hand: the value is ignored on save

## Developer variables

A [Unit Developer](/development-pepeunit/mechanics/roles#unit-developer) can add any variables whose names do not match the standard ones. Their values from the file become the defaults in the [User](/development-pepeunit/mechanics/roles#user) interface.

:::danger
The User fills in the variables by hand, so describe each one in pepeunit.toml and readme.md.
:::

How the final env.json is assembled is described by the [ENV generation mechanism](/development-pepeunit/mechanics/alg-env).
