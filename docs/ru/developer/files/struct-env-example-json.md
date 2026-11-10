# env_example.json

:::warning Для чего нужен env_example.json?
Это контракт между [Разработчиком Unit](/development-pepeunit/mechanics/roles#unit-developer) и Pepeunit:
1. Разработчик гарантирует, что Unit использует все или часть стандартных переменных Pepeunit для связи с ним
1. Pepeunit гарантирует, что [Пользователи](/development-pepeunit/mechanics/roles#user) смогут задать переменные, которые указал Разработчик
1. Pepeunit гарантирует, что сам заполнит стандартные переменные, когда Пользователь впервые сохранит env
:::

## Структура

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

Переменные делятся на стандартные (с префиксом PU_) и переменные Разработчика.

:::info
Стандартные переменные можно не указывать в файле: Pepeunit добавит их в env.json сам. Но с ними проще разрабатывать, например запускать Unit на компьютере без инстанса. Значения здесь только образец: файл лежит в публичном репозитории, поэтому значения должны быть обезличены.
:::

## Стандартные переменные Pepeunit

Pepeunit резервирует эти переменные. Значения в env.json создаёт [Backend](/deployment/dependencies/backend):

Переменная | Значение в env.json | Зачем нужна
-- | -- | --
PU_DOMAIN | PU_DOMAIN из [переменных Backend](/deployment/env-variables/backend) | Домен или ip инстанса
PU_HTTP_TYPE | https, если PU_SECURE равна True, иначе http | Тип соединения с Backend
PU_APP_PREFIX | PU_APP_PREFIX из переменных Backend | Префикс Backend
PU_API_ACTUAL_PREFIX | PU_API_V1_PREFIX из переменных Backend | Префикс актуальной версии API
PU_MQTT_HOST | PU_MQTT_HOST из переменных Backend | Домен или ip [EMQX](/deployment/dependencies/emqx)
PU_MQTT_PORT | PU_MQTT_PORT из переменных Backend | Порт EMQX, по умолчанию 1883
PU_MQTT_PING_INTERVAL | 20 | Как часто Unit шлёт MQTT пинг, в секундах
PU_MQTT_KEEPALIVE | pu_mqtt_keepalive из [настроек инстанса](/deployment/instance-settings#mqtt), по умолчанию 60 | Сколько секунд MQTT соединение считается живым
PU_AUTH_TOKEN | jwt токен | Бессрочный токен Unit. По нему Unit проходит авторизацию в Backend и в EMQX
PU_SECRET_KEY | 32 байта в base64 | Уникален для каждого Unit. Удобен для подписи или генерации jwt
PU_ENCRYPT_KEY | 32 байта в base64 | Уникален для каждого Unit. Удобен для шифрования aes-gcm-256
PU_STATE_SEND_INTERVAL | pu_instance_unit_state_send_interval из [настроек инстанса](/deployment/instance-settings#unit), по умолчанию 60 | Как часто Unit шлёт [состояние](/developer/mqtt/state-mqtt-send#формат-сообщении-в-топик-state-pepeunit), в секундах. Принимается не чаще, чем раз в этот интервал, [подробнее](/developer/mqtt/state-mqtt-send#state-pepeunit-output-base-topic)
PU_MIN_LOG_LEVEL | Debug | Наименьший уровень лога, который уходит по MQTT и пишется в [log.json](/developer/libraries/framework#log-json). Если указать Warning, то Debug и Info не отправятся
PU_MAX_LOG_LENGTH | 64 | Сколько строк хранит [log.json](/developer/libraries/framework#log-json). Старые строки удаляются
PU_COMMIT_VERSION | Хэш коммита | Текущая [таргет версия](/development-pepeunit/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit) Unit. Вручную её не поменять: при сохранении значение игнорируется

## Переменные Разработчика

[Разработчик Unit](/development-pepeunit/mechanics/roles#unit-developer) может добавить любые переменные, названия которых не совпадают со стандартными. Их значения из файла станут значениями по умолчанию в интерфейсе [Пользователя](/development-pepeunit/mechanics/roles#user).

:::danger
Пользователь заполняет переменные вручную, поэтому опишите каждую в pepeunit.toml и readme.md.
:::

Как собирается итоговый env.json, описывает [механизм генерации ENV](/development-pepeunit/mechanics/alg-env).
