# EMQX

[EMQX MQTT Broker](https://docs.emqx.com/en/emqx/latest/) is a server application that coordinates messages between publishers and subscribers of the [MQTT](/en/definitions#mqtt) protocol. The broker provides communication over port `1883` between [Unit](/en/definitions#unit) and [Backend](/en/deployment/dependencies/backend). It can be described as the `data rail` on which the main interaction is built. [More about environment variables](/en/deployment/env-variables/emqx)

It is used by [Unit](/en/definitions#unit), [Backend](/en/deployment/dependencies/backend) and [DataPipe](/en/deployment/dependencies/datapipe) to organize interaction:

Entity | Operations
-- | --
[Unit](/en/definitions#unit) | Publishes/subscribes to specific [MQTT](/en/definitions#mqtt) topics with patterns `example.com/+/pepeunit` and `example.com/+/+/+/pepeunit`
[Backend](/en/deployment/dependencies/backend) | Publishes/subscribes to all [MQTT](/en/definitions#mqtt) topics with pattern `example.com/+/+/+/pepeunit` and, on [User](/en/development-pepeunit/mechanics/roles.html#user) request, can send data to `Input` topics with the pattern `example.com/+/pepeunit`
[DataPipe](/en/deployment/dependencies/datapipe) | Subscribes to all topics with pattern `example.com/+/pepeunit`

::::info
[Default MQTT commands](/en/developer/mqtt/default-mqtt-command)

[Default MQTT state topics](/en/developer/mqtt/state-mqtt-send)

[Message structure in MQTT topics](/en/developer/mqtt/struct-topic-messages)
::::

