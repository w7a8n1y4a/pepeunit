# Развёртывание

## Pepeunit Deploy

Репозиторий `Pepeunit Deploy` содержит всё для запуска инстанса через `docker compose`: описание контейнеров, генератор конфигов `make_env.py` и скрипт резервных копий `backup.sh`. Состав контейнеров описан в [Зависимостях](/deployment/dependencies/backend).
```bash
git clone https://git.pepemoss.com/pepe/pepeunit/pepeunit_deploy.git
cd pepeunit_deploy
```

:::info
Заранее установите `Docker`, `Docker Compose`, `Python 3` и `git`: [Установка Docker и Docker Compose](/deployment/docker/install-docker).
:::

## Файл настроек

Есть два образца:
1. `.env.local.example` - для локальной сети, доступ по `ip` и `http`
1. `.env.global.example` - для публичного инстанса, доступ по домену и `https`

Скопируйте нужный без `.example`:
```bash
cp .env.local.example .env.local
```

:::warning
Если в репозитории лежат оба файла, `make_env.py` использует `.env.local`.
:::

Это единственный файл, который вы правите, остальное `make_env.py` собирает из него. Здесь только [переменные окружения Backend](/deployment/env-variables/backend), которые нельзя менять на работающем инстансе. Остальные параметры меняются из клиента, см. [Настройки инстанса](/deployment/instance-settings).

Обязательно заполните:

Переменная | Пример для .env.local | Пример для .env.global | Зачем нужна?
-- | -- | -- | --
PU_DOMAIN | 192.168.0.22 | unit.pepeunit.com | Домен или `ip` инстанса
PU_SECURE | False | True | Использовать `https` вместо `http`
PU_SQLALCHEMY_DATABASE_URL | postgresql://myuser:mypassword@postgres:5432/pepeunit | postgresql://myuser:mypassword@postgres:5432/pepeunit | Адрес [PostgreSQL](/deployment/dependencies/postgresql). Логин, пароль и база отсюда используются при создании базы
PU_CLICKHOUSE_DATABASE_URL | clickhouse+native://admin:mypassword@clickhouse:9000/default | clickhouse+native://admin:mypassword@clickhouse:9000/default | Адрес [ClickHouse](/deployment/dependencies/clickhouse), работает так же
PU_MQTT_HOST | 192.168.0.22 | emqx.pepeunit.com | Домен или `ip` [EMQX](/deployment/dependencies/emqx). Должен открываться из контейнеров, `127.0.0.1` не подойдёт
PU_MQTT_SECURE | False | True | Как [Backend](/deployment/dependencies/backend) обращается к [EMQX](/deployment/dependencies/emqx), см. [EMQX](/deployment/dependencies/emqx#как-backend-настраивает-emqx)
PU_MQTT_USERNAME | YabJTlmvQ4tvweuTl0gn | YabJTlmvQ4tvweuTl0gn | Имя администратора [EMQX](/deployment/dependencies/emqx)
PU_MQTT_PASSWORD | F2qvym9lxL0DK6DlhmN1HgczWe9lKj30BvJTyvHu | F2qvym9lxL0DK6DlhmN1HgczWe9lKj30BvJTyvHu | Пароль администратора [EMQX](/deployment/dependencies/emqx)
PU_GRAFANA_ADMIN_USER | admin | admin | Логин администратора [Grafana](/deployment/dependencies/grafana)
PU_GRAFANA_ADMIN_PASSWORD | aN4bzmwMjB0v69LPvxpLLJ7LHXTe6hlqZ703mVmB | aN4bzmwMjB0v69LPvxpLLJ7LHXTe6hlqZ703mVmB | Пароль администратора [Grafana](/deployment/dependencies/grafana)
PU_SECRET_KEY, PU_ENCRYPT_KEY | `<32-bit-key>` | `<32-bit-key>` | Секретные ключи. Оставьте как есть: `make_env.py` создаст случайные и запишет в файл

:::danger
Пароли из образца публичные. Замените все логины и пароли на свои.
:::

Остальные переменные можно оставить как в образце, подробнее в [переменных окружения Backend](/deployment/env-variables/backend).

:::warning
Логин, пароль и база в адресах `PU_SQLALCHEMY_DATABASE_URL` и `PU_CLICKHOUSE_DATABASE_URL` применяются только при первом создании тома с данными. Позже изменить их в файле недостаточно: базы не пересоздают пользователей, и [Backend](/deployment/dependencies/backend) перестанет подключаться.
:::

:::info
Telegram Bot, флаги, лимиты и контакты в файле не задаются: их настраивает `Owner` из клиента после запуска, см. [Настройки инстанса](/deployment/instance-settings).
:::

## Генерация .env и конфигов

Сначала можно проверить файл, ничего не записывая:
```bash
python3 make_env.py --dry-run
```

Затем соберите итоговые файлы:
```bash
python3 make_env.py
```

Что получится:

Файл | Для чего
-- | --
.env | Переменные для `docker compose`
data/nginx/nginx.conf | Конфиг [Nginx](/deployment/dependencies/nginx)
data/prometheus/prometheus.yml | Конфиг [Prometheus](/deployment/dependencies/prometheus)
data/grafana/grafana.ini | Конфиг [Grafana](/deployment/dependencies/grafana)

:::danger
Эти файлы создаются заново при каждом запуске `make_env.py`: ручные правки в `.env` и `data/` **пропадут**. Правьте только файл настроек, а для тонкой настройки - `*.template` в `data/`.

Ключи `PU_SECRET_KEY` и `PU_ENCRYPT_KEY` при повторном запуске не меняются. Менять их самим нельзя: все токены и зашифрованные данные станут недействительны. Файл настроек входит в [резервную копию](/deployment/docker/backup-update#работа-с-бэкапами).
:::

Если не хватает обязательных значений или остались шаблоны `<...>`, команда остановится и покажет список ошибок.

## Настройка Nginx

Для `docker compose` настройка [Nginx](/deployment/dependencies/nginx) не нужна. Если инстанс будет за ещё одним `Nginx`, например ради `https`, возьмите [готовые конфиги](/deployment/nginx).

## Открытие портов

Откройте на сервере:
1. `80` - `http`
1. `443` - `https`, если настроен внешний [Nginx](/deployment/nginx)
1. `1883` - MQTT

:::danger
`docker-compose.yml` публикует на хост порты всех сервисов (базы, [EMQX](/deployment/dependencies/emqx), [Backend](/deployment/dependencies/backend), [Grafana](/deployment/dependencies/grafana) и другие). На публичном сервере закройте их файрволом: наружу должны смотреть только `80`, `443` и `1883`. Исключение одно: при `PU_MQTT_SECURE=True` порт `18083` должен быть доступен [внешнему Nginx](/deployment/nginx#emqx-api-за-https), но не всему интернету.
:::

:::warning
Если порт `1883` занят, смените его:
- задайте новый `PU_MQTT_PORT` в файле настроек
- в `docker-compose.yml` в секции `emqx.ports` замените `"1883:1883"`, например на `"1885:1883"`

Затем выполните `python3 make_env.py` и `docker compose up -d`.
:::

## Первый запуск

```bash
docker compose up -d
```

Первый запуск скачивает образы и занимает несколько минут. Ход запуска [Backend](/deployment/dependencies/backend) виден в логах:
```bash
docker logs -f backend
```

Запуск завершён, когда в логе появилась строка `Application startup complete` и логотип Pepeunit с версией.

:::warning
Найдите в логе строку с `SUBACK`:

```json
{"asctime": "2026-11-10 04:55:01,223", "levelname": "INFO", "name": "gmqtt.client", "message": "[SUBACK] 1 (0,)", "funcName": "_handle_suback_packet"}
```

Она показывает, подписался ли [Backend](/deployment/dependencies/backend) на основной MQTT топик. Если в скобках `(135,)` вместо `(0,)`, подписка не удалась. Проверьте:
1. Открыт ли порт `1883` на роутере, хостинге и в файрволе
1. Совпадает ли `PU_MQTT_PORT` с портом `emqx` в `docker-compose.yml`
1. Открывается ли `PU_MQTT_HOST` из контейнера `backend` (`127.0.0.1` не подойдёт)
1. Указывают ли `PU_MQTT_REDIS_AUTH_URL` и `PU_REDIS_URL` на один и тот же [Redis](/deployment/dependencies/redis)
:::

Версию сервера можно узнать без авторизации:
```bash
curl http://127.0.0.1:5291/pepeunit/api/v1/instances/current
```

## Регистрация и Owner

Откройте `PU_DOMAIN` в браузере, веб-клиент сам подключится к инстансу.

Паролей в Pepeunit нет: аккаунт - это пара ключей. Откройте `Аккаунт` → `Регистрация`, клиент создаст ключи и зарегистрирует аккаунт. Сохраните приватный ключ: по нему вы входите, без него доступ потеряется.

Первый пользователь владельцем **не** становится: роль `Owner` назначает администратор сервера. Найдите `uuid` своего аккаунта (`POSTGRES_USER` и `POSTGRES_DB` смотрите в `.env`):
```bash
docker exec -it postgres psql -U <POSTGRES_USER> -d <POSTGRES_DB> -c "SELECT uuid, login FROM users;"
```

Назначьте владельца:
```bash
docker exec -it backend python scripts/set_owner.py <uuid>
```

`Owner` в инстансе один: если выполнить команду с другим `uuid`, прежний владелец станет обычным [Пользователем](/development-pepeunit/mechanics/roles#user).

`Owner` назначает [Администраторов](/development-pepeunit/mechanics/roles#admin) и меняет настройки: `Сеть` → избранный инстанс → `Настройки`. Дальше настройте инстанс: [Настройки инстанса](/deployment/instance-settings).
