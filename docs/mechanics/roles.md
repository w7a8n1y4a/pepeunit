# Роли Пользователей и возможности Unit

## Роли

::: tip Какую функцию несут роли `Пользователей` в системе?
Роль `Пользователя` влияет на его возможности при использовании [инстанса](/definitions#instance) [Pepeunit](/conception/overview), а также на взаимодействие с [RepositoryRegisty](/definitions#repositoryregistry), [Repo](/definitions#repo), [Unit](/definitions#unit), [UnitNode](/definitions#unitnode)
:::

### Bot

Внешний агент - обычный `Пользователь` интернета или любая программа, не прошедшая стадию авторизации.

::: tip Возможности внешнего агента
- Может видеть все публичные записи из [RepositoryRegisty](/definitions#repositoryregistry)
- Может взаимодействовать только с сущностями у которых [уровень видимости](/mechanics/visibility) соответствует `Public`
:::

### User

`Пользователь` - человек, зарегистрированный в [инстансе](/definitions#instance) [Pepeunit](/conception/overview).

::: tip Возможности обычного `Пользователя`
- Имеет доступ к созданию [RepositoryRegisty](/definitions#repositoryregistry), [Repo](/definitions#repo), [Unit](/definitions#unit) и [UnitNode](/definitions#unitnode)
- Имеет возможность видеть все записи [RepositoryRegisty](/definitions#repositoryregistry) включая приватные
- Не имеет возможности создать [Repo](/definitions#repo) на основе приватного [RepositoryRegisty](/definitions#repositoryregistry), если не укажет [Креды доступа](/user/create-repository-registry#доступ-до-закрытого-репозитория)
- Имеет доступ к сущностям чей [уровень видимости](/mechanics/visibility) `Public`, `Internal` или `Private` с предоставленым [доступом](/mechanics/permission)
:::

### Admin

`Администратор` - владелец, выполняющий функции модератора, имеет полномочия полного управления [инстансом](/definitions#instance) [Pepeunit](/conception/overview).

:::tip Возможности `Администратора`
- Блокирование Пользователей, при нарушении условий использования [инстанса](/definitions#instance)
- Видимость всех сущностей [RepositoryRegisty](/definitions#repositoryregistry), [Repo](/definitions#repo), [Unit](/definitions#unit) и [UnitNode](/definitions#unitnode), возможности взаимодействия сводятся к аналогичным при предоставлении [видимости](/mechanics/visibility)
- Возможность просмотра нагрузки на [инстансе](/definitions#instance) через [Grafana](/deployment/dependencies#grafana), достаточно перейти на [Frontend](/definitions#frontend) в ноду отображающую текущий домен, и нажать кнопку `Grafana`.
- Не может получить информацию о [зашифрованных](/mechanics/cipher) данных напрямую через [Pepeunit](/conception/overview), но имеет техническую возможность дешифровать любую [шифрованную](/mechanics/cipher) информацию [инстанса](/definitions#instance)
:::