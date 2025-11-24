# Pepeunit Framework

:::info
Каждая из библиотек является [Framework`ом](/definitions#framework) для работы с [Pepeunit](/conception/overview)

Цель [Framework](/definitions#framework) - облегчить разработку новых [Unit](/definitions#unit), обеспечив работу базового функционала для интеграции с [Pepeunit](/conception/overview) и предоставить инструменты управления программой
:::

## Набор возможностей

1. Встроенный [MQTT](/definitions#mqtt) клиент:
    - массовая подписка на топики на основе [schema.json](/definitions#schema-json) 
    - отправка данных в топики массово на основе [schema.json](/definitions#schema-json)
1. Встроенный [REST](/definitions#rest) клиент:
    - загрузка архива обновлений
    - загрузка [env.json](/definitions#env-json)
    - загрузка [schema.json](/definitions#schema-json)
    - установка состояния [storage](/developer/state-storage-unit)
    - получение состояния [storage](/developer/state-storage-unit)
1. Приём и корректная обработка [cтандартных MQTT команды Pepeunit](/developer/default-mqtt-command)
1. Отправки и генерации [состояния Unit](/developer/state-mqtt-send)
1. Функционал для работы с [schema.json](/definitions#schema-json):
    - Динамическое обновление
    - Поиск по всем `4` типам топиков
    - Поиск топиков по [UnitNode](/definitions#unitnode).uuid или по полному названию конкретных топиков
1. Функционал для работы с [env.json](/definitions#env-json):
    - Динамическое обновление
    - Получение [Unit](/definitions#unit).uuid из токена
    - Получение любой перменной, как атрибута класса
1. Функционал для работы с логами:
    - Поддержка `5` типов логов: `debug`, `info`, `warning`, `error`, `critical`
    - Поддержка отправки логов по [MQTT](/definitions#mqtt)
    - Поддержка сохранения логов в файл [log.json](#logjson)
    - Возможность обнуления логов
1. Установка кастомного `handler` для обновления [Unit](/definitions#unit)
1. Установка `handler` для `Input` сообщений [MQTT](/definitions#mqtt)
1. Установка `handler` для `Output` сообщений [MQTT](/definitions#mqtt)
1. Возможность выбрать несколько типов обновлений
1. Функционал для работы с главным циклом приложения:
    - Запуск
    - Остановка
    - Динамическое изменение `handler`

## log.json

:::info
Чёрный ящик [Unit](/definitions#unit) - позволяет хранить последние N логов не зависимо от состояния сети. 
:::

Логи хранятся в нём в формате `ndjson`, где каждая новая строка отделённая `\n` - это новый словарь:

```ndjson
{"create_datetime":"2025-11-12T19:43:53Z","level":"Info","text":"MQTT connected successfully"}
{"create_datetime":"2025-11-12T19:44:37Z","level":"Info","text":"MQTT client connected successfully"}
{"create_datetime":"2025-11-12T22:00:10Z","level":"Info","text":"Get base MQTT command: update/pepeunit"}
{"create_datetime":"2025-11-12T22:00:10Z","level":"Warning","text":"COMPILED_FIRMWARE_LINK is missing in update payload"}
{"create_datetime":"2025-11-12T23:00:10Z","level":"Info","text":"Get base MQTT command: update/pepeunit"}
{"create_datetime":"2025-11-12T23:00:10Z","level":"Warning","text":"COMPILED_FIRMWARE_LINK is missing in update payload"}
{"create_datetime":"2025-11-12T23:08:50Z","level":"Info","text":"Get base MQTT command: update/pepeunit"}
{"create_datetime":"2025-11-12T23:08:50Z","level":"Warning","text":"COMPILED_FIRMWARE_LINK is missing in update payload"}
{"create_datetime":"2025-11-12T23:25:41Z","level":"Info","text":"MQTT client connected successfully"}
{"create_datetime":"2025-11-12T23:25:41Z","level":"Info","text":"Connected to MQTT Broker"}
{"create_datetime":"2025-11-12T23:25:42Z","level":"Info","text":"Success subscribed to 4 topics"}
```

Ёмкость данного буфера зависит от переменной окружения `PU_MAX_LOG_LENGTH`, все новые записи попадают в конец файла, а все старые записи, если их порядковый номер от конца больше `PU_MAX_LOG_LENGTH` удаляются.

Доступ к даному файлу возможен либо физически через порты устройств или через команду [log_sync](/developer/default-mqtt-command.html#log-sync-log-sync-pepeunit)