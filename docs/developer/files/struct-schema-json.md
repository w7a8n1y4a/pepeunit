# schema.json

:::warning Какое функциональное назначание у [schema.json](/definitions#schema-json)?
Данный файл - это контракт между конкретным экземпляром [Unit](/definitions#unit) и [Pepeunit](/conception/overview):
1. [Unit](/definitions#unit) гарантирует, что он подпишется на все стандартные топики указанные в `input_base_topic` и все [UnitNode](/definitions#unitnode) указанные в `input_topic`
1. [Unit](/definitions#unit) гарантирует, что он будет публиковать данные в стандартные топики из `output_base_topic` и в [UnitNode](/definitions#unitnode) указанные в `output_topic`
1. [Pepeunit](/conception/overview) гарантирует, что будет [отправлять корректные форматы данных](/developer/mqtt/default-mqtt-command) в `input_base_topic` и то что подпишется на все топики в `output_base_topic`
1. [Pepeunit](/conception/overview) гарантирует, что будет производить авторизацию для публикации и подписки на все без исключения топики адресованные на инстанс [EMQX](/deployment/dependencies/emqx) используемый [Backend](/deployment/dependencies/backend)
1. [Pepeunit](/conception/overview) гарантирует, что будет подписан на все топики соответствующие паттерну `unit.example.com/+/+/+/pepeunit`
1. [Pepeunit](/conception/overview) гарантирует, что подпишется на все топики с паттерном `unit.example.com/+/pepeunit` у которых включен механизм [DataPipe](/deployment/dependencies/datapipe)
:::

## Структура

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

Топики можно разделить на две категории, стандартные и топики [Разработчика Unit](/development-pepeunit/mechanics/roles#unit-developer):
- `input_base_topic` и `output_base_topic` - стандартные
- `input_topic` и `output_topic` - топики [Разработчика Unit](/development-pepeunit/mechanics/roles#unit-developer)

## Стандарнтые топики

:::info
1. Всегда состоят из `5` основных элементов
1. Каждому наименованию топика в [schema_example.json](/definitions#schema-example-json) соответствует только один топик из [EMQX](/deployment/dependencies/emqx):

Структура топиков в [EMQX](/deployment/dependencies/emqx):

```txt
Доменное имя инстанса / тип топика / Unit.uuid / назначение / pepeunit
```
:::

Предназначены для корректной работы механизма [стандартных MQTT команд](/developer/mqtt/default-mqtt-command) и [стандартных MQTT топиков состояния](/developer/mqtt/default-mqtt-command)

## Топики Разработчика

:::info
- Могут состоять из `2` или `3` элементов (c и без постфикса `/pepeunit` на конце)
- Для топиков без постфикса `/pepeunit` (состоящих из `2` элементов) нельзя настроить [DataPipe](/deployment/dependencies/datapipe)

Структура топиков в [EMQX](/deployment/dependencies/emqx):
```txt
Доменное имя инстанса / UnitNode.uuid
Доменное имя инстанса / UnitNode.uuid / pepeunit
```

Каждый топик с такой структурой соответствует одному [UnitNode](/definitions#unitnode)
:::

Подробнее о `output_topic`:
- Предназначен чтобы [Unit](/definitions#unit) мог отправлять данные в [EMQX](/deployment/dependencies/emqx)
- Каждому `output_topic` из [schema_example.json](/definitions#schema-example-json) соответствует только один топик из [EMQX](/deployment/dependencies/emqx)
- [Unit](/definitions#unit) имеет эксклюзивное право на публикацию в данные топики, ни один другой [Unit](/definitions#unit) опубликовать данные в них не сможет

Подробнее о `input_topic`:
- Предназначен чтобы [Unit](/definitions#unit) мог принимать сообщения сразу от нескольких [Unit](/definitions#unit)
- Каждому `input_topic` из [schema_example.json](/definitions#schema-example-json) может соответствовать несколько топиков из [EMQX](/deployment/dependencies/emqx)
- Система связей `Output->Input` позволяет [Unit](/definitions#unit) подписываться не только на свой `Input` [UnitNode](/definitions#unitnode), а также получить значения из `Output` [UnitNode](/definitions#unitnode) других [Unit](/definitions#unit) внутри одного `input_topic`

Схематический пример создания связи между двумя [Unit](/definitions#unit)
![img](/schemas/edge_schema.svg)

:::warning Почему существуют только связи `Output->Input`?
В парадигме протокола [MQTT](/definitions#mqtt) в топик информацию публикует издатель, а получить информацию из топика могут подпищики. Если перенести эту логику на [Pepeunit](/conception/overview) можно сделать следующий вывод:

- `Output` - топик в который [Unit](/definitions#unit) может отправить данные ([Unit](/definitions#unit) издатель для этого топика)
- `Input` - набор топиков из которых [Unit](/definitions#unit) может получить данные ([Unit](/definitions#unit) подпищик для этих топиков)

Таким образом когда создаётся связь `Output->Input`, мы говорим [Unit](/definitions#unit) у которого есть `Input` дополнительно подписаться этим `Input` на `Output` другого [Unit](/definitions#unit). Т.е. [Unit](/definitions#unit) может получать в `Input` информацию от нескольких `Output` других [Unit](/definitions#unit).

Если бы существовала возможность создавать связи `Input->Output` - то это означало бы, что `Input` одного [Unit](/definitions#unit) инициирует или влияет на `Output` другого [Unit](/definitions#unit).
:::
