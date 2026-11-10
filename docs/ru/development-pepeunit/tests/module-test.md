# Модульные тесты - Backend

Модульные тесты проверяют отдельные части [Backend](/deployment/dependencies/backend) без базы данных, брокера и сети. Выполняются за секунды, поэтому запускаются на каждый коммит. Покрытие пока небольшое.

## Запуск

Запустить модульное тестирование можно командой:
```bash
make test-module
```
или напрямую:
```bash
uv run pytest app -v
```

Тесты лежат рядом с кодом, в файлах `test_*.py` внутри `app/`. Pytest останавливается на первой ошибке (`--maxfail=1`).

Чтобы тесты шли на каждый коммит, скопируйте `.pre-commit-config.example.yaml` в `.pre-commit-config.yaml`: перед коммитом будут запускаться `Ruff` (проверка и форматирование) и `make test-module`. Вручную: `pre-commit run --all-files`.

## Что проверяется

Файл | Что проверяет
-- | --
`app/services/auth/test_auth_service.py` | `JwtAuthService`: разбор токенов `User`, `Unit` и `Backend`, просроченный и неверный токен, заблокированный агент, неизвестный тип. `TgBotAuthService`: вход по `telegram_chat_id`, заблокированный и не найденный `User`
`app/services/auth/test_authorization_service.py` | `AuthorizationService`: типы агентов и [роли](/development-pepeunit/mechanics/roles) (`Owner` включает `Admin`, `Admin` включает `User`, `Admin` не `Owner`), создатель и `Unit` как владельцы, [видимость](/development-pepeunit/mechanics/visibility) `Public`, `Internal` и `Private`, ограничения списков по [доступам](/development-pepeunit/mechanics/permission)
`app/services/auth/test_challenge.py` | `ChallengeService`: проверка публичного ключа `ML-DSA-87`, одноразовость `challenge`, неверная подпись, домен и срок жизни, см. [Вход по ключу](/development-pepeunit/mechanics/authentication)
`app/configs/test_error_codes.py` | Каталог кодов ошибок: маршрут `/error_codes`, префикс `PUER` в тексте ошибки, у каждой сущности свой домен кодов, коды `Python` и `Golang` ([DataPipe](/deployment/dependencies/datapipe)) уникальны, каждый объявленный код используется
