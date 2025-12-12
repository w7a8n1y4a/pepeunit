# env_example.json

::::warning What is the purpose of [env_example.json](/en/definitions#env-example-json)?
[env_example.json](/en/definitions#env-example-json) is a contract between the [Unit Developer](/en/development-pepeunit/mechanics/roles#unit-developer) and [Pepeunit](/en/conception/overview):

1. The [Unit Developer](/en/development-pepeunit/mechanics/roles#unit-developer) guarantees that they will implement in the [Unit](/en/definitions#unit) logic all or some of the standard [Pepeunit](/en/conception/overview) variables required for integration with [Pepeunit](/en/conception/overview).
1. [Pepeunit](/en/conception/overview) guarantees that [Users](/en/development-pepeunit/mechanics/roles#user) will be able to set the variables specified by the [Unit Developer](/en/development-pepeunit/mechanics/roles#unit-developer).
1. [Pepeunit](/en/conception/overview) guarantees that it will automatically populate the standard variables defined in this file when the [User](/en/development-pepeunit/mechanics/roles#user) first saves the `env`.
::::

## Structure

```json
{   
    "WIFI_SSID": "ssid",
    "WIFI_PASS": "password",
    "PWM_FAN_PIN": 0,
    "DS18B20_PIN_NUM": 4,
    "REGULATOR_OPERATING_RANGE": 1000,
    "PUBLISH_SEND_INTERVAL": 1,
    "TEMP_MIN": 30,
    "TEMP_MAX": 60,
    "DUTY_MIN": 8192,
    "DUTY_MAX": 65535,
    "PU_DOMAIN": "unit.example.com",
    "PU_HTTP_TYPE": "https",
    "PU_APP_PREFIX": "/pepeunit",
    "PU_API_ACTUAL_PREFIX": "/api/v1",
    "PU_MQTT_HOST": "emqx.example.com",
    "PU_MQTT_PORT": 1883,
    "PU_MQTT_PING_INTERVAL": 30,
    "PU_AUTH_TOKEN": "jwt_token",
    "PU_SECRET_KEY": "32_bit_secret_key",
    "PU_ENCRYPT_KEY": "32_bit_encrypt_key",
    "PU_STATE_SEND_INTERVAL": 300,
    "PU_MIN_LOG_LEVEL": "Debug",
    "PU_MAX_LOG_LENGTH": 64
}
```

You can divide the variables into two categories: **standard variables** and **developer environment variables**.

## Standard Pepeunit variables

[Pepeunit](/en/conception/overview) reserves the following set of environment variables for a [Unit](/en/definitions#unit):

Variable | Generated value in `env.json` | Purpose
-- | -- | --
`PU_DOMAIN` | `PU_DOMAIN` from [Backend ENV](/en/deployment/env-variables/backend) | Domain name or IP address of the [Pepeunit](/en/conception/overview) instance.
`PU_HTTP_TYPE` | `PU_SECURE` from [Backend ENV](/en/deployment/env-variables/backend) | Connection type `https/http` to the [Backend](/en/deployment/dependencies/backend) domain or IP, in the `https/http` format.
`PU_APP_PREFIX` | `PU_APP_PREFIX` from [Backend ENV](/en/deployment/env-variables/backend) | [Backend](/en/deployment/dependencies/backend) prefix.
`PU_API_ACTUAL_PREFIX` | `PU_API_V1_PREFIX` from [Backend ENV](/en/deployment/env-variables/backend) | Prefix of the current [API](/en/definitions#api) version of the [Backend](/en/deployment/dependencies/backend). Always points to the latest [API](/en/definitions#api) version.
`PU_MQTT_HOST` | `PU_MQTT_HOST` from [Backend ENV](/en/deployment/env-variables/backend) | Domain or IP address of the [EMQX](/en/deployment/dependencies/emqx) instance.
`PU_MQTT_PORT` | `PU_MQTT_PORT` from [Backend ENV](/en/deployment/env-variables/backend) | Port for communication with [EMQX](/en/deployment/dependencies/emqx), `1883` by default.
`PU_MQTT_PING_INTERVAL` | `30` | [MQTT](/en/definitions#mqtt) ping interval in seconds (`30` seconds for everyone).
`PU_AUTH_TOKEN` | `jwt` token | Permanent access token of the [Unit](/en/definitions#unit) to the [Pepeunit](/en/conception/overview) instance. This token is used to authorize subscriptions and publications in [EMQX](/en/deployment/dependencies/emqx) topics and is set automatically by the [Backend](/en/deployment/dependencies/backend).
`PU_SECRET_KEY` | `32‑byte key` in `base64` format | Unique for each [Unit](/en/definitions#unit). Convenient for signing or generating JWTs. Set automatically by the [Backend](/en/deployment/dependencies/backend).
`PU_ENCRYPT_KEY` | `32‑byte key` in `base64` format | Unique for each [Unit](/en/definitions#unit). Convenient for `aes-gcm-256` encryption. Set automatically by the [Backend](/en/deployment/dependencies/backend).
`PU_STATE_SEND_INTERVAL` | `PU_STATE_SEND_INTERVAL` from [Backend ENV](/en/deployment/env-variables/backend) | Interval for sending state to the [standard state topic](/en/developer/mqtt/state-mqtt-send#message-format-for-the-state-pepeunit-topic).
`PU_MIN_LOG_LEVEL` | `Debug` | Minimum log level that will be sent over [MQTT](/en/definitions#mqtt) and stored in the [log.json](/en/developer/libraries/framework#log-json) file. For example, if you set it to `Warning`, then `Debug` and `Info` messages will not be sent.
`PU_MAX_LOG_LENGTH` | `64` | Maximum number of lines in [log.json](/en/developer/libraries/framework#log-json); old lines are removed from the beginning of the file.
`PU_COMMIT_VERSION` | [Commit](/en/definitions#git-commit) hash | Shows the current [target version](/en/development-pepeunit/mechanics/update-system#algorithm-for-calculating-the-current-unit-version) of the [Unit](/en/definitions#unit). It has special behavior: it cannot be changed manually in the [env.json](/en/definitions#env-json) editing UI; any attempt to change it will be ignored.

## Unit Developer environment variables

The [Unit Developer](/en/development-pepeunit/mechanics/roles#unit-developer) can create any environment variables whose names differ from the standard ones. The values defined in these variables will be shown as default values in the [User](/en/development-pepeunit/mechanics/roles#user) interface.

::::danger
Since in the end it is the [User](/en/development-pepeunit/mechanics/roles#user) who will fill in the variables manually, you must always provide [pepeunit.toml](/en/definitions#pepeunit-toml) and [readme.md](/en/definitions#readme-md) so that the [User](/en/development-pepeunit/mechanics/roles#user) can understand what each variable controls.
::::

::::danger
[env.json](/en/definitions#env-json) is filled by the [User](/en/development-pepeunit/mechanics/roles#user) based on the [ENV generation mechanism](/en/development-pepeunit/mechanics/alg-env).
::::


