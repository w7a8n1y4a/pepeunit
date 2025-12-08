# Система обновлений

- [Что означают флаги обновлений у Repo?](/user/git-repository/settings-repo#флаги-массовых-обновлении)
- [Как получить файлы для создания Unit?](/user/unit/create-physic-unit#получение-фаилов-развертывания)
- [Как обновлять Unit?](/user/unit/update-unit)
- [Как Unit узнаёт о своей текущей версии, используя env.json?](/developer/files/struct-env-example-json#стандартные-переменные-pepeunit)
- [Как генерируются архивы с обновлениями Unit?](/developer/files/struct-archive-update)
- [Какие есть MQTT команды обновлений Unit?](/developer/mqtt/default-mqtt-command)
- [Как Pepeunit узнаёт о текущей версии Unit?](/developer/mqtt/state-mqtt-send#формат-сообщении-в-топик-state-pepeunit)
- [Как Unit получают ссылку на скомпилированные версии?](/developer/release-assets)

## Процесс обновления всех Unit связанных с Repo

### Ручной

1. Обновление локального [RepositoryRegisty](/definitions#repositoryregistry) через кнопку `Update Local Repository`
1. [Pepeunit](/conception/overview) принудительно заменяет локальный репозиторий новым. Максимальная частота обновлений регламентируется переменной `PU_MIN_INTERVAL_SYNC_REPOSITORY`

Обновление связанных [Unit](/definitions#unit)
1. Создатель [Repo](/definitions#repo) нажимает кнопку `Update related Unit` в меню [Repo](/definitions#repo) 
1. [Pepeunit](/conception/overview) выполняет вызывов [MQTT](/definitions#mqtt) команды [UPDATE - update/pepeunit](/developer/mqtt/default-mqtt-command#update-update-pepeunit) для каждого [Unit](/definitions#unit), у которого указано автоматическое обновление

### Автоматический или по запросу Администратора

1. Каждый час или при нажатии [Администратором](/development-pepeunit/mechanics/roles#admin) кнопки `Update all Repo and Unit`, в `Domain` сущности [Frontend](/deployment/dependencies/frontend) запускается задача обновления всех [Unit](/definitions#repo) в соответствии с текущим состоянием физических [RepositoryRegisty](/definitions#repositoryregistry)
1. [Pepeunit](/conception/overview) получает выборку [Repo](/definitions#repo), у которых выставлено автоматическое обновление
1. [Pepeunit](/conception/overview) выполняет вызов [MQTT](/definitions#mqtt) команды [UPDATE - update/pepeunit](/developer/mqtt/default-mqtt-command#update-update-pepeunit) - для каждого [Unit](/definitions#unit), у которого указано автоматическое обновление

:::warning
Для улучшения производительности, обновение [Unit](/definitions#repo) и [RepositoryRegisty](/definitions#repositoryregistry) имеет рассинхронизацию в пол часа.
:::

## Алгоритм вычисления текущей версии Unit
![img](/schemas/update_schema.svg)
