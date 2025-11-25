# Определения


## Micropython
[Micropython](https://docs.micropython.org) - это простая и эффективная реализация языка программирования `Python 3`, включающая небольшое подмножество стандартной библиотеки `Python` и оптимизированная для работы на микроконтроллерах и в ограниченных средах.

## Golang
[Golang](https://go.dev/) - это компилируемый, статически типизированный язык программирования, отлично подходящий для высокой нагрузки.

## Fediverse
[Fediverse](https://en.wikipedia.org/wiki/Fediverse) - это способ организации взаимодействия сервер - сервер, обеспечивающий децентрализованную схему распространения и обработки информации.

## IoT
`Ineternet of Things` - это обширная сеть устройств-предметов, подключенных к Интернету и способных взаимодействовать друг c другом.

## Framework
Готовая программная структура или каркас для разработки программ, который задаёт архитектуру приложения, управляет потоком выполнения и жизненным циклом, предоставляет набор компонентов и инструментов, а также позволяет внедрять свою логику через определённые расширяемые точки. В отличие от библиотеки, фреймворк диктует правила организации кода и вызывает пользовательский код по своему усмотрению.

## Git
[Git](https://git-scm.com/) - это бесплатная распределенная система контроля версий с открытым исходным кодом, предназначенная для быстрой и эффективной работы с проектами, от небольших до очень крупных.

## Interpreterable
`Interpreterable` - семейство языков программирования, у которых программный код выполняется интерпритатором - бинарной программой читающей программы строчка за строчкой.

## Compilable
`Compilable` - семейство языков программирования, у которых программный код перед исполнением преобразуется в машинный код при помощи компилятора. Сгенерированный машинный код исполняется процессором напрямую.

## Git Commit
`Commit или Коммит` - это зафиксированное во времени состояние кода или иной байтовой структуры в системе контроля версий [Git](#git). Каждый [коммит](/#git-commit) имеет свой уникальный идентификатор и обычно имеет `description` - текстовое описание изменений, которые в него входят.

## Git Tag
`Tag или Тег` - это [коммит](/#git-commit), помеченный дополнительным свойством - тегом, обычно тег присваивается стабильным-релизным версиям какой-либо программы.

## Git Branch
`Branch или Ветка` - это набор [коммитов](/#git-commit), расположенных в хронологическом порядке в системе контроля версии [Git](#git).

## readme.md
`readme.md` или `README.md` - файл документации внутри репозитория [Git](#git), по усмотрению создателя репозитория содержит базовую инфорацию о репозитории, нюансах работы, настройки или любую другую информацию, которую автор счёл нужной. В [Pepeunit](/conception/overview) для заполнения `readme.md` использует генератор на основе [pepeunit.toml](#pepeunit-toml). [Подробная инструкция](/developer/struct-readme#readme-md).

## Gitlab
`Gitlab` - это веб-инструмент жизненного цикла [Git](#git) репозиториев от компании `GitLab Inc`. В данной документации под `Gitlab` подразумевается не только [gitlab.com](https://about.gitlab.com/), но и любой другой [Узел](#instance) `Gitlab CE` или `Gitlab EE`

## Github
[Github](https://github.com/) - это хостинг [Git](#git) репозиториев от компании `Github Inc`.

## Instance
`Instance или Узел` - полностью работоспособное, настроенное и запущенное веб приложение - способное отвечать на запросы клиентов.

## API
`Application Programming Interface` - это контракт, проедоставляемый программами и описывающий взаимодействие c ними. Например [Backend](#backend) Pepeunit предоставляет - [REST](#rest), [GQL](#gql), [MQTT](#mqtt)

## REST
`REST API` - контракт описывающий взаимодействие программы с клиентами через `HTTP` запросы. Pepeunit [Backend](#backend) использует пакет [Pydantic](https://docs.pydantic.dev/latest/) и интерфейс [Swagger OpenAPI](https://swagger.io/docs/) для предоставления `REST API`.

## GQL
`GraphQL API` - это язык запросов и серверная среда с открытым исходным кодом, использующая `HTTP` запросы для обмена информацией с клиентами. Pepeunit [Backend](#backend) использует пакет [strawberry-graphql](https://strawberry.rocks/docs) для предоставления `GraphQL API`.

## MQTT
`MQTT API` - упрощённый сетевой протокол, работающий поверх `TCP/IP`, ориентированный на обмен сообщениями между устройствами по принципу издатель-подпищик. Pepeunit [Backend](#backend) использует пакет [fastapi-mqtt](https://sabuhish.github.io/fastapi-mqtt/) как клиент, для взаимодействия c [MQTT Broker - EMQX](https://www.emqx.io/docs/en/latest/).

## MQTT Broker
`MQTT Broker` - это серверное приложение, которое координирует сообщения между издателями и подпищиками [MQTT](#mqtt) протокола. В [Pepeunit](/conception/overview) главными подпищиками и издателеми можно считать [Unit](#unit), а главным руководителем взаимодействия - [Backend](#backend). [Pepeunit](/conception/overview) использует [MQTT](#mqtt) брокера - [EMQX](https://www.emqx.io/docs/en/latest/).

## ACL List
`ACL List` - это файл, определяющий правила авторизации для [MQTT Broker](#mqtt-broker)

## Chat Bot
`Chat Bot` - приложение, позволяющее взаимодействовать с [Backend](#backend) через диалог в чате. Pepeunit [Backend](#backend) использует пакет [AioGram](https://github.com/aiogram/aiogram) как клиент, для взаимодействия с [Telegram Bot API](https://core.telegram.org/bots/api).

## Frontend
`Frontend` - веб приложение, доступное для скачивания открытым способом и предназаначенное для обеспечения взаимодействия Пользователей c [Backend](#backend) приложением. [Pepeunit Frontend Repository](https://git.pepemoss.com/pepe/pepeunit/pepeunit_frontend)

## Backend
`Backend` - приложение размещаемое на сервере, обеспечивающее обработку, хранение и анализ информации, а так же предоставляющее разные [API](#api) для взаимодействия. [Pepeunit Backend Repository](https://git.pepemoss.com/pepe/pepeunit/pepeunit_backend.git)

## Backend Data Pipe
`Backend Data Pipe` - отдельное от `Backend` приложение размещаемое на сервере, обеспечивающее работу `DataPipe`. [Pepeunit Backend Data Pipe Repository](https://git.pepemoss.com/pepe/pepeunit/pepeunit_data_pipe.git)

## RepositoryRegistry
`RepositoryRegistry` - это представление [Pepeunit](/conception/overview) о внешнем [Git](#git) репозитории, например из [Gitlab](#gitlab) или [Github](#github). Данная сущность содержит в себе полный клон репозитория и синхронизирует своё состояние с внешним репозиторием. На основе данной сущности создаются [Repo](#repo).

## Repo
`Repo` - это внутренняя сущность [Pepeunit](/conception/overview) соединяющая [RepositoryRegistry](#repositoryregistry) и [Unit](#unit), позволяющая управлять сразу целым пулом [Unit](#unit). Можно настроить обновления сразу для всех связанных [Unit](#unit) и в ручную или автоматически их обновлять. Основная цель существования этой сущности - отвязка [Unit](#unit) по логике от [RepositoryRegistry](#repositoryregistry).

## Unit
`Unit` - это представление о физичеcком [IoT](#iot) устройстве в [Pepeunit](/conception/overview), данная сущность создаётся на основе [Repo](#repo) и несёт в себе информацию о конкретном физическом [IoT](#iot) устройстве, а так же о версии микропрограммы доступной в [Repo](#repo).

## UnitNode
`UnitNode` - это предстваление о [MQTT](#mqtt) топике для [Pepeunit](/conception/overview), данная сущность описывает точку взаимодействия с [Unit](#unit). `UnitNode` может быть двух типов `Input` и `Output`. Между `UnitNode` разных [Unit](#unit) могут быть связи: от одного `Output` к многим `Input`.

## YML
`YML` или `YAML` - это человеко-читаемый формат данных, используемый для сериализации и конфигурации. Данный формат широко применяется в автоматизации и конвейерах, для описания этапов и их парамтеров. [Pepeunit](/conception/overview) использует его для конвейеров данных.

## DataPipe
`DataPipe` - это модуль [Pepeunit](/conception/overview), состоящий из конфигурации [YML](#yml), отдельного микросервиса на [Golang](#golang) и системы управления. Предназначен для производительного накопления данных из топиков `UnitNode` согласно настройкам из [YML](#yml). У [Pepeunit](/conception/overview) есть глубокая интеграция с [Grafana](/deployment/dependencies#grafana) для визуализации данных из `DataPipe`. Микросервис подписывается на все топики с паттерном `example.com/+/pepeunit` и если работа `DataPipe` активирована в `UnitNode`, проводит процесс описанный в [YML](#yml). [Подробнее о настройке DataPipe](/user/data-pipe#datapipe)

## Datasource
`Datasource` - источник данных [Grafana](/deployment/dependencies#grafana), из которого `Grafana` получает данные для дальнейшей визуализации. [Backend](/definitions#backend) реализует [REST](/definitions#rest) запрос для [InfinityAPI](https://grafana.com/grafana/plugins/yesoreyeram-infinity-datasource/) из коробки для каждой отдельной организации. Который с использованием `headers` и `params` позволяет получать данные накопленные с помощью механизмов [DataPipe](#datapipe).

## Visualization
`Visualization`, панели —  способ отображения данных [Grafana](/deployment/dependencies#grafana). Каждая отдельная визуализация может содержать несколько [Datasource](#datasource) одного или нескольких типов. В каждую визуализацию можно слинковать несколько `UnitNode` с настроенным [DataPipe](#datapipe). При сборке визуализаций, следите, чтобы формат данных был одинаковым.

## Dashboard
`Dashboard` - набор [Visualization](#visualization) в [Grafana](/deployment/dependencies#grafana), собранных на одной панели для удобного мониторинга и анализа данных.

## env_example.json
`env_example.json`- файл, описывающий переменные окружения нужные для корректной работы [Unit](#unit), он создаётся разработчиком [Unit](#unit) и помещается в каждую версию [Repo](#repo). На основе данного файла и ввода Пользователя, [Pepeunit](/conception/overview) может сгенерировать [env.json](#envjson) файл для [Unit](#unit). Более подробная [информация о env_example.json](/developer/struct-env-json#env-example-json).

## env.json
`env.json`- секретный файл, содержащий переменные окружения нужные дла корректной работы [Unit](#unit).
Именно данный файл отличает ваш [Unit](#unit) от других [Unit](#unit) отстыкованных от одного и того же [Repo](#repo).
Он создаётся владельцем [Unit](#unit) совместно с [Pepeunit](/conception/overview) и хранится в 
[шифрованном](/development-pepeunit/mechanics/cipher) виде внутри сущности [Unit](#unit). Более подробная [информация о env.json](/developer/struct-env-json#env-json).

## schema_example.json
`schema_example.json` - файл схемы, описывающий [MQTT](#mqtt) топики нужные [Unit](#unit). Данный файл создаётся разработчиком [Unit](#unit) и помещается в каждую версию [Repo](#repo). Благодаря данному файлу [Pepeunit](/conception/overview) создаёт [UnitNode](#unitnode) сущности, отвечающие за взаимодействие с [Unit](#unit) и регламентирующие политики доступа до топиков [Unit](#unit). Более подробная [информация о schema_example.json](/developer/struct-schema-json#schema-example-json).

## schema.json
`schema.json` - готовый файл схемы для [Unit](#unit) генерируемый [Pepeunit](/conception/overview), содержит в себе ссылки на [UnitNode](#unitnode) и базовые топики для взаимодействия с [Pepeunit](/conception/overview). Более подробная [информация о schema.json](/developer/struct-schema-json#schema-json).

## .pepeignore
`.pepeignore` - файл [Git](#git) репозиториев [Unit](#unit) аналогичный по синтаксису [.gitignore](https://git-scm.com/docs/gitignore), но позволяющий удалить все указанные в нём файлы и дирректории из репозитория в момент генерации [архива с программой](/developer/struct-archive-update) для [Интерпритируемых](#interpreterable) [Unit](#unit). Более подробная [информация о .pepeignore](/developer/struct-archive-update#pepeignore).

## pepeunit.toml
`pepeunit.toml` - стандартизированый информационный блок [Unit](#unit), включающий в себя исчерпывающую информацию о [Unit](#unit). Помещается в корень [Git](#git) репозитория и выполняет функцию машиночитаемого описания [Unit](#unit) для [Pepeunit](/conception/overview). Ближайший аналог в мире разработки - `pyproject.toml`. [Подробнее о заполнении pepeunit.toml](/developer/struct-readme#pepeunit-toml)