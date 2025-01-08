# Всё о сущности UnitNode

[UnitNode](/definitions#unitnode) - это автоматически генерируемые сущности связанные с [Unit](/definitions#unit), они cоздаются на основе файла [schema_example.json](/definitions#schema-example-json), который содержится в разных версиях [Repo](/definitions#repo).

Каждая сущность [UnitNode](/definitions#unitnode) может иметь два типа `Input` или `Output`. При этом между [UnitNode](/definitions#unitnode) разных [Unit](/definitions#unit), могут быть связи - от одного `Output` к многим `Input`. Всё взаимодействие между [UnitNode](/definitions#unitnode) происходит при этом через [MQTT Broker](/definitions#mqtt-broker). [Backend](/definitions#backend) при этом заниматся только авторизацией [Unit](/definitions#unit) для доступа до определённых топиков.

::: warning Нюансы работы UnitNode
`Input` тип для [UnitNode](/definitions#unitnode) можно понимать как точку из которой [Unit](/definitions#unit) получает данные от внешнего мира. Положить данные в данную точку можно любым из [API](/definitions#api), которые поддерживаются в [Backend](/definitions#backend).

`Input` [UnitNode](/definitions#unitnode) могут ограничить доступ на свою перезапись для других [Unit](/definitions#unit)  - это нужно когда есть потребность обеспечить доступ только для пользователей, с такими [UnitNode](/definitions#unitnode) нельзя создать связь.

В `Output` информацию может помещать только сам [Unit](/definitions#unit), которому принадлежит [UnitNode](/definitions#unitnode). [Unit](/definitions#unit) может это осуществить через любой доступный [API](/definitions#api) в [Backend](/definitions#backend).

`Output` [UnitNode](/definitions#unitnode) с определёнными названиями, могут заставлять [Pepeunit](/definitions#pepeunit) накапливать статистику по их состоянию во времени. Это могут быть например датчики температуры - отправляющие сообщения каждую секунду, [Pepeunit](/definitions#pepeunit) позволит найти средне часовые температуры.

[Backend](/definitions#backend) обновляет значения только у топиков с префиксом `/pepeunit` в конце. При этом в [Postgresql](/definitions#postgresql) сохраняются только новые значения, по сравнению с ранее пришедшими.
:::
