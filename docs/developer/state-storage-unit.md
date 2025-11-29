# Хранилище состояний Unit

Позволяет [Unit](/definitions#unit) хранить текстовые данные напрямую в [Pepeunit](/conception/overview). Данное хранилище отлично подойдёт для хранения следующих категорий данных:
1. Последнее состояние [Unit](/definitions#unit)
1. Кэширование информации ввода [Пользователя](/development-pepeunit/mechanics/roles.html#user)
1. Большие по меркам микроконтроллеров данные

:::tip
Хранилище состояний [Unit](/definitions#unit) - долговременная память, которую [Unit](/definitions#unit) может использовать в любой момент времени.
:::

:::danger
Размер данного хранилища ограничен размером [шифруемых объектов](/development-pepeunit/mechanics/cipher#шифрование) на [инстансе](/definitions#instance) [Pepeunit](/conception/overview).
:::

## Отправка данных в хранилище

Для установки значения нужно выполнить алгоритм:
1. Вычислить `uuid` [Unit](/definitions#unit) на основе `jwt` токена `PU_AUTH_TOKEN` из [env.json](/definitions#env-json)
1. Преобразовать ваше значение или структуру данных в строку
1. Выполнить запрос. Переменные `PU_HTTP_TYPE` и `PU_DOMAIN` доступны внутри [env.json](/definitions#env-json):
    ```bash
    curl -X 'POST' \
    'PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/set_state_storage/{Unit.uuid}' \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d '{
    "state": "best_data_for_save_in_storage"
    }'
    ```

:::info
`Curl` запрос можно легко преобразовать в `http` запрос на любом языке программирования, достаточно передать его копию в `LLM`.
:::

## Получение данных из хранилища

Для получения значения нужно выполнить алгоритм:
1. Вычислить `uuid` [Unit](/definitions#unit) на основе `jwt` токена `PU_AUTH_TOKEN` из [env.json](/definitions#env-json)
1. Выполнить запрос. Переменные `PU_HTTP_TYPE` и `PU_DOMAIN` доступны внутри [env.json](/definitions#env-json):
    - `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/get_state_storage/{Unit.uuid}`
1. Преобразовать строку полученную в результате ответа [Pepeunit](/conception/overview) в вашу структуру данных или значение