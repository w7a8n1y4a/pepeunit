# Интеграционные тесты - Backend

:::tip Какую роль выполняют интеграционные тесты?
Проверка корректности работы основных сценариев приложения. Благодаря данным тестам, разработчики [Backend](/definitions#backend), могут не сомневаться в изменениях кодовой базы 
:::

:::warning
Тестовые сценарии проверяют исключительно бизнеслогику, они не стремятся проверить то как работает какой-либо из слоёв API.
:::

## Запуск

0. Настроить дополнительные [ENV переменные Backend](/deployment/env-variables#backend):

    Переменная Backend | Что делает ?
    -- | --
    `TEST_INTEGRATION_CLEAR_DATA` | Удаление всех связанных с тестом данных, происходит в начале и конце теста. Но если указать данную переменную как `False`, удаление в конце теста происходить не будет - удобно для откладки ошибок
    `TEST_INTEGRATION_PRIVATE_REPO_JSON` | Это указание на приватные репозитории в [Gitlab](/definitions#gitlab) и [Github](/definitions#github), структура репозиториев, соответствует такой же для публичных репозиториев, ссылки на них есть в `tests.integration.conftest.py`

1. Запустить [Backend](/definitions#backend) одной из команд, число `workers` может быть произвольным:
   ```
   uvicorn app.main:app --host 0.0.0.0 --port 8555 --log-level info --workers 4
   gunicorn app.main:app -b 0.0.0.0:8555 --workers=4 -k uvicorn.workers.UvicornWorker --log-level=info
   ```
1. Запустить интеграционное тестирование можно командой
   ```
   pytest tests -v
   ```
