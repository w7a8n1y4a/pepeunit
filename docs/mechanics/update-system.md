# Система обновлений

- [Что означают флаги обновлений у Repo?](/user/settings-repo#флаги-массовых-обновлении)
- [Как получить файлы для создания Unit?](/user/create-unit#получение-фаилов-развертывания)
- [Как обновлять Unit?](/user/update-unit)
- [Как Unit узнаёт о своей текущей версии используя env.json?](/developer/struct-env-json#зарезервированные-переменные-pepeunit)
- [Как генерируются архивы с обновлениями Unit?](/developer/struct-archive-update)
- [Какие есть MQTT команды обновлений Unit?](/developer/default-mqtt-command)
- [Как Pepeunit узнаёт о текущей версии Unit?](/developer/state-mqtt-send#формат-сообщении-в-топик-state-pepeunit)
- [Как Unit получают ссылку на скомпилированные версии?](/developer/release-assets.html)

## Процесс обновления всех Unit связанных с Repo

### Ручной

Обновление локального [Repo](/definitions#repo) 
1. Создатель [Repo](/definitions#repo) нажимает кнопку `Update local Repo` в меню [Repo](/definitions#repo) 
1. [Pepeunit](/conception/overview) принудительно заменяет локальный репозиторий новым

Обновление связанных [Unit](/definitions#unit)
1. Создатель [Repo](/definitions#repo) нажимает кнопку `Update related Unit` в меню [Repo](/definitions#repo) 
1. [Pepeunit](/conception/overview) выполняет вызывов [MQTT](/definitions#mqtt) команды [UPDATE - update/pepeunit](/developer/default-mqtt-command#update-update-pepeunit) - для каждого [Unit](/definitions#unit) у которого указано автоматическое обновление

### Автоматический или по запросу Администратора

1. Каждый час или по запросу [Администратора](/mechanics/roles#admin) [Pepeunit](/conception/overview) запускает задачу обновления [Repo](/definitions#repo) 
1. [Pepeunit](/conception/overview) получает выборку [Repo](/definitions#repo) у которых выставлено автоматическое обновление
1. [Pepeunit](/conception/overview) синхронизирует каждый локальный репозиторий из выборки
1. [Pepeunit](/conception/overview) выполняет вызыов [MQTT](/definitions#mqtt) команды [UPDATE - update/pepeunit](/developer/default-mqtt-command#update-update-pepeunit) - для каждого [Unit](/definitions#unit) у которого указано автоматическое обновление и родительский [Repo](/definitions#repo) которого присутствует в выборке

## Алгоритм вычисления текущей версии Unit
![img](/schemas/update_schema.svg)
