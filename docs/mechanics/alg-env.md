# Алгоритм генерации env.json у Unit

:::info
Алгоритм применяется в `3` сценариях:
1. Получение [env.json](/definitions#env-json) через `get_env`
1. Установка [env.json](/definitions#env-json) через `set_env`
1. Любом обновлении программы [Unit](/definitions#unit): ручном или автоматическом
:::

## Алгоритм
Алгоритм построен на приоритете следующих `4` представлениях о [env.json](/definitions#env-json), чем меньше цифра, тем выше приоритет:

1. `Ручные` - то что пользователь вводит в систему руками в [Frontend](/definitions#frontend) или через `set_env` через [REST](/definitions#rest) и [GQL](/definitions#gql)
2. `Текущие` - [env.json](/definitions#env-json) в базе данных [Pepeunit](/conception/overview)
3. `Cгенерированные` - [зарезервированные переменные](/developer/struct-env-json.html#%D0%B7%D0%B0%D1%80%D0%B5%D0%B7%D0%B5%D1%80%D0%B2%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%BD%D1%8B%D0%B5-%D0%BF%D0%B5%D1%80%D0%B5%D0%BC%D0%B5%D0%BD%D0%BD%D1%8B%D0%B5-pepeunit)
4. `Целевые` - те которые указаны разработчиком [Unit](/definitions#unit) в [env_example.json](/definitions#env-example-json)

В конце работы, отсекаются все ключи которых нет в `Целевых`.
