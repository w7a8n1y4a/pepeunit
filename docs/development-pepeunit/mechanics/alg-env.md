# Алгоритм генерации env.json у Unit

:::info
Алгоритм применяется в `3` сценариях:
1. Получение [env.json](/definitions#env-json) через `get_env`
1. Установка [env.json](/definitions#env-json) через `set_env`
1. Любом обновлении программы [Unit](/definitions#unit): ручном или автоматическом
:::

## Алгоритм
Алгоритм построен на приоритете следующих `4` представлений о [env.json](/definitions#env-json), чем меньше цифра, тем выше приоритет:

Приоритет | Представление | Описание
-- | -- | --
1 | `Ручные` | Ручной ввод [Пользователя](/development-pepeunit/mechanics/roles.html#user) в систему с [Frontend](/deployment/dependencies/frontend) или через `set_env` через [REST](/definitions#rest) и [GQL](/definitions#gql)
2 | `Записанные в бд` | [env.json](/definitions#env-json) в базе данных [Pepeunit](/conception/overview)
3 | `Cгенерированные` | [Стандартные переменные](/developer/files/struct-env-example-json#стандартные-переменные-pepeunit) сгенерированные [Backend](/deployment/dependencies/backend)
4 | `Целевые` | Переменные указанные [Разработчиком Unit](/development-pepeunit/mechanics/roles#unit-developer) в [env_example.json](/definitions#env-example-json)

В конце работы, отсекаются все ключи которых нет в `Целевых`

:::info
Если генерируется [env.json](/definitions#env-json) для отправки [Unit](/definitions#unit) или показа [Пользователю](/development-pepeunit/mechanics/roles.html#user), то будет дополнительно добавлена переменная: `PU_COMMIT_VERSION` - в бд она не хранится.
:::

## Примеры работы Алгоритма

### Первая генерация env

Шаги алгоритма:
1. `Целевые` - берутся целиком
1. `Cгенерированные` - заного генерируются [Backend](/deployment/dependencies/backend) в полном объёме и перезаписывают ключи, которые были получены в результате предыдущего шага
1. `Записанные в бд` - отсутствуют
1. `Ручные` - отсутствуют
1. Все ключи которых нет в `Целевых` удаляются

:::info
В результате получится [env.json](/definitions#env-json), в котором поверх переменных [Разработчика Unit](/development-pepeunit/mechanics/roles#unit-developer), записаны переменные сгенерированные [Pepeunit](/conception/overview). Такой [env.json](/definitions#env-json) уже пригоден для использования в [Unit](/definitions#unit)
:::

### Unit изменяет свою версию автоматически с иземенением состава ключей

Шаги алгоритма:
1. `Целевые` - берутся целиком
1. `Cгенерированные` - заного генерируются [Backend](/deployment/dependencies/backend) в полном объёме и перезаписывают ключи, которые были получены в результате предыдущего шага
1. `Записанные в бд` - берутся из бд и перезаписывают все значения с совпадающими ключами, которые были получены в результате предыдущего шага
1. `Ручные` - отсутствуют
1. Все ключи которых нет в `Целевых` удаляются

:::info
В результате получится [env.json](/definitions#env-json), у которого добавятся переменные из новой версии [env_example.json](/definitions#env-example-json) созданной [Разработчиком Unit](/development-pepeunit/mechanics/roles#unit-developer)
:::

### Пользователь вносит изменения в уже существующий env

Шаги алгоритма:
1. `Целевые` - берутся целиком
1. `Cгенерированные` - заного генерируются [Backend](/deployment/dependencies/backend) в полном объёме и перезаписывают ключи, которые были получены в результате предыдущего шага
1. `Записанные в бд` - берутся из бд и перезаписывают все значения с совпадающими ключами, которые были получены в результате предыдущего шага
1. `Ручные` - все полученные от [Пользователя](/development-pepeunit/mechanics/roles.html#user) ключи перезаписывют ключи, которые были получены в результате предыдущего шага
1. Все ключи которых нет в `Целевых` удаляются

:::info
В результате получится [env.json](/definitions#env-json), в котором поверх старых [Пользовательских](/development-pepeunit/mechanics/roles.html#user), записаны новые переменные, в которые [Пользователь](/development-pepeunit/mechanics/roles.html#user) внёс изменения
:::
