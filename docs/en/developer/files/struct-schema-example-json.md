# schema_example.json

:::warning What is schema_example.json for?
It is a contract between the [Unit Developer](/development-pepeunit/mechanics/roles#unit-developer) and Pepeunit:
1. The Developer guarantees that the Unit works with the standard topics from input_base_topic and output_base_topic that they specified
1. The Developer guarantees that input_topic and output_topic work as described in their readme
1. Pepeunit guarantees correct work with the standard topics
1. Pepeunit guarantees that the Unit's UnitIO always match input_topic and output_topic from schema_example.json for the selected version
:::

## Structure

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

The file always has four keys, and the value of each is a list. A list can be empty. If a key is missing or the value is not a list, the Unit will not be created.

Key | What it holds | Details
-- | -- | --
input_base_topic | Standard commands the Unit is ready to execute | [Standard MQTT commands](/developer/mqtt/default-mqtt-command)
output_base_topic | Standard topics the Unit publishes its state and logs to | [Standard MQTT state topics](/developer/mqtt/state-mqtt-send)
input_topic | Developer Input topics. For each one Pepeunit creates an Input UnitIO | [Developer topics](/developer/files/struct-schema-json#developer-topics)
output_topic | Developer Output topics. For each one Pepeunit creates an Output UnitIO | Same place

A topic name can contain Latin letters, digits and the characters / _ -

With the client libraries ([Micropython](/developer/libraries/micropython), [ESP-IDF](/developer/libraries/esp-idf), [Golang](/developer/libraries/golang), [Python](/developer/libraries/python)) you can specify all the standard topics, and they will work on their own. If you write the interaction with Pepeunit without libraries, leave only the ones you need.

:::warning
Backend sends a standard command only if its topic is listed in input_base_topic. Without update/pepeunit the Unit will not receive the update command.
:::

:::warning
When a Unit is created and when its version changes, Pepeunit creates the missing Input and Output UnitIO and deletes the extra ones so that they match the file.
:::

## The /pepeunit postfix

A Developer topic can have the /pepeunit postfix at the end, as in the example. It is needed if the data must be processed by [DataPipe](/deployment/dependencies/datapipe): it reads only such topics. For them the LastValue policy is also enabled automatically at creation, unless this is disabled in the [instance settings](/deployment/instance-settings#datapipe) (pu_datapipe_default_last_value_enable).

Without the postfix, DataPipe cannot be configured for the UnitIO, otherwise such a topic works the same way.
