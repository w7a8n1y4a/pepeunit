# schema_example.json

::::warning What is the purpose of [schema_example.json](/en/definitions#schema-example-json)?
This file is a contract between the [Unit Developer](/en/development-pepeunit/mechanics/roles#unit-developer) and [Pepeunit](/en/conception/overview):

1. The [Unit Developer](/en/development-pepeunit/mechanics/roles#unit-developer) guarantees that the [Unit](/en/definitions#unit) implements the standard [Pepeunit](/en/conception/overview) topics listed in [schema_example.json](/en/definitions#schema-example-json): `input_base_topic` and `output_base_topic`.
1. The [Unit Developer](/en/development-pepeunit/mechanics/roles#unit-developer) guarantees that `input_topic` and `output_topic` work according to the description they provide in the [Readme](/en/definitions#readme-md).
1. [Pepeunit](/en/conception/overview) guarantees correct interaction with the standard `input_base_topic` and `output_base_topic` topics.
1. [Pepeunit](/en/conception/overview) guarantees that it will maintain an up‑to‑date set of [UnitNodes](/en/definitions#unitnode) based on `input_topic` and `output_topic` specified by the developer in [schema_example.json](/en/definitions#schema-example-json), for every [Unit](/en/definitions#unit) version.
::::

## Structure

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

There are exactly **4** topic types in [schema_example.json](/en/definitions#schema-example-json):

Topic type | Description | Details
-- | -- | --
`input_base_topic` | Standard [MQTT](/en/definitions#mqtt) command topics the [Unit](/en/definitions#unit) can handle | [Standard MQTT commands](/en/developer/mqtt/default-mqtt-command)
`output_base_topic` | Standard data publication topics where the [Unit](/en/definitions#unit) can send data | [Standard MQTT state topics](/en/developer/mqtt/state-mqtt-send)
`input_topic` | `Input` topics of the [Unit Developer](/en/development-pepeunit/mechanics/roles#unit-developer). [Pepeunit](/en/conception/overview) uses them as templates to create `Input` [UnitNodes](/en/definitions#unitnode) | [Developer topics](/en/developer/files/struct-schema-json#developer-topics)
`output_topic` | `Output` topics of the [Unit Developer](/en/development-pepeunit/mechanics/roles#unit-developer). [Pepeunit](/en/conception/overview) uses them as templates to create `Output` [UnitNodes](/en/definitions#unitnode) | [Developer topics](/en/developer/files/struct-schema-json#developer-topics)

::::info
When using client libraries for [Micropython](/en/developer/libraries/micropython), [Golang](/en/developer/libraries/golang), or [Python](/en/developer/libraries/python), you can include all topics from `input_base_topic` and `output_base_topic`; they will work correctly.

If you implement interaction with [Pepeunit](/en/conception/overview) without using these libraries, you can leave only the topics you actually need for your [Unit](/en/definitions#unit).
::::

::::warning
When a [Unit](/en/definitions#unit) is created or its version changes, [Pepeunit](/en/conception/overview) automatically creates missing and removes obsolete `Input` and `Output` [UnitNodes](/en/definitions#unitnode) according to [schema_example.json](/en/definitions#schema-example-json).
::::


