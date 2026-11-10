# Стандартные MQTT команды Pepeunit

:::warning
Команды, которые поддерживает Unit, должны быть указаны в schema_example.json в разделе input_base_topic. Backend шлёт команду только в топик, который там есть.

Unit должен быть подписан на эти топики и при получении сообщения вести себя так, как описано ниже.
:::

В Pepeunit пять команд, у каждой свой топик:
1. UPDATE: update/pepeunit
1. SCHEMA_UPDATE: schema_update/pepeunit
1. ENV_UPDATE: env_update/pepeunit
1. LOG_SYNC: log_sync/pepeunit
1. RESET: reset/pepeunit

Во всех запросах ниже PU_HTTP_TYPE, PU_DOMAIN и PU_AUTH_TOKEN берутся из env.json. Токен передаётся в заголовке x-auth-token.

Любую команду можно вызвать по кнопке в клиенте: `Аппараты` → Unit → `Управление аппаратом` → `Команды`, или [через REST](#отправка-команды-через-rest).

## UPDATE - update/pepeunit

Команда просит Unit обновиться: Unit выполняет алгоритм ниже и переходит на новую версию программы. Кроме кнопки и REST, она вызывается при ручном обновлении Unit и при автоматическом: после смены настроек Unit, раз в час по расписанию и по запросу администратора, сразу для всех Unit.

### Формат сообщения в топик update/pepeunit

Для компилируемых и интерпретируемых Unit формат разный.

Компилируемые:

```json
{
    "COMMAND": "Update",
    "PU_COMMIT_VERSION": "ad1ddee1e559153f6ea4ae33790f5980e32d61cf",
    "COMPILED_FIRMWARE_LINK": "https://git.pepemoss.com/api/v4/projects/281/packages/generic/release/0.0.2/picker-linux-amd64"
}
```

Интерпретируемые:

```json
{
    "COMMAND": "Update",
    "PU_COMMIT_VERSION": "ad1ddee1e559153f6ea4ae33790f5980e32d61cf"
}
```

### Алгоритм действий Unit

Для компилируемых и интерпретируемых Unit алгоритм разный.

Компилируемые:

1. Сравнить PU_COMMIT_VERSION из сообщения с PU_COMMIT_VERSION из env.json. Если совпали, обновление прекращается
1. Получить uuid Unit из токена PU_AUTH_TOKEN из env.json
1. Скачать архив tgz, tar или zip с env.json и schema.json:
    - `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/firmware/tgz/{Unit.uuid}?wbits=9&level=9`
        - wbits: от -15 до -9, от 9 до 15 или от 25 до 31, по умолчанию 9
        - level: от -1 до 9, по умолчанию 9
    - `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/firmware/tar/{Unit.uuid}`
    - `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/firmware/zip/{Unit.uuid}`
1. Распаковать env.json и schema.json
1. Скачать новую программу по ссылке COMPILED_FIRMWARE_LINK, [подробнее о компиляции](/developer/release-assets)
1. Запустить новую программу и остановить старую

Интерпретируемые:

1. Сравнить версии и получить uuid Unit так же, как у компилируемых (шаги 1 и 2)
1. Скачать архив tgz, tar или zip с обновлением, адреса те же, что у компилируемых выше
1. Распаковать все файлы в отдельную папку или область памяти
1. Заменить текущую программу файлами из новой папки
1. Перезапустить Unit

:::info
Pepeunit считает обновление выполненным, когда Unit присылает в [состоянии](/developer/mqtt/state-mqtt-send) нужный pu_commit_version. Если этого не случилось за два интервала PU_STATE_SEND_INTERVAL, обновление помечается ошибкой.
:::

## SCHEMA_UPDATE - schema_update/pepeunit

Команда просит Unit обновить schema.json.

### Формат сообщения в топик schema_update/pepeunit

```json
{
    "COMMAND": "SchemaUpdate"
}
```

### Алгоритм действий Unit

1. Скачать новый schema.json: `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/get_current_schema/{Unit.uuid}`
1. Заменить им текущий schema.json

## ENV_UPDATE - env_update/pepeunit

Команда просит Unit обновить env.json.

### Формат сообщения в топик env_update/pepeunit

```json
{
    "COMMAND": "EnvUpdate"
}
```

### Алгоритм действий Unit

1. Скачать новый env.json: `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/env/{Unit.uuid}`
1. Заменить им текущий env.json

## LOG_SYNC - log_sync/pepeunit

Команда просит Unit отправить все логи, которые есть у него локально. Перед этим Pepeunit удаляет логи этого Unit из [ClickHouse](/deployment/dependencies/clickhouse). Unit собирает все свои логи и отправляет их по MQTT. Команда нужна для отладки: не все ошибки удаётся получить по MQTT в момент, когда они случились.

### Формат сообщения в топик log_sync/pepeunit

```json
{
    "COMMAND": "LogSync"
}
```

### Алгоритм действий Unit

1. Подготовить логи в нужном формате: [формат описан в разделе топика log/pepeunit](/developer/mqtt/state-mqtt-send#log-pepeunit-output-base-topic)
1. Отправить их в топик log/pepeunit из output_base_topic

## RESET - reset/pepeunit

Команда просит Unit перезапуститься.

### Формат сообщения в топик reset/pepeunit

```json
{
    "COMMAND": "Reset"
}
```

### Алгоритм действий Unit

1. Перезапустить устройство или программу

## Отправка команды через REST

Любую из команд можно отправить запросом. Название команды: Update, SchemaUpdate, EnvUpdate, LogSync или Reset.

```bash
curl -X 'POST' \
'PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/send_command_to_input_base_topic/{Unit.uuid}?command=Update' \
-H 'x-auth-token: PU_AUTH_TOKEN'
```
