# Стандартные MQTT команды Pepeunit

:::warning
Команды которые поддерживает Unit должны быть отражены в schema_example.json в разделе `input_base_topic`.

Unit должен быть подписан на эти топики, при получении сообщения Unit`ы должны следовать единому паттерну поведения описанному в данном разделе.
:::

Всего в Pepeunit есть три команды - топика:
1. `UPDATE` - `update/pepeunit`
1. `SCHEMA_UPDATE` - `schema_update/pepeunit`
1. `ENV_UPDATE` - `env_update/pepeunit`

## UPDATE - update/pepeunit

:::info Когда вызывается данная команда?
1. Если происходит ручное обновление Unit
1. Если происходит автоматическое обновление Unit
1. Если команда была вызвана через отдельную кнопку в меню Unit
1. Если команда была вызвана через REST или GQL
:::

Данная команда отправляет Unit запрос на обновление, Unit в ответ должен выполнить опредлённый алгоритм действий, приводящий к изменению текущей версии программного кода, на новый.

### Формат сообщения в топик `update/pepeunit`
:::danger
Формат сообщения для компилируемых и интерпритируемых Repo отличается:
:::

Компилируемые:

```.json
{
    "COMMAND": "Update",
    "NEW_COMMIT_VERSION": "ad1ddee1e559153f6ea4ae33790f5980e32d61cf",
    "COMPILED_FIRMWARE_LINK": "https://git.pepemoss.com/api/v4/projects/281/packages/generic/release/0.0.2/picker-linux-amd64"
}
```

Интерпритируемые:

```.json
{
    "COMMAND": "Update",
    "NEW_COMMIT_VERSION": "ad1ddee1e559153f6ea4ae33790f5980e32d61cf"
}
```

### Алгоритм действий Unit
:::danger
Алгоритм Unit различается для компилируемых и интерпритируемых Repo.
:::

Компилируемые:

1. Сверить версию `NEW_COMMIT_VERSION` с текущей версией `COMMIT_VERSION` из env.json, если совпали пропускаем обновление, если нет переходим дальше
1. Вычислить uuid Unit на основе jwt токена `PEPEUNIT_TOKEN` из env.json
1. Скачать архив tgz, tar или zip с env.json и schema.json при помощи REST. `HTTP_TYPE` и `PEPEUNIT_URL` доступны внутри env.json:
    - `HTTP_TYPE://PEPEUNIT_URL/pepeunit/api/v1/units/firmware/tgz/{Unit.uuid}?wbits=9&level=9` 
        - Доступные `wbits` - `(от -15 до -8) (от 9 до 16) (от 25 до 32)`
        - Доступные `level` - `(от -1 до 10)`
    - `HTTP_TYPE://PEPEUNIT_URL/pepeunit/api/v1/units/firmware/tar/{Unit.uuid}`
    - `HTTP_TYPE://PEPEUNIT_URL/pepeunit/api/v1/units/firmware/zip/{Unit.uuid}`
1. Распаковать из архива файлы env.json и schema.json
1. Скачать новую скомпилированную часть по ссылке из `COMPILED_FIRMWARE_LINK` 
1. Запустить новую скомпилированную часть c прекращением работы старой

Интерпритируемые:

1. Сверить версию `NEW_COMMIT_VERSION` с текущей версией `COMMIT_VERSION` из env.json, если совпали пропускаем обновление, если нет переходим дальше
1. Вычислить uuid Unit на основе jwt токена `PEPEUNIT_TOKEN` из env.json
1. Скачать архив tgz, tar или zip с обновлением при помощи REST. `HTTP_TYPE` и `PEPEUNIT_URL` доступны внутри env.json:
    - `HTTP_TYPE://PEPEUNIT_URL/pepeunit/api/v1/units/firmware/tgz/{Unit.uuid}?wbits=9&level=9` 
        - Доступные `wbits` - `(от -15 до -8) (от 9 до 16) (от 25 до 32)`
        - Доступные `level` - `(от -1 до 10)`
    - `HTTP_TYPE://PEPEUNIT_URL/pepeunit/api/v1/units/firmware/tar/{Unit.uuid}`
    - `HTTP_TYPE://PEPEUNIT_URL/pepeunit/api/v1/units/firmware/zip/{Unit.uuid}`
1. Распаковать из архива все файлы в отдельную дирректорию или область памяти
1. Заменить текущую версию программы на файлы из новой дирректории или области памяти
1. Перезапустить Unit

## SCHEMA_UPDATE - schema_update/pepeunit

:::info Когда вызывается данная команда?
1. Если команда была вызвана через отдельную кнопку в меню Unit
1. Если команда была вызвана через REST или GQL
:::

Данная команда отправляет Unit запрос на обновление schema.json, Unit в ответ должен выполнить опредлённый алгоритм действий, приводящий к изменению текущей версии schema.json, на новую.

### Формат сообщения в топик `schema_update/pepeunit`

```.json
{
    "COMMAND": "SchemaUpdate"
}
```

### Алгоритм действий

1. Скачать новую версию файла schema.json через REST. `HTTP_TYPE` и `PEPEUNIT_URL` доступны внутри env.json:
    - `HTTP_TYPE://PEPEUNIT_URL/pepeunit/api/v1/units/get_current_schema/{Unit.uuid}`
1. Установить новое состояние для schema.json у Unit

## ENV_UPDATE - env_update/pepeunit

:::info Когда вызывается данная команда?
1. Если команда была вызвана через отдельную кнопку в меню Unit
1. Если команда была вызвана через REST или GQL
:::

Данная команда отправляет Unit запрос на обновление env.json, Unit в ответ должен выполнить опредлённый алгоритм действий, приводящий к изменению текущей версии env.json, на новую.

### Формат сообщения в топик `env_update/pepeunit`

```.json
{
    "COMMAND": "EnvUpdate"
}
```

### Алгоритм действий

1. Скачать новую версию файла env.json через REST. `HTTP_TYPE` и `PEPEUNIT_URL` доступны внутри существующего env.json:
    - `HTTP_TYPE://PEPEUNIT_URL/pepeunit/api/v1/units/env/{Unit.uuid}`
1. Установить новое состояние для env.json у Unit
