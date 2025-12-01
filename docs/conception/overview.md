# Pepeunit

:::info
`Pepeunit` - платформа с открытым исходным кодом, основанная на принципах [Fediverse](/definitions#fediverse) и [IoT](/definitions#iot), предназначенная для организации устройств в единую, управляемую информационную систему.
:::

## CI/CD для Unit

`Pepeunit` способен на основе внешних [Git](/definitions#git) репозиториев из [Gitlab](/definitions#gitlab) и [Github](/definitions#github), создавать готовые к использованию программы - это могут быть программы на основе [Интерпритируемых](/definitions#interpreterable) или [Компилируемых](/definitions#compilable) языков программирования.

## Конвейеры обработки данных

`Pepeunit` способен производительно накапливать, предварительно отчищенные и трансформированные данные в [Clickhouse](/deployment/dependencies/clickhouse) и [Postgresql](/deployment/dependencies/postgresql). Обработка производится на основании конвейерных конфигураций в [YML](/definitions#yml) формате. Cкорость обработки обеспечивает отдельный микросервис написанный на [Golang](/definitions#golang). Доступно `4` основных типа накопления данных:
- `Last Value` - сохранение последнего значения
- `N Records` - сохранение `N` последних записей
- `Time Window` - сохранение всех записей за установленное временное окно
- `Aggregation` - сохранение данных аггрегированных при помощи фукнций: `avg, sum, min, max` - за выбранное временное окно

## Интеграция с Grafana

`Pepeunit` - позволяет создавать кастомные [Dashboard](/definitions#dashboard) из [Visualization](/definitions#visualization). В качестве данных служат [UnitNode](/definitions#unitnode) с настроенными [DataPipe](/deployment/dependencies/datapipe)


## Управление устройствами IoT

`Pepeunit` предоставляет несколько способов взаимодействия с [Unit](/definitions#unit)
- [MQTT](/definitions#mqtt) - [EMQX](/deployment/dependencies/emqx)
- [Frontend](/deployment/dependencies/frontend) - `React`
- [REST](/definitions#rest) - `Swagger`
- [GQL](/definitions#gql) - `Strawberry`
- [Telegram Bot](/definitions#telegram-bot) - `AioGram`

## Управление топиками

`Pepeunit` позволяет отслеживать состояние [Unit](/definitions#unit) при помощи системы именования топиков. [UnitNode](/definitions#unitnode) могут образовывать связи `Output` -> `Input` для передачи информации между разными [Unit](/definitions#unit).

## Настройка политик доступа

`Pepeunit` позволяет регулировать уровни [доступа](/development-pepeunit/mechanics/permission) `Пользователь-Unit` и `Unit-Unit`. Глубина взаимодействия с платформой определяется [ролью Пользователя](/development-pepeunit/mechanics/roles) и [видимостью](/development-pepeunit/mechanics/visibility) отдельных сушностей [Repo](/definitions#repo), [Unit](/definitions#unit), [UnitNode](/definitions#unitnode).

## Клиентские библиотеки

`Pepeunit` имеет библиотеки облегчающие создание [Unit](/definitions#unit), каждая из библиотек поддерживает полный функционал, на данный момент доступны:
- [Micropython](/developer/libraries/micropython)
- [Python](/developer/libraries/python)
- [Golang](/developer/libraries/golang)

## Сравнение Инстансов

Будет доступно начиная с одной из версий > 1.0.0

## Федерация

Будет доступно в версии 2.0.0

## Монетизация

Будет доступно в версии 2.0.0
