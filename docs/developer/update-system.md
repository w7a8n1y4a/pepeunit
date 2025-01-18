# Система обновлений

:::info
Здесь рассматриваются разные аспекты работы системы обновлений
:::

## Алгоритм вычисления текущей версии Unit
![img](/schemas/update_schema.svg)


## Процесс обновления Repo и Unit

### Ручной

Обновление локального [Repo](/definitions#repo) 
1. Создатель [Repo](/definitions#repo) нажимает кнопку `Update local Repo` в меню [Repo](/definitions#repo) 
1. [Pepeunit](/conception/overview) принудительно заменяет локальный репозиторий новым

Обновление связанных [Unit](/definitions#unit)
1. Создатель [Repo](/definitions#repo) нажимает кнопку `Update related Unit` в меню [Repo](/definitions#repo) 
1. [Pepeunit](/conception/overview) выполняет вызывов [MQTT](/definitions#mqtt) команды UPDATE - update/pepeunit - для каждого [Unit](/definitions#unit) у которого указано автоматическое обновление

### Автоматический или по запросу Администратора

1. Каждый час или по запросу [Администратора](/mechanics/roles#admin) [Pepeunit](/conception/overview) запускает задачу обновления [Repo](/definitions#repo) 
1. [Pepeunit](/conception/overview) получает выборку [Repo](/definitions#repo) у которых выставлено автоматическое обновление
1. [Pepeunit](/conception/overview) синхронизирует каждый локальный репозиторий из выборки
1. [Pepeunit](/conception/overview) выполняет вызывов [MQTT](/definitions#mqtt) команды UPDATE - update/pepeunit - для каждого [Unit](/definitions#unit) у которого указано автоматическое обновление и родительский [Repo](/definitions#repo) которого присутствует в выборке