# EMQX

[EMQX MQTT Broker](https://docs.emqx.com/en/emqx/latest/) - серверное приложение, которое координирует сообщения между издателями и подпищиками [MQTT](/definitions#mqtt-broker) протокола. Брокер обеспечивает взаимодействие через `1883` порт между [Unit](/definitions#unit) и [Backend](/definitions#backend). Его можно назвать рельсой данных, на которую завязано основное взаимодействие.

Используется [Unit](/definitions#unit), [Backend](/definitions#backend) и [DataPipe](/definitions#datapipe) для организации взаимодействия:

Сущность | Операции
-- | --
[Unit](/definitions#unit) | Публикуют/подписываются на конкретные [MQTT](/definitions#mqtt) топики с паттернами `example.com/+/pepeunit` и `example.com/+/+/+/pepeunit`
[Backend](/definitions#backend) | Публикует/подписывается на все [MQTT](/definitions#mqtt) топики с паттерном `example.com/+/+/+/pepeunit` и имеет возможность по запросу [Пользователя](/development-pepeunit/mechanics/roles.html#user) отправлять данные в `Input` топики c паттерном  `example.com/+/pepeunit`
[DataPipe](/definitions#datapipe) | Подписан на все топики с паттерном `example.com/+/pepeunit`

:::info
[Стандартные MQTT команды](/developer/mqtt/default-mqtt-command)

[Стандартные MQTT топики состояния](/developer/mqtt/state-mqtt-send)

[Структура сообщений в MQTT топиках](/developer/mqtt/struct-topic-messages)
:::
