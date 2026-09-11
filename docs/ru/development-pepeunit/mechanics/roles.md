# Роли Пользователей и возможности Unit

## Роли

::: tip Какую функцию несут роли `Пользователей` в системе?
Роль `Пользователя` влияет на его возможности при использовании инстанса [Pepeunit](/conception/overview), а также на взаимодействие с [RepositoryRegisty](/definitions#repositoryregistry), [Repo](/definitions#repo), [Unit](/definitions#unit), [UnitNode](/definitions#unitnode), [Instance](/definitions#instance) и [Operation Task](/definitions#operation-task)
:::

### Unit Developer

`Разработчик Unit` - создатель [Git](/definitions#git) репозиториев [GitLab](/definitions#gitlab) или [GitHub](/definitions#github). Используя для своих целей [RepositoryRegisty](/definitions#repositoryregistry), опосредованно взаимодействует с [Pepeunit](/conception/overview) при помощи своего кода, который эксплуатируется `Пользователями` в качестве [RepositoryRegisty](/definitions#repositoryregistry), [Repo](/definitions#repo) и [Unit](/definitions#unit)

:::tip Возможности `Разработчика Unit`
- Имеет возможность вносить изменения в [Git](/definitions#git) репозитории [GitLab](/definitions#gitlab) или [GitHub](/definitions#github)
:::

### User

`Пользователь` - человек, зарегистрированный в инстансе [Pepeunit](/conception/overview).

::: tip Возможности обычного `Пользователя`
- Имеет доступ к созданию [RepositoryRegisty](/definitions#repositoryregistry), [Repo](/definitions#repo), [Unit](/definitions#unit) и [UnitNode](/definitions#unitnode)
- Имеет возможность видеть все записи [RepositoryRegisty](/definitions#repositoryregistry), включая приватные
- Не имеет возможности создать [Repo](/definitions#repo) на основе приватного [RepositoryRegisty](/definitions#repositoryregistry), если не укажет [Креды доступа](/user/git-repository/create-repository-registry#доступ-до-закрытого-репозитория)
- Имеет доступ к сущностям, чей [уровень видимости](/development-pepeunit/mechanics/visibility) `Public`, `Internal` или `Private`, с предоставленным [доступом](/development-pepeunit/mechanics/permission)
- Может просматривать список известных [Instance](/definitions#instance) и свою историю [Operation Task](/definitions#operation-task)
:::

### Admin

`Администратор` - владелец, выполняющий функции модератора. Имеет полномочия полного управления инстансом [Pepeunit](/conception/overview).

:::tip Возможности `Администратора`
- Блокирование `Пользователей` при нарушении условий использования инстанса
- Видимость всех сущностей [RepositoryRegisty](/definitions#repositoryregistry), [Repo](/definitions#repo), [Unit](/definitions#unit) и [UnitNode](/definitions#unitnode), возможности взаимодействия сводятся к аналогичным при предоставлении [видимости](/development-pepeunit/mechanics/visibility)
- Не может получить информацию о [зашифрованных](/development-pepeunit/mechanics/cipher) данных напрямую через [Pepeunit](/conception/overview), но имеет техническую возможность дешифровать любую [шифрованную](/development-pepeunit/mechanics/cipher) информацию инстанса
- [Добавление](/user/instance/add-instance) внешних [Instance](/definitions#instance), перевод их в `Trust` или `Blocking`, принудительный опрос одного инстанса или всех сразу
- [Глобальные команды](/user/operation-task/operation-tasks#типы-задач) на узле `Domain` и разбор их лога в [Operation Tasks](/user/operation-task/operation-tasks): интеграционные тесты, сканирование известных инстансов, обновление всех [RepositoryRegistry](/definitions#repositoryregistry) и массовое обновление прошивок [Unit](/definitions#unit)
:::

### Bot

Внешний агент - обычный `Пользователь` интернета или любая программа, не прошедшая стадию авторизации.

::: tip Возможности внешнего агента
- Может видеть все публичные записи из [RepositoryRegisty](/definitions#repositoryregistry)
- Может взаимодействовать только с сущностями, у которых [уровень видимости](/development-pepeunit/mechanics/visibility) соответствует `Public`
- Может читать публичное состояние инстанса `GET /pepeunit/api/v1/instances/current` и списки известных [Instance](/definitions#instance)
:::
