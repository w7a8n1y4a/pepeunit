# Уровни видимости - Public, Internal и Private

::: tip На что влияет уровень видимости?
От `уровня видимости` сущности зависит кто может получить о ней информацию и/или провзаимодействовать с ней
:::

Уровень видимости | Состояние
-- | --
`Public` | Предоставляет [доступ](/development-pepeunit/mechanics/permission) всем
`Internal` | Предоставляет [доступ](/development-pepeunit/mechanics/permission) до сущности только авторизованным [Пользователям](/development-pepeunit/mechanics/roles.html#user) инстанса или всем [Unit](/definitions#unit) находящимся в инстансе
`Private` | Предоставляет [доступ](/development-pepeunit/mechanics/permission) до сущности только создателю и агентам которых укажет создатель. Работает в пределах инстанса

:::danger
Сущность [RepositoryRegisty](/definitions#repositoryregistry) уникальная и имеет только два типа `Public` и `Private`. Предоставление доступа к `Private` сущности отличается, и завязано на ввод [Пользователями](/development-pepeunit/mechanics/roles.html#user) [Кредов доступа](/user/git-repository/create-repository-registry#доступ-до-закрытого-репозитория).

Создатель не может сам предоставить доступ, это связано с `бизнес-логикой` работы этой сущности
:::

## Возможности создателя сущностей

Создатель имеет `абсолютно полный доступ` по управлению своими cущностями.

### RepositoryRegistry
- Изменение своих [Кредов доступа](/user/git-repository/create-repository-registry#доступ-до-закрытого-репозитория)
- Просмотр размера репозитория
- Создание [Repo](/definitions#repo) на основе [RepositoryRegisty](/definitions#repositoryregistry)
- Обновление [Git](/definitions#git) репозитория внутри [Pepeunit](/conception/overview)
- Удаление [RepositoryRegisty](/definitions#repositoryregistry) если у него нет связанных [Repo](/definitions#repo)

### Repo

- Просмотр распределения [Unit](/definitions#unit) по версиям
- Создание [Unit](/definitions#unit) на основе [Repo](/definitions#repo)
- Обновление всех связанных [Unit](/definitions#unit)
- Настройки [Repo](/definitions#repo)
- Выдача [доступов](/development-pepeunit/mechanics/permission)
- Удаление [Repo](/definitions#repo) если у него нет связанных [Unit](/definitions#repo)

### Unit

- Просмотр информации о текущей версии [Unit](/definitions#unit)
- Просмотр информации о состоянии [Unit](/definitions#unit)
- Установка [env.json](/definitions#env-json)
- Скачивание `Firmware` и скомпилированных пакетов
- Команды обновления по [MQTT](/definitions#mqtt) - `Firmware`, `Schema` и `Env`
- Настройки [Unit](/definitions#unit)
- Выдача [доступов](/development-pepeunit/mechanics/permission)
- Удаление [Unit](/definitions#unit)

### UnitNode

- Просмотр состояния
- Установка значений с отправкой в `Input` через [MQTT](/definitions#mqtt)
- Создание связей для `Input`
- Настройки [UnitNode](/definitions#unitnode)
- Выдача [доступов](/development-pepeunit/mechanics/permission)
- Все аспекты управления [DataPipe](/deployment/dependencies/datapipe)

## Возможности агентов для видимых сущностей

Агенты имеют ограниченный [доступ](/development-pepeunit/mechanics/permission) до чужих сущностей, которые они видят с помощью `системы видимости`:

### RepositoryRegistry
- Изменение своих [Кредов доступа](/user/git-repository/create-repository-registry#доступ-до-закрытого-репозитория)
- Просмотр размера репозитория. Доступно для `Private` и `Public` репозиториев не зависимо от [Кредов доступа](/user/git-repository/create-repository-registry#доступ-до-закрытого-репозитория)
- Создание [Repo](/definitions#repo) на основе [RepositoryRegisty](/definitions#repositoryregistry). Для `Public` доступно всем, для `Private` доступно только если у [Кредов доступа](/user/git-repository/create-repository-registry#доступ-до-закрытого-репозитория) статус `Valid`
- Обновление [Git](/definitions#git) репозитория внутри [Pepeunit](/conception/overview). Для `Public` доступно всем, для `Private` доступно только если у [Кредов доступа](/user/git-repository/create-repository-registry#доступ-до-закрытого-репозитория) статус `Valid`

### Repo

- Просмотр распределения [Unit](/definitions#unit) по версиям
- Создание [Unit](/definitions#unit) на основе [Repo](/definitions#repo)

### Unit

- Просмотр информации о текущей версии [Unit](/definitions#unit)
- Просмотр информации о состоянии [Unit](/definitions#unit)

### UnitNode

- Просмотр состояния
- Установка значений с отправкой в `Input` через [MQTT](/definitions#mqtt)
- Создание связей для `Input`