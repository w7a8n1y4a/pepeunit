# Алгоритм генерации env.json у Unit

:::info
Алгоритм применяется в `3` сценариях:
1. Получение [env.json](/definitions#env-json) через `get_env`
1. Установка [env.json](/definitions#env-json) через `set_env`
1. Любом обновлении программы [Unit](/definitions#unit): ручном или автоматическом
:::

## Алгоритм
Алгоритм построен на приоритете следующих `4` представлениях о [env.json](/definitions#env-json), чем меньше цифра, тем выше приоритет:

1. `Ручные` - то что пользователь вводит в систему руками в [Frontend](/deployment/dependencies/frontend) или через `set_env` через [REST](/definitions#rest) и [GQL](/definitions#gql)
2. `Текущие` - [env.json](/definitions#env-json) в базе данных [Pepeunit](/conception/overview)
3. `Cгенерированные` - [стандартные переменные](/developer/files/struct-env-example-json#стандартные-переменные-pepeunit)
4. `Целевые` - те которые указаны разработчиком [Unit](/definitions#unit) в [env_example.json](/definitions#env-example-json)

В конце работы, отсекаются все ключи которых нет в `Целевых`.
