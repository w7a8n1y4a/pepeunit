# PostgreSQL

[PostgreSQL](https://www.postgresql.org/docs/) is a relational database. Container `postgres`, data in the `postgres_data` volume. [Environment variables](/deployment/env-variables/postgresql)

:::info
[Backend](/deployment/dependencies/backend) stores in it:
1. All entities: User, Repo, Unit, UnitIO, Link, Dashboard, Peer, Notification and others
1. [Encrypted](/development-pepeunit/mechanics/cipher) data
1. [Access](/development-pepeunit/mechanics/permission) and [visibility](/development-pepeunit/mechanics/visibility)
1. [Instance settings](/deployment/instance-settings)
1. Configurations of [DataPipe](/deployment/dependencies/datapipe) pipelines
:::

The database is created by the `postgres` container, and the tables by [Backend](/deployment/dependencies/backend) on start.

:::warning
Starting with version `18`, the `postgres` image stores data in a different directory, so a volume from version `17` does not fit. How to migrate is described in [Backups and updates](/deployment/docker/backup-update#updating-from-versions-before-130).
:::
