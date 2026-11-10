# schema.json

:::warning What is schema.json for?
It is a contract between a specific Unit and Pepeunit:
1. The Unit will subscribe to all standard topics from input_base_topic and to all UnitIO from input_topic
1. The Unit will publish to the standard topics from output_base_topic and to all UnitIO from output_topic
1. Pepeunit will [send data in the right format](/developer/mqtt/default-mqtt-command) to input_base_topic and read all topics from output_base_topic
1. Pepeunit will check the Unit's rights to subscribe and publish in [EMQX](/deployment/dependencies/emqx) for any topics of the instance
1. Backend is subscribed to all state and log topics, they match the pattern example.com/+/+/+/pepeunit
1. [DataPipe](/deployment/dependencies/datapipe) is subscribed to the example.com/+/pepeunit topics of those UnitIO that have it enabled
:::

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

Pepeunit takes the topic names from [schema_example.json](/developer/files/struct-schema-example-json) and substitutes the addresses in EMQX for each of them. Topics are divided into standard ones and topics of the [Unit Developer](/development-pepeunit/mechanics/roles#unit-developer):
- input_base_topic and output_base_topic: standard
- input_topic and output_topic: the Developer's

## Standard topics

:::info
1. Always consist of five parts
1. Each name from schema_example.json corresponds to exactly one topic in [EMQX](/deployment/dependencies/emqx)

Topic structure:

```txt
Instance domain / topic type / Unit.uuid / purpose / pepeunit
```
:::

They are needed for the [standard MQTT commands](/developer/mqtt/default-mqtt-command) and the [standard MQTT state topics](/developer/mqtt/state-mqtt-send) to work.

A standard topic is available only to the Unit itself: other Units cannot connect to it.

## Developer topics

:::info
1. Consist of two or three parts: with the /pepeunit postfix at the end or without it
1. DataPipe cannot be configured for topics without the postfix, see more in [the /pepeunit postfix](/developer/files/struct-schema-example-json#the-pepeunit-postfix)

Topic structure:
```txt
Instance domain / UnitIO.uuid
Instance domain / UnitIO.uuid / pepeunit
```

Each such topic corresponds to one UnitIO.
:::

More about output_topic:
- Through it the Unit sends data to [EMQX](/deployment/dependencies/emqx)
- Each output_topic name corresponds to exactly one topic
- The Unit itself publishes to it, and it can be read by those whom the UnitIO [visibility](/development-pepeunit/mechanics/visibility) allows

More about input_topic:
- Through it the Unit receives messages from several Units at once
- Each input_topic name can correspond to several topics
- Output->Input links allow subscribing an Input not only to its own topic but also to the Output UnitIO of other Units, all within one input_topic

Diagram of a link between two Units:
![img](/schemas/edge_schema.svg)

:::warning Why only Output->Input links?
In MQTT the publisher writes to a topic and the subscribers read it. For Pepeunit this means:

- Output: the topic the Unit writes data to (the Unit is the publisher)
- Input: a set of topics the Unit reads data from (the Unit is the subscriber)

An Output->Input link gives the Unit with the Input an additional subscription to the Output of another Unit. This way data from several Outputs arrives in one Input.

An Input->Output link would mean that the Input of one Unit affects the Output of another, which contradicts the publisher-subscriber scheme.
:::
