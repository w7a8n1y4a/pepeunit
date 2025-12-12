# PostgreSQL

[PostgreSQL](https://www.postgresql.org/docs/) is an open-source clustered relational database that uses the [SQL](/en/definitions#sql) query language. [More about environment variables](/en/deployment/env-variables/postgresql)

::::info
[Backend](/en/deployment/dependencies/backend) stores the following information in PostgreSQL:
1. All entities: [RepositoryRegisty](/en/definitions#repositoryregistry), [Repo](/en/definitions#repo), [Unit](/en/definitions#unit), [UnitNode](/en/definitions#unitnode), [DataPipe](/en/deployment/dependencies/datapipe), [Datasource](/en/definitions#datasource), [Visualization](/en/definitions#visualization), [Dashboard](/en/definitions#dashboard)
1. Storage of [encrypted](/en/development-pepeunit/mechanics/cipher) information
1. Storage of [permissions](/en/development-pepeunit/mechanics/permission) and [visibility](/en/development-pepeunit/mechanics/visibility) information
::::

