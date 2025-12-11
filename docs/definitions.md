# Определения

## RepositoryRegistry
`RepositoryRegistry` - представление [Pepeunit](/conception/overview) о внешнем [Git](#git) репозитории, например, из [GitLab](#gitlab) или [GitHub](#github). Данная сущность содержит в себе полную копию репозитория и синхронизирует своё состояние с внешним репозиторием. На основе данной сущности создаются [Repo](#repo).

## Repo
`Repo` - внутренняя сущность [Pepeunit](/conception/overview), соединяющая [RepositoryRegistry](#repositoryregistry) и [Unit](#unit), позволяющая управлять пулом [Unit](#unit). Можно настроить обновления сразу для всех связанных [Unit](#unit) и в ручную или автоматически их обновлять. Основная цель этой сущности - отвязка [Unit](#unit) по логике от [RepositoryRegistry](#repositoryregistry).

## Unit
`Unit` - представление о физическом [IoT](#iot) устройстве в [Pepeunit](/conception/overview), данная сущность создаётся на основе [Repo](#repo) и несёт в себе информацию о конкретном физическом [IoT](#iot) устройстве, а также о версии микропрограммы, доступной в [Repo](#repo).

## UnitNode
`UnitNode` - представление о [MQTT](#mqtt) топике для [Pepeunit](/conception/overview), данная сущность описывает точку взаимодействия с [Unit](#unit). `UnitNode` может быть двух типов: `Input` и `Output`. Между `UnitNode` разных [Unit](#unit) могут быть связи: от одного `Output` к многим `Input`.

## Datasource
`Datasource` - источник данных [Grafana](/deployment/dependencies/grafana), из которого [Grafana](/deployment/dependencies/grafana) получает данные для дальнейшей визуализации. [Backend](/deployment/dependencies/backend) реализует [REST](/definitions#rest) запрос для [InfinityAPI](https://grafana.com/grafana/plugins/yesoreyeram-infinity-datasource/) из коробки для каждой отдельной организации. Такой запрос с использованием `headers` и `params` позволяет получать данные, накопленные с помощью механизмов [DataPipe](/deployment/dependencies/datapipe).

## Visualization
`Visualization`, панели - способ отображения данных [Grafana](/deployment/dependencies/grafana). Каждая отдельная визуализация может содержать несколько [Datasource](#datasource) одного или нескольких типов. В каждую визуализацию можно связать несколько [UnitNode](#unitnode) с настроенным [DataPipe](/deployment/dependencies/datapipe). При сборке визуализаций следите, чтобы формат данных был одинаковым.

## Dashboard
`Dashboard` - набор [Visualization](#visualization) в [Grafana](/deployment/dependencies/grafana), собранных на одной панели для удобного мониторинга и анализа данных.

## schema_example.json
`schema_example.json` - файл схемы, описывающий [MQTT](#mqtt) топики, нужные [Unit](#unit). Данный файл создаётся [Разработчиком Unit](/development-pepeunit/mechanics/roles#unit-developer) и помещается в каждую версию [Repo](#repo). Благодаря данному файлу [Pepeunit](/conception/overview) создаёт [UnitNode](#unitnode) сущности, отвечающие за взаимодействие с [Unit](#unit) и регламентирующие политики доступа до топиков [Unit](#unit). [Подробнее](/developer/files/struct-schema-example-json#schema-example-json)

## schema.json
`schema.json` - готовый файл схемы для [Unit](#unit), генерируемый [Pepeunit](/conception/overview). Содержит в себе ссылки на [UnitNode](#unitnode) и базовые топики для взаимодействия с [Pepeunit](/conception/overview). [Подробнее](/developer/files/struct-schema-json#schema-json)

## env_example.json
`env_example.json`- файл, описывающий переменные окружения, нужные для корректной работы [Unit](#unit). Он создаётся [Разработчиком Unit](/development-pepeunit/mechanics/roles#unit-developer) и помещается в каждую версию [Repo](#repo). На основе данного файла и ввода [Пользователя](/development-pepeunit/mechanics/roles.html#user), [Pepeunit](/conception/overview) может сгенерировать [env.json](#envjson) файл для [Unit](#unit). [Подробнее](/developer/files/struct-env-example-json#env-example-json)

## env.json
`env.json`- секретный файл, содержащий переменные окружения, нужные для корректной работы [Unit](#unit).
Именно этот файл отличает ваш [Unit](#unit) от других [Unit](#unit), созданных из одного и того же [Repo](#repo).

Создаётся владельцем [Unit](#unit) совместно с [Pepeunit](/conception/overview) и хранится в 
[шифрованном](/development-pepeunit/mechanics/cipher) виде внутри сущности [Unit](#unit). [Подробнее](/developer/files/struct-env-json#env-json)

## pepeunit.toml
`pepeunit.toml` - стандартизированный информационный блок [Unit](#unit), включающий в себя исчерпывающую информацию о [Unit](#unit). Помещается в корень [Git](#git) репозитория и выполняет функцию машиночитаемого описания [Unit](#unit) для [Pepeunit](/conception/overview). Ближайший аналог в мире разработки - [pyproject.toml](https://packaging.python.org/en/latest/guides/writing-pyproject-toml/). [Подробнее](/developer/files/struct-pepeunit-toml#pepeunit-toml)

## readme.md
`readme.md` или `README.md` - файл документации внутри репозитория [Git](#git), по усмотрению создателя репозитория содержит базовую информацию о репозитории, особенностях работы, настройке или любую другую информацию, которую автор счёл нужной. В [Pepeunit](/conception/overview) для заполнения `readme.md` используется генератор на основе [pepeunit.toml](#pepeunit-toml). [Подробнее](/developer/files/struct-readme#readme-md)

## .gitignore
[.gitignore](https://git-scm.com/docs/gitignore) - файл, содержащий перечисление файлов и директорий, которые [Git](#git) должен игнорировать. Поддерживает паттерны для облегчения чистки файлов. [Подробнее](/developer/files/struct-gitignore)

## .pepeignore
`.pepeignore` - аналогичный по синтаксису [.gitignore](#gitignore) файл [Git](#git) репозиториев у [Unit](#unit), но позволяющий удалить все указанные в нём файлы и директории из репозитория в момент генерации [архива с программой](/developer/files/struct-archive-update) для [Интерпретируемых](#interpretable) [Unit](#unit). [Подробнее](/developer/files/struct-pepeignore)

## LICENSE
`LICENSE` - файл лицензии, устанавливается в корень репозитория [Git](#git), регламентирует юридический аспект использования репозитория. Репозитории [Pepeunit](/conception/overview) публикуются под лицензией `AGPL v3`; авторы собственных репозиториев выбирают лицензию самостоятельно (см. [spdx.org](https://spdx.org/licenses/)).

## Micropython
[Micropython](https://docs.micropython.org) - простая и эффективная реализация языка программирования `Python 3`, включающая небольшое подмножество стандартной библиотеки `Python` и оптимизированная для работы на микроконтроллерах и в ограниченных средах.

## Golang
[Go](https://go.dev/), `Golang` - компилируемый язык программирования со статической типизацией, хорошо подходящий для высокой нагрузки.

## Fediverse
[Fediverse](https://en.wikipedia.org/wiki/Fediverse) - способ организации взаимодействия `сервер-сервер`, обеспечивающий децентрализованную схему распространения и обработки информации.

## IoT
`Internet of Things` - глобальная экосистема взаимосвязанных устройств, где обычные предметы, такие как холодильники, лампочки или автомобили, обретают общие возможности для взаимодействия, благодаря встроенным сенсорам, чипам и интернет-подключению, самостоятельно обмениваясь данными для упрощения жизни человека.

## Framework
`Framework` - готовая программная структура или каркас для разработки программ, который задаёт архитектуру приложения, управляет потоком выполнения и жизненным циклом, предоставляет набор компонентов и инструментов, а также позволяет внедрять свою логику через определённые расширяемые точки.

В отличие от библиотеки, фреймворк диктует правила организации кода и вызывает пользовательский код по своему усмотрению.

## Git
[Git](https://git-scm.com/) - бесплатная распределенная система контроля версий с открытым исходным кодом, предназначенная для быстрой и эффективной работы с проектами, от небольших до очень крупных.

## Interpretable
`Interpretable` - семейство языков программирования, в которых код исполняется интерпретатором (часто через байткод/JIT), без обязательной предварительной компиляции в отдельный исполняемый файл.

## Compilable
`Compilable` - семейство языков программирования, где код перед исполнением компилируется в машинный код или байткод, после чего исполняется напрямую или через виртуальную машину/JIT.

## Git Commit
`Commit или Коммит` - зафиксированное во времени состояние кода или иной байтовой структуры в системе контроля версий [Git](#git). Каждый [коммит](#git-commit) имеет свой уникальный идентификатор и обычно имеет `description` - текстовое описание изменений, которые в него входят.

## Git Tag
`Tag или Тег` - специальное обозначение [коммита](#git-commit). Обычно, тег присваивается стабильным-релизным коммитам какой-либо программы и характеризуют её версию.

## Git Branch
`Branch или Ветка` - набор [коммитов](#git-commit), расположенных в хронологическом порядке в системе контроля версии [Git](#git).

## GitLab
`GitLab` - веб-инструмент жизненного цикла [Git](#git) репозиториев от компании `GitLab Inc`. В данной документации под `GitLab` подразумевается не только [gitlab.com](https://about.gitlab.com/), но и любой другой инстанс `GitLab CE` или `GitLab EE`

## GitHub
[GitHub](https://github.com/) - хостинг [Git](#git) репозиториев от компании `GitHub, Inc.`.

## SQL
`SQL (Structured Query Language)` — декларативный язык программирования для создания, изменения и управления базами данных.

## API
`Application Programming Interface` - набор правил взаимодействия, предоставляемый программами и описывающий взаимодействие с ними. Обычно, описывается набором контрактов, или договоров. Например, [Backend](/deployment/dependencies/backend) [Pepeunit](/conception/overview) предоставляет: [REST](#rest), [GQL](#gql), [MQTT](#mqtt).

## REST
`REST API` - архитектурный стиль, описывающий взаимодействие программы с клиентами через `HTTP` запросы. Pepeunit [Backend](/deployment/dependencies/backend) использует пакет [Pydantic](https://docs.pydantic.dev/latest/) и спецификацию [OpenAPI](https://swagger.io/docs/) для предоставления `REST API`.

## GQL
`GraphQL API` - язык запросов и серверная среда с открытым исходным кодом, использующая `HTTP(S)` для запросов. [Pepeunit](/conception/overview) [Backend](/deployment/dependencies/backend) использует пакет [strawberry-graphql](https://strawberry.rocks/docs) для предоставления `GraphQL API`.

## MQTT
`MQTT` - лёгкий сетевой протокол, работающий поверх `TCP/IP`, ориентированный на обмен сообщениями по модели издатель-подписчик. [Pepeunit](/conception/overview) [Backend](/deployment/dependencies/backend) использует пакет [fastapi-mqtt](https://sabuhish.github.io/fastapi-mqtt/) как клиент для взаимодействия c [EMQX](deployment/dependencies/emqx).

## Telegram
[Telegram](https://telegram.org/) - популярный мессенджер, имеющий функционал [Telegram Bot](#telegram-bot).

## Telegram Bot
[Telegram Bot API](https://core.telegram.org/bots/api) - открытый [API](#api) для взаимодействия с внешними по отношению к [Telegram](#telegram) сервисами, например: [Pepeunit](/conception/overview). Для интеграции с `Telegram Bot API` [Pepeunit](/conception/overview) использует пакет [AioGram](https://github.com/aiogram/aiogram) как клиент. `Telegram Bot API` позволяет [Backend](/deployment/dependencies/backend) верифицировать [Пользователей](/development-pepeunit/mechanics/roles.html#user). Управление ботами происходит через [Bot Father](https://t.me/BotFather).

## YML
`YML` или `YAML` - человекочитаемый формат данных, используемый для сериализации и конфигурации. Данный формат широко применяется в автоматизации и конвейерах для описания этапов и их параметров. [Pepeunit](/conception/overview) использует его для конвейеров данных.
