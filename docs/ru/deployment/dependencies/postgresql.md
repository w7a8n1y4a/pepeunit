# PostgreSQL

[PostgreSQL](https://www.postgresql.org/docs/) - открытая кластерная реляционная база данных с языком запросов SQL. [Подробнее о переменных окружения](/deployment/env-variables/postgresql)

:::info
[Backend](/deployment/dependencies/backend) хранит в ней следующую информацию:
1. Все сущности: RepositoryRegisty, Repo, Unit, UnitNode, [DataPipe](/deployment/dependencies/datapipe), Datasource, Visualization, Dashboard
1. Хранения [шифрованной](/development-pepeunit/mechanics/cipher) информации
1. Хранения информации о [доступах](/development-pepeunit/mechanics/permission) и [видимости](/development-pepeunit/mechanics/visibility)
:::
