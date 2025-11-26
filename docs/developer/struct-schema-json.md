# Структура schema.json и schema_example.json

## schema_example.json

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
`input_base_topic` | Топики стандартных [MQTT](/definitions#mqtt) команд, которые [Unit](/definitions#unit) может выполнить | [Стандартные MQTT команды](/developer/default-mqtt-command)
`output_base_topic` | Топики стандартной публикации данных, в которые [Unit](/definitions#unit) может публиковать данные | [Стандартные MQTT топики состояния](/developer/default-mqtt-command)
`input_topic` | `Input` топики Разработчика [Unit](/definitions#unit). [Pepeunit](/conception/overview) использует их как шаблон для создания `Input` [UnitNode](/definitions#unitnode) | -
`output_topic` | `Output` топики Разработчика [Unit](/definitions#unit). [Pepeunit](/conception/overview) использует их как шаблон для создания `Output` [UnitNode](/definitions#unitnode) | -

:::info
При использовании клиентских библиотек: [Micropython](/libraries/micropython), [Golang](/libraries/golang) и [Python](/libraries/python) - можно указывать все топики из `input_base_topic` и `output_base_topic`, они будут корректно работать.

Если вы сами реализуете взаимодействие с [Pepeunit](/conception/overview) без библиотек, то можно оставить только те топики, которые нужны для реализации [Unit](/definitions#unit).
:::

:::warning
При создании [Unit](/definitions#unit) или изменении его версии, [Pepeunit](/conception/overview) автоматически создаёт и удаляет недостающие `Input` и `Output` [UnitNode](/definitions#unitnode) в соответствии с [schema_example.json](/definitions#schema-example-json).
:::

## schema.json

:::warning Какое функциональное назначание у [schema.json](/definitions#schema-json)?
Данный файл - это контракт между конкретным экземпляром [Unit](/definitions#unit) и [Pepeunit](/conception/overview):
1. [Unit](/definitions#unit) гарантирует, что он подпишется на все стандартные топики указанные в `input_base_topic` и все [UnitNode](/definitions#unitnode) указанные в `input_topic`
1. [Unit](/definitions#unit) гарантирует, что он будет публиковать данные в стандартные топики из `output_base_topic` и в [UnitNode](/definitions#unitnode) указанные в `output_topic`
1. [Pepeunit](/conception/overview) гарантирует, что будет [отправлять корректные форматы данных](/developer/default-mqtt-command) в `input_base_topic` и то что подпишется на все топики в `output_base_topic`
1. [Pepeunit](/conception/overview) гарантирует, что будет производить авторизацию для публикации и подписки на все без исключения топики адресованные на [инстанс](/definitions#instance) [EMQX MQTT Broker](/definitions#mqtt-broker) используемый [Backend](/definitions#backend)
1. [Pepeunit](/conception/overview) гарантирует, что будет подписан на все топики соответствующие паттернам: `unit.example.com/+/+/+/pepeunit` и `unit.example.com/+/pepeunit`
:::

### Структура

```json
{
    "input_base_topic": {
        "update/pepeunit": [
            "example.com/input_base_topic/9d0c2f4d-108e-488a-85e5-6040ef3d842a/update/pepeunit"
        ],
        "env_update/pepeunit": [
            "example.com/input_base_topic/9d0c2f4d-108e-488a-85e5-6040ef3d842a/env_update/pepeunit"
        ],
        "schema_update/pepeunit": [
            "example.com/input_base_topic/9d0c2f4d-108e-488a-85e5-6040ef3d842a/schema_update/pepeunit"
        ],
        "log_sync/pepeunit": [
            "example.com/input_base_topic/9d0c2f4d-108e-488a-85e5-6040ef3d842a/log_sync/pepeunit"
        ]
    },
    "output_base_topic": {
        "state/pepeunit": [
            "example.com/output_base_topic/9d0c2f4d-108e-488a-85e5-6040ef3d842a/state/pepeunit"
        ],
        "log/pepeunit": [
            "example.com/output_base_topic/9d0c2f4d-108e-488a-85e5-6040ef3d842a/log/pepeunit"
        ]
    },
    "input_topic": {
        "set_fan_state/pepeunit": [
            "example.com/2d98b4ba-c935-4379-8e1a-520e76018c17/pepeunit"
            "example.com/c0b107a7-9ae0-44ed-bc76-db5ff2af8887"
        ]
    },
    "output_topic": {
        "current_fan_speed_percentage/pepeunit": [
            "example.com/d76b4234-3997-4a4a-a113-6d1c21d6b84a/pepeunit"
        ],
        "current_temp/pepeunit": [
            "example.com/7279d28d-53b6-4866-99da-0b81bc1cc025/pepeunit"
        ]
    }
}
```

Топики можно разделить на две категории, стандартные и соответствующие [UnitNode](/definitions#unitnode):
- `input_base_topic` и `output_base_topic` - стандартные
- `input_topic` и `output_topic` - соответствующие [UnitNode](/definitions#unitnode)

Стандарнтые топики:
1. Всегда состоят из `5` основных элементов
1. Каждому наименованию топика в [schema_example.json](/definitions#schema-example-json) соответствует только один топик из [EMQX MQTT Broker](/definitions#mqtt-broker):

:::info Структура стандарнтных топиков
```txt
Доменное имя инстанса / тип топика / Unit.uuid / назначение / pepeunit
```
:::

 [UnitNode](/definitions#unitnode) топики:
- Могут состоять из `2` или `3` элементов
- Каждому `output_topic` из [schema_example.json](/definitions#schema-example-json) соответствует только один топик из [EMQX MQTT Broker](/definitions#mqtt-broker)
- Каждому `input_topic` из [schema_example.json](/definitions#schema-example-json) может соответствовать несколько топиков из [EMQX MQTT Broker](/definitions#mqtt-broker). Они подставляются на основании созданых связей `Output->Input`

:::info Структура [UnitNode](/definitions#unitnode) топиков
```txt
Доменное имя инстанса / UnitNode.uuid 
Доменное имя инстанса / UnitNode.uuid / pepeunit
```
:::
