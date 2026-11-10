# PostgreSQL

[PostgreSQL](https://www.postgresql.org/docs/) - реляционная база данных. Контейнер `postgres`, данные в томе `postgres_data`. [Переменные окружения](/deployment/env-variables/postgresql)

:::info
[Backend](/deployment/dependencies/backend) хранит в ней:
1. Все сущности: User, Repo, Unit, UnitIO, Link, Dashboard, Peer, Notification и другие
1. [Шифрованные](/development-pepeunit/mechanics/cipher) данные
1. [Доступы](/development-pepeunit/mechanics/permission) и [видимость](/development-pepeunit/mechanics/visibility)
1. [Настройки инстанса](/deployment/instance-settings)
1. Конфигурации конвейеров [DataPipe](/deployment/dependencies/datapipe)
:::

Базу создаёт контейнер `postgres`, а таблицы - [Backend](/deployment/dependencies/backend) при старте.

:::warning
Начиная с версии `18` образ `postgres` хранит данные в другом каталоге, поэтому том от версии `17` не подходит. Как перейти, описано в [Бэкапах и обновлении](/deployment/docker/backup-update#обновление-с-версий-до-130).
:::
