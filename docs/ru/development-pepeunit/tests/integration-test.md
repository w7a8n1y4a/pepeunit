# Интеграционные тесты - Backend

:::tip Какую роль выполняют интеграционные тесты?
Проверка корректности работы основных сценариев приложения. Благодаря данным тестам, разработчики [Backend](/deployment/dependencies/backend) могут не сомневаться в изменениях кодовой базы
:::

:::warning
Тестовые сценарии проверяют исключительно `бизнес-логику`, они не стремятся проверить то, как работает какой-либо из слоёв API
:::

Тесты ходят в уже запущенный [Backend](/deployment/dependencies/backend). Имена создаваемых сущностей содержат хэш от `PU_DOMAIN`, чтобы несколько инстансов не пересекались. Запуск с [Frontend](/deployment/dependencies/frontend) и разбор лога описаны в [руководстве по интеграционным тестам](/user/operation-task/integration-tests).

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

Тот же прогон [Администратор](/development-pepeunit/mechanics/roles#admin) может запустить кнопкой `Integration Tests` на узле `Domain` или командой `/control` в [Telegram Bot](/definitions#telegram-bot). [Backend](/deployment/dependencies/backend) создаёт [Operation Task](/definitions#operation-task) и выполняет команду `uv run pytest tests -v` в фоне.

## Переменные интеграционного тестирования

Переменная | По умолчанию | Значения | Что делает
-- | -- | -- | --
`PU_TEST_INTEGRATION_CLEAR_DATA` | `True` | `True` / `False` | В начале прогона тестовые данные всегда удаляются. Если `True`, такая же очистка выполняется в конце. Если `False`, данные остаются, свой [Instance](/definitions#instance) восстанавливается, а при включённой [Grafana](/deployment/dependencies/grafana) сохраняется демонстрационный [Dashboard](/definitions#dashboard) `test0_*` для ручной отладки
`PU_TEST_INTEGRATION_GITHUB_PUBLIC_REPO_URL` | `https://github.com/w7a8n1y4a/github_unit_pub_test.git` | `http` / `https`, не пусто, `≤ 512` симв. | Публичный тестовый репозиторий [GitHub](/definitions#github)
`PU_TEST_INTEGRATION_GITLAB_PUBLIC_REPO_URL` | `https://git.pepemoss.com/pepe/pepeunit/units/gitlab_unit_pub_test.git` | `http` / `https`, не пусто, `≤ 512` симв. | Публичный тестовый репозиторий [GitLab](/definitions#gitlab)
`PU_TEST_INTEGRATION_UNIVERSAL_REPO_URL` | `https://git.pepemoss.com/pepe/pepeunit/units/universal_test_unit.git` | `http` / `https`, не пусто, `≤ 512` симв. | Универсальный тестовый [Unit](/definitions#unit)

:::warning
Набор функциональных флагов `PU_FF_*` влияет и на объём покрытия: сценарии выключенных возможностей снимаются с прогона
:::

:::warning
Запуск с [Frontend](/deployment/dependencies/frontend) или из [Telegram Bot](/definitions#telegram-bot) создаёт [Operation Task](/definitions#operation-task): полный лог `pytest` пишется в `result`, а публичное состояние инстанса обновляет поля `state.integration_tests_*` в `GET /pepeunit/api/v1/instances/current`. Лог можно [прикрепить к issue](/user/operation-task/integration-tests#как-прикрепить-к-issue)
:::
