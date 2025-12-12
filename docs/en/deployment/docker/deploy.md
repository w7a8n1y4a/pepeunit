# Deployment
## Pepeunit Deploy

The `Pepeunit Deploy` repository contains all files and examples needed to run a [Pepeunit](/en/conception/overview) instance using `docker compose`. To clone it, run:
```bash
git clone https://git.pepemoss.com/pepe/pepeunit/pepeunit_deploy.git
cd pepeunit_deploy
```

## Filling the primary .env file

You can choose between two installation options:
1. For local use – `.env.local.example`
1. For global use – `.env.global.example`

The difference is that the local option is intended for operation within a local network, while the global option allows accessing the [Pepeunit](/en/conception/overview) instance via a domain name over `https`.

Choose one file and remove the `.example` suffix:
- `.env.local.example` -> `.env.local`
- `.env.global.example` -> `.env.global`

For example, using:
```bash
mv .env.local.example .env.local
```

The `.env.local` and `.env.global` files use a reduced set of environment variables, because all `docker compose` service env files are generated from them:

Variable | Example for `.env.local` | Example for `.env.global` | Purpose
-- | -- | -- | --
`POSTGRES_USER` | `pepeunit-admin` | `pepeunit-admin` | Username under which the database will be created
`POSTGRES_PASSWORD` | `f6prBUMbhvNnlLZ0f0HN` | `f6prBUMbhvNnlLZ0f0HN` | Password for the database user
`POSTGRES_DB` | `pepeunit-db` | `pepeunit-db` | Database name
`CLICKHOUSE_USER` | `pepeunit-admin` | `pepeunit-admin` | Username under which the ClickHouse database will be created
`CLICKHOUSE_PASSWORD` | `f6prBUMbhvNnlLZ0f0HN` | `f6prBUMbhvNnlLZ0f0HN` | Password for the ClickHouse user
`CLICKHOUSE_DB` | `default` | `default` | ClickHouse database name
`PU_DOMAIN` | `192.168.0.22` | `unit.pepeunit.com` | Domain name of the [Pepeunit](/en/conception/overview) instance
`PU_SECURE` | `False` | - | Selects `http` or `https` for the `BACKEND_DOMAIN` of the [Pepeunit](/en/conception/overview) instance, `https` by default
`PU_TELEGRAM_TOKEN `| `1111111111:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA` | `1111111111:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA` | [Telegram Bot](/en/definitions#telegram-bot) token you obtain from [Bot Father](https://t.me/BotFather)
`PU_TELEGRAM_BOT_LINK` | `https://t.me/PepeUnitRobot` | `https://t.me/PepeUnitRobot` | Link to the [Telegram Bot](/en/definitions#telegram-bot) you create via [Bot Father](https://t.me/BotFather)
`PU_MQTT_HOST` | `192.168.0.22` | `emqx.pepeunit.com` | Domain name of the [EMQX](/en/deployment/dependencies/emqx) instance. For local use ensure the address is reachable from containers; `127.0.0.1` will most likely not work
`PU_MQTT_SECURE` | `False` | - | Selects `http` or `https` for `MQTT_HOST` of the [Pepeunit](/en/conception/overview) instance, `https` by default
`PU_MQTT_PORT` | `1883` | `1883` | [MQTT](/en/definitions#mqtt) port for [EMQX](/en/deployment/dependencies/emqx)
`PU_MQTT_USERNAME` | `YabJTlmvQ4tvweuTl0gn` | `YabJTlmvQ4tvweuTl0gn` | [EMQX](/en/deployment/dependencies/emqx) admin username
`PU_MQTT_PASSWORD` | `F2qvym9lxL0DK6DlhmN1HgczWe9lKj30BvJTyvHu` | `F2qvym9lxL0DK6DlhmN1HgczWe9lKj30BvJTyvHu` | [EMQX](/en/deployment/dependencies/emqx) admin password
`GF_USER` | `admin` | `admin` | [Grafana](/en/deployment/dependencies/grafana) admin login
`GF_PASSWORD` | `aN4bzmwMjB0v69LPvxpLLJ7LHXTe6hlqZ703mVmB` | `aN4bzmwMjB0v69LPvxpLLJ7LHXTe6hlqZ703mVmB` | [Grafana](/en/deployment/dependencies/grafana) admin password

## Generating env/.env.service

Run the command that generates the final `.env.service` files in the `env/.env.service` directory:
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

::::danger
The `python3 make_env.py` command re-generates configs every time. When re-generating, existing secret `32‑byte keys` are not changed. Use the [backup creation commands](/en/deployment/docker/backup-update#working-with-backups) to preserve the old configuration.
::::

::::danger
You may need to adjust configuration of individual services for fine‑tuning:

- [Backend variables](/en/deployment/env-variables/backend)
- [DataPipe variables](/en/deployment/env-variables/data-pipe)
- [Frontend variables](/en/deployment/env-variables/frontend)
- [PostgreSQL variables](/en/deployment/env-variables/postgresql)
- [ClickHouse variables](/en/deployment/env-variables/clickhouse)
- [EMQX variables](/en/deployment/env-variables/emqx)
- [Grafana variables](/en/deployment/env-variables/grafana)
::::

## Nginx configuration

Usually, you do not need to configure [Nginx](/en/deployment/dependencies/nginx) inside `docker compose`, but if your [Pepeunit](/en/conception/overview) instance is located behind an additional [Nginx](/en/deployment/dependencies/nginx), review the [Nginx configuration examples for https and reverse proxy](/en/deployment/nginx).

## Opening ports

For [Pepeunit](/en/conception/overview) to work correctly, you need to open the following ports:
1. `80` – for `http`
1. `443` – for `https`
1. `1883` – for [MQTT](/en/definitions#mqtt)

::::warning
If port `1883` is used by other applications, change it to another one and update:
- `PU_MQTT_PORT` – see [Backend ENV variables](/en/deployment/env-variables/backend)
- `PU_DP_MQTT_PORT` – see [DataPipe ENV variables](/en/deployment/env-variables/data-pipe)
- `docker-compose.yml` in the `emqx.ports` section: change `- "1883:1883"` to, for example, `- "1885:1883"`.
::::

::::danger
If you have a public [Pepeunit](/en/conception/overview) instance with a domain, you must open the ports listed above.
::::

## First run

Configure access for configurations in the `data` directory:
```bash
sudo chmod 777 -R data
```

Start [Pepeunit](/en/conception/overview):
```bash
docker compose up -d
```

::::info
An example of a correct [Backend](/en/deployment/dependencies/backend) startup based on `.env.global`. For `.env.local` only IP addresses and [Telegram Bot](/en/definitions#telegram-bot) `pooling` mode will differ:
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
        :..:-:.+-+=+#%%***+#@#*=---..+:=**+%@%%*@@*+=-...:
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
::::

::::warning
Pay special attention to the following line:

```json
{"time": "2025-12-06 11:51:33,223", "level": "INFO", "logger": "gmqtt.client", "message": "[SUBACK] 1 (0,)", "funcName": "_handle_suback_packet"}
```

It shows whether the [Backend](/en/deployment/dependencies/backend) managed to subscribe to the `dcunit.pepeunit.com/+/+/+/pepeunit` topic. If the value in parentheses is `(135,)` instead of `(0,)`, then the [Backend](/en/deployment/dependencies/backend) **failed** to subscribe to the main topic. Usually this indicates one of the following configuration errors:
1. Port `1883` is closed on the router, hosting provider, or system firewall
1. While configuring [EMQX](/en/deployment/dependencies/emqx) ports in `docker-compose.yml`, a different port was specified but not opened
1. When using a custom [MQTT](/en/definitions#mqtt) port, you must set it in two `.env` files: `backend` and `datapipe`
1. Errors in [EMQX](/en/deployment/dependencies/emqx) and [Backend](/en/deployment/dependencies/backend) configuration, such as `PU_MQTT_REDIS_AUTH_URL` or `PU_REDIS_URL`. See [Backend env variables](/en/deployment/env-variables/backend) for details. These variables must point to the same [Redis](/en/deployment/dependencies/redis) instance, because [Redis](/en/deployment/dependencies/redis) is responsible for initial authorization.
::::

## Creating an Administrator

The first user created on a [Pepeunit](/en/conception/overview) instance automatically becomes an [Administrator](/en/development-pepeunit/mechanics/roles#admin). To do this, just go through the standard registration form.

