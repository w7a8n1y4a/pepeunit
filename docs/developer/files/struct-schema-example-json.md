# schema_example.json

:::warning Какое функциональное назначание у [schema_example.json](/definitions#schema-example-json) ?
Данный файл - это контракт между разработчиком [Unit](/definitions#unit) и [Pepeunit](/conception/overview):
1. Разработчик гарантирует, что он реализует в функционале [Unit](/definitions#unit), работу указанных в [schema_example.json](/definitions#schema-example-json) стандартных топиков [Pepeunit](/conception/overview): `input_base_topic` и `output_base_topic`
1. Разработчик гарантирует работу `input_topic` и `output_topic` в соответствии описанием, которое он составил в [Readme](/definitions#readme-md)
1. [Pepeunit](/conception/overview) гарантирует корректное взаимодействие со стандартными топиками `input_base_topic` и `output_base_topic`
1. [Pepeunit](/conception/overview) гарантирует, что будет поддерживать актуальный набор [UnitNode](/definitions#unitnode) в соответствии с `input_topic` и `output_topic` указанных разработчиком в [schema_example.json](/definitions#schema-example-json) , для каждой версии [Unit](/definitions#unit).
:::

## Структура

```json
{   
    "input_base_topic": [
        "update/pepeunit",
        "env_update/pepeunit",
        "schema_update/pepeunit",
        "log_sync/pepeunit"
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

Всего в [schema_example.json](/definitions#schema-example-json) есть `4` типа топиков:

Топик | Описание | Подробности
-- | -- | -- 
`input_base_topic` | Топики стандартных [MQTT](/definitions#mqtt) команд, которые [Unit](/definitions#unit) может выполнить | [Стандартные MQTT команды](/developer/mqtt/default-mqtt-command)
`output_base_topic` | Топики стандартной публикации данных, в которые [Unit](/definitions#unit) может публиковать данные | [Стандартные MQTT топики состояния](/developer/mqtt/default-mqtt-command)
`input_topic` | `Input` топики Разработчика [Unit](/definitions#unit). [Pepeunit](/conception/overview) использует их как шаблон для создания `Input` [UnitNode](/definitions#unitnode) | [Топики разработчика](/developer/files/struct-schema-json#топики-разработчика)
`output_topic` | `Output` топики Разработчика [Unit](/definitions#unit). [Pepeunit](/conception/overview) использует их как шаблон для создания `Output` [UnitNode](/definitions#unitnode) | [Топики разработчика](/developer/files/struct-schema-json#топики-разработчика)

:::info
При использовании клиентских библиотек: [Micropython](/developer/libraries/micropython), [Golang](/developer/libraries/golang) и [Python](/developer/libraries/python) - можно указывать все топики из `input_base_topic` и `output_base_topic`, они будут корректно работать.

Если вы сами реализуете взаимодействие с [Pepeunit](/conception/overview) без библиотек, то можно оставить только те топики, которые нужны для реализации [Unit](/definitions#unit).
:::

:::warning
При создании [Unit](/definitions#unit) или изменении его версии, [Pepeunit](/conception/overview) автоматически создаёт и удаляет недостающие `Input` и `Output` [UnitNode](/definitions#unitnode) в соответствии с [schema_example.json](/definitions#schema-example-json).
:::