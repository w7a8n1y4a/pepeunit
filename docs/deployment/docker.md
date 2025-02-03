# Docker Compose

## Установка Docker и Docker Compose

:::info
Пример для `debian 12`, подойдёт почти для всех `Linux`.
:::

:::warning
Если сомневаетесь, спросите для вашей платформы у доступной вам `LLM` следующий промт:

```text
Напиши гайд как установить docker и docker compose на машину <Название дистрибутива>
```
:::

## Установка Docker

Данный набор команд позволит установить `Docker` в систему для пользователя `root`:
```bash
sudo su
curl -fsSL https://get.docker.com -o get-docker.sh
sh ./get-docker.sh
```

Проверьте работу `Docker`:

```bash
docker --version
docker run hello-world
```

Если права для использования команды `docker` нужно предоставить другому пользователю - можно воспользоваться командой, выполнять нужно из консоли пользоватля `root`:
```bash
sudo usermod -aG docker <user-name>
```

Установите `docker` в автозапуск:

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

## Устновка Docker Compose

```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

Проверьте установку Docker Compose:
```bash
docker-compose --version
```

## Установка Pepeunit через Docker Compose

## Скачивание репозитория Pepeunit Deploy

```bash
git clone https://git.pepemoss.com/pepe/pepeunit/pepeunit_deploy.git
cd pepeunit_deploy
```

## Заполняем первичный .env файл

На выбор есть два варианта установки:
1. Для локального использования на основе `.env.local.example`
1. Для глобавльно использования на основе `.env.global.example`

Отличие состоит в том, что локальный рассчитан на эксплуатацию в локальной сети, а глобальный позволяет обращаться к Pepeunit инстасу по доменному имени через https.

Выберите один из файлов и уберите у него приставу `.example`
- `.env.local.example` -> `.env.local`
- `.env.global.example` -> `.env.global`

Например командой:
```bash
mv .env.local.example .env.local
```

В файлах `.env.local` и `.env.global` используется уменьшенное число переменных окружения, т.к. на его основе генирируются файлы для всех docker compose сервисов:

Переменная | Пример для `.env.local` | Пример для `.env.global` | Зачем нужна?
-- | -- | -- | --
POSTGRES_USER | `pepeunit-admin` | `pepeunit-admin` | Имя пользователя, от имени которого будет создана база данных
POSTGRES_PASSWORD | `f6prBUMbhvNnlLZ0f0HN` | `f6prBUMbhvNnlLZ0f0HN` | Пароль пользователя, от имени которого будет создана база данных
POSTGRES_DB | `pepeunit-db` | `pepeunit-db` | Название базы данных
BACKEND_DOMAIN | `192.168.0.22` | `unit.pepeunit.com` | Доменное имя от инстанса Pepeunit
BACKEND_SECURE | `False` | - | Выбирает `http` или `https` для `BACKEND_DOMAIN` инстанса Pepeunit, по умолчанию `https`
TELEGRAM_TOKEN | `1111111111:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA` | `1111111111:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA` | Токен `Telegram Bot` можно получить у [Bot Father](https://t.me/BotFather)
TELEGRAM_BOT_LINK | `https://t.me/PepeUnitRobot` | `https://t.me/PepeUnitRobot` | Ccылка на бота, которого вы создаёте в [Bot Father](https://t.me/BotFather)
MQTT_HOST | `192.168.0.22` | `emqx.pepeunit.com` | Доменное имя от инстанса EMQX MQTT Broker
MQTT_SECURE | `False` | - | Выбирает `http` или `https` для `MQTT_HOST` инстанса Pepeunit, по умолчанию `https`
MQTT_USERNAME | `YabJTlmvQ4tvweuTl0gn` | `YabJTlmvQ4tvweuTl0gn` | Имя администратора EMQX MQTT Broker
MQTT_PASSWORD | `F2qvym9lxL0DK6DlhmN1HgczWe9lKj30BvJTyvHu` | `F2qvym9lxL0DK6DlhmN1HgczWe9lKj30BvJTyvHu` | Пароль администратора EMQX MQTT Broker

## Генерация env/.env.service

Выполните команду генерирующую итоговые `.env.service` файлы в дирректории `env/.env.service`:
```bash
$> python3 make_env.py
2025-02-03 04:35:32,123 - INFO - Run make envs
2025-02-03 04:35:32,123 - INFO - Run search .env.local or .env.global
2025-02-03 04:35:32,123 - INFO - The .env.local file was found
2025-02-03 04:35:32,123 - INFO - Load variables from .env.local
2025-02-03 04:35:32,123 - INFO - Generate .env.emqx
2025-02-03 04:35:32,123 - INFO - Save env/.env.emqx
2025-02-03 04:35:32,123 - INFO - Generate .env.postgres
2025-02-03 04:35:32,124 - INFO - Save env/.env.postgres
2025-02-03 04:35:32,124 - INFO - Generate .env.frontend
2025-02-03 04:35:32,124 - INFO - Save env/.env.frontend
2025-02-03 04:35:32,124 - INFO - Generate .env.backend
2025-02-03 04:35:32,124 - INFO - Save env/.env.backend
2025-02-03 04:35:32,124 - INFO - Environment file generation is complete
```

:::danger
Вам может потребоваться внести изменения в конфигурацию отдельных сервисов для тонкой настройки. [Подробнее о переменных окружения Backend и Frontend](/deployment/env-variables)
:::

## Настройка Nginx

Найдите файл `data/nginx/nginx.conf`, измените `192.168.0.22` в `service_name` на локальный `ip` адрес вашей машины. Адресс можно узнать командой:
```bash
ip a
```

:::danger
[Подробная настройка nginx для https и reverse proxy](/deployment/nginx)
:::

## Открытие портов

Для корректной работы Pepeunit, нужно открыть следующие порты:
1. `80` - для работы по `http`
1. `443` - для работы по `https`
1. `1883` - для работы по протоколу MQTT

:::danger
Если у вас публичный инстанс Pepeunit с доменом - вам потребуется прокинуть данные порты наружу
:::

## Первый запуск

Настройте доступ для `volumes`:
```bash
sudo chmod 777 -R data
```

Выполните команду запуска Pepeunit:
```bash
docker compose up
```

:::info
Пример корреткного запуска Backend на основе конфига `.env.local`. Для `.env.global` будут отличаться только `ip` адреса и установка `webhook` для `Telegram Bot`:
```bash
backend | INFO 2025-02-03 10:16:30.936: fastapi_mqtt.handlers:on_message: on_message handler accepted
backend | INFO 2025-02-03 10:16:31.215: app.configs.emqx:__init__: Check state EMQX Broker http://192.168.0.6:18083
backend | INFO 2025-02-03 10:16:31.339: httpx._client:_send_single_request: HTTP Request: GET http://192.168.0.6:18083/api-docs/swagger.json "HTTP/1.1 200 OK"
backend | INFO 2025-02-03 10:16:32.344: app.configs.emqx:__init__: EMQX Broker http://192.168.0.6:18083 - Ready to work
backend | INFO 2025-02-03 10:16:32.360: httpx._client:_send_single_request: HTTP Request: POST http://192.168.0.6:18083/api/v5/login "HTTP/1.1 200 OK"
backend | INFO 2025-02-03 10:16:32.361: app.configs.emqx:delete_auth_hooks: Del file auth hook MQTT Broker
backend | INFO 2025-02-03 10:16:32.406: httpx._client:_send_single_request: HTTP Request: DELETE http://192.168.0.6:18083/api/v5/authorization/sources/file "HTTP/1.1 204 No Content"
backend | INFO 2025-02-03 10:16:32.407: app.configs.emqx:delete_auth_hooks: Del http auth hook MQTT Broker
backend | INFO 2025-02-03 10:16:32.443: httpx._client:_send_single_request: HTTP Request: DELETE http://192.168.0.6:18083/api/v5/authorization/sources/http "HTTP/1.1 204 No Content"
backend | INFO 2025-02-03 10:16:32.445: app.configs.emqx:delete_auth_hooks: Del redis auth hook MQTT Broker
backend | INFO 2025-02-03 10:16:32.488: httpx._client:_send_single_request: HTTP Request: DELETE http://192.168.0.6:18083/api/v5/authorization/sources/redis "HTTP/1.1 204 No Content"
backend | INFO 2025-02-03 10:16:32.489: app.configs.emqx:set_file_auth_hook: Set ACL file auth hook MQTT Broker
backend | INFO 2025-02-03 10:16:32.532: httpx._client:_send_single_request: HTTP Request: POST http://192.168.0.6:18083/api/v5/authorization/sources "HTTP/1.1 204 No Content"
backend | INFO 2025-02-03 10:16:32.533: app.configs.emqx:set_http_auth_hook: Set http auth hook MQTT Broker
backend | INFO 2025-02-03 10:16:32.683: httpx._client:_send_single_request: HTTP Request: POST http://192.168.0.6:18083/api/v5/authorization/sources "HTTP/1.1 204 No Content"
backend | INFO 2025-02-03 10:16:32.684: app.configs.emqx:set_redis_auth_hook: Set redis auth hook MQTT Broker
backend | INFO 2025-02-03 10:16:32.831: httpx._client:_send_single_request: HTTP Request: POST http://192.168.0.6:18083/api/v5/authorization/sources "HTTP/1.1 204 No Content"
backend | INFO 2025-02-03 10:16:32.833: app.configs.emqx:set_auth_cache_ttl: Set cache settings auth hook MQTT Broker
backend | INFO 2025-02-03 10:16:33.217: httpx._client:_send_single_request: HTTP Request: PUT http://192.168.0.6:18083/api/v5/authorization/settings "HTTP/1.1 200 OK"
backend | INFO 2025-02-03 10:16:33.246: app.main:_lifespan: Get current TG bot webhook info
backend | INFO 2025-02-03 10:16:33.246: app.main:run_polling_bot: Delete webhook before run polling
backend | INFO 2025-02-03 10:16:33.248: app.main:run_mqtt_client: Connect to mqtt server: 192.168.0.6:1883
backend | INFO 2025-02-03 10:16:33.249: gmqtt.mqtt.protocol:connection_made: [CONNECTION MADE]
backend | INFO 2025-02-03 10:16:33.252: gmqtt.mqtt.package:build_package: [SEND SUB] 1 [b'192.168.0.6/+/+/+/pepeunit']
backend | INFO 2025-02-03 10:16:33.253: gmqtt.mqtt.package:build_package: [SEND SUB] 2 [b'192.168.0.6/+/pepeunit']
backend | INFO 2025-02-03 10:16:33.265: app.services.repo_service:sync_local_repo_storage: run sync local repo storage
backend | INFO 2025-02-03 10:16:33.330: app.services.repo_service:sync_local_repo_storage: end sync local repo storage
backend | INFO 2025-02-03 10:16:33.333: gmqtt.mqtt.handler:_handle_suback_packet: [SUBACK] 1 (0,)
backend | INFO 2025-02-03 10:16:33.334: gmqtt.mqtt.handler:_handle_suback_packet: [SUBACK] 2 (0,)
backend | INFO 2025-02-03 10:16:33.548: app.main:run_polling_bot: Run polling
backend | INFO 2025-02-03 10:16:33.549: aiogram.dispatcher.dispatcher:start_polling: Start polling
backend | INFO 2025-02-03 10:16:33.622: aiogram.dispatcher.dispatcher:_polling: Run polling for bot @PepeUnitDevRobot id=8192216998 - 'PepeUnitDevRobot'
```
:::

:::warning
Стоит обратить особое внимание на строчки:

```bash
gmqtt.mqtt.handler:_handle_suback_packet: [SUBACK] 1 (0,)
gmqtt.mqtt.handler:_handle_suback_packet: [SUBACK] 2 (0,)
```

Они отображают смог ли Backend подписаться на топики `192.168.0.6/+/+/+/pepeunit` и `192.168.0.6/+/pepeunit`. Если в скобках будет указано `(135,)` вместо `(0,)`, то Backend `не смог` подписаться на основные топики. Обычно это связано со следующими нюансами:
1. Закрытым портом `1883`
1. Настройкой портов сервиса `emqx` в `docker-compose.yml`, вы могли указать другой порт, и не открыли его
1. Ошибками в настройках EMQX MQTT Broker и Backend, например `MQTT_REDIS_AUTH_URL` или `REDIS_URL`. [подробнее о переменных окружения Backend Env](/deployment/env-variables#backend). Данные переменные должны смотреть строго на один и тот же инстанас Redis.
:::

## Создание Администратора

Первый созданный пользователь на инстансе Pepeunit автоматически становится Администратором. Для этого достаточно пройти стандартную форму регистрации Пользователя.

## Полезные команды для дебага

- Остановить `docker compose`
    ```bash
    docker compose down
    ```
- Запустить `docker compose` в фоновом режиме
    ```bash
    docker compose up -d
    ```
- Посмотреть логи конкретного контейнера
    ```bash
    docker logs postgres
    ```
- Зайти во внутрь контейнера, чтобы посмотреть состояние файлов и тд:
    ```bash
    docker exec -it frontend /bin/sh
    docker exec -it backend /bin/bash
    docker exec -it emqx /bin/bash
    docker exec -it postgres /bin/bash
    docker exec -it redis /bin/bash
    docker exec -it nginx /bin/bash
    ```
- Зайти в консоль базы данных, `POSTGRES_USER` и `POSTGRES_DB` можно найти в `env/.env.postgres`
    ```bash
    docker exec -it postgres psql -U <POSTGRES_USER> -d <POSTGRES_DB>
    psql -U <POSTGRES_USER> -d <POSTGRES_DB>
    ```
