# Настройки UnitNode

:::warning
[UnitNode](/definitions#unitnode) создаются автоматически, их количество может изменяться от версии к версии [Unit](/definitions#unit), в зависимости от содержания файла [schema_example.json](/definitions#schema-example-json). [Pepeunit](/conception/overview) сам поддерживает актуальный набор [UnitNode](/definitions#unitnode).
:::

:::info Как найти UnitNode?
1. Найдите интересующий вас [Unit](/definitions#unit) визуально или через вкладку поиска. 
1. Нажмите `ПКМ` по [Unit](/definitions#unit) если [UnitNode](/definitions#unitnode) ещё не отобразились
:::

## Уровень видимости
Выберите [Уровень видимости](/mechanics/visibility)

## Настройка Перезаписываемости для Input

Если состояние флага перезаписываемости `False` то [Unit](/definitions#unit) у которых есть [доступ](/mechanics/permission), несмогут записать новое значение через [REST](/definitions#rest) и [GQL](/definitions#gql). Т.е. возможность установить значение будет только у [Пользователей](/mechanics/roles.html#user) с [доступом](/mechanics/permission) и связанных через `Output->Input` топиков.

:::info
Данная настройка нужна, чтобы ограничить возможности [Unit](/definitions#unit) по перезаписи информации в [доступных](/mechanics/permission) им [UnitNode](/definitions#unitnode).
:::