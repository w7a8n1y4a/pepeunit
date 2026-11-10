# schema.json

:::warning Для чего нужен schema.json?
Это контракт между конкретным Unit и Pepeunit:
1. Unit подпишется на все стандартные топики из input_base_topic и на все UnitIO из input_topic
1. Unit будет публиковать в стандартные топики из output_base_topic и во все UnitIO из output_topic
1. Pepeunit будет [отправлять данные в нужном формате](/developer/mqtt/default-mqtt-command) в input_base_topic и читать все топики из output_base_topic
1. Pepeunit будет проверять права Unit на подписку и публикацию в [EMQX](/deployment/dependencies/emqx) для любых топиков инстанса
1. Backend подписан на все топики состояния и логов, они подходят под шаблон example.com/+/+/+/pepeunit
1. [DataPipe](/deployment/dependencies/datapipe) подписан на топики example.com/+/pepeunit тех UnitIO, у которых он включён
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
        ],
        "reset/pepeunit": [
            "example.com/input_base_topic/9d0c2f4d-108e-488a-85e5-6040ef3d842a/reset/pepeunit"
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
            "example.com/2d98b4ba-c935-4379-8e1a-520e76018c17/pepeunit",
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

Pepeunit берёт имена топиков из [schema_example.json](/developer/files/struct-schema-example-json) и для каждого подставляет адреса в EMQX. Топики делятся на стандартные и топики [Разработчика Unit](/development-pepeunit/mechanics/roles#unit-developer):
- input_base_topic и output_base_topic: стандартные
- input_topic и output_topic: Разработчика

## Стандартные топики

:::info
1. Всегда состоят из пяти частей
1. Каждому имени из schema_example.json соответствует ровно один топик в [EMQX](/deployment/dependencies/emqx)

Структура топика:

```txt
Домен инстанса / тип топика / Unit.uuid / назначение / pepeunit
```
:::

Нужны для работы [стандартных MQTT команд](/developer/mqtt/default-mqtt-command) и [стандартных MQTT топиков состояния](/developer/mqtt/state-mqtt-send).

Стандартный топик доступен только самому Unit: другие Unit к нему не подключатся.

## Топики Разработчика

:::info
1. Состоят из двух или трёх частей: с постфиксом /pepeunit на конце или без него
1. Для топиков без постфикса нельзя настроить DataPipe, подробнее в [постфиксе /pepeunit](/developer/files/struct-schema-example-json#постфикс-pepeunit)

Структура топика:
```txt
Домен инстанса / UnitIO.uuid
Домен инстанса / UnitIO.uuid / pepeunit
```

Каждый такой топик соответствует одному UnitIO.
:::

Подробнее об output_topic:
- Через него Unit отправляет данные в [EMQX](/deployment/dependencies/emqx)
- Каждому имени output_topic соответствует ровно один топик
- Публикует в него сам Unit, а читать его могут те, кому позволяет [видимость](/development-pepeunit/mechanics/visibility) UnitIO

Подробнее об input_topic:
- Через него Unit получает сообщения сразу от нескольких Unit
- Каждому имени input_topic может соответствовать несколько топиков
- Связи Output->Input позволяют подписать Input не только на свой топик, но и на Output UnitIO других Unit, всё внутри одного input_topic

Схема связи двух Unit:
![img](/schemas/edge_schema.svg)

:::warning Почему связи только Output->Input?
В MQTT в топик пишет издатель, а читают подписчики. Для Pepeunit это значит:

- Output: топик, в который Unit пишет данные (Unit издатель)
- Input: набор топиков, из которых Unit читает данные (Unit подписчик)

Связь Output->Input даёт Unit с Input дополнительную подписку на Output другого Unit. Так в один Input приходят данные из нескольких Output.

Связь Input->Output означала бы, что Input одного Unit влияет на Output другого, а это противоречит схеме издатель-подписчик.
:::
