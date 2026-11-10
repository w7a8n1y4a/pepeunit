# Интеграционные тесты - Backend

Интеграционные тесты проверяют основные сценарии приложения, чтобы разработчики [Backend](/deployment/dependencies/backend) могли уверенно менять кодовую базу. Сценарии проверяют исключительно `бизнес-логику`, а не работу слоёв API.

Тесты работают с настоящими [PostgreSQL](/deployment/dependencies/postgresql), [ClickHouse](/deployment/dependencies/clickhouse), [Redis](/deployment/dependencies/redis) и [EMQX](/deployment/dependencies/emqx): сервисы Backend вызываются напрямую, а сценарии обновления `Unit`, MQTT и [DataPipe](/deployment/dependencies/datapipe) обращаются ещё и к запущенному Backend по HTTP.

:::danger
Тесты создают и удаляют данные инстанса. Тестовые пользователи и сущности получают имена с хэшем от `PU_DOMAIN`, чтобы несколько инстансов не пересекались, и перед прогоном такие остатки прошлого запуска удаляются. Роль `Owner` тесты на время подменяют, а в конце возвращают прежнему владельцу.
:::

## Запуск из консоли

1. Настроить [ENV переменные Backend](/deployment/env-variables/backend), включая переменные ниже
1. Запустить Backend вместе с DataPipe:
   ```
   make start
   ```
   Команда собирает DataPipe, запускает его и Backend на порту `5291` с двумя воркерами. В Docker Backend слушает порт `5000` и запускается через `gunicorn`, см. [Backend](/deployment/dependencies/backend)
1. Запустить интеграционное тестирование:
   ```
   make test-integration
   ```
   или напрямую:
   ```
   uv run pytest tests -v
   ```

Тот же прогон [Admin](/development-pepeunit/mechanics/roles#admin) может запустить из клиента или Telegram Bot, см. [операции](/development-pepeunit/mechanics/operations). Backend выполняет `uv run pytest tests -v` в фоне, а полный лог приходит уведомлением типа `IntegrationTests`. Публичное состояние инстанса обновляет поля `state.integration_tests_*` в `GET /pepeunit/api/v1/instances/current`, так что другие инстансы видят результат.

## Что проверяется

Файлы лежат в `tests/integration/services/` и выполняются по номерам. Pytest останавливается на первой ошибке.

Файл | Область
-- | --
`01_user_test.py` | Регистрация, вход по [ключу](/development-pepeunit/mechanics/authentication), роли `Admin` и `Owner`, блокировка, вход в Grafana, привязка Telegram
`02_repo_test.py` | [Repo](/development-pepeunit/mechanics/entities#repo): создание, коммиты, синхронизация, приватные
`03_unit_test.py` | `Unit`: создание, имена, правила [обновления](/development-pepeunit/mechanics/update-system), [env.json](/development-pepeunit/mechanics/alg-env), прошивка, MQTT команды и проверка MQTT прав
`04_unit_io_test.py` | `UnitIO`, `Link`, настройки DataPipe и данные
`05_permission_test.py` | [Permission](/development-pepeunit/mechanics/permission) и [видимость](/development-pepeunit/mechanics/visibility)
`06_metrics_test.py` | Метрики инстанса для `Bot`, `User` и `Backend`
`07_grafana_test.py` | `Dashboard` и панели
`08_icon_test.py` | Иконки `User`, `Unit` и `UnitGroup`
`09_unit_group_test.py` | `UnitGroup`
`10_instance_settings_test.py` | Настройки инстанса, доступные только [Owner](/development-pepeunit/mechanics/roles#owner), лимиты, перезапуск
`11_peer_test.py` | [Peer](/development-pepeunit/mechanics/federation): добавление, доверие, опрос
`12_operation_task_test.py` | [Операции](/development-pepeunit/mechanics/operations)
`13_notification_test.py` | Уведомления и их настройки
`99_end_test.py` | Завершающая проверка и очистка

## Переменные интеграционного тестирования

Переменная | По умолчанию | Значения | Что делает
-- | -- | -- | --
`PU_TEST_INTEGRATION_CLEAR_DATA` | `True` | `True` / `False` | В начале прогона тестовые данные всегда удаляются. Если `True`, такая же очистка выполняется в конце. Если `False`, данные остаются, свой `Peer` восстанавливается, а при включённой [Grafana](/deployment/dependencies/grafana) сохраняется демонстрационный `Dashboard` `test0_*` для ручной отладки
`PU_TEST_INTEGRATION_GITHUB_PUBLIC_REPO_URL` | `https://github.com/w7a8n1y4a/github_unit_pub_test.git` | `http` / `https`, не пусто, `≤ 512` симв. | Публичный тестовый репозиторий GitHub
`PU_TEST_INTEGRATION_GITLAB_PUBLIC_REPO_URL` | `https://git.pepemoss.com/pepe/pepeunit/units/gitlab_unit_pub_test.git` | `http` / `https`, не пусто, `≤ 512` симв. | Публичный тестовый репозиторий GitLab
`PU_TEST_INTEGRATION_UNIVERSAL_REPO_URL` | `https://git.pepemoss.com/pepe/pepeunit/units/universal_test_unit.git` | `http` / `https`, не пусто, `≤ 512` симв. | Универсальный тестовый Unit
`PU_TEST_INTEGRATION_PRIVATE_REPO_ENABLE` | `False` | `True` / `False` | Включает сценарии приватных репозиториев. При `True` нужен непустой `PU_TEST_INTEGRATION_PRIVATE_REPO_JSON`
`PU_TEST_INTEGRATION_PRIVATE_REPO_JSON` | пусто | JSON, `≤ 8192` симв. | Объект с полем `data`: список репозиториев. У каждого `link`, `username`, `pat_token`, `is_public` и `platform` (`Github` или `Gitlab`). Обязателен и должен быть валидным JSON при `PU_TEST_INTEGRATION_PRIVATE_REPO_ENABLE=True`
`PU_TEST_INTEGRATION_TELEGRAM_CHAT_ID` | пусто | пусто или chat id, `≤ 32` симв. | Chat id тестового [Пользователя](/development-pepeunit/mechanics/roles#user) в Telegram. Пустое значение подставляет случайный id. Id не должен принадлежать никакому другому `User` инстанса, иначе тест сломается на ранних этапах

## Флаги и покрытие

Сценарии выключенных возможностей снимаются с прогона по маркерам `pytest`. Прогон смотрит на флаги `pu_ff_*` в [настройках инстанса](/deployment/instance-settings) и на переменные теста, поэтому результат нужно читать вместе со списком пропущенных сценариев:

Маркер | Нужно для запуска
-- | --
`grafana` | `pu_ff_grafana_integration_enable`
`datapipe` | `pu_ff_datapipe_enable`
`last_value` | `pu_ff_datapipe_enable` и `pu_datapipe_default_last_value_enable`
`telegram` | `pu_ff_telegram_bot_enable`
`prometheus` | `pu_ff_prometheus_enable`
`federation` | `pu_ff_federation_enable`
`notification` | `pu_ff_notification_enable`
`private_repo` | `PU_TEST_INTEGRATION_PRIVATE_REPO_ENABLE` и непустой список репозиториев
