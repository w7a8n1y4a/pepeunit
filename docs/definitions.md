# Определения


## Micropython
[Micropython](https://docs.micropython.org) - это простая и эффективная реализация языка программирования Python 3, включающая небольшое подмножество стандартной библиотеки Python и оптимизированная для работы на микроконтроллерах и в ограниченных средах.

## Fediverse
[Fediverse](https://en.wikipedia.org/wiki/Fediverse) - это способ организации взаимодействия сервер - сервер, обеспечивающий децентрализованную схему распространения и обработки информации.

## IoT
`Ineternet of Things` - это обширная сеть устройств-предметов, подключенных к Интернету и способных взаимодействовать друг c другом.

## Git
[Git](https://git-scm.com/) - это бесплатная распределенная система контроля версий с открытым исходным кодом, предназначенная для быстрой и эффективной работы с проектами, от небольших до очень крупных.

## Interpreterable
`Interpreterable` - семейство языков программирования, у которых программный код выполняется интерпритатором - бинарной программой читающей программы строчка за строчкой.

## Compilable
`Compilable` - семейство языков программирования, у которых программный код перед исполнением преобразуется в машинный код при помощи компилятора. Сгенерированный машинный код исполняется процессором напрямую.

## Git Commit
`Commit или Коммит` - это зафиксированное во времени состояние кода или иной байтовой структуры в системе контроля версии [Git](#git). Каждый коммит имеет свой уникальный идентификатор и обычно имеет `description` - текстовое описание изменений, которые в него входят.

## Git Tag
`Tag или Тег` - это коммит, помеченный дополнительным свойством - тегом, обычно тег присваивается стабильным-релизным версиям какой-либо программы.

## Git Branch
`Branch или Ветка` - это набор коммитов, расположенных в хронологическом порядке в системе контроля версии [Git](#git).

## Gitlab
`Gitlab` - это веб-инструмент жизненного цикла [Git](#git) репозиториев от компании `GitLab Inc`. В данной документации под `Gitlab` подразумевается не только [gitlab.com](https://about.gitlab.com/), но и любой другой [Узел](#instance) `Gitlab CE` или `Gitlab EE`

## Github
[Github](https://github.com/) - это хостинг [Git](#git) репозиториев от компании `Github Inc`.

## Pepeunit
[Pepeunit](https://pepeunit.com) - платформа с открытым исходным кодом, основанная на принципах [Fediverse](definitions#fediverse) и [IoT](definitions#iot), предназначенная для организации устройств в единую, управляемую информационную систему.

## Instance
`Instance или Узел` - полностью работоспособное, настроенное и запущенное веб приложение - способное отвечать на запросы клиентов.

## API
`Application Programming Interface` - это контракт, проедоставляемый программами и описывающий взаимодействие c ними.

## REST
`REST API` - контракт описывающий взаимодействие программы с клиентами через `HTTP` запросы. Pepeunit [Backend](#backend) использует пакет [Pydantic](https://docs.pydantic.dev/latest/) и интерфейс [Swagger OpenAPI](https://swagger.io/docs/) для предоставления `REST API`.

## GQL
`GraphQL API` - это язык запросов и серверная среда с открытым исходным кодом, использующая `HTTP` запросы для обмена информацией с клиентами. Pepeunit [Backend](#backend) использует пакет [strawberry-graphql](https://strawberry.rocks/docs) для предоставления `GraphQL API`.

## MQTT
`MQTT API` - упрощённый сетевой протокол, работающий поверх `TCP/IP`, ориентированный на обмен сообщениями между устройствами по принципу издатель-подпищик. Pepeunit [Backend](#backend) использует пакет [fastapi-mqtt](https://sabuhish.github.io/fastapi-mqtt/) как клиент, для взаимодействия c [MQTT Broker - EMQX](https://www.emqx.io/docs/en/latest/).

## OTA
`Over The Air` - обновление по воздуху, способ доставки и установки новых микропрограм в [IoT](#iot) устройства. [Pepeunit](#pepeunit) поддерживает обновление по `OTA` через [REST](#rest) и отдаёт три вида архивов:
- `zip` для первичной ручной установки на устройство
- `tar` для устройств не поддерживающих распаковку `gz`
- `tgz` как основной способ обновления

## MQTT Broker
`MQTT Broker` - это серверное приложение, которое координирует сообщения между издателями и подпищиками [MQTT](#mqtt) протокола. В [Pepeunit](#pepeunit) главными подпищиками и издателеми можно считать [Unit](#unit), а главным руководителем взаимодействия - [Backend](#backend). [Pepeunit](#pepeunit) использует [MQTT](#mqtt) брокера - [EMQX](https://www.emqx.io/docs/en/latest/).

## ACL List
`ACL List` - это файл, определяющий правила авторизации для [MQTT Broker](#mqtt-broker)

## Redis
[Redis](https://redis.io/) - `NoSQL` кластерная база данных использующая парадигму `key-value`

## Postgresql
[Postgresql](https://www.postgresql.org/docs/) - кластерная реляционная база данных с языком запросов `SQL`.

## ChatBot
`ChatBot` - приложение, позволяющее взаимодействовать с [Backend](#backend) через диалог в чате. Pepeunit [Backend](#backend) использует пакет [AioGram](https://github.com/aiogram/aiogram) как клиент, для взаимодействия с [Telegram Bot API](https://core.telegram.org/bots/api).

## Frontend
`Frontend` - веб приложение, доступное для скачивания открытым способом и предназаначенное для обеспечения взаимодействия пользователя c [Backend](#backend) приложением. [Pepeunit Frontend Repository](https://git.pepemoss.com/pepe/pepeunit/pepeunit_frontend)

## Backend
`Backend` - приложение размещаемое на сервере, обеспечивающее обработку, хранение и анализ информации, а так же предоставляющее разные [API](#api) для взаимодействия. [Pepeunit Backend Repository](https://git.pepemoss.com/pepe/pepeunit/pepeunit_backend.git)

## Repo
`Repo` - это представление [Pepeunit](#pepeunit) о внешнем [Git](#git) репозитории, например из [Gitlab](#gitlab) или [Github](#github). Данная сущность содержит в себе полный клон репозитория и синхронизирует своё состояние с внешним репозиторием, что позволяет [Pepeunit](#pepeunit) быстро создавать микропрограммы для [Unit](#unit).

## Unit
`Unit` - это представление о физичеcком [IoT](#iot) устройстве в [Pepeunit](#pepeunit), данная сущность создаётся на основе [Repo](#repo) и несёт в себе информацию о конкретном физическом [IoT](#iot) устройстве, а так же о версии микропрограммы доступной в [Repo](#repo)

## UnitNode
`UnitNode` - это предстваление о топике в [MQTT](#mqtt) для [Pepeunit](#pepeunit), данная сущность описывает точку взаимодействия с [Unit](#unit). `UnitNode` может быть двух типов `Input` и `Output`. Между `UnitNode` разных [Unit](#unit) могут быть связи: от одного `Output` к многим `Input`.

## env_example.json
`env_example.json`- файл, описывающий переменные окружения нужные дла корректной работы микропрограммы [Unit](#unit), он создаётся разработчиком [Unit](#unit) и помещается в каждую версию [Repo](#repo). На основе данного файла и ввода пользователя, [Pepeunit](#pepeunit) может сгенерировать [env.json](#envjson) файл для [Unit](#unit).

## env.json
`env.json`- секретный файл, содержащий переменные окружения нужные дла корректной работы микропрограммы [Unit](#unit). Именно данный файл отличает ваш [Unit](#unit) от других [Unit](#unit) отстыкованных от одного и того же [Repo](#repo). Он создаётся владельцем [Unit](#unit) совместно с [Pepeunit](#pepeunit) и хранится в шифрованном виде внутри сущности [Unit](#unit).

::: danger
Никогда и никому не передавайте `env.json` файл, любой человек имеющий данный файл, может эмулировать ваше устройство [Unit](#unit).
:::

## schema_example.json
`schema_example.json` - файл схемы, описывающий [MQTT](#mqtt) топики нужные [Unit](#unit). Данный файл создаётся разработчиком [Unit](#unit) и помещается в каждую версию [Repo](#repo). Благодаря данному файлу [Pepeunit](#pepeunit) создаёт [UnitNode](#unitnode) сущности, отвечающие за взаимодействие с [Unit](#unit) и регламентирующие политики доступа до топиков [Unit](#unit). Пример:
```json
{
    "input_base_topic": [
        "update/pepeunit",
        "schema_update/pepeunit"
    ],
    "output_base_topic": [
        "state/pepeunit"
    ],
    "input_topic": [
        "input/pepeunit"
    ],
    "output_topic": [
        "output/pepeunit"
    ]
}
```

## schema.json
`schema.json` - готовый файл схемы для [Unit](#unit) генерируемый [Pepeunit](#pepeunit), содержит в себе ссылки на [UnitNode](#unitnode) и базовые топики для взаимодействия с [Pepeunit](#pepeunit). Пример готовой схемы:

```json
{
    "input_base_topic": {
        "update/pepeunit": [
            "example.com/input_base_topic/5e1a4151-515e-4926-8b8a-5e821713e25e/update/pepeunit"
        ],
        "schema_update/pepeunit": [
            "example.com/input_base_topic/5e1a4151-515e-4926-8b8a-5e821713e25e/schema_update/pepeunit"
        ]
    },
    "output_base_topic": {
        "state/pepeunit": [
            "example.com/output_base_topic/5e1a4151-515e-4926-8b8a-5e821713e25e/state/pepeunit"
        ]
    },
    "input_topic": {
        "input/pepeunit": [
            "example.com/dc2d6f5e-90b3-4cdb-91a4-5ae12db1887f/pepeunit",
            "example.com/f06bcaa8-bb00-45ea-aba8-0fc0eba41e08/pepeunit"
        ]
    },
    "output_topic": {
        "output/pepeunit": [
            "example.com/4114a3f8-65c1-4d42-8d1d-481785d0dcca/pepeunit"
        ]
    }
}
```
- `5e1a4151-515e-4926-8b8a-5e821713e25e` - при этом `uuid` [Unit](#unit)
- `dc2d6f5e-90b3-4cdb-91a4-5ae12db1887f`, `f06bcaa8-bb00-45ea-aba8-0fc0eba41e08`, `4114a3f8-65c1-4d42-8d1d-481785d0dcca` - при этом `uuid` разных [UnitNode](#unitnode)
- `input/pepeunit` - имеет сразу два топика, это означает что один из этих [UnitNode](#unitnode) принадлежит к текущему [Unit](#unit) с `uuid=5e1a4151-515e-4926-8b8a-5e821713e25e`, а второй другому [UnitNode](#unitnode)
