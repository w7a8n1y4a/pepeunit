# Pepeunit

:::info
`Pepeunit` - платформа с открытым исходным кодом, основанная на принципах [Fediverse](/definitions#fediverse) и [IoT](/definitions#iot), предназначенная для организации устройств в единую и управляемую информационную систему.
:::

![img](/schemas/work_schema.svg)

## CI/CD для Unit

`Pepeunit` способен на основе внешних [Git](/definitions#git) репозиториев из [GitLab](/definitions#gitlab) и [GitHub](/definitions#github), создавать готовые к использованию программы - это могут быть программы на основе [Интерпретируемых](/definitions#interpreterable) или [Компилируемых](/definitions#compilable) языков программирования.

:::info
[Cистема обновлений](/development-pepeunit/mechanics/update-system)
:::

## Конвейеры обработки данных

`Pepeunit` способен производительно накапливать предварительно очищенные и трансформированные данные в [ClickHouse](/deployment/dependencies/clickhouse) и [PostgreSQL](/deployment/dependencies/postgresql).

Обработка производится на основании конвейерных конфигураций в [YML](/definitions#yml) формате. Cкорость обработки обеспечивает микросервис, написанный на [Golang](/definitions#golang). Доступно `4` основных типа накопления данных:
- `Last Value` - сохранение последнего значения
- `N Records` - сохранение `N` последних записей
- `Time Window` - сохранение всех записей за установленное временное окно
- `Aggregation` - сохранение за выбранное временное окно данных, агрегированных при помощи фукнций `avg, sum, min, max`

:::info
[DataPipe](/deployment/dependencies/datapipe)
:::

## Интеграция с Grafana

`Pepeunit` - позволяет создавать кастомные [Dashboard](/definitions#dashboard) из [Visualization](/definitions#visualization). В качестве данных служат [UnitNode](/definitions#unitnode) с настроенными [DataPipe](/deployment/dependencies/datapipe)

:::info
[Создание Dashboard](/user/grafana/create)
:::

## Управление устройствами IoT

`Pepeunit` предоставляет несколько способов взаимодействия с [Unit](/definitions#unit)
- [MQTT](/definitions#mqtt) - [EMQX](/deployment/dependencies/emqx)
- [Frontend](/deployment/dependencies/frontend) - `React`
- [REST](/definitions#rest) - `Swagger`
- [GQL](/definitions#gql) - `Strawberry`
- [Telegram Bot](/definitions#telegram-bot) - `AioGram`

## Управление топиками

`Pepeunit` позволяет отслеживать состояние [Unit](/definitions#unit) при помощи системы именования топиков. [UnitNode](/definitions#unitnode) могут образовывать связи `Output->Input` для передачи информации между разными [Unit](/definitions#unit).

:::info
[Связи Output->Input](/user/unit/edge-unit-node)

[Стандартные MQTT команды](/developer/mqtt/default-mqtt-command)

[Стандартные MQTT топики состояния](/developer/mqtt/state-mqtt-send)

[Структура сообщений в MQTT топиках](/developer/mqtt/struct-topic-messages)
:::


## Настройка политик доступа

`Pepeunit` позволяет регулировать уровни [доступа](/development-pepeunit/mechanics/permission) [Пользователей](/development-pepeunit/mechanics/roles.html#user) и `Unit-Unit`. Глубина взаимодействия с платформой определяется ролью [Пользователя](/development-pepeunit/mechanics/roles) и [видимостью](/development-pepeunit/mechanics/visibility) отдельных сущностей [Repo](/definitions#repo), [Unit](/definitions#unit), [UnitNode](/definitions#unitnode).

:::info
[Управление доступами](/development-pepeunit/mechanics/permission)
:::

## Клиентские библиотеки

`Pepeunit` имеет библиотеки, облегчающие создание [Unit](/definitions#unit), каждая из которых поддерживает полный функционал [Pepeunit Framework](/developer/libraries/framework). На данный момент доступны:
- [Micropython](/developer/libraries/micropython)
- [Python](/developer/libraries/python)
- [Golang](/developer/libraries/golang)

## Сравнение Инстансов

[Будет доступно, начиная с одной из версий > 1.0.0](/roadmap/comparison)

## Федерация

[Будет доступно в версии 2.0.0](/roadmap/federation)

## Монетизация

[Будет доступно в версии 2.0.0](/roadmap/monetisation)
