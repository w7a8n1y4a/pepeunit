# Система обновлений

- Что означают флаги обновлений у Repo?
- Как получить файлы для создания Unit?
- Как обновлять Unit?
- [Как Unit узнаёт о своей текущей версии, используя env.json?](/developer/files/struct-env-example-json#стандартные-переменные-pepeunit)
- [Как генерируются архивы с обновлениями Unit?](/developer/files/struct-archive-update)
- [Какие есть MQTT команды обновлений Unit?](/developer/mqtt/default-mqtt-command)
- [Как Pepeunit узнаёт о текущей версии Unit?](/developer/mqtt/state-mqtt-send#формат-сообщении-в-топик-state-pepeunit)
- [Как Unit получают ссылку на скомпилированные версии?](/developer/release-assets)

## Процесс обновления всех Unit связанных с Repo

### Ручной

1. Обновление локального RepositoryRegisty через кнопку `Update Local Repository`
1. Pepeunit принудительно заменяет локальный репозиторий новым. Максимальная частота обновлений регламентируется переменной `PU_MIN_INTERVAL_SYNC_REPOSITORY`

Обновление связанных Unit
1. Создатель Repo нажимает кнопку `Update related Unit` в меню Repo
1. Pepeunit выполняет вызов MQTT команды [UPDATE - update/pepeunit](/developer/mqtt/default-mqtt-command#update-update-pepeunit) для каждого Unit, у которого указано автоматическое обновление

### Автоматический или по запросу Администратора

1. Каждый час или при нажатии [Администратором](/development-pepeunit/mechanics/roles#admin) кнопки `Update all Repo and Unit`, в `Domain` сущности [Frontend](/deployment/dependencies/frontend) запускается задача обновления всех Unit в соответствии с текущим состоянием физических RepositoryRegisty
1. Pepeunit получает выборку Repo, у которых выставлено автоматическое обновление
1. Pepeunit выполняет вызов MQTT команды [UPDATE - update/pepeunit](/developer/mqtt/default-mqtt-command#update-update-pepeunit) - для каждого Unit, у которого указано автоматическое обновление

:::warning
Для улучшения производительности, обновление Unit и RepositoryRegisty имеет рассинхронизацию в пол часа.
:::

## Алгоритм вычисления текущей версии Unit
![img](/schemas/update_schema.svg)
