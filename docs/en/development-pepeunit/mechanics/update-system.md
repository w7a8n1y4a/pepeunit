# Update system

- [What do Repo update flags mean?](/en/user/git-repository/settings-repo#флаги-массовых-обновлении)
- [How to get files for creating a Unit?](/en/user/unit/create-physic-unit#получение-фаилов-развертывания)
- [How to update a Unit?](/en/user/unit/update-unit)
- [How does a Unit learn its current version using env.json?](/en/developer/files/struct-env-example-json#стандартные-переменные-pepeunit)
- [How are Unit update archives generated?](/en/developer/files/struct-archive-update)
- [What MQTT commands exist for updating a Unit?](/en/developer/mqtt/default-mqtt-command)
- [How does Pepeunit know the current version of a Unit?](/en/developer/mqtt/state-mqtt-send#формат-сообщении-в-топик-state-pepeunit)
- [How do Units get links to compiled versions?](/en/developer/release-assets)

## Process of updating all Units linked to a Repo

### Manual

1. Update the local [RepositoryRegisty](/en/definitions#repositoryregistry) via the `Update Local Repository` button.
1. [Pepeunit](/en/conception/overview) forcibly replaces the local repository with the new one. The maximum update frequency is limited by the `PU_MIN_INTERVAL_SYNC_REPOSITORY` variable.

Updating related [Unit](/en/definitions#unit)
1. The [Repo](/en/definitions#repo) creator clicks the `Update related Unit` button in the [Repo](/en/definitions#repo) menu.
1. [Pepeunit](/en/conception/overview) calls the [MQTT](/en/definitions#mqtt) command [UPDATE - update/pepeunit](/en/developer/mqtt/default-mqtt-command#update-update-pepeunit) for each [Unit](/en/definitions#unit) that has automatic updates enabled.

### Automatic or by Administrator request

1. Every hour, or when the [Administrator](/en/development-pepeunit/mechanics/roles#admin) presses the `Update all Repo and Unit` button, an update task is started in the `Domain` entity of the [Frontend](/en/deployment/dependencies/frontend) to update all [Unit](/en/definitions#repo) instances in accordance with the current state of physical [RepositoryRegisty](/en/definitions#repositoryregistry).
1. [Pepeunit](/en/conception/overview) selects [Repo](/en/definitions#repo) objects that have automatic updates enabled.
1. [Pepeunit](/en/conception/overview) calls the [MQTT](/en/definitions#mqtt) command [UPDATE - update/pepeunit](/en/developer/mqtt/default-mqtt-command#update-update-pepeunit) for each [Unit](/en/definitions#unit) that has automatic updates enabled.

::::warning
To improve performance, updates of [Unit](/en/definitions#repo) and [RepositoryRegisty](/en/definitions#repositoryregistry) are desynchronized by half an hour.
::::

## Algorithm for calculating the current Unit version

![img](/schemas/update_schema.svg)


