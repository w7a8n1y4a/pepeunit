# schema_example.json

:::warning Какое функциональное назначение у schema_example.json?
Данный файл - это контракт между [Разработчиком Unit](/development-pepeunit/mechanics/roles#unit-developer) и Pepeunit:
1. [Разработчик Unit](/development-pepeunit/mechanics/roles#unit-developer) гарантирует, что он реализует в функционале Unit, работу указанных в schema_example.json стандартных топиков Pepeunit: `input_base_topic` и `output_base_topic`
1. [Разработчик Unit](/development-pepeunit/mechanics/roles#unit-developer) гарантирует работу `input_topic` и `output_topic` в соответствии описанием, которое он составил в Readme
1. Pepeunit гарантирует корректное взаимодействие со стандартными топиками `input_base_topic` и `output_base_topic`
1. Pepeunit гарантирует, что будет поддерживать актуальный набор UnitNode в соответствии с `input_topic` и `output_topic`, указанных разработчиком в schema_example.json, для каждой версии Unit.
:::

## Структура

```json
{   
    "input_base_topic": [
        "update/pepeunit",
        "env_update/pepeunit",
        "schema_update/pepeunit",
        "log_sync/pepeunit",
        "reset/pepeunit"
    ],
    "output_base_topic": [
        "state/pepeunit",
        "log/pepeunit"
    ],
    "input_topic": [
        "set_fan_state/pepeunit"
    ],
    "output_topic": [
        "current_fan_speed_percentage/pepeunit",
        "current_temp/pepeunit"
    ]
}
```

Всего в schema_example.json есть `4` типа топиков:

Топик | Описание | Подробности
-- | -- | -- 
`input_base_topic` | Топики стандартных MQTT команд, которые Unit может выполнить | [Стандартные MQTT команды](/developer/mqtt/default-mqtt-command)
`output_base_topic` | Топики стандартной публикации данных, в которые Unit может публиковать данные | [Стандартные MQTT топики состояния](/developer/mqtt/state-mqtt-send)
`input_topic` | `Input` топики [Разработчика Unit](/development-pepeunit/mechanics/roles#unit-developer). Pepeunit использует их как шаблон для создания `Input` UnitNode | [Топики разработчика](/developer/files/struct-schema-json#топики-разработчика)
`output_topic` | `Output` топики [Разработчика Unit](/development-pepeunit/mechanics/roles#unit-developer). Pepeunit использует их как шаблон для создания `Output` UnitNode | [Топики разработчика](/developer/files/struct-schema-json#топики-разработчика)

:::info
При использовании клиентских библиотек [Micropython](/developer/libraries/micropython), [ESP-IDF](/developer/libraries/esp-idf), [Golang](/developer/libraries/golang) и [Python](/developer/libraries/python), можно указывать все топики из `input_base_topic` и `output_base_topic`, они будут корректно работать.

Если вы сами реализуете взаимодействие с Pepeunit без библиотек, то можно оставить только те топики, которые нужны для реализации Unit.
:::

:::warning
При создании Unit или изменении его версии, Pepeunit автоматически создаёт и удаляет недостающие `Input` и `Output` UnitNode в соответствии с schema_example.json.
:::