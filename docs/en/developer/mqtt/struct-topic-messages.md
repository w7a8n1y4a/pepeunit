# Structure of messages in MQTT topics

::::info
Messages sent via [MQTT](/en/definitions#mqtt) topics are transferred in text form.
::::

::::danger
[Unit Developers](/en/development-pepeunit/mechanics/roles#unit-developer) can always apply additional encryption on top of the textual data if needed. For example, the `aes-gcm-256` algorithm based on `PU_ENCRYPT_KEY` is built into the [client libraries](/en/developer/libraries/framework).
::::

::::warning
The size of any message a [Unit](/en/definitions#unit) sends through [EMQX](/en/deployment/dependencies/emqx) is limited by the `PU_MQTT_MAX_PAYLOAD_SIZE` environment variable in the [Backend ENV](/en/deployment/env-variables/backend).
::::

## DataPipe

For simple text or numeric messages, you can process data through [DataPipe](/en/deployment/dependencies/datapipe).


