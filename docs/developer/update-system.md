# Система обновлений

:::info
Здесь рассматриваются разные аспекты работы системы обновлений
:::

## Алгоритм вычисления текущей версии Unit
![img](/schemas/update_schema.svg)


## Процесс обновления Repo и Unit

### Ручной

Обновление локального Repo
1. Создатель Repo нажимает кнопку `Update local Repo` в меню Repo
1. [Pepeunit](/conception/overview) принудительно заменяет локальный репозиторий новым

Обновление связанных [Unit](/definitions#unit)
1. Создатель Repo нажимает кнопку `Update related Unit` в меню Repo
1. [Pepeunit](/conception/overview) выполняет вызывов [MQTT](/definitions#mqtt) команды UPDATE - update/pepeunit - для каждого [Unit](/definitions#unit) у которого указано автоматическое обновление

### Автоматический или по запросу Администратора

1. Каждый час или по запросу Администратора [Pepeunit](/conception/overview) запускает задачу обновления Repo
1. [Pepeunit](/conception/overview) получает выборку Repo у которых выставлено автоматическое обновление
1. [Pepeunit](/conception/overview) синхронизирует каждый локальный репозиторий из выборки
1. [Pepeunit](/conception/overview) выполняет вызывов [MQTT](/definitions#mqtt) команды UPDATE - update/pepeunit - для каждого [Unit](/definitions#unit) у которого указано автоматическое обновление и родительский Repo которого присутствует в выборке