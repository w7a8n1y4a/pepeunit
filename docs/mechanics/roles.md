# Роли Пользователей и возможности Unit

## Роли

::: tip Какую функцию несут роли `Пользователей` в системе?
Роль `Пользователя` влияет на его возможности при использовании [инстанса](/definitions#instance) [Pepeunit](/conception/overview), а также на взаимодействие с [Repo](/definitions#repo), [Unit](/definitions#unit), [UnitNode](/definitions#unitnode)
:::

### Bot

Внешний агент - обычный `Пользователь` интернета или любая программа, не прошедшая стадию авторизации.

::: tip Возможности внешнего агента
- Может взаимодействовать только с сущностями у которых [уровень видимости](/mechanics/visibility) соответствует `Public`
:::

### User

`Пользователь` - человек, зарегистрированный в [инстансе](/definitions#instance) [Pepeunit](/conception/overview).

::: tip Возможности обычного `Пользователя`
- Имеет доступ к созданию [Repo](/definitions#repo), [Unit](/definitions#unit) и [UnitNode](/definitions#unitnode)
- Имеет доступ к сущностям чей [уровень видимости](/mechanics/visibility) `Public`, `Internal` или `Private` если предоставлен [доступ](/user/permission)
:::

### Admin

`Администратор` - владелец, выполняющий функции модератора, имеет полномочия полного управления [инстансом](/definitions#instance) [Pepeunit](/conception/overview).

:::tip Возможности `Администратора`
- Блокирование Пользователей, при нарушении условий использования [инстанса](/definitions#instance)
- Видимость всех сущностей [Repo](/definitions#repo), [Unit](/definitions#unit) и [UnitNode](/definitions#unitnode), возможности взаимодействия сводятся к аналогичным при предоставлении [видимости](/mechanics/visibility)
- Принудительный запуск процесса [автоматического обновления](/developer/update-system#автоматическии-или-по-запросу-администратора) всех [Repo](/definitions#repo)
- Не может получить информацию о [зашифрованных](/mechanics/cipher) данных напрямую через [Pepeunit](/conception/overview), но имеет техническую возможность дешифровать любую [шифрованную](/mechanics/cipher) информацию [инстанса](/definitions#instance)
:::