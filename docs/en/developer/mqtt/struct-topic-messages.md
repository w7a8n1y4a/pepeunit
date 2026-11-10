# Structure of messages in MQTT topics

:::info
Messages in MQTT topics are transmitted as text.
:::

:::danger
A [Unit Developer](/development-pepeunit/mechanics/roles#unit-developer) may additionally encrypt the text however they see fit. For example, the aes-gcm-256 algorithm based on PU_ENCRYPT_KEY is built into the [client libraries](/developer/libraries/framework).
:::

:::warning
The size of a message that a Unit sends through [EMQX](/deployment/dependencies/emqx) is limited by the pu_mqtt_max_payload_size instance setting, 256 KB by default, see [instance settings](/deployment/instance-settings#mqtt).
:::

## DataPipe

Simple messages with text and numbers can be processed through [DataPipe](/deployment/dependencies/datapipe): filtered, transformed, stored, and used to trigger notifications. More details in the [user guide](/user/datapipe/datapipe).
