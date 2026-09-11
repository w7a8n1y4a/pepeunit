# Интеграционные тесты

:::tip Зачем это нужно?
Прогон на живом инстансе проверяет основные сценарии [Backend](/deployment/dependencies/backend). По логу видно, что работает, и этот лог можно приложить к `issue`
:::

## Запуск

Доступен только [Администратору](/development-pepeunit/mechanics/roles#admin).

1. Кликните узел `Domain` на главной странице
1. Нажмите `Integration Tests`
1. В [Operation Tasks](/user/operation-task/operation-tasks) дождитесь `Success` или `Error`

Тот же запуск есть в [Telegram Bot](/definitions#telegram-bot) по команде `/control`. Паузы между запусками нет. Пока тесты идут, в публичном состоянии инстанса стоит `Running`.

## Результат

В [Operation Tasks](/user/operation-task/operation-tasks) откройте строку `Integration Tests` и иконку в колонке `Result`. Модальное окно `Task Result` показывает полный лог `pytest`, его можно скопировать.

Краткий итог [Backend](/deployment/dependencies/backend) берёт из финальной строки, например `total 241, passed 231, skipped 10, failed 0, error 0 in 174.21s`. Процент успешности `(passed + xpassed) / executed * 100` попадает в публичное состояние инстанса.

Статус | Что означает
-- | --
`Running` | Ещё выполняется
`Success` | `pytest` завершился с кодом `0`
`Warning` | Задача упала, но часть тестов прошла
`Error` | Запуск сорвался или процент разобрать нельзя

Этот статус и процент видны всем: колонка `Tests` в [Instances](/user/instance/instances), блок `Identity` в карточке инстанса и поля `state.integration_tests_*` в `GET /pepeunit/api/v1/instances/current`. Доверенные соседи забирают то же состояние при опросе.

:::info
Если тесты давно не запускались, поля в `/current` пустые. Для диагностики нужен свежий прогон
:::

## Как прикрепить к issue

1. Скопируйте лог из `Task Result`
1. Вставьте его в `issue` нужного репозитория: [Backend](https://github.com/w7a8n1y4a/pepeunit_backend), [Frontend](https://github.com/w7a8n1y4a/pepeunit_frontend), [Документация](https://github.com/w7a8n1y4a/pepeunit). Список репозиториев - на [карте](/development-pepeunit/maps)

## Переменные

Тесты читают [ENV Backend](/deployment/env-variables/backend). Выключенные флаги `PU_FF_*` снимают связанные сценарии с прогона. `PU_TEST_INTEGRATION_CLEAR_DATA=False` оставляет тестовые данные для ручного разбора.

:::info
Значения по умолчанию, диапазоны и запуск из консоли - в [Интеграционные тесты Backend](/development-pepeunit/tests/integration-test)
:::
