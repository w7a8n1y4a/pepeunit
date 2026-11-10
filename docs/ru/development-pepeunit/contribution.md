# Хотите внести вклад в разработку ?


## Репозитории
:::tip
Найти все `core` репозитории можно на [Карте репозиториев](/development-pepeunit/maps)
:::

:::tip
Основная платформа для разработки - GitLab. Чтобы зарегистрироваться, свяжитесь с [@w7a8n1y4a](https://t.me/w7a8n1y4a), при этом все `core` репозитории имеют зеркало на GitHub, чтобы [Пользователям](/development-pepeunit/mechanics/roles#user) было проще оставлять `issues`.

В каждом репозитории разработки вы найдёте `Makefile` и readme.md с важными нюансами по работе кода. Список команд: `make help`
:::

## Что запускать перед коммитом

Репозиторий | Что проверить
-- | --
Server | `make lint` (`Ruff`) и `make test-module`, а перед изменением логики ещё [интеграционные тесты](/development-pepeunit/tests/integration-test). Шаблон `.pre-commit-config.example.yaml` запускает `Ruff` и модульные тесты на каждый коммит
Client | `flutter test`: тесты сверяют роутер с деревом экранов, проверяют документацию (ссылки, якоря, оглавление) и тексты ошибок
Deploy | Прогнать `python3 make_env.py` на образце `.env.local.example` и убедиться, что `.env` и конфиги в `data/` собираются

В CI Server проходит стадии `build`, `security`, `deploy` и `test` (модульные, интеграционные и два нагрузочных теста), а при теге ещё `tag`. Проверки безопасности: `trivy`, `osv-scanner`, `govulncheck` и `semgrep`. Client проходит `build`, `security` и `deploy_dev`.

## Что менять вместе с кодом

Часть правил проверяется тестами, часть держится на договорённости. Изменение считается законченным, если в нём есть:

Что изменили | Что добавить в том же изменении
-- | --
Новый маршрут или ячейка в клиенте | Строку в `lib/library/screen_tree.dart` и файл подсказки `tooltip/ru/<экран>.<ячейка>.md`
Новая статья документации | Строку в `docs/ru/sidebar.json`
Новый код ошибки Backend | Строку в `lib/locale/error_texts.dart` клиента
Новая сущность, роль или поле в API | Правку в [сущностях](/development-pepeunit/mechanics/entities), [ролях](/development-pepeunit/mechanics/roles) и соответствующей статье этого раздела
Новая настройка инстанса или флаг `pu_ff_*` | Строку в [настройках инстанса](/deployment/instance-settings) и в маркерах [интеграционных тестов](/development-pepeunit/tests/integration-test#флаги-и-покрытие), если флаг включает сценарии
Новая миграция | Файл в `alembic/versions/` (`alembic revision -m 'name'`, применяется `make migrate`), а для ClickHouse файл в `clickhouse/migrations/`

:::warning
Клиент работает только с версиями Backend из своего окна совместимости (`backendCompatible` в `lib/api/backend_version.dart`). Если меняете API несовместимо, проверьте это окно.
:::

## TBD

В репозиториях Pepeunit принята методология разработки `TBD`

:::info
`Trunk Based Development (TBD)` — методология разработки, при которой вся команда работает в одной основной ветке `master`, а любые вспомогательные ветки `feature/best_feature_name` живут заведомо малое время `часы или дни`. Все изменения интегрируются часто, поддерживается постоянная готовность ветки к релизу.

`TBD` также подразумевает использование `feature flags (FF)` для включения и отключения функционала в разворачиваемых инстансах. В Pepeunit это флаги `pu_ff_*` в [настройках инстанса](/deployment/instance-settings), которые меняет [Owner](/development-pepeunit/mechanics/roles#owner).

Такой подход значительно ускоряет разработку по сравнению с `Git Flow`, снижает конфликты слияния и повышает стабильность кода.
:::

## Соглашение о именовании коммитов

:::info
Система именования коммитов [COMMITLINT example](https://www.commitvalidator.dev/) помогает быстро понять суть каждого изменения и улучшает прозрачность истории разработки.
  
Основные преимущества:
- Повышает читаемость и структурность истории Git
- Упрощает поиск нужных изменений и анализ причин ошибок

Единый стиль именования облегчает совместную работу в рамках методологии `TBD` и ускоряет код-ревью.
:::

Примеры наименования коммитов:
1. `feat(unit_service): add new function`
2. `fix(tests, unit_service): hotfix logic create UnitIO`
3. `refactor(permission_service): add new permission and rest for creator UnitIO`
4. `resolve(conflicts): resolve`
5. `ci(Dockerfile): change packages`
