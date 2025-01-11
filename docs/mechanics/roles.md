# Роли пользователей и возможности Unit

## Роли

::: tip Какую функцию несут роли пользователей в системе?
Роль пользователя влияет на его возможности при использовании [Узла](/definitions#instance) [Pepeunit](/conception/overview), а также на взаимодействие с [Repo](/definitions#repo), [Unit](/definitions#unit), [UnitNode](/definitions#unitnode)
:::

### Bot

Внешний агент - обычный пользователь интернета или любая программа, не прошедшая стадию авторизации.

::: tip Возможности внешнего агента
- Может взаимодействовать только с сущностями у которых [уровень видимости](/mechanics/visibility) соответствует `Public`
:::

### User

Пользователь - человек, зарегистрированный на [Узле](/definitions#instance) [Pepeunit](/conception/overview).

::: tip Возможности обычного пользователя
- Имеет доступ к созданию [Repo](/definitions#repo), [Unit](/definitions#unit) и [UnitNode](/definitions#unitnode)
- Имеет доступ к сущностям чей [уровень видимости](/mechanics/visibility) `Public`, `Internal` или `Private` если предоставлен доступ
:::

### Admin

Aдминистратор - владелец, выполняющий функции модератора, имеет полномочия полного управления [Узлом](/definitions#instance) [Pepeunit](/conception/overview).

:::tip Возможности Администратора
- Блокирование пользователей, при нарушении условий использования [Узла](/definitions#instance)
- Видимость всех сущностей [Repo](/definitions#repo), [Unit](/definitions#unit) и [UnitNode](/definitions#unitnode), возможности взаимодействия сводятся к аналогичным при предоставлении [видимости](/mechanics/visibility)
- Не может получить информацию о [зашифрованных](/mechanics/cipher) данных напрямую через [Pepeunit](/conception/overview), но имеет техническую возможность дешифровать любую [шифрованную](/mechanics/cipher) информацию инстанса
:::