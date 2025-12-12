# schema.json

::::warning What is the purpose of [schema.json](/en/definitions#schema-json)?
This file is a contract between a specific [Unit](/en/definitions#unit) instance and [Pepeunit](/en/conception/overview):

1. The [Unit](/en/definitions#unit) guarantees that it will subscribe to all standard topics listed in `input_base_topic` and to all [UnitNodes](/en/definitions#unitnode) listed in `input_topic`.
1. The [Unit](/en/definitions#unit) guarantees that it will publish data to the standard topics from `output_base_topic` and to all [UnitNodes](/en/definitions#unitnode) listed in `output_topic`.
1. [Pepeunit](/en/conception/overview) guarantees that it will [send correctly formatted data](/en/developer/mqtt/default-mqtt-command) to `input_base_topic` and subscribe to all topics in `output_base_topic`.
1. [Pepeunit](/en/conception/overview) guarantees that it will authorize publication and subscription for **all** topics that are addressed to the [EMQX](/en/deployment/dependencies/emqx) instance used by the [Backend](/en/deployment/dependencies/backend).
1. [Pepeunit](/en/conception/overview) guarantees that it will subscribe to all topics matching the pattern `unit.example.com/+/+/+/pepeunit`.
1. [Pepeunit](/en/conception/overview) guarantees that it will subscribe to all topics matching `unit.example.com/+/pepeunit` that have [DataPipe](/en/deployment/dependencies/datapipe) enabled.
::::

## Structure

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

Topics can be divided into two categories: **standard topics** and **developer topics**:

- `input_base_topic` and `output_base_topic` – standard topics  
- `input_topic` and `output_topic` – [Unit Developer](/en/development-pepeunit/mechanics/roles#unit-developer) topics

## Standard topics

::::info
1. Always consist of **5** main elements.
1. Every topic name in [schema_example.json](/en/definitions#schema-example-json) maps to exactly one physical topic in [EMQX](/en/deployment/dependencies/emqx).

Topic structure in [EMQX](/en/deployment/dependencies/emqx):

```txt
instance domain / topic type / Unit.uuid / purpose / pepeunit
```
::::

Standard topics are used to implement [standard MQTT commands](/en/developer/mqtt/default-mqtt-command) and [standard MQTT state topics](/en/developer/mqtt/default-mqtt-command).

## Developer topics

::::info
1. Can consist of **2** or **3** elements (with or without the `/pepeunit` suffix).
1. For topics without the `/pepeunit` suffix (2 elements), [DataPipe](/en/deployment/dependencies/datapipe) cannot be enabled.

Topic structure in [EMQX](/en/deployment/dependencies/emqx):

```txt
instance domain / UnitNode.uuid
instance domain / UnitNode.uuid / pepeunit
```

Each topic with this structure corresponds to a single [UnitNode](/en/definitions#unitnode).
::::

More about `output_topic`:

- Used so that a [Unit](/en/definitions#unit) can send data to [EMQX](/en/deployment/dependencies/emqx).
- Each `output_topic` from [schema_example.json](/en/definitions#schema-example-json) maps to exactly one [EMQX](/en/deployment/dependencies/emqx) topic.
- The [Unit](/en/definitions#unit) has exclusive rights to publish to these topics—no other [Unit](/en/definitions#unit) can publish to them.

More about `input_topic`:

- Used so that a [Unit](/en/definitions#unit) can receive messages from multiple other [Units](/en/definitions#unit).
- Each `input_topic` from [schema_example.json](/en/definitions#schema-example-json) can correspond to several [EMQX](/en/deployment/dependencies/emqx) topics.
- The `Output->Input` link system allows a [Unit](/en/definitions#unit) to subscribe not only to its own `Input` [UnitNode](/en/definitions#unitnode) but also to receive values from `Output` [UnitNodes](/en/definitions#unitnode) of other [Units](/en/definitions#unit) within the same `input_topic`.

The diagram below shows an example of a link between two [Units](/en/definitions#unit):

![img](/schemas/edge_schema.svg)

::::warning Why are there only `Output->Input` links?
In the [MQTT](/en/definitions#mqtt) protocol paradigm, publishers send data to topics and subscribers receive it from those topics. If we apply this logic to [Pepeunit](/en/conception/overview), we get:

- `Output` – a topic where the [Unit](/en/definitions#unit) can send data (the [Unit](/en/definitions#unit) is the publisher).
- `Input` – a set of topics from which the [Unit](/en/definitions#unit) can receive data (the [Unit](/en/definitions#unit) is the subscriber).

Thus, when we create an `Output->Input` link, we instruct the [Unit](/en/definitions#unit) that owns the `Input` to additionally subscribe that `Input` to the `Output` of another [Unit](/en/definitions#unit). The [Unit](/en/definitions#unit) can then receive data in its `Input` from multiple `Output`s of other [Units](/en/definitions#unit).

If there were `Input->Output` links, they would imply that the `Input` of one [Unit](/en/definitions#unit) initiates or affects the `Output` of another [Unit](/en/definitions#unit), which does not match the MQTT communication model.
::::


