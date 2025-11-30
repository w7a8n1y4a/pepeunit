# EMQX

[EMQX MQTT Broker](https://docs.emqx.com/en/emqx/latest/) - это серверное приложение, которое координирует сообщения между издателями и подпищиками [MQTT](/definitions#mqtt-broker) протокола. Брокер обеспечивает взаимодействие через `1883` и `8883` порты между [Unit](/definitions#unit) и [Backend](/definitions#backend). Его можно назвать рельсой данных, на которую завязано основное взаимодействие.

::: tip Ключевые моменты взаимодействия [MQTT Broker](/definitions#mqtt-broker), [Backend](/definitions#backend) и [Unit](/definitions#unit)
[Backend](/definitions#backend) выполняет [Административные](/development-pepeunit/mechanics/roles#admin) функции, а именно:
1. Авторизация всех [Unit](/definitions#unit) для доступа к определённым топикам
1. Агрегация данных из определённых топиков, согласно политике имён топиков
1. Управление [Unit](/definitions#unit), при помощи системы команд, позволяющей публиковать в топики задания на обновление [schema.json](/definitions#schema-json), [env.json](/definitions#env-json) или программы целиком.
1. Получение состояний [Unit](/definitions#unit) через специальный топик.
:::