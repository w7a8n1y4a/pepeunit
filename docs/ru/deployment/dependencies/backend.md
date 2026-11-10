# Backend

## Backend в широком смысле

Это пять контейнеров: `backend`, [PostgreSQL](/deployment/dependencies/postgresql), [ClickHouse](/deployment/dependencies/clickhouse), [Redis](/deployment/dependencies/redis) и [EMQX](/deployment/dependencies/emqx). Внутри `backend` ещё работает [DataPipe](/deployment/dependencies/datapipe). Вместе они реализуют логику Pepeunit и общаются с внешним миром:

- [Пользователи](/development-pepeunit/mechanics/roles#user) и [Frontend](/deployment/dependencies/frontend)
- Unit
- GitLab и GitHub
- Telegram
- другие инстансы Pepeunit (Peer)

## Backend-сервис

Главный из этих контейнеров. Образ `w7a8n1y4a/pepeunit-server`, контейнер `backend`, исходники в [`pepeunit_server`](/development-pepeunit/maps). Отвечает за REST API (документация `swagger` по адресу `/pepeunit/docs`), MQTT и Telegram Bot.

Префикс `/pepeunit` задаёт `PU_APP_PREFIX`. Версию сервера и публичное состояние инстанса можно получить без авторизации: `GET /pepeunit/api/v1/instances/current`.

### Запуск контейнера

При старте `backend` сам ждёт PostgreSQL, применяет миграции баз данных, настраивает EMQX и Grafana, запускает DataPipe и сервер. Вручную ничего делать не нужно.

Сервер можно перезапустить без остановки контейнера: `Owner` делает это в клиенте, см. [Настройки инстанса](/deployment/instance-settings#применение-изменений).

### Что где настраивается

Источник | Что хранит
-- | --
[Переменные окружения](/deployment/env-variables/backend) | Адрес, ключи, подключения к базам, EMQX и Grafana. Меняются только в [файле настроек](/deployment/docker/deploy#файл-настроек)
[Настройки инстанса](/deployment/instance-settings) | Флаги, лимиты, Telegram Bot, DataPipe и всё, что меняет `Owner` из клиента. Хранятся в PostgreSQL

### Тома и порты

Порт в контейнере 5000, на хосте 5291. Том `backend_repo_cache` хранит скачанные Git репозитории.
