# Всё о сущности UnitNode

`UnitNode` - это автоматически генерируемые сущности связанные с [Unit](/definitions#unit), они cоздаются на основе файла [schema_example.json](/definitions#schema-example-json), который содержится в разных версиях [Repo](/definitions#repo).

Каждая сущность `UnitNode` может иметь два типа `Input` или `Output`. При этом между `UnitNode` разных [Unit](/definitions#unit), могут быть связи - от одного `Output` к многим `Input`.

Всё взаимодействие между `UnitNode` происходит при этом через [MQTT Broker](/definitions#mqtt-broker). [Backend](/definitions#backend) заниматся только авторизацией [Unit](/definitions#unit) для доступа до определённых топиков.

Для настройки `UnitNode` можно воспользоваться [Инструкцией](/user/settings-unit-node#настроики-unitnode)

::: warning Нюансы работы UnitNode
`Input` тип для `UnitNode` можно понимать как точку из которой [Unit](/definitions#unit) получает данные от внешнего мира. Положить данные в данную точку можно любым из [API](/definitions#api), которые поддерживаются в [Backend](/definitions#backend).

`Input` `UnitNode` могут ограничить доступ на свою перезапись для других [Unit](/definitions#unit)  - это нужно когда есть потребность обеспечить доступ только для пользователей, с такими `UnitNode` нельзя создать связь.

В `Output` информацию может помещать только сам [Unit](/definitions#unit) от которого отстыкован `Output`. [Unit](/definitions#unit) может это осуществить через любой доступный [API](/definitions#api) в [Backend](/definitions#backend).

`Output` `UnitNode` с определёнными названиями, могут заставлять [Pepeunit](/conception/overview) накапливать статистику по их состоянию во времени. Это могут быть например датчики температуры - отправляющие сообщения каждую секунду, [Pepeunit](/conception/overview) позволит найти средне часовые температуры.

[Backend](/definitions#backend) подписан только на топики с префиксом `/pepeunit` в конце. При этом в `Postgresql` сохраняются только новые значения, по сравнению с ранее пришедшими.
:::
