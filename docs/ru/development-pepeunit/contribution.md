# Хотите внести вклад в разработку ?


## Репозитории
Все `core` репозитории собраны на [Карте репозиториев](/development-pepeunit/maps).

Основная платформа для разработки - GitLab. Чтобы зарегистрироваться, свяжитесь с [@w7a8n1y4a](https://t.me/w7a8n1y4a). Все `core` репозитории имеют зеркало на GitHub, чтобы [Пользователям](/development-pepeunit/mechanics/roles#user) было проще оставлять `issues`.

В репозиториях Client и Server есть `Makefile`. Список команд: `make help`.

## Что запускать перед коммитом

Репозиторий | Что проверить
-- | --
Server | `make lint` (`Ruff`) и `make test-module` ([модульные тесты](/development-pepeunit/tests/module-test), их же запускает pre-commit), а перед изменением логики ещё [интеграционные тесты](/development-pepeunit/tests/integration-test)
Client | `flutter test`: тесты сверяют роутер с деревом экранов, проверяют документацию (ссылки, якоря, оглавление) и тексты ошибок
Deploy | Прогнать `python3 make_env.py` на образце `.env.local.example` и убедиться, что `.env` и конфиги в `data/` собираются

В CI Server проходит стадии `build`, `security`, `deploy` и `test` (модульные, интеграционные и два нагрузочных теста), а при теге ещё `tag`. Проверки безопасности: `trivy`, `osv-scanner`, `govulncheck` и `semgrep`. Client проходит `build`, `security` и `deploy_dev`.

## Что менять вместе с кодом

Часть правил проверяется тестами, часть держится на договорённости. Изменение считается законченным, если в нём есть:

Что изменили | Что добавить в том же изменении
-- | --
Новый маршрут или ячейка в клиенте | Строку в `lib/library/screen_tree.dart` и файл подсказки `tooltip/ru/<экран>.<ячейка>.md`
Новая статья документации | Файл `.md` и строку в `docs/ru/sidebar.json`, а также перевод в `docs/en/` и строку в `docs/en/sidebar.json`
Новый код ошибки Backend | Строку в `lib/locale/error_texts.dart` клиента: тест клиента сверяет файл с таблицей Backend, когда репозитории лежат рядом
Новая сущность, роль или поле в API | Правку в [сущностях](/development-pepeunit/mechanics/entities), [ролях](/development-pepeunit/mechanics/roles) и соответствующей статье этого раздела
Новая настройка инстанса или флаг `pu_ff_*` | Строку в [настройках инстанса](/deployment/instance-settings) и в маркерах [интеграционных тестов](/development-pepeunit/tests/integration-test#флаги-и-покрытие), если флаг включает сценарии
Новая миграция | Файл в `alembic/versions/` (`alembic revision -m 'name'`, применяется `make migrate`), а для ClickHouse файл в `clickhouse/migrations/`

:::warning
Клиент работает только с версиями Backend из своего окна совместимости (`backendCompatible` в `lib/api/backend_version.dart`). Если меняете API несовместимо, проверьте это окно.
:::

## TBD

В репозиториях Pepeunit принята методология разработки `TBD`.

`Trunk Based Development (TBD)` — вся команда работает в одной основной ветке `master`, а вспомогательные ветки `feature/best_feature_name` живут часы или дни. Изменения интегрируются часто, ветка всегда готова к релизу. По сравнению с `Git Flow` это ускоряет разработку и снижает конфликты слияния.

`TBD` подразумевает `feature flags (FF)` для включения и отключения функционала в разворачиваемых инстансах. В Pepeunit это флаги `pu_ff_*` в [настройках инстанса](/deployment/instance-settings), которые меняет [Owner](/development-pepeunit/mechanics/roles#owner).

## Соглашение о именовании коммитов

Имена коммитов следуют системе [COMMITLINT example](https://www.commitvalidator.dev/): она делает историю Git читаемой, упрощает поиск изменений и ускоряет код-ревью.

Примеры наименования коммитов:
1. `feat(unit_service): add new function`
2. `fix(tests, unit_service): hotfix logic create UnitIO`
3. `refactor(permission_service): add new permission and rest for creator UnitIO`
4. `resolve(conflicts): resolve`
5. `ci(Dockerfile): change packages`
