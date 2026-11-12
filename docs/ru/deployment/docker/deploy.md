# Развёртывание

Репозиторий `Pepeunit Deploy` содержит всё для запуска инстанса через `docker compose`. Состав контейнеров описан в [Зависимостях](/deployment/dependencies/backend).

Заранее установите `Docker`, `Docker Compose`, `Python 3` и `git`: [Установка Docker и Docker Compose](/deployment/docker/install-docker).

```bash
git clone https://git.pepemoss.com/pepe/pepeunit/pepeunit_deploy.git
cd pepeunit_deploy
```

## Файл настроек

Это единственный файл, который вы правите: остальное собирается из него. Возьмите образец под свой случай:

- `.env.local.example` - локальная сеть, доступ по `ip` и `http`
- `.env.global.example` - публичный инстанс, доступ по домену и `https`

```bash
cp .env.local.example .env.local
```

Заполните в нём:

Переменная | Что указать
-- | --
PU_DOMAIN | Домен или `ip` инстанса, например `192.168.0.22` или `unit.pepeunit.com`
PU_SECURE | `True`, если доступ по `https`, иначе `False`
PU_MQTT_HOST | Домен или `ip` [EMQX](/deployment/dependencies/emqx), обычно тот же, что в `PU_DOMAIN`. `127.0.0.1` не подойдёт: адрес должен открываться из контейнеров
PU_MQTT_SECURE | `True`, если [EMQX](/deployment/dependencies/emqx) работает за `https`, иначе `False`

:::danger
Пароли в образце публичные. Замените на свои все логины и пароли: `PU_SQLALCHEMY_DATABASE_URL`, `PU_CLICKHOUSE_DATABASE_URL`, `PU_MQTT_USERNAME`, `PU_MQTT_PASSWORD`, `PU_GRAFANA_ADMIN_USER`, `PU_GRAFANA_ADMIN_PASSWORD`.

Секретные ключи `PU_SECRET_KEY` и `PU_ENCRYPT_KEY` не трогайте: они создаются сами.
:::

Остальное оставьте как в образце, подробнее в [переменных окружения Backend](/deployment/env-variables/backend). Логины и пароли баз применяются только при первом создании данных, поэтому задайте их сразу. Telegram Bot, флаги и лимиты в файле не нужны: их настраивает `Owner` из клиента, см. [Настройки инстанса](/deployment/instance-settings).

## Генерация конфигов

```bash
python3 make_env.py
```

Скрипт создаёт `.env` и конфиги в `data/`. Если чего-то не хватает, он остановится и покажет список ошибок.

:::danger
Файлы создаются заново при каждом запуске: правки в `.env` и `data/` пропадут. Правьте только файл настроек. Сам файл настроек входит в [резервную копию](/deployment/docker/backup-update#работа-с-бэкапами).
:::

## Порты

Откройте на сервере `80` для `http` и `443` для `https`, если перед инстансом стоит [внешний Nginx](/deployment/nginx). А также `1883` (MQTT).

:::danger
`docker-compose.yml` публикует порты всех сервисов. На публичном сервере закройте файрволом всё, кроме `80`, `443` и `1883`.
:::

## Запуск

```bash
docker compose up -d
docker logs -f backend
```

Первый запуск скачивает образы и занимает несколько минут. Он завершён, когда в логе [Backend](/deployment/dependencies/backend) появилась строка `Application startup complete`.

:::warning
Если в логе есть строка `[SUBACK] 1 (135,)` вместо `(0,)`, `Backend` не подписался на MQTT. Проверьте, что порт `1883` открыт и `PU_MQTT_HOST` доступен из контейнеров.
:::

## Регистрация и Owner

Откройте `PU_DOMAIN` в браузере. Паролей в Pepeunit нет: аккаунт - это пара ключей. Откройте `Аккаунт` → `Регистрация`, клиент создаст ключи и зарегистрирует аккаунт. Сохраните приватный ключ: без него доступ потеряется.

Первый пользователь владельцем не становится, роль `Owner` назначает администратор сервера. Найдите `uuid` своего аккаунта (`POSTGRES_USER` и `POSTGRES_DB` смотрите в `.env`):

```bash
docker exec -it postgres psql -U <POSTGRES_USER> -d <POSTGRES_DB> -c "SELECT uuid, LEFT(hash_public_key, 6) || '-' || RIGHT(hash_public_key, 6) AS hash_public_key, role, create_datetime FROM users;"
```

Запрос показывает `uuid`, первые и последние 6 символов `hash_public_key` через `-`, роль `role` и дату создания аккаунта `create_datetime`.

Назначьте владельца, запустив скрипт как модуль из `/app`, чтобы Python мог импортировать пакет `app`:

```bash
docker exec -it -w /app backend python -m scripts.set_owner <uuid>
```

`Owner` в инстансе один: при повторном запуске с другим `uuid` прежний владелец станет обычным [Пользователем](/development-pepeunit/mechanics/roles#user).

Дальнейшие настройки инстанса выполняются в клиенте: [Настройки инстанса](/deployment/instance-settings).
