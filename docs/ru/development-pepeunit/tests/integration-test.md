# Интеграционные тесты - Backend

:::tip Какую роль выполняют интеграционные тесты?
Проверка корректности работы основных сценариев приложения. Благодаря данным тестам, разработчики [Backend](/deployment/dependencies/backend) могут не сомневаться в изменениях кодовой базы
:::

:::warning
Тестовые сценарии проверяют исключительно `бизнес-логику`, они не стремятся проверить то, как работает какой-либо из слоёв API
:::

Тесты ходят в уже запущенный [Backend](/deployment/dependencies/backend). Имена создаваемых сущностей содержат хэш от `PU_DOMAIN`, чтобы несколько инстансов не пересекались. Запуск с [Frontend](/deployment/dependencies/frontend) и разбор лога описаны в [руководстве по интеграционным тестам](/user/notification/integration-tests).

## Запуск из консоли

1. Настроить [ENV переменные Backend](/deployment/env-variables/backend), включая переменные ниже
1. Запустить [Backend](/deployment/dependencies/backend) одной из команд, число `workers` может быть произвольным:
   ```
   uvicorn app.main:app --host 0.0.0.0 --port 8555 --log-level info --workers 4
   gunicorn app.main:app -b 0.0.0.0:8555 --workers=4 -k uvicorn.workers.UvicornWorker --log-level=info
   ```
1. Запустить интеграционное тестирование:
   ```
   make test-integration
   ```
   или напрямую:
   ```
   uv run pytest tests -v
   ```

Тот же прогон [Администратор](/development-pepeunit/mechanics/roles#admin) может запустить кнопкой `Integration Tests` на узле `Domain` или командой `/control` в [Telegram Bot](/definitions#telegram-bot). [Backend](/deployment/dependencies/backend) выполняет команду `uv run pytest tests -v` в фоне и пишет ход в [уведомление](/definitions#notification) типа `Integration Tests`.

## Переменные интеграционного тестирования

Переменная | По умолчанию | Значения | Что делает
-- | -- | -- | --
`PU_TEST_INTEGRATION_CLEAR_DATA` | `True` | `True` / `False` | В начале прогона тестовые данные всегда удаляются. Если `True`, такая же очистка выполняется в конце. Если `False`, данные остаются, свой [Instance](/definitions#instance) восстанавливается, а при включённой [Grafana](/deployment/dependencies/grafana) сохраняется демонстрационный [Dashboard](/definitions#dashboard) `test0_*` для ручной отладки
`PU_TEST_INTEGRATION_GITHUB_PUBLIC_REPO_URL` | `https://github.com/w7a8n1y4a/github_unit_pub_test.git` | `http` / `https`, не пусто, `≤ 512` симв. | Публичный тестовый репозиторий [GitHub](/definitions#github)
`PU_TEST_INTEGRATION_GITLAB_PUBLIC_REPO_URL` | `https://git.pepemoss.com/pepe/pepeunit/units/gitlab_unit_pub_test.git` | `http` / `https`, не пусто, `≤ 512` симв. | Публичный тестовый репозиторий [GitLab](/definitions#gitlab)
`PU_TEST_INTEGRATION_UNIVERSAL_REPO_URL` | `https://git.pepemoss.com/pepe/pepeunit/units/universal_test_unit.git` | `http` / `https`, не пусто, `≤ 512` симв. | Универсальный тестовый [Unit](/definitions#unit)
`PU_TEST_INTEGRATION_PRIVATE_REPO_ENABLE` | `False` | `True` / `False` | Включает сценарии приватных репозиториев. При `True` нужен непустой `PU_TEST_INTEGRATION_PRIVATE_REPO_JSON`
`PU_TEST_INTEGRATION_PRIVATE_REPO_JSON` | пусто | JSON, `≤ 8192` симв. | Объект с полем `data`: список репозиториев. У каждого `link`, `username`, `pat_token`, `is_public` и `platform` (`Github` или `Gitlab`). Обязателен и должен быть валидным JSON при `PU_TEST_INTEGRATION_PRIVATE_REPO_ENABLE=True`
`PU_TEST_INTEGRATION_TELEGRAM_CHAT_ID` | пусто | пусто или chat id, `≤ 32` симв. | Chat id тестового [Пользователя](/development-pepeunit/mechanics/roles#user) в [Telegram](/definitions#telegram). Пустое значение подставляет случайный id. Id из этой переменной не должен принадлежать никакому другому [Пользователю](/development-pepeunit/mechanics/roles#user) инстанса, если будет то тест сломается на ранних этапах

:::warning
Набор функциональных флагов `PU_FF_*` влияет и на объём покрытия: сценарии выключенных возможностей снимаются с прогона
:::

:::warning
Запуск с [Frontend](/deployment/dependencies/frontend) или из [Telegram Bot](/definitions#telegram-bot) создаёт [уведомление](/definitions#notification): полный лог `pytest` открывается из строки `Integration Tests`, а публичное состояние инстанса обновляет поля `state.integration_tests_*` в `GET /pepeunit/api/v1/instances/current`. Лог можно [прикрепить к issue](/user/notification/integration-tests#как-прикрепить-к-issue)
:::
