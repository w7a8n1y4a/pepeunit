# Бэкапы и обновление

## Работа с бэкапами

Резервная копия - один `tar` архив в каталоге `backups/` с именем `<дата>_v<версия>_pepeunit_backup.tar`. В нём:
- дамп [PostgreSQL](/deployment/dependencies/postgresql): настройки инстанса, пользователи, Repo, Unit и остальное
- копия [ClickHouse](/deployment/dependencies/clickhouse): история данных UnitIO
- тома `backend_repo_cache` и `grafana_data`
- файл настроек `.env.local` или `.env.global` с секретными ключами

Логи ([Loki](/deployment/dependencies/loki)) в копию не попадают, а [EMQX](/deployment/dependencies/emqx) [Backend](/deployment/dependencies/backend) настроит заново при запуске.

:::danger
В архиве лежат ключи и пароли. Храните его так же бережно, как сам сервер.
:::

:::warning
Имена томов зависят от имени каталога с `docker-compose.yml` (по умолчанию `pepeunit_deploy`). Скрипт берёт его из текущего каталога или из `COMPOSE_PROJECT_NAME`.
:::

### Создание бэкапа
1. Запустите Pepeunit, чтобы скрипт мог подключиться к базам
    ```bash
    docker compose up -d
    ```
1. Создайте бэкап, контейнеры работают как обычно
    ```bash
    sudo ./backup.sh backup
    ```

### Восстановление из бэкапа

:::danger
Восстановление **удаляет все тома проекта**, в том числе те, что не входят в бэкап, и заменяет файл настроек файлом из архива.
:::

1. Запустите восстановление. Скрипт сам остановит инстанс, вернёт файл настроек, пересоздаст тома и запустит Pepeunit
    ```bash
    sudo ./backup.sh restore backups/<имя файла>.tar
    ```
1. Дождитесь запуска [Backend](/deployment/dependencies/backend)
    ```bash
    docker logs -f backend
    ```

## Обновление

1. Создайте бэкап
    ```bash
    sudo ./backup.sh backup
    ```
1. Скачайте новую версию репозитория
    ```bash
    git pull
    ```
1. Пересоберите конфиги. Если в новой версии появились обязательные переменные, `make_env.py` перечислит их: сверьтесь с актуальным `.env.*.example`
    ```bash
    python3 make_env.py
    ```
1. Запустите новые версии. Ключ `--remove-orphans` убирает контейнеры, которых больше нет в `docker-compose.yml`
    ```bash
    docker compose up -d --remove-orphans
    ```
1. Дождитесь запуска [Backend](/deployment/dependencies/backend), он сам обновит базы
    ```bash
    docker logs -f backend
    ```
1. Проверьте версию сервера
    ```bash
    curl http://127.0.0.1:5291/pepeunit/api/v1/instances/current
    ```
1. От имени [Администратора](/development-pepeunit/mechanics/roles#admin) запустите интеграционные тесты. При ошибках посмотрите [логи контейнеров](/deployment/docker/commands) или напишите `issue`

:::info
Клиент и сервер совместимы в пределах `1.5.x`. Обновляйте [Frontend](/deployment/dependencies/frontend) и [Backend](/deployment/dependencies/backend) вместе: версии образов закреплены в `docker-compose.yml`.
:::

## Обновление с 1.4.0 на 1.5.0

Что изменилось в `1.5.0`:
- Образы `pepeunit-backend`, `pepeunit-data-pipe` и `pepeunit-frontend` заменены на `pepeunit-server` и `pepeunit`. Контейнера `datapipe` больше нет: [DataPipe](/deployment/dependencies/datapipe) работает внутри [Backend](/deployment/dependencies/backend)
- Каталог `env/` не используется: все переменные лежат в одном файле настроек
- В файле настроек теперь переменные `PU_*`, в том числе адреса баз `PU_SQLALCHEMY_DATABASE_URL` и `PU_CLICKHOUSE_DATABASE_URL`
- Telegram Bot, лимиты и флаги переехали в [PostgreSQL](/deployment/dependencies/postgresql) и настраиваются из клиента, см. [Настройки инстанса](/deployment/instance-settings). Старые значения не переносятся, настройте инстанс заново
- Первого `Owner` назначают командой, см. [Регистрация и Owner](/deployment/docker/deploy#регистрация-и-owner)

Порядок:
1. Создайте бэкап на `1.4.0`
    ```bash
    sudo ./backup.sh backup
    ```
1. Скачайте новую версию репозитория
    ```bash
    git pull
    ```
1. Сохраните старый файл настроек и возьмите новый образец
    ```bash
    mv .env.local .env.local.old
    cp .env.local.example .env.local
    ```
1. Перенесите значения из старого файла: домен, `PU_MQTT_*`, `PU_GRAFANA_ADMIN_*`, а также логин, пароль и базу [PostgreSQL](/deployment/dependencies/postgresql) и [ClickHouse](/deployment/dependencies/clickhouse) в адреса `PU_SQLALCHEMY_DATABASE_URL` и `PU_CLICKHOUSE_DATABASE_URL`. Они **должны совпасть** со старыми, иначе базы не пустят [Backend](/deployment/dependencies/backend) к существующим данным
1. Оставьте `<32-bit-key>` у `PU_SECRET_KEY` и `PU_ENCRYPT_KEY`: `make_env.py` возьмёт действующие ключи из `env/.env.backend`. Если каталога `env/` нет, перенесите ключи из старого файла вручную
1. Соберите конфиги и запустите новые версии
    ```bash
    python3 make_env.py
    docker compose up -d --remove-orphans
    ```
1. Назначьте `Owner` и настройте инстанс: [Регистрация и Owner](/deployment/docker/deploy#регистрация-и-owner)

## Обновление с версий до 1.3.0

:::info
Обновление сложнее обычного, потому что [PostgreSQL](/deployment/dependencies/postgresql) при переходе с `17` на `18` изменил структуру каталогов: старый том не подходит.
:::

:::danger
Новые версии `ClickHouse` требуют процессор с `x86-64-v3` и выше. Если ваш процессор старее, закрепите в `docker-compose.yml` старую версию, например `clickhouse:25.8.32`.
:::

Данные переносятся через бэкап: восстановление само удалит старые тома и создаст новые.

1. Создайте бэкап на старой версии
    ```bash
    sudo ./backup.sh backup
    ```
1. Остановите инстанс
    ```bash
    docker compose down
    ```
1. Скачайте новую версию репозитория и образы
    ```bash
    git pull
    docker compose pull
    ```
1. Восстановите данные, подставив имя своего файла
    ```bash
    sudo ./backup.sh restore backups/<имя файла>.tar
    ```

Дальше следуйте инструкции [обновления](#обновление) до нужной версии.
