# Сущности Pepeunit

Имена сущностей одинаковы в [Backend](/deployment/dependencies/backend), клиенте и документации. Тип сущности пишется с заглавной буквы, как в коде: `Repo`, `Unit`, `UnitIO`.

:::tip Зачем знать сущности?
[Роль](/development-pepeunit/mechanics/roles), [видимость](/development-pepeunit/mechanics/visibility) и [доступ](/development-pepeunit/mechanics/permission) всегда относятся к конкретной сущности. Названия ниже встречаются во всех разделах для разработчиков Pepeunit.
:::

## Основные сущности

Сущность | Что это | Кто создаёт | Кто видит
-- | -- | -- | --
`User` | Аккаунт инстанса: пара ключей, [роль](/development-pepeunit/mechanics/roles) и статус `Active` или `Blocked` | Сам человек при регистрации | Любой вошедший `User`
`Repo` | Git репозиторий на `GitLab` или `GitHub`, копия которого хранится на инстансе | `User` или [Peer](/development-pepeunit/mechanics/federation) | `User` видит все `Repo`, [Bot](/development-pepeunit/mechanics/roles#bot) только публичные
`Unit` | Устройство или программа, созданная из `Repo`. У него своя версия, окружение и токен | `User` | [Уровень видимости](/development-pepeunit/mechanics/visibility)
`UnitIO` | Вход (`Input`) или выход (`Output`) `Unit`: один топик из `schema_example.json` | Pepeunit, при создании и обновлении `Unit` | [Уровень видимости](/development-pepeunit/mechanics/visibility)
`Link` | Связь выхода одного `UnitIO` с входом другого | `User`, который видит оба `UnitIO` | Вместе со своим `Unit`
`UnitGroup` | Группа `Unit` для удобства. Не влияет на доступ | `User` | Только создатель
`Permission` | Запись о том, что агент (`User` или `Unit`) может видеть `Unit` или `UnitIO` с уровнем `Private` | Pepeunit и создатель ресурса | Создатель ресурса
`Dashboard` | Дашборд [Grafana](/deployment/dependencies/grafana) из панелей (`DashboardPanel`), в которые добавлены `UnitIO` | `User` | Только создатель
`Peer` | Другой инстанс Pepeunit, о котором знает этот инстанс | [Admin](/development-pepeunit/mechanics/roles#admin) или сам Pepeunit при опросе других `Peer` | `User` и `Bot`
`Notification` | Уведомление одного `User` | Pepeunit | Только получатель
`NotificationSettings` | Настройки уведомлений одного `User` | Pepeunit | Только владелец настроек
`OperationTask` | Запись о запущенной вручную долгой операции. Результат приходит как `Notification` | Pepeunit при запуске операции | Через `Notification` получателя
`InstanceSettings` | Единственная запись с [настройками инстанса](/deployment/instance-settings) | Pepeunit при первом запуске | Меняет только [Owner](/development-pepeunit/mechanics/roles#owner)
`Icon` | PNG картинка `User`, `Unit`, `UnitGroup` или самого инстанса. Хранится в [PostgreSQL](/deployment/dependencies/postgresql) | Pepeunit генерирует её сама, владелец сущности может загрузить свою | Любой

Данные временного ряда лежат отдельно, в [ClickHouse](/deployment/dependencies/clickhouse): логи `Unit` и значения из [DataPipe](/deployment/dependencies/datapipe).

## Как сущности связаны

```text
User ─┬─ Repo ── Unit ── UnitIO ── Link ── UnitIO
      │            │        └── Permission
      │            └── UnitGroup (многие ко многим)
      ├─ Dashboard ── DashboardPanel ── UnitIO
      └─ Notification, NotificationSettings
```

1. `Unit` всегда создан из одного `Repo` и принадлежит одному `User`
1. У `Unit` столько `UnitIO`, сколько топиков в разделах `input_topic` и `output_topic` файла [schema_example.json](/developer/files/struct-schema-example-json). Стандартные топики из `input_base_topic` и `output_base_topic` `UnitIO` не создают
1. `UnitIO`, `Link` и `Permission` удаляются вместе с `Unit`, `Dashboard` и `DashboardPanel` вместе с создателем
1. `Repo` нельзя удалить, пока у него есть `Unit`. Удалить `Repo` может только его создатель
1. `User` через API не удаляется: его можно только заблокировать

## Repo

Раньше существовали два понятия: хранилище репозиториев и сам `Repo`. Теперь это одна сущность `Repo`:

- `is_public_repository` делит `Repo` на публичные и приватные. Уровня видимости, как у `Unit`, у `Repo` нет
- Приватный `Repo` виден в списке любому `User`, но работать с ним (синхронизировать, создавать `Unit`) можно только со своими `Креды доступа` к платформе. Креды хранятся [шифрованными](/development-pepeunit/mechanics/cipher) отдельно для каждого `User`, у них статус `Valid`, `NotVerified` или `Error`. Работать можно, только если статус `Valid`
- `Bot` видит только публичные `Repo`
- Статус синхронизации с Git: `Updated`, `Processing` или `Error`
- Размер копии на диске ограничен настройкой `pu_instance_repo_max_size`, а частота синхронизации настройкой `pu_instance_repo_min_interval_sync`

## UnitIO

Раньше эта сущность называлась `UnitNode`. Теперь везде `UnitIO`: в базе таблица `units_io`, в тестах и уведомлениях `UnitIO`.

Поле | Что значит
-- | --
`type` | `Input` или `Output`
`topic_name` | Имя топика из `schema_example.json`
`visibility_level` | [Уровень видимости](/development-pepeunit/mechanics/visibility), не мягче, чем у `Unit`
`is_rewritable_input` | Может ли другой `Unit` писать в этот `Input`
`max_connections` | Сколько `Link` может быть у `UnitIO`
`state` | Последнее значение, которое прошло через топик
`is_data_pipe_active` | Включён ли [DataPipe](/deployment/dependencies/datapipe) для этого `UnitIO`. Доступно для топиков с суффиксом `/pepeunit`. Если включена настройка `pu_datapipe_default_last_value_enable`, такие `UnitIO` создаются сразу с политикой `LastValue`

## Peer

Раньше внешний инстанс назывался `Instance`. Теперь `Instance` - это развёрнутый Pepeunit целиком, а другие инстансы, о которых он знает, называются `Peer`. Подробнее в [Федерации](/development-pepeunit/mechanics/federation).

Статус доверия | Что значит
-- | --
`Trust` | `Peer` опрашивается, его публичные `Repo` попадают на инстанс
`Pending` | `Peer` найден у другого `Peer`. Не опрашивается, пока [Admin](/development-pepeunit/mechanics/roles#admin) не примет решение
`Blocking` | Связь запрещена, `Peer` не опрашивается

## Агенты и сущности

Сущностью `User` является только человек. Остальные участники запросов называются [агентами](/development-pepeunit/mechanics/roles#агенты): `Bot`, `Unit`, `Backend`, `Grafana` и `GrafanaUnitIO`. `Unit` - единственный агент, у которого есть и собственная сущность, и право ходить в API.
