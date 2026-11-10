# Pepeunit Framework

[Ссылки на репозитории библиотек](/development-pepeunit/maps#библиотеки)

Каждая из библиотек является клиентским Framework для работы с Pepeunit. Он облегчает разработку новых Unit: берёт на себя базовую интеграцию с Pepeunit и управление циклом выполнения.

## Набор возможностей

1. Встроенный MQTT клиент:
    - массовая подписка на топики на основе schema.json
    - отправка данных в топики массово на основе schema.json
1. Встроенный REST клиент:
    - загрузка архива обновлений
    - загрузка env.json
    - загрузка schema.json
    - установка состояния [storage](/developer/state-storage-unit)
    - получение состояния [storage](/developer/state-storage-unit)
    - получение списка Unit при помощи списка UnitIO.uuid
    - получение `Input` UnitIO при помощи `Output` UnitIO
1. Приём и корректная обработка [стандартных MQTT команд Pepeunit](/developer/mqtt/default-mqtt-command)
1. Отправки и генерации [состояния Unit](/developer/mqtt/state-mqtt-send)
1. Функционал для работы с schema.json:
    - Динамическое обновление
    - Поиск по всем `4` типам топиков
    - Поиск топиков по UnitIO.uuid или по полному названию конкретных топиков
1. Функционал для работы с env.json:
    - Динамическое обновление
    - Получение Unit.uuid из токена
    - Получение любой переменной, как атрибута класса
1. Функционал для работы с логами:
    - Поддержка `5` типов логов: `debug`, `info`, `warning`, `error`, `critical`
    - Поддержка отправки логов по MQTT
    - Поддержка сохранения логов в файл [log.json](#logjson)
    - Возможность обнуления логов
1. Установка кастомного `handler` для обновления Unit
1. Установка `handler` для `Input` сообщений MQTT
1. Установка `handler` для `Output` сообщений MQTT
1. Возможность выбрать несколько типов обновлений
1. Шифрование `aes-gcm-256` поддерживающее `16/24/32` байтовый ключ, работает только при ручном использовании
1. Функционал для работы с главным циклом приложения:
    - Запуск
    - Остановка
    - Динамическое изменение `handler`

## log.json

'Чёрный ящик' Unit хранит последние `N` логов независимо от состояния сети. Логи хранятся в формате `ndjson`: каждая строка, отделённая `\n`, это новый словарь:

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

Ёмкость буфера задаёт переменная окружения `PU_MAX_LOG_LENGTH`: новые записи попадают в конец файла, а записи, чей порядковый номер от конца больше `PU_MAX_LOG_LENGTH`, удаляются.

Доступ к файлу возможен физически через порты устройств или через команду [log_sync](/developer/mqtt/default-mqtt-command#log-sync-log-sync-pepeunit)