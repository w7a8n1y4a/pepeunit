# env_example.json

:::warning Какое функциональное назначание у [env_example.json](/definitions#env-example-json)?
Данный файл - это контракт между разработчиком [Unit](/definitions#unit) и [Pepeunit](/conception/overview):
1. Разработчик гарантирует, что он реализует в функционале [Unit](/definitions#unit) все или часть стандартных переменных [Pepeunit](/conception/overview), позволяющих взаимодействовать с [Pepeunit](/conception/overview)
1. [Pepeunit](/conception/overview) гарантирует возможность [Пользователей](/development-pepeunit/mechanics/roles.html#user) установить переменные указанные разработчиком
1. [Pepeunit](/conception/overview) гарантирует, что автоматически установит стандартные переменные указанные в файле при первом сохранении `env` со стороны [Пользователя](/development-pepeunit/mechanics/roles.html#user).
:::

### Структура
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

Переменные можно разделить на две категории - `стандартные` и `переменные разработчика`

### Стандартные переменные Pepeunit

[Pepeunit](/conception/overview) резервирует следующий набор переменных окружения [Unit](/definitions#unit):

Переменная | Генерируемое значение в `env.json` | Зачем нужна?
-- | -- | --
`PU_DOMAIN` | `PU_DOMAIN` из [Backend ENV](/deployment/env-variables/backend) | Доменное имя или `ip` адрес [инстанса](/definitions#instance) [Pepeunit](/conception/overview)
`PU_HTTP_TYPE` | `PU_SECURE` из [Backend ENV](/deployment/env-variables/backend) | Тип соединения `https/http` с доменным именем или `ip` адресом [Backend](/deployment/dependencies/backend) в формате `https/http`
`PU_APP_PREFIX` | `PU_APP_PREFIX` из [Backend ENV](/deployment/env-variables/backend) | Префикс [Backend](/deployment/dependencies/backend)
`PU_API_ACTUAL_PREFIX` | `PU_API_V1_PREFIX` из [Backend ENV](/deployment/env-variables/backend) | Префикс актауальной версии [API](/definitions#api) для [Backend](/deployment/dependencies/backend). Полностью соответствует последней версии [API](/definitions#api)
`PU_MQTT_HOST` | `PU_MQTT_HOST` из [Backend ENV](/deployment/env-variables/backend) | Доменное имя или `ip` - адрес [инстанса](/definitions#instance) [EMQX](/deployment/dependencies/emqx)
`PU_MQTT_PORT` | `PU_MQTT_PORT` из [Backend ENV](/deployment/env-variables/backend) | Порт для взаимодействия с [EMQX](/deployment/dependencies/emqx), по умолчанию `1883`
`PU_MQTT_PING_INTERVAL` | 30 | Частота [MQTT](/definitions#mqtt) пинга в секундах, `30` секунд для всех
`PU_AUTH_TOKEN` | `jwt` токен | Вечный токен доступа [Unit](/definitions#unit) к [инстансу](/definitions#instance) [Pepeunit](/conception/overview). Данный токен позволяет пройти авторизацию на подписку и публикацию у топиков [EMQX](/deployment/dependencies/emqx), устанавливается [Backend](/deployment/dependencies/backend) автоматически.
`PU_SECRET_KEY` | `32 байтовый ключ` в формате `base64` | Уникальный для каждого [Unit](/definitions#unit). Удобно использовать для подписи или генерации `jwt`. Устанавливается [Backend](/deployment/dependencies/backend) автоматически
`PU_ENCRYPT_KEY` | `32 байтовый ключ` в формате `base64` | Уникальный для каждого [Unit](/definitions#unit). Удобно использовать для шифрования методом `aes-gcm-256`. Устанавливается [Backend](/deployment/dependencies/backend) автоматически
`PU_STATE_SEND_INTERVAL` | `PU_STATE_SEND_INTERVAL` из [Backend ENV](/deployment/env-variables/backend) | Частота отправки состояния в [стандартный топик состояния](/developer/mqtt/state-mqtt-send#формат-сообщении-в-топик-state-pepeunit)
`PU_MIN_LOG_LEVEL` | `Debug` | Минимальный уровень лога, который будет отправляться по [MQTT](/definitions#mqtt) и сохраняться в файл [log.json](/developer/libraries/framework#log-json). Если установить например `Warning`, то `Debug` и `Info` отправляться не будут
`PU_MAX_LOG_LENGTH` | `64` | Максимальное число строк в файле [log.json](/developer/libraries/framework#log-json), удаляются строки из начала файла, сохрняются в конец.
`PU_COMMIT_VERSION` | `Hash` [коммита](/definitions#git-commit) | Отображает текущую [таргет версию](/development-pepeunit/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit) [Unit](/definitions#unit). Имеет уникальный функционал, её нельзя изменить вручную в меню изменения [env.json](/definitions#env-json), она будет игнорироваться при сохранении

### Переменные окружения Разработчика [Unit](/definitions#unit)

Разработчик [Unit](/definitions#unit) может создавать любые переменные окружения, которые отличаются по названию от стандартных. При этом значения указанные в переменных, будут отображаться как значения по умолчанию в интерфейсе [Пользователей](/development-pepeunit/mechanics/roles.html#user).

:::danger
Так как [Пользователь](/development-pepeunit/mechanics/roles.html#user) в итоге будет заполнять переменные в ручную, всегда нужно заполнить [pepeunit.toml](/definitions#pepeunit-toml) и [readme.md](/definitions#readme-md), чтобы Пользователь мог понять за что отвечает каждая переменная
:::

:::danger
Заполнение [env.json](/definitions#env-json) пользовтелем происходит на основе: [Механизма генерации ENV](/development-pepeunit/mechanics/alg-env)
:::
