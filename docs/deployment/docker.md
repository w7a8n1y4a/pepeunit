# Docker Compose установка Pepeunit

:::info
Данное руководство для `debian 12`, но подойдёт почти для всех `unix` систем.
:::

:::warning
Если сомневаетесь, спросите для вашей платформы у доступной вам `LLM`, следующий промт:

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

Проверьте установку `Docker`:

```bash
docker --version
docker run hello-world
```

Если права для использования команды `docker` нужно предоставить другому пользователю - можно воспользоваться командой:
```bash
sudo su
sudo usermod -aG docker <user-name>
```

Установите `docker` в автозапуск:

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

## Установка Docker Compose

Выполните команды:
```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

Проверьте установку `Docker Compose`:
```bash
docker-compose --version
```

## Репозиторий Pepeunit Deploy

Хранит в себе все файлы и примеры нужные для запуска инстанса [Pepeunit](/conception/overview) при помощи `docker compose`, чтобы склонировать репозиторий выполните команды:
```bash
git clone https://git.pepemoss.com/pepe/pepeunit/pepeunit_deploy.git
cd pepeunit_deploy
```

## Заполняем первичный .env файл

На выбор есть два варианта установки:
1. Для локального использования на основе `.env.local.example`
1. Для глобального использования на основе `.env.global.example`

Отличие состоит в том, что локальный рассчитан на эксплуатацию в локальной сети, а глобальный позволяет обращаться к инстансу [Pepeunit](/conception/overview) по доменному имени через `https`.

Выберите один из файлов и уберите у него приставу `.example`
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
`BACKEND_DOMAIN` | `192.168.0.22` | `unit.pepeunit.com` | Доменное имя от [инстанса](/definitions#instance) [Pepeunit](/conception/overview)
`BACKEND_SECURE` | `False` | - | Выбирает `http` или `https` для `BACKEND_DOMAIN` [инстанса](/definitions#instance) [Pepeunit](/conception/overview), по умолчанию `https`
`TELEGRAM_TOKEN `| `1111111111:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA` | `1111111111:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA` | Токен `Telegram Bot` можно получить у [Bot Father](https://t.me/BotFather)
`TELEGRAM_BOT_LINK` | `https://t.me/PepeUnitRobot` | `https://t.me/PepeUnitRobot` | Ccылка на бота, которого вы создаёте в [Bot Father](https://t.me/BotFather)
`MQTT_HOST` | `192.168.0.22` | `emqx.pepeunit.com` | Доменное имя от [инстансa](/definitions#instance) [EMQX MQTT Broker](/definitions#mqtt-broker)
`MQTT_SECURE` | `False` | - | Выбирает `http` или `https` для `MQTT_HOST` [инстансa](/definitions#instance) [Pepeunit](/conception/overview), по умолчанию `https`
`MQTT_USERNAME` | `YabJTlmvQ4tvweuTl0gn` | `YabJTlmvQ4tvweuTl0gn` | Имя администратора [EMQX MQTT Broker](/definitions#mqtt-broker)
`MQTT_PASSWORD` | `F2qvym9lxL0DK6DlhmN1HgczWe9lKj30BvJTyvHu` | `F2qvym9lxL0DK6DlhmN1HgczWe9lKj30BvJTyvHu` | Пароль администратора [EMQX MQTT Broker](/definitions#mqtt-broker)
`GF_PASSWORD` | `aN4bzmwMjB0v69LPvxpLLJ7LHXTe6hlqZ703mVmB` | `aN4bzmwMjB0v69LPvxpLLJ7LHXTe6hlqZ703mVmB` | Пароль для [Grafana](/definitions#grafana)

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
Команда `python3 make_env.py` каждый раз перегенерирует конфиги. При перегенерации существующие секретные `32 битные ключи` не измененяются. Используйте команды [создания backup](/deployment/docker#работа-с-бэкапами), для сохранения старой конфигурации.
:::

:::danger
Вам может потребоваться внести изменения в конфигурацию отдельных сервисов для тонкой настройки. [Подробнее о переменных окружения Backend и Frontend](/deployment/env-variables)
:::

## Настройка Nginx

Обычно настройка `Nginx` для `docker compose` не требуется. Если ваш инстанс [Pepeunit](/conception/overview) будет находиться за ещё одним `Nginx`, используйте подробную настройку: [Подробная настройка nginx для https и reverse proxy](/deployment/nginx)

## Открытие портов

Для корректной работы [Pepeunit](/conception/overview), нужно открыть следующие порты:
1. `80` - для работы по `http`
1. `443` - для работы по `https`
1. `1883` - для работы по протоколу [MQTT](/definitions#mqtt)

:::warning
если ваш `1883` порт занят другими приложениями, изменить его на другой и внесите изменения в [ENV переменные Backend](/deployment/env-variables#backend) - `MQTT_PORT`, а также в `docker-compose.yml` в секцию `emqx.ports` - значение `- "1883:1883"` вам нужно будет заменить например на: `- "1885:1883"`
:::
:::danger
Если у вас публичный [инстанс](/definitions#instance) [Pepeunit](/conception/overview) с доменом - вам потребуется прокинуть данные порты наружу
:::

## Первый запуск

Настройте доступ для `volumes`:
```bash
sudo chmod 777 -R data
```

Выполните команду запуска [Pepeunit](/conception/overview):
```bash
docker compose up
```

:::info
Пример корреткного запуска [Backend](/definitions#backend) на основе конфига `.env.global`. Для `.env.local` будут отличаться только `ip` адреса и установка `pooling` для `Telegram Bot`:
```bash
INFO - 2025-03-14 01:11:48,419 - HTTP Request: GET https://dcemqx.pepemoss.com/api-docs/swagger.json "HTTP/1.1 200 OK"
INFO - 2025-03-14 01:11:49,541 - EMQX Broker https://dcemqx.pepemoss.com - Ready to work
INFO - 2025-03-14 01:11:49,594 - HTTP Request: POST https://dcemqx.pepemoss.com/api/v5/login "HTTP/1.1 200 OK"
INFO - 2025-03-14 01:11:49,594 - Del file auth hook MQTT Broker
INFO - 2025-03-14 01:11:49,677 - HTTP Request: DELETE https://dcemqx.pepemoss.com/api/v5/authorization/sources/file "HTTP/1.1 204 No Content"
INFO - 2025-03-14 01:11:49,678 - Del http auth hook MQTT Broker
INFO - 2025-03-14 01:11:49,749 - HTTP Request: DELETE https://dcemqx.pepemoss.com/api/v5/authorization/sources/http "HTTP/1.1 204 No Content"
INFO - 2025-03-14 01:11:49,750 - Del redis auth hook MQTT Broker
INFO - 2025-03-14 01:11:49,838 - HTTP Request: DELETE https://dcemqx.pepemoss.com/api/v5/authorization/sources/redis "HTTP/1.1 204 No Content"
INFO - 2025-03-14 01:11:49,838 - Set ACL file auth hook MQTT Broker
INFO - 2025-03-14 01:11:49,911 - HTTP Request: POST https://dcemqx.pepemoss.com/api/v5/authorization/sources "HTTP/1.1 204 No Content"
INFO - 2025-03-14 01:11:49,912 - Set http auth hook MQTT Broker
INFO - 2025-03-14 01:11:50,144 - HTTP Request: POST https://dcemqx.pepemoss.com/api/v5/authorization/sources "HTTP/1.1 204 No Content"
INFO - 2025-03-14 01:11:50,145 - Set redis auth hook MQTT Broker
INFO - 2025-03-14 01:11:50,342 - HTTP Request: POST https://dcemqx.pepemoss.com/api/v5/authorization/sources "HTTP/1.1 204 No Content"
INFO - 2025-03-14 01:11:50,343 - Set cache settings auth hook MQTT Broker
INFO - 2025-03-14 01:11:50,485 - HTTP Request: PUT https://dcemqx.pepemoss.com/api/v5/authorization/settings "HTTP/1.1 200 OK"
INFO - 2025-03-14 01:11:50,486 - Disable ssl listener MQTT Broker
INFO - 2025-03-14 01:11:50,555 - HTTP Request: POST https://dcemqx.pepemoss.com/api/v5/listeners/ssl:default/stop "HTTP/1.1 200 OK"
INFO - 2025-03-14 01:11:50,556 - Disable ws listener MQTT Broker
INFO - 2025-03-14 01:11:50,620 - HTTP Request: POST https://dcemqx.pepemoss.com/api/v5/listeners/ws:default/stop "HTTP/1.1 200 OK"
INFO - 2025-03-14 01:11:50,620 - Disable wss listener MQTT Broker
INFO - 2025-03-14 01:11:50,692 - HTTP Request: POST https://dcemqx.pepemoss.com/api/v5/listeners/wss:default/stop "HTTP/1.1 200 OK"
INFO - 2025-03-14 01:11:50,692 - Set settings for tcp listener
INFO - 2025-03-14 01:11:50,776 - HTTP Request: PUT https://dcemqx.pepemoss.com/api/v5/listeners/tcp:default "HTTP/1.1 200 OK"
INFO - 2025-03-14 01:11:50,777 - Set global mqtt settings
INFO - 2025-03-14 01:11:50,813 - HTTP Request: PUT https://dcemqx.pepemoss.com/api/v5/configs/global_zone "HTTP/1.1 200 OK"
INFO - 2025-03-14 01:11:50,814 - Disable retainer
INFO - 2025-03-14 01:11:50,876 - HTTP Request: PUT https://dcemqx.pepemoss.com/api/v5/mqtt/retainer "HTTP/1.1 200 OK"
INFO - 2025-03-14 01:11:50,883 - Get current TG bot webhook info
INFO - 2025-03-14 01:11:50,883 - Delete webhook before set new webhook
INFO - 2025-03-14 01:11:51,107 - Set new TG bot webhook url: https://dcunit.pepeunit.com/pepeunit/api/v1/bot
INFO - 2025-03-14 01:11:51,177 - Success set TG bot webhook url
INFO - 2025-03-14 01:11:51,196 - run sync local repo storage
INFO - 2025-03-14 01:11:51,234 - end sync local repo storage
INFO - 2025-03-14 01:11:51,235 - 
            
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
                   
     v0.3.0 - AGPL v3 License
     Federated IoT Platform
     Front: https://dcunit.pepeunit.com
     REST:  https://dcunit.pepeunit.com/pepeunit/docs
     GQL:   https://dcunit.pepeunit.com/pepeunit/graphql
     TG:    https://t.me/PepeUnitDevRobot
     Docs:  https://pepeunit.com
            
INFO - 2025-03-14 01:11:51,235 - Connect to mqtt server: dcemqx.pepemoss.com:1885
[2025-03-14 01:11:51 +0000] [35] [INFO] Used broker version is 5
INFO - 2025-03-14 01:11:51,239 - [CONNECTION MADE]
INFO - 2025-03-14 01:11:51,257 - Connect to mqtt server: dcemqx.pepemoss.com:1885
[2025-03-14 01:11:51 +0000] [36] [INFO] Used broker version is 5
INFO - 2025-03-14 01:11:51,264 - [CONNECTION MADE]
INFO - 2025-03-14 01:11:53,243 - MQTT subscriptions initialized in this worker
INFO - 2025-03-14 01:11:53,243 - [SEND SUB] 1 [b'dcunit.pepeunit.com/+/+/+/pepeunit']
INFO - 2025-03-14 01:11:53,244 - [SEND SUB] 2 [b'dcunit.pepeunit.com/+/pepeunit']
[2025-03-14 01:11:53 +0000] [35] [INFO] Application startup complete.
INFO - 2025-03-14 01:11:53,249 - [SUBACK] 1 (0,)
INFO - 2025-03-14 01:11:53,249 - [SUBACK] 2 (0,)
INFO - 2025-03-14 01:11:53,268 - Another worker already subscribed to MQTT topics
[2025-03-14 01:11:53 +0000] [36] [INFO] Application startup complete.
```
:::

:::warning
Стоит обратить особое внимание на строчки:

```bash
INFO - 2025-03-14 01:11:53,249 - [SUBACK] 1 (0,)
INFO - 2025-03-14 01:11:53,249 - [SUBACK] 2 (0,)
```

Они отображают смог ли [Backend](/definitions#backend) подписаться на топики `dcunit.pepeunit.com/+/+/+/pepeunit` и `dcunit.pepeunit.com/+/pepeunit`. Если в скобках будет указано `(135,)` вместо `(0,)`, то [Backend](/definitions#backend) `не смог` подписаться на основные топики. Обычно это связано со следующими недочётами:
1. Закрытым портом `1883`
1. Настройкой портов сервиса `emqx` в `docker-compose.yml`, вы могли указать другой порт, и не открыли его
1. Ошибками в настройках [EMQX MQTT Broker](/definitions#mqtt-broker) и [Backend](/definitions#backend), например `MQTT_REDIS_AUTH_URL` или `REDIS_URL`. [Подробнее о переменных окружения Backend Env](/deployment/env-variables#backend). Данные переменные должны смотреть строго на один и тот же инстанас [Redis](/deployment/dependencies#redis). За первичную авторизацию отвечает именно [Redis](/deployment/dependencies#redis).
:::

## Создание Администратора

Первый созданный пользователь на [инстансе](/definitions#instance) [Pepeunit](/conception/overview) автоматически становится [Администратором](/mechanics/roles#admin). Для этого достаточно пройти стандартную форму регистрации.

## Работа с бэкапами

0. Запустите `Pepeunit` командой, это требуется для получения корректной версии
    ```bash
    docker compose up -d
    ```
1. Запустите создание `backup` командой, скрипт сам выключит контейнеры
    ```bash
    sudo ./backup.sh backup
    ```
1. Развернуть версию из `backup`
    ```bash
    sudo ./backup.sh restore backups/backup_name.tar
    ```

## Обновление

0. Создайте `backup`
    ```bash
    sudo ./backup.sh backup
    ```
1. Выполните обновление репозитория
    ```bash
    git pull
    ```
1. Выполните обновление `env` переменных. Существующие секретные `32 битные ключи` изменены не будут. Остальные переменные будут сгенерированны, как при первой генерации, если вы выполняли ручной ввод данных в `env/.env.<service-name>` файлы, то ваши изменения будут **УДАЛЕНЫ**, поэтому обязательно делайте `backup` перед запуском команды. Если у вас очень тонкая настройка, изменяйте настройки в ручную, напрямую в `env/.env.<service-name>`.
    ```bash
    python make_env.py
    ```
1. Выполните запуск `Pepeunit`
    ```bash
    docker compose up -d
    ```

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
    docker exec -it clickhouse /bin/bash
    ```
- Зайти в консоль базы данных, `POSTGRES_USER` и `POSTGRES_DB` можно найти в `env/.env.postgres`
    ```bash
    docker exec -it postgres psql -U <POSTGRES_USER> -d <POSTGRES_DB>
    psql -U <POSTGRES_USER> -d <POSTGRES_DB>
    ```
- Отправить запрос в clickhouse через curl:
    ```bash
    curl "http://admin:mypassword@127.0.0.1:8123/?query=SHOW+TABLES"
    ```