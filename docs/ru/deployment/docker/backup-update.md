# Бэкапы и обновление

## Работа с бэкапами

Резервная копия - один `tar` архив в каталоге `backups/` с именем `<дата>_v<версия>_pepeunit_backup.tar`. В нём всё, что нужно для восстановления: базы [PostgreSQL](/deployment/dependencies/postgresql) и [ClickHouse](/deployment/dependencies/clickhouse), кэш репозиториев, данные [Grafana](/deployment/dependencies/grafana) и файл настроек. Логи ([Loki](/deployment/dependencies/loki)) в копию не попадают.

:::danger
В архиве лежат ключи и пароли. Храните его так же бережно, как сам сервер.
:::

### Создание бэкапа

Инстанс должен работать, останавливать его не нужно:

```bash
docker compose up -d
sudo ./backup.sh backup
```

### Восстановление из бэкапа

:::danger
Восстановление **удаляет все тома проекта** и заменяет файл настроек файлом из архива.
:::

Скрипт сам остановит инстанс, пересоздаст тома и запустит Pepeunit:

```bash
sudo ./backup.sh restore backups/<имя файла>.tar
docker logs -f backend
```

## Обновление

```bash
sudo ./backup.sh backup
git pull
python3 make_env.py
docker compose up -d --remove-orphans
docker logs -f backend
```

Что здесь происходит: сначала бэкап, затем новая версия репозитория и конфигов, затем запуск. [Backend](/deployment/dependencies/backend) сам обновит базы, дождитесь `Application startup complete`. Если `make_env.py` попросил новые обязательные переменные, добавьте их из актуального `.env.*.example`.

После обновления проверьте версию сервера:

```bash
curl http://127.0.0.1:5291/pepeunit/api/v1/instances/current
```

Если что-то пошло не так, посмотрите [логи контейнеров](/deployment/docker/commands) или напишите `issue`.

:::info
Клиент и сервер совместимы в пределах `1.5.x`. Обновляйте [Frontend](/deployment/dependencies/frontend) и [Backend](/deployment/dependencies/backend) вместе: версии образов закреплены в `docker-compose.yml`.
:::

## Обновление с 1.4.0 на 1.5.0

В `1.5.0` все переменные собраны в одном файле настроек, а Telegram Bot, лимиты и флаги переехали в базу и настраиваются из клиента. Старые значения не переносятся, см. [Настройки инстанса](/deployment/instance-settings). Образы заменены на `pepeunit-server` и `pepeunit`, контейнера `datapipe` больше нет.

```bash
sudo ./backup.sh backup
git pull
mv .env.local .env.local.old
cp .env.local.example .env.local
```

Перенесите в новый файл значения из старого: домен, `PU_MQTT_*`, `PU_GRAFANA_ADMIN_*`, а также логин, пароль и базу в `PU_SQLALCHEMY_DATABASE_URL` и `PU_CLICKHOUSE_DATABASE_URL`. Они **должны совпасть** со старыми, иначе базы не пустят [Backend](/deployment/dependencies/backend) к данным.

Ключи `PU_SECRET_KEY` и `PU_ENCRYPT_KEY` оставьте как `<32-bit-key>`: `make_env.py` возьмёт действующие из `env/.env.backend`. Если каталога `env/` нет, перенесите ключи вручную.

```bash
python3 make_env.py
docker compose up -d --remove-orphans
```

Затем назначьте `Owner` и настройте инстанс: [Регистрация и Owner](/deployment/docker/deploy#регистрация-и-owner).

## Обновление с версий до 1.3.0

[PostgreSQL](/deployment/dependencies/postgresql) при переходе с `17` на `18` изменил структуру каталогов, поэтому старый том не подходит. Данные переносятся через бэкап.

:::danger
Новые версии `ClickHouse` требуют процессор с `x86-64-v3` и выше. Если ваш процессор старее, закрепите в `docker-compose.yml` старую версию, например `clickhouse:25.8.32`.
:::

```bash
sudo ./backup.sh backup
docker compose down
git pull
docker compose pull
sudo ./backup.sh restore backups/<имя файла>.tar
```

Дальше следуйте инструкции [обновления](#обновление) до нужной версии.
