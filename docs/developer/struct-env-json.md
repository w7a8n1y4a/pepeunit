# Структура env.json и env_example.json

## env_example.json

:::warning Какое функциональное назначание у [env_example.json](/definitions#env-example-json)?
Данный файл - это контракт между разработчиком [Unit](/definitions#unit) и [Pepeunit](/conception/overview):
1. Разработчик гарантирует, что он реализует в функционале [Unit](/definitions#unit) все или часть зарезервированных переменных [Pepeunit](/conception/overview), позволяющих взаимодействовать с [Pepeunit](/conception/overview)
1. [Pepeunit](/conception/overview) гарантирует возможность [Пользователей](/mechanics/roles.html#user) установить переменные указанные разработчиком
1. [Pepeunit](/conception/overview) гарантирует, что автоматически установит зарезервированные переменные указанные в файле при первом сохранении со стороны [Пользователя](/mechanics/roles.html#user).
:::

### Структура
```json
{
    "WIFI_SSID": "My_Perfect_Wifi_SSID",
    "WIFI_PASS": "Strong_Password",
    "PUBLISH_SEND_INTERVAL": 10,
    "DUTY_MIN": 8192,
    "DUTY_MAX": 65535,
    "TEMP_MIN": 30,
    "TEMP_MAX": 60,
    "PEPEUNIT_URL": "unit.example.com",
    "PEPEUNIT_APP_PREFIX": "/pepeunit",
    "PEPEUNIT_API_ACTUAL_PREFIX": "/api/v1",
    "HTTP_TYPE": "https",
    "MQTT_URL": "emqx.example.com",
    "MQTT_PORT": 1883,
    "PEPEUNIT_TOKEN": "jwt_token",
    "SYNC_ENCRYPT_KEY": "32_bit_encrypt_key",
    "SECRET_KEY": "32_bit_secret_key",
    "PING_INTERVAL": 30,
    "STATE_SEND_INTERVAL": 300,
    "MIN_LOG_LEVEL": "Debug",
    "MAX_LOG_LENGTH": 64
}
```

Переменные можно разделить на две категории - `зарезервированные` и `переменные разработчика`

### Зарезервированные переменные Pepeunit

[Pepeunit](/conception/overview) резервирует под нужды связи и стандартные процедуры следующий набор переменных окружения [Unit](/definitions#unit):

Переменная | Значение | Зачем нужна?
-- | -- | --
`PEPEUNIT_URL` | `BACKEND_DOMAIN` из [Backend ENV](/deployment/env-variables#backend) | Доменное имя или `ip` адрес [инстанса](/definitions#instance) [Pepeunit](/conception/overview)
`PEPEUNIT_APP_PREFIX` | `BACKEND_APP_PREFIX` из [Backend ENV](/deployment/env-variables#backend) | Префикс [Backend](/definitions#backend)
`PEPEUNIT_API_ACTUAL_PREFIX` | `BACKEND_API_V1_PREFIX` из [Backend ENV](/deployment/env-variables#backend) | Префикс актауальной версии [API](/definitions#api) для [Backend](/definitions#backend). Полностью соответствует последней версии [API](/definitions#api)
`HTTP_TYPE` | `BACKEND_SECURE` из [Backend ENV](/deployment/env-variables#backend) | Тип соединения `https/http` с доменным именем или `ip` адресом [Backend](/definitions#backend) в формате `https/http`
`MQTT_URL` | `MQTT_HOST` из [Backend ENV](/deployment/env-variables#backend) | Доменное имя или `ip` - адрес [инстанса](/definitions#instance) [EMQX MQTT Broker](/definitions#mqtt-broker)
`MQTT_PORT` | `MQTT_PORT` из [Backend ENV](/deployment/env-variables#backend) | Порт для взаимодействия с [EMQX MQTT Broker](/definitions#mqtt-broker), по умолчанию `1883`
`PEPEUNIT_TOKEN` | - | Вечный `jwt` токен доступа [Unit](/definitions#unit) к [инстансу](/definitions#instance) [Pepeunit](/conception/overview). Данный токен позволяет пройти авторизацию на подписку и публикацию у топиков [EMQX MQTT Broker](/definitions#mqtt-broker)
`SYNC_ENCRYPT_KEY` | - | `32 байтовый ключ` в формате `base64`. Уникальный для каждого [Unit](/definitions#unit). Удобно использовать при шифровании чего-либо
`SECRET_KEY` | - | `32 байтовый ключ` в формате `base64`. Уникальный для каждого [Unit](/definitions#unit). Удобно использовать для подписи или генерации `jwt`
`PING_INTERVAL` | - | Частота [MQTT](/definitions#mqtt) пинга в секундах, `30` секунд для всех
`STATE_SEND_INTERVAL` | `BACKEND_STATE_SEND_INTERVAL` из [Backend ENV](/deployment/env-variables#backend) | Частота отправки состояния в [стандартный топик состояния](/developer/state-mqtt-send#формат-сообщении-в-топик-state-pepeunit)
`MIN_LOG_LEVEL` | `Debug` | Минимальный уровень лога, который будет отправляться по [MQTT](/definitions#mqtt) и сохраняться в файл [log.json](/libraries/framework#log-json). Если установить например `Warning`, то `Debug` и `Info` отправляться не будут
`MAX_LOG_LENGTH` | `64` | Максимальное число строк в файле [log.json](/libraries/framework#log-json), удаляются строки из начала файла, сохрняются в конец.
`COMMIT_VERSION` | - | `Hash` [коммита](/definitions#git-commit). Отображает текущую [таргет версию](/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit) [Unit](/definitions#unit). Имеет уникальный функционал, её нельзя изменить вручную в меню изменения [env.json](/definitions#env-json), она будет игнорироваться при сохранении

### Переменные окружения от разработчика [Unit](/definitions#unit)

Разработчик [Unit](/definitions#unit) может создавать любые переменные окружения, которые отличаются по названию от стандартных. При этом значения указанные в переменных, будут отображаться как значения по умолчанию в интерфейсе [Пользователей](/mechanics/roles.html#user).

:::danger
Так как [Пользователь](/mechanics/roles.html#user) в итоге будет заполнять переменные в ручную, очень желательно заполнить [Readme](/definitions#readme-file) репозитория, который вы создаёте.
:::

:::danger
Заполнение [env.json](/definitions#env-json) пользовтелем происходит на основе: [Механизм генерации ENV](/mechanics/alg-env)
:::

## env.json

Файлы окружения, такие как [env.json](/definitions#env-json) или [Backend ENV](/deployment/env-variables#backend), представляют собой механизм индивидуализации общего кода под конкретное устройство или экземпляр приложения.

:::warning Какое функциональное назначание у [env.json](/definitions#env-json)?
Данный файл - это четырёхсторонний контракт между [Unit](/definitions#unit), [Pepeunit](/conception/overview), [Пользователем](/mechanics/roles.html#user) и [Администратором](/mechanics/roles#admin) [инстанса](/definitions#instance) [Pepeunit](/conception/overview):
1. [Unit](/definitions#unit) гарантирует всем сторонам, что будет использовать для соответствующих значений из [env_example.json](/definitions#env-example-json) значения из [env.json](/definitions#env-json)
1. [Pepeunit](/conception/overview) гарантирует всем сторонам, что при первой установке переменных окружения в [env.json](/definitions#env-json), сгенерирует зарезервированные переменные
1. [Pepeunit](/conception/overview) гарантирует всем сторонам, что [Unit](/definitions#unit) сможет пройти авторизацию для топиков и соединений в [EMQX MQTT Broker](/definitions#mqtt-broker), авторизацию [Backend](/definitions#backend) с использованием `PEPEUNIT_TOKEN`
1. [Pepeunit](/conception/overview) гарантирует всем сторонам, возможность изменения [env.json](/definitions#env-json)
1. [Pepeunit](/conception/overview) гарантирует всем сторонам, что [env.json](/definitions#env-json) будет храниться в [шифрованном виде](/mechanics/cipher#шифрование)
1. [Pepeunit](/conception/overview) гарантирует всем сторонам, что доступ до [env.json](/definitions#env-json) будет предоставлен только создателю [Unit](/definitions#unit)
1. [Aдминистратор](/mechanics/roles#admin) гарантирует всем сторонам, что [env.json](/definitions#env-json) ни в каком виде не будет передан тем кто не явялется стороной данного контракта.
:::

::: danger
Используйте только доверенные [инстансы](/definitions#instance) [Pepeunit](/conception/overview). Следите, чтобы [Администратор](/mechanics/roles#admin) [инстанса](/definitions#instance) [Pepeunit](/conception/overview) выполнял свои контрактные обязательства, связанные с [env.json](/definitions#env-json).
:::

:::info Какие основные свойства можно выделить у [env.json](/definitions#env-json)?
1. [env.json](/definitions#env-json) файл секретен, его нельзя передавать кому-либо
1. [env.json](/definitions#env-json) файл позволяет удобно конфигурировать и обновлять состояние [Unit](/definitions#unit) без полного обновления файлов программы
1. [env.json](/definitions#env-json) файл позволяет [Unit](/definitions#unit) знать какому [инстансу](/definitions#instance) [Pepeunit](/conception/overview) он принадлежит
1. [env.json](/definitions#env-json) файл при помощи переменной PEPEUNIT_TOKEN позволяет [Pepeunit](/conception/overview) производить авторизацию для конкретных [Unit](/definitions#unit)
:::