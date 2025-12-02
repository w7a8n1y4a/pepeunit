# Развёртывание
## Pepeunit Deploy

Хранит в себе все файлы и примеры, нужные для запуска инстанса [Pepeunit](/conception/overview) при помощи `docker compose`, чтобы склонировать репозиторий выполните команды:
```bash
git clone https://git.pepemoss.com/pepe/pepeunit/pepeunit_deploy.git
cd pepeunit_deploy
```

## Заполнение первичного .env файла

На выбор есть два варианта установки:
1. Для локального использования - `.env.local.example`
1. Для глобального использования - `.env.global.example`

Отличие состоит в том, что локальный рассчитан на эксплуатацию в локальной сети, а глобальный позволяет обращаться к инстансу [Pepeunit](/conception/overview) по доменному имени через `https`.

Выберите один из файлов и уберите у него приставку `.example`
- `.env.local.example` -> `.env.local`
- `.env.global.example` -> `.env.global`

Например командой:
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
`PU_TELEGRAM_TOKEN `| `1111111111:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA` | `1111111111:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA` | Токен [Telegram Bot](/definitions#telegram-bot) можно получить у [Bot Father](https://t.me/BotFather)
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
Команда `python3 make_env.py` каждый раз перегенерирует конфиги. При перегенерации существующие секретные `32 битные ключи` не измененяются. Используйте команды [создания backup](/deployment/docker/backup-update#работа-с-бэкапами), для сохранения старой конфигурации.
:::

:::danger
Вам может потребоваться внести изменения в конфигурацию отдельных сервисов для тонкой настройки. [Подробнее о переменных окружения Backend, Backend Data Pipe и Frontend](/deployment/env-variables/backend)
:::

## Настройка Nginx

Обычно настройка [Nginx](/deployment/dependencies/nginx) для `docker compose` не требуется, но если ваш инстанс [Pepeunit](/conception/overview) будет находиться за ещё одним [Nginx](/deployment/dependencies/nginx), используйте: [Подробная настройка nginx для https и reverse proxy](/deployment/nginx)

## Открытие портов

Для корректной работы [Pepeunit](/conception/overview), нужно открыть следующие порты:
1. `80` - для работы по `http`
1. `443` - для работы по `https`
1. `1883` - для работы по протоколу [MQTT](/definitions#mqtt)

:::warning
если ваш `1883` порт занят другими приложениями, изменить его на другой и внесите изменения в [ENV переменные Backend](/deployment/env-variables/backend) - `PU_MQTT_PORT`, а также в `docker-compose.yml` в секцию `emqx.ports` - значение `- "1883:1883"` вам нужно будет заменить например на: `- "1885:1883"`
:::
:::danger
Если у вас публичный инстанс [Pepeunit](/conception/overview) с доменом - вам потребуется прокинуть данные порты наружу
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
INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
INFO  [alembic.runtime.migration] Will assume transactional DDL.
Del old lock files
[2025-09-15 22:09:28 +0000] [42] [INFO] Starting gunicorn 23.0.0
[2025-09-15 22:09:28 +0000] [42] [INFO] Listening at: http://0.0.0.0:5000 (42)
[2025-09-15 22:09:28 +0000] [42] [INFO] Using worker: uvicorn.workers.UvicornWorker
[2025-09-15 22:09:28 +0000] [43] [INFO] Booting worker with pid: 43
[2025-09-15 22:09:28 +0000] [44] [INFO] Booting worker with pid: 44
[2025-09-15 22:09:33 +0000] [44] [INFO] on_connect handler accepted
[2025-09-15 22:09:33 +0000] [44] [INFO] on_message handler accepted
[2025-09-15 22:09:33 +0000] [43] [INFO] on_connect handler accepted
[2025-09-15 22:09:33 +0000] [43] [INFO] on_message handler accepted
[2025-09-15 22:09:33 +0000] [44] [INFO] Started server process [44]
[2025-09-15 22:09:33 +0000] [44] [INFO] Waiting for application startup.
INFO - 2025-09-15 22:09:33,442 - Total migrations to apply: 0
INFO - 2025-09-15 22:09:33,443 - Check state EMQX Broker https://dcemqx.pepemoss.com
[2025-09-15 22:09:33 +0000] [43] [INFO] Started server process [43]
[2025-09-15 22:09:33 +0000] [43] [INFO] Waiting for application startup.
INFO - 2025-09-15 22:09:33,671 - HTTP Request: GET https://dcemqx.pepemoss.com/api-docs/swagger.json "HTTP/1.1 200 OK"
INFO - 2025-09-15 22:09:34,803 - EMQX Broker https://dcemqx.pepemoss.com - Ready to work
INFO - 2025-09-15 22:09:34,850 - HTTP Request: POST https://dcemqx.pepemoss.com/api/v5/login "HTTP/1.1 200 OK"
INFO - 2025-09-15 22:09:34,851 - Del file auth hook MQTT Broker
INFO - 2025-09-15 22:09:34,923 - HTTP Request: DELETE https://dcemqx.pepemoss.com/api/v5/authorization/sources/file "HTTP/1.1 204 No Content"
INFO - 2025-09-15 22:09:34,923 - Del http auth hook MQTT Broker
INFO - 2025-09-15 22:09:34,987 - HTTP Request: DELETE https://dcemqx.pepemoss.com/api/v5/authorization/sources/http "HTTP/1.1 204 No Content"
INFO - 2025-09-15 22:09:34,988 - Del redis auth hook MQTT Broker
INFO - 2025-09-15 22:09:35,057 - HTTP Request: DELETE https://dcemqx.pepemoss.com/api/v5/authorization/sources/redis "HTTP/1.1 204 No Content"
INFO - 2025-09-15 22:09:35,058 - Set ACL file auth hook MQTT Broker
INFO - 2025-09-15 22:09:35,100 - HTTP Request: POST https://dcemqx.pepemoss.com/api/v5/authorization/sources "HTTP/1.1 204 No Content"
INFO - 2025-09-15 22:09:35,101 - Set http auth hook MQTT Broker
INFO - 2025-09-15 22:09:35,315 - HTTP Request: POST https://dcemqx.pepemoss.com/api/v5/authorization/sources "HTTP/1.1 204 No Content"
INFO - 2025-09-15 22:09:35,315 - Set redis auth hook MQTT Broker
INFO - 2025-09-15 22:09:35,492 - HTTP Request: POST https://dcemqx.pepemoss.com/api/v5/authorization/sources "HTTP/1.1 204 No Content"
INFO - 2025-09-15 22:09:35,492 - Set cache settings auth hook MQTT Broker
INFO - 2025-09-15 22:09:35,608 - HTTP Request: PUT https://dcemqx.pepemoss.com/api/v5/authorization/settings "HTTP/1.1 200 OK"
INFO - 2025-09-15 22:09:35,609 - Set settings for tcp listener
INFO - 2025-09-15 22:09:35,705 - HTTP Request: PUT https://dcemqx.pepemoss.com/api/v5/listeners/tcp:default "HTTP/1.1 200 OK"
INFO - 2025-09-15 22:09:35,706 - Set global mqtt settings
INFO - 2025-09-15 22:09:35,749 - HTTP Request: PUT https://dcemqx.pepemoss.com/api/v5/configs/global_zone "HTTP/1.1 200 OK"
INFO - 2025-09-15 22:09:35,750 - Disable retainer
INFO - 2025-09-15 22:09:35,803 - HTTP Request: PUT https://dcemqx.pepemoss.com/api/v5/mqtt/retainer "HTTP/1.1 200 OK"
INFO - 2025-09-15 22:09:35,810 - Run sync all repository in RepositoryRegistry
INFO - 2025-09-15 22:09:35,871 - End sync all repository in RepositoryRegistry
INFO - 2025-09-15 22:09:35,872 - 
            
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
                   
     v0.9.0 - AGPL v3 License
     Federated IoT Platform
     Front: https://dcunit.pepeunit.com
     REST:  https://dcunit.pepeunit.com/pepeunit/docs
     GQL:   https://dcunit.pepeunit.com/pepeunit/graphql
     TG:    https://t.me/PepeUnitDevRobot
     Docs:  https://pepeunit.com
            
INFO - 2025-09-15 22:09:35,872 - Delete webhook before set new webhook
INFO - 2025-09-15 22:09:35,873 - Connect to mqtt server: dcemqx.pepemoss.com:1885
[2025-09-15 22:09:35 +0000] [44] [INFO] Used broker version is 5
INFO - 2025-09-15 22:09:35,878 - [CONNECTION MADE]
INFO - 2025-09-15 22:09:36,537 - Connect to mqtt server: dcemqx.pepemoss.com:1885
[2025-09-15 22:09:36 +0000] [43] [INFO] Used broker version is 5
INFO - 2025-09-15 22:09:36,543 - [CONNECTION MADE]
INFO - 2025-09-15 22:09:37,882 - MQTT subscriptions initialized in this worker
INFO - 2025-09-15 22:09:37,882 - [SEND SUB] 1 [b'dcunit.pepeunit.com/+/+/+/pepeunit']
INFO - 2025-09-15 22:09:37,884 - [SUBACK] 1 (0,)
[2025-09-15 22:09:37 +0000] [44] [INFO] Application startup complete.
172.20.1.13:38050 - "POST /pepeunit/api/v1/units/auth HTTP/1.0" 200
172.20.1.11:35616 - "GET /pepeunit/metrics HTTP/1.1" 200
INFO - 2025-09-15 22:09:38,548 - Another worker already subscribed to MQTT topics
[2025-09-15 22:09:38 +0000] [43] [INFO] Application startup complete.
172.20.1.13:38058 - "POST /pepeunit/api/v1/bot HTTP/1.0" 422
INFO - 2025-09-15 22:09:38,569 - HTTP Request: POST https://dcunit.pepeunit.com/pepeunit/api/v1/bot "HTTP/1.1 422 Unprocessable Entity"
INFO - 2025-09-15 22:09:38,640 - Success set TG bot webhook url
```
:::

:::warning
Стоит обратить особое внимание на строчку:

```bash
INFO - 2025-03-14 01:11:53,249 - [SUBACK] 1 (0,)
```

Она отображает смог ли [Backend](/deployment/dependencies/backend) подписаться на топик `dcunit.pepeunit.com/+/+/+/pepeunit`. Если в скобках будет указано `(135,)` вместо `(0,)`, то [Backend](/deployment/dependencies/backend) `не смог` подписаться на основной топик. Обычно это одна из ошибок конфигурирования:
1. Закрытым портом `1883`
1. Настройкой портов сервиса [EMQX](/deployment/dependencies/emqx) в `docker-compose.yml`, вы могли указать другой порт, и не открыли его
1. При использовании кастомного порта для [MQTT](/definitions#mqtt), требуется указать его в двух `.env` файлах: `backend` и `datapipe`
1. Ошибками в настройках [EMQX](/deployment/dependencies/emqx) и [Backend](/deployment/dependencies/backend), например `PU_MQTT_REDIS_AUTH_URL` или `PU_REDIS_URL`. [Подробнее о переменных окружения Backend Env](/deployment/env-variables/backend). Данные переменные должны смотреть строго на один и тот же инстанас [Redis](/deployment/dependencies/redis). За первичную авторизацию отвечает именно [Redis](/deployment/dependencies/redis).
:::

## Создание Администратора

Первый созданный пользователь на инстансе [Pepeunit](/conception/overview) автоматически становится [Администратором](/development-pepeunit/mechanics/roles#admin). Для этого достаточно пройти стандартную форму регистрации.