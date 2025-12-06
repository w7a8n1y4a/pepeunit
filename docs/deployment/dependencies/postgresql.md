# Postgresql

[Postgresql](https://www.postgresql.org/docs/) - открытая кластерная реляционная база данных с языком запросов [SQL](/definitions#sql). [Подробнее о переменных окружения](/deployment/env-variables/postgresql)

:::info
[Backend](/deployment/dependencies/backend) хранит в ней следующую информацию:
1. Все сущности: [RepositoryRegisty](/definitions#repositoryregistry), [Repo](/definitions#repo), [Unit](/definitions#unit), [UnitNode](/definitions#unitnode), [DataPipe](/deployment/dependencies/datapipe), [Datasource](/definitions#datasource), [Visualization](/definitions#visualization), [Dashboard](/definitions#dashboard)
2. Хранения [шифрованной](/development-pepeunit/mechanics/cipher) информации
3. Хранения информации о [доступах](/development-pepeunit/mechanics/permission) и [видимости](/development-pepeunit/mechanics/visibility)
:::
