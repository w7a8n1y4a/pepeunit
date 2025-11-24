# Стандартные MQTT команды Pepeunit

:::warning
Команды которые поддерживает [Unit](/definitions#unit) должны быть отражены в [schema_example.json](/definitions#schema-example-json) в разделе `input_base_topic`.

[Unit](/definitions#unit) должен быть подписан на эти топики, при получении сообщения [Unit](/definitions#unit) должны следовать единому паттерну поведения описанному в данном разделе.
:::

Всего в [Pepeunit](/conception/overview) есть четыре команды - топика:
1. `UPDATE` - `update/pepeunit`
1. `SCHEMA_UPDATE` - `schema_update/pepeunit`
1. `ENV_UPDATE` - `env_update/pepeunit`
1. `LOG_SYNC` - `log_sync/pepeunit`

## UPDATE - update/pepeunit

:::info Когда вызывается данная команда?
1. Если происходит ручное обновление [Unit](/definitions#unit)
1. Если происходит автоматическое обновление [Unit](/definitions#unit)
1. Если команда была вызвана через отдельную кнопку в меню [Unit](/definitions#unit)
1. Если команда была вызвана через [REST](/definitions#rest) или [GQL](/definitions#gql)
:::

Данная команда отправляет [Unit](/definitions#unit) запрос на обновление, [Unit](/definitions#unit) в ответ должен выполнить опредлённый алгоритм действий, приводящий к изменению текущей версии программного кода, на новый.

### Формат сообщения в топик `update/pepeunit`
:::danger
Формат сообщения для [Компилируемых](/definitions#compilable) и [Интерпритируемых](/definitions#interpreterable) [Repo](/definitions#repo) отличается:
:::

[Компилируемые](/definitions#compilable):

```json
{
    "COMMAND": "Update",
    "PU_COMMIT_VERSION": "ad1ddee1e559153f6ea4ae33790f5980e32d61cf",
    "COMPILED_FIRMWARE_LINK": "https://git.pepemoss.com/api/v4/projects/281/packages/generic/release/0.0.2/picker-linux-amd64"
}
```

[Интерпритируемые](/definitions#interpreterable):

```json
{
    "COMMAND": "Update",
    "PU_COMMIT_VERSION": "ad1ddee1e559153f6ea4ae33790f5980e32d61cf"
}
```

### Алгоритм действий Unit
:::danger
Алгоритм [Unit](/definitions#unit) различается для [Компилируемых](/definitions#compilable) и [Интерпритируемых](/definitions#interpreterable) [Repo](/definitions#repo)
:::

[Компилируемые](/definitions#compilable):

1. Сверить версию `PU_COMMIT_VERSION` с текущей версией `PU_COMMIT_VERSION` из [env.json](/definitions#env-json), если совпали обновление прерывается, если не совпали - [Unit](/definitions#unit) начинает процесс обновления
1. Вычислить `uuid` [Unit](/definitions#unit) на основе `jwt` токена `PU_AUTH_TOKEN` из [env.json](/definitions#env-json)
1. Скачать архив `tgz`, `tar` или `zip` с [env.json](/definitions#env-json) и [schema.json](/definitions#schema-json) при помощи [REST](/definitions#rest). Переменные `PU_HTTP_TYPE` и `PU_DOMAIN` доступны внутри [env.json](/definitions#env-json):
    - `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/firmware/tgz/{Unit.uuid}?wbits=9&level=9` 
        - Доступные `wbits` - `(от -15 до -8) (от 9 до 16) (от 25 до 32)`
        - Доступные `level` - `(от -1 до 10)`
    - `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/firmware/tar/{Unit.uuid}`
    - `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/firmware/zip/{Unit.uuid}`
1. Распаковать из архива файлы [env.json](/definitions#env-json) и [schema.json](/definitions#schema-json)
1. Скачать новую скомпилированную часть по ссылке из `COMPILED_FIRMWARE_LINK` - [подробнее о предварительной компиляции](/developer/release-assets)
1. Запустить новую скомпилированную часть c прекращением работы старой

[Интерпритируемые](/definitions#interpreterable):

1. Сверить версию `PU_COMMIT_VERSION` с текущей версией `COMMIT_VERSION` из [env.json](/definitions#env-json), если совпали обновление прерывается, если не совпали [Unit](/definitions#unit) начинает процесс обновления
1. Вычислить `uuid` [Unit](/definitions#unit) на основе `jwt` токена `PU_AUTH_TOKEN` из [env.json](/definitions#env-json)
1. Скачать архив `tgz`, `tar` или `zip` с обновлением при помощи [REST](/definitions#rest). Переменные `PU_HTTP_TYPE` и `PU_DOMAIN` доступны внутри [env.json](/definitions#env-json):
    - `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/firmware/tgz/{Unit.uuid}?wbits=9&level=9` 
        - Доступные `wbits` - `(от -15 до -8) (от 9 до 16) (от 25 до 32)`
        - Доступные `level` - `(от -1 до 10)`
    - `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/firmware/tar/{Unit.uuid}`
    - `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/firmware/zip/{Unit.uuid}`
1. Распаковать из архива все файлы в отдельную дирректорию или область памяти
1. Заменить текущую версию программы на файлы из новой дирректории или области памяти
1. Перезапустить [Unit](/definitions#unit)

## SCHEMA_UPDATE - schema_update/pepeunit

:::info Когда вызывается данная команда?
1. Если команда была вызвана через отдельную кнопку в меню [Unit](/definitions#unit)
1. Если команда была вызвана через [REST](/definitions#rest) или [GQL](/definitions#gql)
:::

Данная команда отправляет [Unit](/definitions#unit) запрос на обновление [schema.json](/definitions#schema-json), [Unit](/definitions#unit) в ответ должен выполнить опредлённый алгоритм действий, приводящий к изменению текущей версии [schema.json](/definitions#schema-json), на новую.

### Формат сообщения в топик `schema_update/pepeunit`

```json
{
    "COMMAND": "SchemaUpdate"
}
```

### Алгоритм действий Unit

1. Скачать новую версию файла [schema.json](/definitions#schema-json) через [REST](/definitions#rest). Переменные `PU_HTTP_TYPE` и `PU_DOMAIN` доступны внутри [env.json](/definitions#env-json):
    - `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/get_current_schema/{Unit.uuid}`
1. Установить новое состояние для [schema.json](/definitions#schema-json) у [Unit](/definitions#unit)

## ENV_UPDATE - env_update/pepeunit

:::info Когда вызывается данная команда?
1. Если команда была вызвана через отдельную кнопку в меню [Unit](/definitions#unit)
1. Если команда была вызвана через [REST](/definitions#rest) или [GQL](/definitions#gql)
:::

Данная команда отправляет [Unit](/definitions#unit) запрос на обновление [env.json](/definitions#env-json), [Unit](/definitions#unit) в ответ должен выполнить опредлённый алгоритм действий, приводящий к изменению текущей версии [env.json](/definitions#env-json), на новую.

### Формат сообщения в топик `env_update/pepeunit`

```json
{
    "COMMAND": "EnvUpdate"
}
```

### Алгоритм действий Unit

1. Скачать новую версию файла [env.json](/definitions#env-json) через [REST](/definitions#rest). Переменные `PU_HTTP_TYPE` и `PU_DOMAIN` доступны внутри существующего [env.json](/definitions#env-json):
    - `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/env/{Unit.uuid}`
1. Установить новое состояние для [env.json](/definitions#env-json) у [Unit](/definitions#unit)

## LOG_SYNC - log_sync/pepeunit

:::info Когда вызывается данная команда?
1. Если команда была вызвана через отдельную кнопку в меню [Unit](/definitions#unit)
1. Если команда была вызвана через [REST](/definitions#rest) или [GQL](/definitions#gql)
:::

Данная команда отправляет [Unit](/definitions#unit) запрос на синхронизацию всех логов, которые есть в распоряжении [Unit](/definitions#unit) локально. При этом [Pepeunit](/conception/overview) принудительно удаляет все логи из [Clickhouse](/deployment/dependencies#clickhouse). [Unit](/definitions#unit) в ответ должен собрать все существующие логи и отправить их через [MQTT](/definitions#mqtt) в [Pepeunit](/conception/overview).

### Формат сообщения в топик `log_sync/pepeunit`

```json
{
    "COMMAND": "LogSync"
}
```

### Алгоритм действий Unit

1. Подготовить логи в нужном формате - [подробнее в разделе с топиком `log/pepeunit`](/developer/state-mqtt-send#log-pepeunit-output-base-topic)
1. Отправить подготовленные логи в топик `log/pepeunit` из раздела `output_base_topic`

:::info
Данная команда создана с целью упрощения отладки и контроля за [Unit](/definitions#unit). Т.к. не все ошибки можно получить через [MQTT](/definitions#mqtt) сразу же в момент их возникновения.
:::
