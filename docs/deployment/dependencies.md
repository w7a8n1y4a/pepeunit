# Зависимости

## Postgresql

[Postgresql](https://www.postgresql.org/docs/) - открытая, кластерная реляционная база данных с языком запросов `SQL`. [Pepeunit](/conception/overview) использует её для:

1. Хранения информации о всех сущностях - [RepositoryRegisty](/definitions#repositoryregistry), [Repo](/definitions#repo), [Unit](/definitions#unit), [UnitNode](/definitions#unitnode), [DataPipe](/definitions#datapipe)
1. Хранения [шифрованной](/development-pepeunit/mechanics/cipher) информации
1. Хранения информации о [доступах](/development-pepeunit/mechanics/permission) и [видимости](/development-pepeunit/mechanics/visibility)

## EMQX MQTT Broker

[EMQX MQTT Broker](https://docs.emqx.com/en/emqx/latest/) - это серверное приложение, которое координирует сообщения между издателями и подпищиками [MQTT](/definitions#mqtt-broker) протокола. Брокер обеспечивает взаимодействие через `1883` и `8883` порты между [Unit](/definitions#unit) и [Backend](/definitions#backend). Его можно назвать рельсой данных, на которую завязано основное взаимодействие.

::: tip Ключевые моменты взаимодействия [MQTT Broker](/definitions#mqtt-broker), [Backend](/definitions#backend) и [Unit](/definitions#unit)
[Backend](/definitions#backend) выполняет [Административные](/development-pepeunit/mechanics/roles#admin) функции, а именно:
1. Авторизация всех [Unit](/definitions#unit) для доступа к определённым топикам
1. Агрегация данных из определённых топиков, согласно политике имён топиков
1. Управление [Unit](/definitions#unit), при помощи системы команд, позволяющей публиковать в топики задания на обновление [schema.json](/definitions#schema-json), [env.json](/definitions#env-json) или программы целиком.
1. Получение состояний [Unit](/definitions#unit) через специальный топик.
:::

Брокер `EMQX` на два порядка производительней чем [Backend](/definitions#backend), но благодаря системе кэширования авторизации `EMQX` и кэшированию через `Redis`, [Backend](/definitions#backend) может справиться с нагрузкой.

## Clickhouse

[Clickhouse](https://clickhouse.com/) - это колончатая аналитическая СУБД с открытым исходным кодом, позволяющая выполнять аналитические запросы на структурированных данных. Используется [Backend](/definitions#backend) для хранения логов [Unit](/definitions#unit), а также для [DataPipe](/definitions#datapipe).

## Redis

[Redis](https://redis.io/) - `NoSQL` кластерная база данных использующая парадигму `key-value`

1. Обеспечивает кэширование и хранение промежуточной информации о состоянии [UnitNode](/definitions#unitnode), во время обращения [Unit](/definitions#unit) к [MQTT Broker](/definitions#mqtt-broker) через топики.
1. Используется также для авторизации [Backend](/definitions#backend) в момент подписки на основной топик `unit.example.com/+/+/+/pepeunit` в [MQTT Broker](/definitions#mqtt-broker). Подписка на `unit.example.com/+/pepeunit` осуществляется стандартными средствами через [REST](/definitions#rest).
1. `Stream` используется для синхронизации конфигураций [Backend](/definitions#backend) и [DataPipe](/definitions#datapipe) сервисом.

## Grafana

[Grafana](https://grafana.com/) - платформа с открытым исходным кодом, для визуализации данных и их анализа. Включает в себя следующий набор абстракций: [Datasource](/definitions#datasourcee), [Visualization](/definitions#visualization), [Dashboard](/definitions#dashboard). Интегрирована для визуализации данных из [DataPipe](/definitions#datapipe) и [Мониторинга](/deployment/monitoring)

## Общая схема взаимодействия

```mermaid
flowchart LR
  Broker <--> Unit
  Broker <--> Pepeunit
  Pepeunit <--> Unit
  Pepeunit <--> Postgresql
  Pepeunit <--> Grafana
  Pepeunit <--> Clickhouse
  Broker <--> Redis
  Pepeunit <--> Redis
```