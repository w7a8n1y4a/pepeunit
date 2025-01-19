# Структура env.json и env_example.json

## env_example.json

:::warning Какое функциональное назначание у [env_example.json](/definitions#env-example-json)?
Данный файл - это контракт между разработчиком [Unit](/definitions#unit) и [Pepeunit](/conception/overview):
1. Разработчик гарантирует, что он реализует в функционале [Unit](/definitions#unit) зарезервированные переменные [Pepeunit](/conception/overview), позволяющие взаимодействовать с [Pepeunit](/conception/overview)
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
    "PEPEUNIT_URL": "unit.pepemoss.com",
    "HTTP_TYPE": "https",
    "MQTT_URL": "emqx.pepemoss.com",
    "PEPEUNIT_TOKEN": "jwt_token",
    "SYNC_ENCRYPT_KEY": "32_bit_encrypt_key",
    "SECRET_KEY": "32_bit_secret_key",
    "PING_INTERVAL": 30,
    "STATE_SEND_INTERVAL": 300
}
```

Переменные можно разделить на две категории - `зарезервированные` и `переменные разработчика`

### Зарезервированные переменные Pepeunit

[Pepeunit](/conception/overview) резервирует под нужды связи и стандартные процедуры следующий набор переменных окружения [Unit](/definitions#unit):
- `PEPEUNIT_URL` - доменное имя или `ip` адрес [инстанса](/definitions#instance) [Pepeunit](/conception/overview). Полностью соответствует `BACKEND_DOMAIN` из `.env` файла [Pepeunit](/conception/overview)
- `HTTP_TYPE` - тип соединения с доменным именем или адресом [инстанса](/definitions#instance) [Pepeunit](/conception/overview). Полностью соответствует `SECURE` из `.env` файла [Pepeunit](/conception/overview)
- `MQTT_URL` - доменное имя или `ip` адрес [инстанса](/definitions#instance) [EMQX MQTT Broker](/definitions#mqtt-broker). Полностью соответствует `MQTT_URL` из `.env` файла [Pepeunit](/conception/overview)
- `PEPEUNIT_TOKEN` - `jwt` токен доступа для [Unit](/definitions#unit) на [инстансе](/definitions#instance) [Pepeunit](/conception/overview). Данный токен позволяет пройти авторизацию на публикацию и подписку у топиков [EMQX MQTT Broker](/definitions#mqtt-broker)
- `SYNC_ENCRYPT_KEY` - `32 байтовый` ключ синхронного шифрования - уникальный для каждого [Unit](/definitions#unit). Удобно использовать при шифровании чего-либо
- `SECRET_KEY` - `32 байтовый` секретный ключ устройства - уникальный для каждого [Unit](/definitions#unit). Удобно использовать для подписи или генерации `jwt`
- `PING_INTERVAL` - частота [MQTT](/definitions#mqtt) пинга в секундах
- `STATE_SEND_INTERVAL` - частота отправки состояния в стандартный топик [Pepeunit](/conception/overview). Полностью соответствует `STATE_SEND_INTERVAL` из `.env` файла [Pepeunit](/conception/overview)
- `COMMIT_VERSION` - уникальная переменная, не отображается [Пользователю](/mechanics/roles.html#user), но подставляется каждый раз когда [env.json](/definitions#env-json) предоставляется [Unit](/definitions#unit) в формате архива.

### Переменные окружения разработчика [Unit](/definitions#unit)

Разработчик [Unit](/definitions#unit) может создавать любые переменные окружения, которые отличаются по названию от стандартных. При этом значения указанные в переменных, будут отображаться как значения по умолчанию в интерфейсе [Пользователей](/mechanics/roles.html#user).

:::danger
Так как Пользователь имеет возможность заполнять значение переменных окружения, очень желательно заполнить readme репозитория, который вы создаёте.
:::

:::info Пользовательский опыт
При первой попытке [Пользователя](/mechanics/roles.html#user) установить переменные окружения, он изначально видит только переменные которые добавил разработчик [Unit](/definitions#unit) через [env_example.json](/definitions#env-example-json).
:::

## env.json

Файлы окружения, такие как [env.json](/definitions#env-json) или `.env`, представляют собой механизм индивидуализации общего кода под конкретное устройство или экземпляр приложения.

:::warning Какое функциональное назначание у [env.json](/definitions#env-json)?
Данный файл - это четырёхсторонний контракт между [Unit](/definitions#unit), [Pepeunit](/conception/overview), [Пользователем](/mechanics/roles.html#user) и [Администратором](/mechanics/roles#admin) [инстанса](/definitions#instance) [Pepeunit](/conception/overview):
1. [Unit](/definitions#unit) гарантирует всем сторонам, что будет использовать для соответствующих значений из [env_example.json](/definitions#env-example-json) значения из [env.json](/definitions#env-json)
1. [Pepeunit](/conception/overview) гарантирует всем сторонам, что при первой установке переменных окружения в [env.json](/definitions#env-json), сгенерирует зарезервированные переменные
1. [Pepeunit](/conception/overview) гарантирует всем сторонам, что [Unit](/definitions#unit) сможет пройти авторизацию для топиков и соединений в [EMQX MQTT Broker](/definitions#mqtt-broker), авторизацию [Backend](/definitions#backend) с использованием `PEPEUNIT_TOKEN`
1. [Pepeunit](/conception/overview) гарантирует всем сторонам, возможность изменения [env.json](/definitions#env-json)
1. [Pepeunit](/conception/overview) гарантирует всем сторонам, что [env.json](/definitions#env-json) будет храниться в шифрованном виде
1. [Pepeunit](/conception/overview) гарантирует всем сторонам, что доступ до [env.json](/definitions#env-json) будет предоставлен только создателю [Unit](/definitions#unit)
1. [Aдминистратор](/mechanics/roles#admin) гарантирует всем сторонам, что [env.json](/definitions#env-json) ни в каком виде не будет передан тем кто не явялется стороной данного контракта.
:::

::: danger
Используйте только доверенные [инстансы](/definitions#instance) [Pepeunit](/conception/overview). Следите, чтобы [Администратор](/mechanics/roles#admin) [инстанса](/definitions#instance) [Pepeunit](/conception/overview) выполнял свои контрактные обязательства, связанные с [env.json](/definitions#env-json).
:::

:::info Какие основные свойства можно выделить у [env.json](/definitions#env-json)?
1. [env.json](/definitions#env-json) файл секретен, его нельзя передавать кому-либо
1. [env.json](/definitions#env-json) файл позволяет удобно конфигурировать и обновлять [Unit](/definitions#unit)
1. [env.json](/definitions#env-json) файл позволяет [Unit](/definitions#unit) знать какому [инстансу](/definitions#instance) [Pepeunit](/conception/overview) он принадлежит
1. [env.json](/definitions#env-json) файл при помощи переменной PEPEUNIT_TOKEN позволяет [Pepeunit](/conception/overview) производить авторизацию для конкретных [Unit](/definitions#unit)
:::