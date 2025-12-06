# Развёртывание
## Pepeunit Deploy

`Pepeunit Deploy` хранит в себе все файлы и примеры, нужные для запуска инстанса [Pepeunit](/conception/overview) при помощи `docker compose`. Для клонирования репозиторий выполните команды:
```bash
git clone https://git.pepemoss.com/pepe/pepeunit/pepeunit_deploy.git
cd pepeunit_deploy
```

## Заполнение первичного .env файла

На выбор есть два варианта установки:
1. Для локального использования - `.env.local.example`
1. Для глобального использования - `.env.global.example`

Отличие состоит в том, что локальный вариант рассчитан на эксплуатацию в локальной сети, а глобальный позволяет обращаться к инстансу [Pepeunit](/conception/overview) по доменному имени через `https`.

Выберите один из файлов и уберите у него приставку `.example`
- `.env.local.example` -> `.env.local`
- `.env.global.example` -> `.env.global`

Например, командой:
```bash
mv .env.local.example .env.local
```

В файлах `.env.local` и `.env.global` используется уменьшенное число переменных окружения, т.к. на его основе генирируются файлы для всех `docker compose` сервисов:

Переменная | Пример для `.env.local` | Пример для `.env.global` | Зачем нужна?
-- | -- | -- | --
`POSTGRES_USER` | `pepeunit-admin` | `pepeunit-admin` | Имя пользователя, от имени которого будет создана база данных
`POSTGRES_PASSWORD` | `f6prBUMbhvNnlLZ0f0HN` | `f6prBUMbhvNnlLZ0f0HN` | Пароль пользователя, от имени которого будет создана база данных
`POSTGRES_DB` | `pepeunit-db` | `pepeunit-db` | Название базы данных
`CLICKHOUSE_USER` | `pepeunit-admin` | `pepeunit-admin` | Имя пользователя, от имени которого будет создана база данных
`CLICKHOUSE_PASSWORD` | `f6prBUMbhvNnlLZ0f0HN` | `f6prBUMbhvNnlLZ0f0HN` | Пароль пользователя, от имени которого будет создана база данных
`CLICKHOUSE_DB` | `default` | `default` | Название базы данных
`PU_DOMAIN` | `192.168.0.22` | `unit.pepeunit.com` | Доменное имя от инстанса [Pepeunit](/conception/overview)
`PU_SECURE` | `False` | - | Выбирает `http` или `https` для `BACKEND_DOMAIN` инстанса [Pepeunit](/conception/overview), по умолчанию `https`
`PU_TELEGRAM_TOKEN `| `1111111111:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA` | `1111111111:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA` | Токен [Telegram Bot](/definitions#telegram-bot), можно получить у [Bot Father](https://t.me/BotFather)
`PU_TELEGRAM_BOT_LINK` | `https://t.me/PepeUnitRobot` | `https://t.me/PepeUnitRobot` | Ccылка на [Telegram Bot](/definitions#telegram-bot), которого вы создаёте в [Bot Father](https://t.me/BotFather)
`PU_MQTT_HOST` | `192.168.0.22` | `emqx.pepeunit.com` | Доменное имя от инстансa [EMQX](/deployment/dependencies/emqx). Для локального использования, убедитесь, что адрес будет доступен из контейнеров, `127.0.0.1` скорее всего работать не будет
`PU_MQTT_SECURE` | `False` | - | Выбирает `http` или `https` для `MQTT_HOST` инстансa [Pepeunit](/conception/overview), по умолчанию `https`
`PU_MQTT_PORT` | `1883` | `1883` | [MQTT](/definitions#mqtt) порт для [EMQX](/deployment/dependencies/emqx)
`PU_MQTT_USERNAME` | `YabJTlmvQ4tvweuTl0gn` | `YabJTlmvQ4tvweuTl0gn` | Имя администратора [EMQX](/deployment/dependencies/emqx)
`PU_MQTT_PASSWORD` | `F2qvym9lxL0DK6DlhmN1HgczWe9lKj30BvJTyvHu` | `F2qvym9lxL0DK6DlhmN1HgczWe9lKj30BvJTyvHu` | Пароль администратора [EMQX](/deployment/dependencies/emqx)
`GF_USER` | `admin` | `admin` | Логин админа для [Grafana](/deployment/dependencies/grafana)
`GF_PASSWORD` | `aN4bzmwMjB0v69LPvxpLLJ7LHXTe6hlqZ703mVmB` | `aN4bzmwMjB0v69LPvxpLLJ7LHXTe6hlqZ703mVmB` | Пароль админа для [Grafana](/deployment/dependencies/grafana)

## Генерация env/.env.service

Выполните команду генерирующую итоговые `.env.service` файлы в дирректории `env/.env.service`:
```bash
$> python make_env.py
2025-09-16 00:51:44,693 - INFO - Run make envs
2025-09-16 00:51:44,693 - INFO - Run search .env.local or .env.global
2025-09-16 00:51:44,693 - INFO - The .env.global file was found
2025-09-16 00:51:44,693 - INFO - Load variables from .env.global
2025-09-16 00:51:44,694 - INFO - Generate .env.emqx
2025-09-16 00:51:44,694 - INFO - Save env/.env.emqx
2025-09-16 00:51:44,694 - INFO - Generate .env.postgres
2025-09-16 00:51:44,694 - INFO - Save env/.env.postgres
2025-09-16 00:51:44,694 - INFO - Generate .env.frontend
2025-09-16 00:51:44,694 - INFO - Save env/.env.frontend
2025-09-16 00:51:44,694 - INFO - Generate .env.backend
2025-09-16 00:51:44,694 - INFO - Existing .env.backend found, loading sensitive keys
2025-09-16 00:51:44,695 - INFO - Load variables from env/.env.backend
2025-09-16 00:51:44,695 - INFO - Save env/.env.backend
2025-09-16 00:51:44,695 - INFO - Generate .env.grafana
2025-09-16 00:51:44,695 - INFO - Save env/.env.grafana
2025-09-16 00:51:44,695 - INFO - Generate .env.clickhouse
2025-09-16 00:51:44,695 - INFO - Save env/.env.clickhouse
2025-09-16 00:51:44,696 - INFO - Generate .env.backend_data_pipe
2025-09-16 00:51:44,696 - INFO - Existing .env.backend found, loading sensitive keys
2025-09-16 00:51:44,696 - INFO - Load variables from env/.env.backend
2025-09-16 00:51:44,696 - INFO - Save env/.env.backend_data_pipe
2025-09-16 00:51:44,696 - INFO - Generate grafana.ini
2025-09-16 00:51:44,696 - INFO - Environment file generation is complete
```

:::danger
Команда `python3 make_env.py` каждый раз перегенерирует конфиги. При перегенерации существующие секретные `32-битные ключи` не измененяются. Используйте команды [создания backup](/deployment/docker/backup-update#работа-с-бэкапами), для сохранения старой конфигурации.
:::

:::danger
Вам может потребоваться внести изменения в конфигурацию отдельных сервисов для тонкой настройки. [Подробнее о переменных окружения Backend, Backend Data Pipe и Frontend](/deployment/env-variables/backend)
:::

## Настройка Nginx

Обычно, настройка [Nginx](/deployment/dependencies/nginx) для `docker compose` не требуется, но если ваш инстанс [Pepeunit](/conception/overview) будет находиться за ещё одним [Nginx](/deployment/dependencies/nginx), изучите [примеры конфигов Nginx для https и reverse proxy](/deployment/nginx)

## Открытие портов

Для корректной работы [Pepeunit](/conception/overview) нужно открыть следующие порты:
1. `80` - для работы по `http`
1. `443` - для работы по `https`
1. `1883` - для работы по протоколу [MQTT](/definitions#mqtt)

:::warning
Если ваш порт `1883` занят другими приложениями, измените его на другой и внесите изменения в [ENV переменные Backend](/deployment/env-variables/backend) - `PU_MQTT_PORT`, а также в `docker-compose.yml` в секцию `emqx.ports`, значение `- "1883:1883"` вам нужно будет заменить, например, на `- "1885:1883"`.
:::
:::danger
Если у вас публичный инстанс [Pepeunit](/conception/overview) с доменом - вам потребуется открыть указанные порты.
:::

## Первый запуск

Настройте доступ для конфигураций из дирректории `data`:
```bash
sudo chmod 777 -R data
```

Выполните команду запуска [Pepeunit](/conception/overview):
```bash
docker compose up -d
```

:::info
Пример корреткного запуска [Backend](/deployment/dependencies/backend) на основе конфига `.env.global`. Для `.env.local` будут отличаться только `ip` адреса и установка `pooling` для [Telegram Bot](/definitions#telegram-bot):
```bash
$> docker logs -f backend
Wait Ready PostgreSQL...
postgres:5432 - accepting connections
PostgreSQL available.
Wait check DB 'pepeunit'...
DB 'pepeunit' Exist.
Fix collation postgres for swap version containers
NOTICE:  version has not changed
ALTER DATABASE
Collation fixed.
Run migration...
{"asctime": "2025-12-06 11:51:13,514", "levelname": "INFO", "name": "alembic.runtime.migration", "message": "Context impl PostgresqlImpl."}
{"asctime": "2025-12-06 11:51:13,514", "levelname": "INFO", "name": "alembic.runtime.migration", "message": "Will assume transactional DDL."}
Del old lock files
{"time": "2025-12-06 11:51:16,012", "level": "INFO", "logger": "gunicorn.error", "message": "Starting gunicorn 23.0.0", "funcName": "info"}
{"time": "2025-12-06 11:51:16,013", "level": "INFO", "logger": "gunicorn.error", "message": "Listening at: http://0.0.0.0:5000 (28)", "funcName": "info"}
{"time": "2025-12-06 11:51:16,014", "level": "INFO", "logger": "gunicorn.error", "message": "Using worker: uvicorn.workers.UvicornWorker", "funcName": "info"}
{"time": "2025-12-06 11:51:16,017", "level": "INFO", "logger": "gunicorn.error", "message": "Booting worker with pid: 29", "funcName": "info"}
{"time": "2025-12-06 11:51:16,088", "level": "INFO", "logger": "gunicorn.error", "message": "Booting worker with pid: 30", "funcName": "info"}
{"time": "2025-12-06 11:51:22,533", "level": "INFO", "logger": "uvicorn.error", "message": "on_connect handler accepted", "funcName": "on_connect"}
{"time": "2025-12-06 11:51:22,533", "level": "INFO", "logger": "uvicorn.error", "message": "on_message handler accepted", "funcName": "on_message"}
{"time": "2025-12-06 11:51:22,534", "level": "INFO", "logger": "uvicorn.error", "message": "on_connect handler accepted", "funcName": "on_connect"}
{"time": "2025-12-06 11:51:22,534", "level": "INFO", "logger": "uvicorn.error", "message": "on_message handler accepted", "funcName": "on_message"}
{"time": "2025-12-06 11:51:22,827", "level": "INFO", "logger": "uvicorn.error", "message": "Started server process [29]", "funcName": "_serve", "color_message": "Started server process [\u001b[36m%d\u001b[0m]"}
{"time": "2025-12-06 11:51:22,827", "level": "INFO", "logger": "uvicorn.error", "message": "Waiting for application startup.", "funcName": "startup"}
{"time": "2025-12-06 11:51:22,844", "level": "INFO", "logger": "uvicorn.error", "message": "Started server process [30]", "funcName": "_serve", "color_message": "Started server process [\u001b[36m%d\u001b[0m]"}
{"time": "2025-12-06 11:51:22,844", "level": "INFO", "logger": "uvicorn.error", "message": "Waiting for application startup.", "funcName": "startup"}
{"time": "2025-12-06 11:51:22,856", "level": "INFO", "logger": "root", "message": "Total migrations to apply: 0", "funcName": "apply_migration"}
{"time": "2025-12-06 11:51:22,856", "level": "INFO", "logger": "root", "message": "Check state EMQX Broker https://dcemqx.pepemoss.com", "funcName": "__init__"}
{"time": "2025-12-06 11:51:23,650", "level": "INFO", "logger": "httpx", "message": "HTTP Request: GET https://dcemqx.pepemoss.com/api-docs/swagger.json \"HTTP/1.1 200 OK\"", "funcName": "_send_single_request"}
{"time": "2025-12-06 11:51:25,405", "level": "INFO", "logger": "root", "message": "EMQX Broker https://dcemqx.pepemoss.com - Ready to work", "funcName": "__init__"}
{"time": "2025-12-06 11:51:25,802", "level": "INFO", "logger": "httpx", "message": "HTTP Request: POST https://dcemqx.pepemoss.com/api/v5/login \"HTTP/1.1 200 OK\"", "funcName": "_send_single_request"}
{"time": "2025-12-06 11:51:25,803", "level": "INFO", "logger": "root", "message": "Del file auth hook MQTT Broker", "funcName": "delete_auth_hooks"}
{"time": "2025-12-06 11:51:26,266", "level": "INFO", "logger": "httpx", "message": "HTTP Request: DELETE https://dcemqx.pepemoss.com/api/v5/authorization/sources/file \"HTTP/1.1 204 No Content\"", "funcName": "_send_single_request"}
{"time": "2025-12-06 11:51:26,268", "level": "INFO", "logger": "root", "message": "Del http auth hook MQTT Broker", "funcName": "delete_auth_hooks"}
{"time": "2025-12-06 11:51:26,679", "level": "INFO", "logger": "httpx", "message": "HTTP Request: DELETE https://dcemqx.pepemoss.com/api/v5/authorization/sources/http \"HTTP/1.1 204 No Content\"", "funcName": "_send_single_request"}
{"time": "2025-12-06 11:51:26,681", "level": "INFO", "logger": "root", "message": "Del redis auth hook MQTT Broker", "funcName": "delete_auth_hooks"}
{"time": "2025-12-06 11:51:27,092", "level": "INFO", "logger": "httpx", "message": "HTTP Request: DELETE https://dcemqx.pepemoss.com/api/v5/authorization/sources/redis \"HTTP/1.1 204 No Content\"", "funcName": "_send_single_request"}
{"time": "2025-12-06 11:51:27,095", "level": "INFO", "logger": "root", "message": "Set ACL file auth hook MQTT Broker", "funcName": "set_file_auth_hook"}
{"time": "2025-12-06 11:51:27,487", "level": "INFO", "logger": "httpx", "message": "HTTP Request: POST https://dcemqx.pepemoss.com/api/v5/authorization/sources \"HTTP/1.1 204 No Content\"", "funcName": "_send_single_request"}
{"time": "2025-12-06 11:51:27,490", "level": "INFO", "logger": "root", "message": "Set http auth hook MQTT Broker", "funcName": "set_http_auth_hook"}
{"time": "2025-12-06 11:51:28,282", "level": "INFO", "logger": "httpx", "message": "HTTP Request: POST https://dcemqx.pepemoss.com/api/v5/authorization/sources \"HTTP/1.1 204 No Content\"", "funcName": "_send_single_request"}
{"time": "2025-12-06 11:51:28,284", "level": "INFO", "logger": "root", "message": "Set redis auth hook MQTT Broker", "funcName": "set_redis_auth_hook"}
{"time": "2025-12-06 11:51:28,801", "level": "INFO", "logger": "httpx", "message": "HTTP Request: POST https://dcemqx.pepemoss.com/api/v5/authorization/sources \"HTTP/1.1 204 No Content\"", "funcName": "_send_single_request"}
{"time": "2025-12-06 11:51:28,803", "level": "INFO", "logger": "root", "message": "Set cache settings auth hook MQTT Broker", "funcName": "set_auth_cache_ttl"}
{"time": "2025-12-06 11:51:29,286", "level": "INFO", "logger": "httpx", "message": "HTTP Request: PUT https://dcemqx.pepemoss.com/api/v5/authorization/settings \"HTTP/1.1 200 OK\"", "funcName": "_send_single_request"}
{"time": "2025-12-06 11:51:29,288", "level": "INFO", "logger": "root", "message": "Set settings for tcp listener", "funcName": "set_tcp_listener_settings"}
{"time": "2025-12-06 11:51:29,710", "level": "INFO", "logger": "httpx", "message": "HTTP Request: PUT https://dcemqx.pepemoss.com/api/v5/listeners/tcp:default \"HTTP/1.1 200 OK\"", "funcName": "_send_single_request"}
{"time": "2025-12-06 11:51:29,712", "level": "INFO", "logger": "root", "message": "Set global mqtt settings", "funcName": "set_global_mqtt_settings"}
{"time": "2025-12-06 11:51:30,112", "level": "INFO", "logger": "httpx", "message": "HTTP Request: PUT https://dcemqx.pepemoss.com/api/v5/configs/global_zone \"HTTP/1.1 200 OK\"", "funcName": "_send_single_request"}
{"time": "2025-12-06 11:51:30,114", "level": "INFO", "logger": "root", "message": "Disable retainer", "funcName": "set_global_mqtt_settings"}
{"time": "2025-12-06 11:51:30,257", "level": "INFO", "logger": "httpx", "message": "HTTP Request: PUT https://dcemqx.pepemoss.com/api/v5/mqtt/retainer \"HTTP/1.1 200 OK\"", "funcName": "_send_single_request"}
{"time": "2025-12-06 11:51:30,264", "level": "INFO", "logger": "root", "message": "Run sync all repository in RepositoryRegistry", "funcName": "sync_local_repository_storage"}
{"time": "2025-12-06 11:51:30,331", "level": "INFO", "logger": "root", "message": "End sync all repository in RepositoryRegistry", "funcName": "sync_local_repository_storage"}


                             ........:
                            :......::-
                             .....::.:
                             .....::.-
                        :.........::.-****
                      :........::::--==++###%
                    :::-++*++=======++*#@@%%-::
                  ....:-=---==++******###%%*-...:
                :....:--===++=*=+**%@@%@%%%%*+:..:
              :....::=====+====+==*##%@%%%#*##+=...:
            -...........:-===++*=++**#%*:....::---...:
           :......-..:*##%%*+++===+#*-.:-..+#%%%#*+:...:
         :......=..++*##%%%%#**++--=..-.--*##%%*%@#+=....-
        :..:-:.+-+=+#%%***+#@#*=---..+:=**+%@%%*%@@*+=-...:
       =--===-.%%=#*#%-.=:+@@%**==-::%%#==#@@#%@@+@%**+=:::
       =-=====.+@%%+@@%:.-#@@##***+-:%@%*%@%@%%=%@@#++::-::
       =--====-.#@@*@+@@*@@@#***#**#-:%@*%%+@=@*@@#*==-..::
       ==+*=+++=::#@@@@@@@########*#%==+%@@@@@@@#**++++*+::-
       *@*+++++++++****#####%##%###%#%%%%#########*##+==*#--
       -*@%**==+=+*#=+**###%%%%####%%##%%%%%%%#%%%#####@@%=+
    :::-=--+%%@*##*.-.*#####%%%########%%%%%%%###%%@@%*++=+****
    ....:---------==***#%%%%%*%#%%#%%%%%%%%%#*++=====+**#######%
    ....:-:::-=====-----------------------===+++***+++*#%@@%###%
    :--=:=++++====---::::---------===========++*##%@@@@@@@@@@@@@
       =--+*++++***+=+*****###########%%%%%%%%%#%%%#@@@@@@@@
         +==++++**+...:*=+=*=+==*++##++=+++#%-:-*%#%@@@@@@
            %#*****#####*##*-+-=*==#--+#**%*%%%%@@@@@@@
              *##%@@@@@@@%%%%%%%%%%%%%%@@@@@@@@@@@@@@
              *###%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                  %%@@@@@@@@@@@@@@@@@@@@@@@@@@@@
               _____                            _ _
              |  __ \                          (_) |
              | |__) |__ _ __   ___ _   _ _ __  _| |_
              |  ___/ _ \ '_ \ / _ \ | | | '_ \| | __|
              | |  |  __/ |_) |  __/ |_| | | | | | |_
              |_|   \___| .__/ \___|\__,_|_| |_|_|\__|
                        | |
                        |_|

       v1.0.0 - AGPL v3 License
       Federated IoT Platform
       Front: https://dcunit.pepeunit.com
       REST:  https://dcunit.pepeunit.com/pepeunit/docs
       GQL:   https://dcunit.pepeunit.com/pepeunit/graphql
       TG:    https://t.me/PepeUnitDevRobot
       Docs:  https://pepeunit.com

{"time": "2025-12-06 11:51:30,333", "level": "INFO", "logger": "root", "message": "Delete webhook before set new webhook", "funcName": "run_webhook_bot"}
{"time": "2025-12-06 11:51:30,333", "level": "INFO", "logger": "root", "message": "Connect to mqtt server: dcemqx.pepemoss.com:1885", "funcName": "run_mqtt_client"}
{"time": "2025-12-06 11:51:30,334", "level": "INFO", "logger": "uvicorn.error", "message": "Used broker version is 5", "funcName": "connection"}
{"time": "2025-12-06 11:51:30,335", "level": "INFO", "logger": "uvicorn.error", "message": "Application startup complete.", "funcName": "startup"}
{"time": "2025-12-06 11:51:30,343", "level": "INFO", "logger": "root", "message": "NoAccessError('403: 1: No Access: Token is invalid')", "funcName": "get_mqtt_auth"}
{"time": "2025-12-06 11:51:30,349", "level": "INFO", "logger": "uvicorn.access", "message": "GET /pepeunit/metrics 200", "funcName": "send", "client_ip": "172.20.1.12", "http_method": "GET", "http_path": "/pepeunit/metrics", "http_version": "1.1", "http_status_code": 200}
{"time": "2025-12-06 11:51:30,445", "level": "INFO", "logger": "gmqtt.mqtt.protocol", "message": "[CONNECTION MADE]", "funcName": "connection_made"}
{"time": "2025-12-06 11:51:30,724", "level": "INFO", "logger": "httpx", "message": "HTTP Request: GET https://dcunit.pepeunit.com/grafana/api/dashboards/uid/all-docker-logs/permissions \"HTTP/1.1 200 OK\"", "funcName": "_send_single_request"}
{"time": "2025-12-06 11:51:30,850", "level": "INFO", "logger": "root", "message": "Connect to mqtt server: dcemqx.pepemoss.com:1885", "funcName": "run_mqtt_client"}
{"time": "2025-12-06 11:51:30,850", "level": "INFO", "logger": "uvicorn.error", "message": "Used broker version is 5", "funcName": "connection"}
{"time": "2025-12-06 11:51:30,855", "level": "INFO", "logger": "uvicorn.error", "message": "Application startup complete.", "funcName": "startup"}
{"time": "2025-12-06 11:51:30,978", "level": "INFO", "logger": "gmqtt.mqtt.protocol", "message": "[CONNECTION MADE]", "funcName": "connection_made"}
{"time": "2025-12-06 11:51:31,193", "level": "INFO", "logger": "httpx", "message": "HTTP Request: POST https://dcunit.pepeunit.com/grafana/api/dashboards/uid/all-docker-logs/permissions \"HTTP/1.1 200 OK\"", "funcName": "_send_single_request"}
{"time": "2025-12-06 11:51:31,631", "level": "INFO", "logger": "httpx", "message": "HTTP Request: GET https://dcunit.pepeunit.com/grafana/api/dashboards/uid/backend-aggregated-logs/permissions \"HTTP/1.1 200 OK\"", "funcName": "_send_single_request"}
{"time": "2025-12-06 11:51:32,072", "level": "INFO", "logger": "httpx", "message": "HTTP Request: POST https://dcunit.pepeunit.com/grafana/api/dashboards/uid/backend-aggregated-logs/permissions \"HTTP/1.1 200 OK\"", "funcName": "_send_single_request"}
{"time": "2025-12-06 11:51:32,553", "level": "INFO", "logger": "root", "message": "MQTT subscriptions initialized in this worker", "funcName": "connect"}
{"time": "2025-12-06 11:51:32,554", "level": "INFO", "logger": "gmqtt.mqtt.package", "message": "[SEND SUB] 1 [b'dcunit.pepeunit.com/+/+/+/pepeunit']", "funcName": "build_package"}
{"time": "2025-12-06 11:51:33,087", "level": "INFO", "logger": "root", "message": "Another worker already subscribed to MQTT topics", "funcName": "connect"}
{"time": "2025-12-06 11:51:33,108", "level": "INFO", "logger": "uvicorn.access", "message": "POST /pepeunit/api/v1/bot 422", "funcName": "send", "client_ip": "172.20.1.10", "http_method": "POST", "http_path": "/pepeunit/api/v1/bot", "http_version": "1.0", "http_status_code": 422}
{"time": "2025-12-06 11:51:33,113", "level": "INFO", "logger": "uvicorn.access", "message": "POST /pepeunit/api/v1/units/auth 200", "funcName": "send", "client_ip": "172.20.1.10", "http_method": "POST", "http_path": "/pepeunit/api/v1/units/auth", "http_version": "1.0", "http_status_code": 200}
{"time": "2025-12-06 11:51:33,172", "level": "INFO", "logger": "httpx", "message": "HTTP Request: POST https://dcunit.pepeunit.com/pepeunit/api/v1/bot \"HTTP/1.1 422 Unprocessable Content\"", "funcName": "_send_single_request"}
{"time": "2025-12-06 11:51:33,179", "level": "INFO", "logger": "uvicorn.access", "message": "GET /pepeunit/metrics 200", "funcName": "send", "client_ip": "172.20.1.12", "http_method": "GET", "http_path": "/pepeunit/metrics", "http_version": "1.1", "http_status_code": 200}
{"time": "2025-12-06 11:51:33,223", "level": "INFO", "logger": "gmqtt.client", "message": "[SUBACK] 1 (0,)", "funcName": "_handle_suback_packet"}
{"time": "2025-12-06 11:51:33,249", "level": "INFO", "logger": "root", "message": "Success set TG bot webhook url", "funcName": "run_webhook_bot"}
```
:::

:::warning
Стоит обратить особое внимание на строчку:

```json
{"time": "2025-12-06 11:51:33,223", "level": "INFO", "logger": "gmqtt.client", "message": "[SUBACK] 1 (0,)", "funcName": "_handle_suback_packet"}
```

Она отображает, смог ли [Backend](/deployment/dependencies/backend) подписаться на топик `dcunit.pepeunit.com/+/+/+/pepeunit`. Если в скобках будет указано `(135,)` вместо `(0,)`, то [Backend](/deployment/dependencies/backend) `не смог` подписаться на основной топик. Обычно, это одна из ошибок конфигурирования:
1. Закрыт порт `1883` в роутере, хостинге и ли системе
1. Настройкой портов сервиса [EMQX](/deployment/dependencies/emqx) в `docker-compose.yml`, вы могли указать другой порт, и не открыли его
1. При использовании кастомного порта для [MQTT](/definitions#mqtt), требуется указать его в двух `.env` файлах: `backend` и `datapipe`
1. Ошибками в настройках [EMQX](/deployment/dependencies/emqx) и [Backend](/deployment/dependencies/backend), например `PU_MQTT_REDIS_AUTH_URL` или `PU_REDIS_URL`. [Подробнее о переменных окружения Backend Env](/deployment/env-variables/backend). Данные переменные должны смотреть строго на один и тот же инстанас [Redis](/deployment/dependencies/redis). За первичную авторизацию отвечает именно [Redis](/deployment/dependencies/redis).
:::

## Создание Администратора

Первый созданный пользователь на инстансе [Pepeunit](/conception/overview) автоматически становится [Администратором](/development-pepeunit/mechanics/roles#admin). Для этого достаточно пройти стандартную форму регистрации.
