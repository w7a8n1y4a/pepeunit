# Хранилище состояний Unit

Позволяет Unit хранить текстовые данные прямо в Pepeunit. Подходит для:
1. Последнего состояния Unit
1. Ввода [Пользователя](/development-pepeunit/mechanics/roles#user), который нужно запомнить
1. Данных, которые велики для памяти микроконтроллера

:::tip
Это долговременная память Unit: он может обратиться к ней в любой момент.
:::

:::danger
Данные хранятся в [шифрованном виде](/development-pepeunit/mechanics/cipher). Размер ограничен настройкой инстанса pu_instance_cipher_max_length, по умолчанию 1000000 символов, подробнее в [настройках инстанса](/deployment/instance-settings#базовые).
:::

Содержимое хранилища видно в клиенте: `Аппараты` → Unit → `Управление аппаратом` → `Хранилище`.

## Отправка данных в хранилище

1. Получите uuid Unit из токена PU_AUTH_TOKEN в env.json
1. Преобразуйте значение или структуру данных в строку
1. Выполните запрос. PU_HTTP_TYPE, PU_DOMAIN и PU_AUTH_TOKEN возьмите из env.json:
    ```bash
    curl -X 'POST' \
    'PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/set_state_storage/{Unit.uuid}' \
    -H 'Content-Type: application/json' \
    -H 'x-auth-token: PU_AUTH_TOKEN' \
    -d '{
    "state": "best_data_for_save_in_storage"
    }'
    ```

Ответ приходит без тела, с кодом 204. Пустая строка в state очищает хранилище.

:::info
curl легко превратить в запрос на любом языке: достаточно показать его LLM.
:::

## Получение данных из хранилища

1. Получите uuid Unit из токена PU_AUTH_TOKEN в env.json
1. Выполните запрос:
    ```bash
    curl 'PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/get_state_storage/{Unit.uuid}' \
    -H 'x-auth-token: PU_AUTH_TOKEN'
    ```
1. Ответ приходит как JSON строка, то есть в кавычках. Снимите их и преобразуйте текст в свою структуру данных или значение

:::info
Префикс /pepeunit и версия API /api/v1 взяты из PU_APP_PREFIX и PU_API_ACTUAL_PREFIX в env.json. Клиентские [библиотеки](/developer/libraries/framework) делают это сами.
:::
