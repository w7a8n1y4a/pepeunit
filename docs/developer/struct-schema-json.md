# Структура schema.json и schema_example.json

## schema_example.json
### Структура

```json
{
    "input_base_topic": [
        "update/pepeunit",
        "schema_update/pepeunit",
        "env_update/pepeunit"
    ],
    "output_base_topic": [
        "state/pepeunit"
    ],
    "input_topic": [
        "set_heater_duty/pepeunit"
    ],
    "output_topic": [
        "current_temperature/pepeunit",
        "current_pressure/pepeunit",
        "current_heater_duty/pepeunit",
        "current_humidity/pepeunit"
    ]
}
```

Всего в schema_example.json есть 4 типа топиков:
- `input_base_topic` - топики стандартных MQTT команд, которые Unit может выполнить
- `output_base_topic` - топики стандартной публикации данных, в которые Unit может публиковать данные
- `input_topic` - топики Input UnitNode - набор UnitNode на которые Unit будет подписан
- `output_topic` - Output UnitNode - набор UnitNode в которые Unit будет публиковать данные

:::warning Какое функциональное назначание у schema_example.json?
Данный файл - это контракт между разработчиком Unit и Pepeunit:
1. Разработчик гарантирует, что он реализует в функционале Unit, работу указанных в schema_example.json стандартных топиков Pepeunit `input_base_topic` и `output_base_topic`
1. Разработчик гарантирует работу `input_topic` и `output_topic` в соответствии с readme
1. Pepeunit гарантирует корректное взаимодействие со стандартными топиками `input_base_topic` и `output_base_topic`
1. Pepeunit гарантирует, что будет поддерживать актуальный набор UnitNode в соответствии с `input_topic` и `output_topic` указанных разработчиком в schema_example.json, для каждой версии Unit.
:::

:::info Пользовательский опыт
При создании Unit или изменении его версии, Pepeunit автоматически создаёт и удаляет недостающие Input и Output UnitNode в соответствии с schema_example.json.
:::

## schema.json

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

Топики можно разделить на две категории, стандартные и соответствующие UnitNode:
- `input_base_topic` и `output_base_topic` - стандартные
- `input_topic` и `output_topic` - соответствующие UnitNode

Стандарнтые топики:
1. Всегда состоят из 5 основных элементов
1. Каждому наименованию топика в schema_example.json соответствует только один топик из EMQX MQTT Brocker:

:::info Структура стандарнтных топиков
```txt
Доменное имя инстанса / тип топика / Unit.uuid / назначение / pepeunit
```
:::

UnitNode топики:
- Могут состоять из 2 ли 3 элементов
- Каждому `output_topic` из schema_example.json соответствует только один топик из EMQX MQTT Brocker
- Каждому `input_topic` из schema_example.json может соответствовать несколько топиков из EMQX MQTT Brocker. Они подставляются на основании созданых связей `Output->Input`

:::info Структура UnitNode топиков
```txt
Доменное имя инстанса / UnitNode.uuid 
Доменное имя инстанса / UnitNode.uuid / pepeunit
```
:::

:::warning Какое функциональное назначание у schema.json?
Данный файл - это контракт между конкретным экземпляром Unit и Pepeunit:
1. Unit гарантирует что он подпишется на все стандартные топики указанные в `input_base_topic` и все UnitNode указанные в `input_topic`
1. Unit гарантирует, что он будет публиковать данные в стандартные топики из `output_base_topic` и в UnitNode указанные в `output_topic`
1. Pepeunit гарантирует, что будет отправлять корректные данные в `input_base_topic` и то что подпишется на все топики в `output_base_topic`
1. Pepeunit гарантирует, что он будет производить авторизацию для публикации и подписки на все без исключения топики адресованные на инстанс EMQX MQTT Brocker используемый Backend
1. Pepeunit гарантирует, что будет подписан на все топики соответствующие паттернам: `unit.example.com/+/+/+/pepeunit` и `unit.example.com/+/pepeunit`
:::