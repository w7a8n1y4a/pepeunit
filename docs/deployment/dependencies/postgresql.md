# Postgresql

[Postgresql](https://www.postgresql.org/docs/) - открытая, кластерная реляционная база данных с языком запросов `SQL`. [Pepeunit](/conception/overview) использует её для:

1. Хранения информации о всех сущностях - [RepositoryRegisty](/definitions#repositoryregistry), [Repo](/definitions#repo), [Unit](/definitions#unit), [UnitNode](/definitions#unitnode), [DataPipe](/definitions#datapipe)
1. Хранения [шифрованной](/development-pepeunit/mechanics/cipher) информации
1. Хранения информации о [доступах](/development-pepeunit/mechanics/permission) и [видимости](/development-pepeunit/mechanics/visibility)