# Хранилище состояний Unit

Позволяет [Unit](/definitions#unit) хранить любые данные напрямую в [Pepeunit](/conception/overview). Данное хранилище отлично подойдёт для хранения следующих категорий данных:
1. [Пользовательские](/mechanics/roles.html#user) настройки
1. Последнее состояние [Unit](/definitions#unit)
1. Кэширование информации ввода [Пользователя](/mechanics/roles.html#user)
1. Большие по меркам микроконтроллеров данные

:::tip
Хранилище состояний [Unit](/definitions#unit) - долговременная память, которую [Unit](/definitions#unit) может использовать в любой момент времени.
:::

:::danger
Размер данного хранилища ограничен размером шифруемых объектов на [инстансе](/definitions#instance) [Pepeunit](/conception/overview).
:::

## Отправка данных в хранилище

Для установки значения нужно выполнить алгоритм:
1. Вычислить uuid [Unit](/definitions#unit) на основе jwt токена `PEPEUNIT_TOKEN` из [env.json](/definitions#env-json)
1. Преобразовать ваше значение или структуру данных в строку
1. Выполнить запрос. `HTTP_TYPE` и `PEPEUNIT_URL` доступны внутри [env.json](/definitions#env-json):
    ```bash
    curl -X 'POST' \
    'HTTP_TYPE://PEPEUNIT_URL/pepeunit/api/v1/units/set_state_storage/{Unit.uuid}' \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d '{
    "state": "best_data_for_save_in_storage"
    }'
    ```

:::info
Curl запрос можно легко преобразовать в http запрос на любом языке программирования, достаточно передать его копию в LLM или GPT.
:::

## Получение данных из хранилища

Для получения значения нужно выполнить алгоритм:
1. Вычислить uuid [Unit](/definitions#unit) на основе jwt токена `PEPEUNIT_TOKEN` из [env.json](/definitions#env-json)
1. Выполнить запрос. `HTTP_TYPE` и `PEPEUNIT_URL` доступны внутри [env.json](/definitions#env-json):
    - `HTTP_TYPE://PEPEUNIT_URL/pepeunit/api/v1/units/get_state_storage/{Unit.uuid}`
1. Преобразовать строку полученную в результате ответа [Pepeunit](/conception/overview) в вашу структуру данных или значение