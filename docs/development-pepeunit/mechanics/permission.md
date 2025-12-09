# Работа с доступами

:::info Что означает предоставление доступа?
[Пользователь](/development-pepeunit/mechanics/roles.html#user) может найти вашу сущность через поиск и выполнить ряд манипуляции описаных в [возможностях агентов для видимых сущностей](/development-pepeunit/mechanics/visibility#возможности-агентов-для-видимых-сущностеи)
:::

:::warning
Cистема доступов работает только для сущностей у которых [уровень видимости](/development-pepeunit/mechanics/visibility) - `Private`.
:::

:::danger
Доступ до `Private` [RepositoryRegisty](/definitions#repositoryregistry), осуществляется на основе [Кредов доступа](/user/git-repository/create-repository-registry#доступ-до-закрытого-репозитория) и игнорирует систему ниже.
:::

## Создание доступа

1. Перейдите в меню сущности [Repo](/definitions#repo), [Unit](/definitions#unit) или [UnitNode](/definitions#unitnode).
1. Нажмите на кнопку `Permission`
1. Вы попадёте в меню где указаны агенты, которые могут вызаимодействовать с данной сущностью
1. Чтобы добавить нового агента нажмите `Pick Agent`
1. Выберите тип агента [User](/development-pepeunit/mechanics/roles#user) или [Unit](/definitions#unit)
1. Найдите нужного вам агента и нажмите `add` напротив него

## Удаление доступа

1. Перейдите в меню сущности [Repo](/definitions#repo), [Unit](/definitions#unit) или [UnitNode](/definitions#unitnode).
1. Нажмите на кнопку `Permission`
1. Вы попадёте в меню где указаны агенты, которые могут вызаимодействовать с данной сущностью
1. Чтобы удалить агента нажмите `delete`
