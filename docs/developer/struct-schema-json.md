# Структура schema.json и schema_example.json

## schema_example.json

:::warning Какое функциональное назначание у [schema_example.json](/definitions#schema-example-json) ?
Данный файл - это контракт между разработчиком [Unit](/definitions#unit) и [Pepeunit](/conception/overview):
1. Разработчик гарантирует, что он реализует в функционале [Unit](/definitions#unit), работу указанных в [schema_example.json](/definitions#schema-example-json) стандартных топиков [Pepeunit](/conception/overview): `input_base_topic` и `output_base_topic`
1. Разработчик гарантирует работу `input_topic` и `output_topic` в соответствии описанием, которое он составил в [Readme](/definitions#readme-md)
1. [Pepeunit](/conception/overview) гарантирует корректное взаимодействие со стандартными топиками `input_base_topic` и `output_base_topic`
1. [Pepeunit](/conception/overview) гарантирует, что будет поддерживать актуальный набор [UnitNode](/definitions#unitnode) в соответствии с `input_topic` и `output_topic` указанных разработчиком в [schema_example.json](/definitions#schema-example-json) , для каждой версии [Unit](/definitions#unit).
:::

### Структура

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

Всего в [schema_example.json](/definitions#schema-example-json) есть 4 типа топиков:
- `input_base_topic` - топики стандартных [MQTT](/definitions#mqtt) команд, которые [Unit](/definitions#unit) может выполнить
- `output_base_topic` - топики стандартной публикации данных, в которые [Unit](/definitions#unit) может публиковать данные
- `input_topic` - топики `Input` [UnitNode](/definitions#unitnode) = набор [UnitNode](/definitions#unitnode) на которые [Unit](/definitions#unit) будет подписан
- `output_topic` - `Output` [UnitNode](/definitions#unitnode) = набор [UnitNode](/definitions#unitnode) в которые [Unit](/definitions#unit) будет публиковать данные

:::info Пользовательский опыт
При создании [Unit](/definitions#unit) или изменении его версии, [Pepeunit](/conception/overview) автоматически создаёт и удаляет недостающие `Input` и `Output` [UnitNode](/definitions#unitnode) в соответствии с [schema_example.json](/definitions#schema-example-json) .
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
            "example.com/input_base_topic/5e1a4151-515e-4926-8b8a-5e821713e25e/update/pepeunit"
        ],
        "schema_update/pepeunit": [
            "example.com/input_base_topic/5e1a4151-515e-4926-8b8a-5e821713e25e/schema_update/pepeunit"
        ],
        "env_update/pepeunit": [
            "example.com/input_base_topic/5e1a4151-515e-4926-8b8a-5e821713e25e/env_update/pepeunit"
        ]
    },
    "output_base_topic": {
        "state/pepeunit": [
            "example.com/output_base_topic/5e1a4151-515e-4926-8b8a-5e821713e25e/state/pepeunit"
        ]
    },
    "input_topic": {
        "input/pepeunit": [
            "example.com/dc2d6f5e-90b3-4cdb-91a4-5ae12db1887f/pepeunit",
            "example.com/f06bcaa8-bb00-45ea-aba8-0fc0eba41e08"
        ]
    },
    "output_topic": {
        "output/pepeunit": [
            "example.com/4114a3f8-65c1-4d42-8d1d-481785d0dcca/pepeunit"
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
