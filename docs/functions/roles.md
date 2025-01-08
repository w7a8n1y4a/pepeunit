# Роли пользователей и возможности Unit

## Роли

::: tip Какую функцию несут роли пользователей в системе?
Роль пользователя влияет на его возможности при использовании [Узла](/definitions#instance) [Pepeunit](/definitions#pepeunit), а также на взаимодействие с [Repo](/definitions#repo), [Unit](/definitions#unit), [UnitNode](/definitions#unitnode)
:::

### Admin

Aдминистратор - владелец, выполняющий функции модератора, имеет полномочия полного управления [Узлом](/definitions#instance) [Pepeunit](/definitions#pepeunit).

:::tip Возможности Администратора
- блокирование пользователей, при нарушении условий использования [Узла](/definitions#instance)
- блокирование работы отдельных [Unit](/definitions#unit), при нарушении условий использования [Узла](/definitions#instance)
- блокирование взаимодействия [Узел](/definitions#instance)-[Узел](/definitions#instance), если это нарушает работу текущего [Узла](/definitions#instance) [Pepeunit](/definitions#pepeunit)
- имеет доступ к настройке лимитов для создания [Unit](/definitions#unit)
- имеет доступ ко всем сущностям, но не может получить информацию о зашифрованных данных напрямую через [Pepeunit](/definitions#pepeunit)
:::

:::danger Очень важно!!!!
Стоит понимать что имея досутп до `.env` файла [Pepeunit](/definitions#pepeunit), Администратор может расшифровать ваши [env.json](/definitions#env-json) файлы. Поэтому используйте только [Pepeunit](/definitions#pepeunit) [Узлы](/definitions#instance), которым вы можете доверить информацию из своих [env.json](/definitions#env-json) файлов.
:::

### User

Пользователь - человек, зарегистрированный на [Узле](/definitions#instance) [Pepeunit](/definitions#pepeunit).

::: tip Возможности обычного пользователя
- имеет доступ к созданию [Repo](/definitions#repo), [Unit](/definitions#unit) и [UnitNode](/definitions#unitnode)
- имеет доступ к сущностям чей уровень видимости `Public`, `Internal` или `Private` если предоставлен доступ
:::

### Bot

Внешний агент - обычный пользователь интернета или любая программа.

::: tip Возможности внешнего агента
- Может взаимодействовать только с сущностями у которых уровень видимости соответствует Public
:::