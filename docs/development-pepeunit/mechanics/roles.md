# Роли Пользователей и возможности Unit

## Роли

::: tip Какую функцию несут роли `Пользователей` в системе?
Роль `Пользователя` влияет на его возможности при использовании инстанса [Pepeunit](/conception/overview), а также на взаимодействие с [RepositoryRegisty](/definitions#repositoryregistry), [Repo](/definitions#repo), [Unit](/definitions#unit), [UnitNode](/definitions#unitnode)
:::

### Bot

Внешний агент - обычный `Пользователь` интернета или любая программа, не прошедшая стадию авторизации.

::: tip Возможности внешнего агента
- Может видеть все публичные записи из [RepositoryRegisty](/definitions#repositoryregistry)
- Может взаимодействовать только с сущностями у которых [уровень видимости](/development-pepeunit/mechanics/visibility) соответствует `Public`
:::

### User

`Пользователь` - человек, зарегистрированный в инстансе [Pepeunit](/conception/overview).

::: tip Возможности обычного `Пользователя`
- Имеет доступ к созданию [RepositoryRegisty](/definitions#repositoryregistry), [Repo](/definitions#repo), [Unit](/definitions#unit) и [UnitNode](/definitions#unitnode)
- Имеет возможность видеть все записи [RepositoryRegisty](/definitions#repositoryregistry) включая приватные
- Не имеет возможности создать [Repo](/definitions#repo) на основе приватного [RepositoryRegisty](/definitions#repositoryregistry), если не укажет [Креды доступа](/user/create-repository-registry#доступ-до-закрытого-репозитория)
- Имеет доступ к сущностям чей [уровень видимости](/development-pepeunit/mechanics/visibility) `Public`, `Internal` или `Private` с предоставленым [доступом](/development-pepeunit/mechanics/permission)
:::

### Admin

`Администратор` - владелец, выполняющий функции модератора, имеет полномочия полного управления инстансом [Pepeunit](/conception/overview).

:::tip Возможности `Администратора`
- Блокирование Пользователей, при нарушении условий использования инстанса
- Видимость всех сущностей [RepositoryRegisty](/definitions#repositoryregistry), [Repo](/definitions#repo), [Unit](/definitions#unit) и [UnitNode](/definitions#unitnode), возможности взаимодействия сводятся к аналогичным при предоставлении [видимости](/development-pepeunit/mechanics/visibility)
- Не может получить информацию о [зашифрованных](/development-pepeunit/mechanics/cipher) данных напрямую через [Pepeunit](/conception/overview), но имеет техническую возможность дешифровать любую [шифрованную](/development-pepeunit/mechanics/cipher) информацию инстанса
:::