# Переменные окружения

## Backend

:::warning
Пример заполнения переменных есть в [Backend](/definitions#backend), файл `.env_example`. Обычно нужно заполнить только основные переменные т.к. есть [файл генерации .env файлов для сервисов](/deployment/docker)
:::

Переменная | По умолчанию | Зачем нужна?
-- | -- | -- 
`BACKEND_DEBUG` | `False` | При включении расширяет вывод логов для [FastApi](https://fastapi.tiangolo.com/) и [SqlAlchemy](https://docs.sqlalchemy.org/en/20/)
`BACKEND_APP_PREFIX` | `/pepeunit` | Стандартный префикс, позволяющий дистанцировать навигацию от домена, обычно не требует изменений. Нужен для сложных встраиваемых систем
`BACKEND_API_V1_PREFIX` | `/api/v1` | Префикс версии [REST API](/definitions#rest), нужен для возможности поддержки старых версий [REST API](/definitions#rest), а также для систем требующих поддержки нескольких версий одновременно
`BACKEND_WORKER_COUNT` | `2` | Число воркеров Gunicorn, позволяет увеличить нагрузку, которую способен выдержать [Backend](/definitions#backend)
`BACKEND_DOMAIN` | - | Доменное имя или `ip`. Влияет на ссылки которые генерирует [Backend](/definitions#backend). Позволяет [Unit](/definitions#unit) связываться с [Backend](/definitions#backend). Устанавливается в [Unit ENV](/developer/struct-env-json) - в поле `PEPEUNIT_URL`
`BACKEND_SECURE` | `True` | Если `True`, то [Backend](/definitions#backend) будет генерировать ссылки с `https` для `BACKEND_DOMAIN`. Устанавливается в [Unit ENV](/developer/struct-env-json) - в поле `HTTP_TYPE`, но уже в формате `https/http`
`BACKEND_AUTH_TOKEN_EXPIRATION` | `2678400` | Время жизни токенов авторизации [Пользователей](/mechanics/roles.html#user) в секундах
`BACKEND_SAVE_REPO_PATH` | `repo_cache` | Путь по которому [Backend](/definitions#backend) хранит внешние [Git](/definitions#git) репозитории. Устанавливается относительно корневой дирректории [Backend](/definitions#backend)
`SQLALCHEMY_DATABASE_URL` | - | Ссылка для подключения к [Postgresql](/deployment/dependencies#postgresql)
`CLICKHOUSE_DATABASE_URL` | - | Ссылка для подключения к [Clickhouse](/deployment/dependencies#clickhouse)
`BACKEND_SECRET_KEY` | - | `32 байтовый ключ` в формате `base64`. Отвечает за подпись токенов авторизации. В случае изменения все `jwt` токены созданные до изменения - становятся не действительными
`BACKEND_ENCRYPT_KEY` | - | `32 байтовый ключ` в формате `base64`. Отвечает за шифрование всех данных. В случае изменения все шифрованные записи - становится невозможно расшифровать
`BACKEND_STATIC_SALT` | - | `32 байтовый ключ` в формате `base64`. Отвечает за генерацию `hash` для паролей пользователей. В случае изменения все учётные записи созданные до момента изменения - потеряют возможность авторизоваться
`BACKEND_MIN_INTERVAL_SYNC_REPOSITORY` | `10` | Время в секундах, которое должно пройти перед следующим запросом обновления репозитория из внешнего ресурса
`BACKEND_STATE_SEND_INTERVAL` | `60` | Частота в секундах с которой [Unit'ы](/definitions#unit) должны отправлять своё состояние. Устанавливается в [Unit ENV](/developer/struct-env-json) - в поле `STATE_SEND_INTERVAL`
`BACKEND_MAX_EXTERNAL_REPO_SIZE` | `50` | Значение в `МБ`, ограничивающее размер внешних [Git](/definitions#git) репозиториев для скачивания
`BACKEND_MAX_CIPHER_LENGTH` | `1000000` | Максимальная длинна в символах для шифруемой информации
`BACKEND_MIN_TOPIC_UPDATE_TIME` | `30` | Частота обновления сообщений в `domain.com/+/pepeunit` топиках [MQTT](/definitions#mqtt)
`BACKEND_UNIT_LOG_EXPIRATION` | `86400` | Вермя жизни логов, которые присылают [Unit](/definitions#unit) в секундах
`TELEGRAM_BOT_ENABLE` | `True` | Состояние интеграции с `Telegram Bot`, если установить `False` - весь `Telegram Bot` функционал будет отключён
`TELEGRAM_BOT_MODE` | `webhook` | Принимает значения: `webhook` или `pooling`. Позволяет указать как [Backend](/definitions#backend) будет обмениваться информацией с `Telegram Bot API`. `pooling` позволяет работать без личного домена и `https`, в средах где есть доступ в интернет. `webhook` более производительный вариант, предназаначен для использования с `https` и личным доменом, ссылка на `webhook` устанавливает автоматически в момент старта приложения
`TELEGRAM_DEL_OLD_WEBHOOK` | `True` | Удаляется ли `webhook` через `Telegram Bot API`, перед тем как создать новый
`TELEGRAM_TOKEN` | - | Токен `Telegram Bot API`, можно получить через `Telegram Bot Father`. Секретный, никому не показывайте
`TELEGRAM_BOT_LINK` | - | Ссылка на `Telegram Bot` которым управляет [Backend](/definitions#backend). Используется для генерации верификационных ссылок для пользователей бота. Передаётся в `openapi.json`
`TELEGRAM_ITEMS_PER_PAGE` | `7` | Число пагинируемых элементов при отображении за один раз в `Telegram Bot`
`TELEGRAM_HEADER_ENTITY_LENGTH` | `15` | Предельная длинна наименований сущностей при отображении в `Telegram Bot`
`TELEGRAM_GIT_HASH_LENGTH` | `8` | Предельная длинна `hash` [Git Commit](/definitions#git-commit) при отображении в `Telegram Bot`
`PROMETHEUS_MULTIPROC_DIR` | `./prometheus_metrics` | Дирректория, которую `Prometheus` использует для хранения статистик с нескольких `worker` - `uvicorn`. При старте приложения содержимое дирректории отчищается
`REDIS_URL` | `redis://redis:6379/0` | Ссылка для доступа к [Redis](/deployment/dependencies#redis), которую использует [Backend](/definitions#backend) для соединения c [Redis](/deployment/dependencies#redis). Инстанс [Redis](/deployment/dependencies#redis) должен быть единым с `MQTT_REDIS_AUTH_URL`
`MQTT_HOST` | - | Доменное имя или `ip`. Позволяет [Backend](/definitions#backend) управлять и подписываться на топики [EMQX MQTT Broker](/definitions#mqtt-broker). Позволяет Unit связываться с [EMQX MQTT Broker](/definitions#mqtt-broker). Устанавливается в [Unit ENV](/developer/struct-env-json) - в поле `MQTT_URL`
`MQTT_SECURE` | `True` | Если `True`, то [Backend](/definitions#backend) будет использовать `https` для настройки [EMQX MQTT Broker](/definitions#mqtt-broker)
`MQTT_PORT` | `1883` | Порт по которому [Unit](/definitions#unit) и [Backend](/definitions#backend) связываются c [EMQX MQTT Broker](/definitions#mqtt-broker). Устанавливается в [Unit ENV](/developer/struct-env-json) - в поле `MQTT_PORT`
`MQTT_API_PORT` | `18083` | Порт [API](/definitions#api) [EMQX MQTT Broker](/definitions#mqtt-broker), по которому [Backend](/definitions#backend) производит настройку [EMQX MQTT Broker](/definitions#mqtt-broker)
`MQTT_KEEPALIVE` | `60` | Максимальный период в секундах между отправками `ping` от [Backend](/definitions#backend) до [EMQX MQTT Broker](/definitions#mqtt-broker)
`MQTT_USERNAME` | - | Имя пользователя [EMQX MQTT Broker](/definitions#mqtt-broker). [Backend](/definitions#backend) использует его для первичной настройки брокера
`MQTT_PASSWORD` | - | Пароль пользователя [EMQX MQTT Broker](/definitions#mqtt-broker). [Backend](/definitions#backend) использует его для первичной настройки брокера
`MQTT_REDIS_AUTH_URL` | `redis://redis:6379/0` | Ссылка для доступа к [Redis](/deployment/dependencies#redis), которую использует [EMQX MQTT Broker](/definitions#mqtt-broker) для соединения c [Redis](/deployment/dependencies#redis). Инстанс [Redis](/deployment/dependencies#redis) должен быть единым с `REDIS_URL`
`MQTT_MAX_CLIENTS` | `10000` | Максимальное число клиентов [EMQX MQTT Broker](/definitions#mqtt-broker)
`MQTT_MAX_CLIENT_CONNECTION_RATE` | `20/s` | Максимальная скорость подписки клиентов [EMQX MQTT Broker](/definitions#mqtt-broker)
`MQTT_MAX_CLIENT_ID_LEN` | `512` | Максимальная длинная `id` клиентов [EMQX MQTT Broker](/definitions#mqtt-broker)
`MQTT_CLIENT_MAX_MESSAGES_RATE` | `30/s` | Максимальная частота отправки сообщений одним клиентом [EMQX MQTT Broker](/definitions#mqtt-broker)
`MQTT_CLIENT_MAX_BYTES_RATE` | `1MB/s` | Максимальная скорость соединения с клиентом [EMQX MQTT Broker](/definitions#mqtt-broker)
`MQTT_MAX_PAYLOAD_SIZE` | `256` | Максимальный размер в кБ, для данных передаваемых через топики [EMQX MQTT Broker](/definitions#mqtt-broker)
`MQTT_MAX_QOS` | `2` | Максимальное качество обслуживания доступное в [EMQX MQTT Broker](/definitions#mqtt-broker)
`MQTT_MAX_TOPIC_LEVELS` | `5` | Максимальная вложенность топиков [EMQX MQTT Broker](/definitions#mqtt-broker)
`MQTT_MAX_LEN_MESSAGE_QUEUE` | `128` | Максимальная длинна очереди сообщений [EMQX MQTT Broker](/definitions#mqtt-broker)
`MQTT_MAX_TOPIC_ALIAS` | `128` | Максимальное число топиков-ссылок [EMQX MQTT Broker](/definitions#mqtt-broker)
`GF_ADMIN_USER` | - | Логин админа для [Grafana](/deployment/dependencies#grafana)
`GF_ADMIN_PASSWORD` | - | Пароль админа для [Grafana](/deployment/dependencies#grafana)
`GF_LIMIT_UNIT_NODE_PER_ONE_PANEL` | `10` | Максимальное число [UnitNode](/definitions#unitnode) для одной [Visualization](/definitions#visualization)
`GITHUB_TOKEN_NAME` | - | Название [Github](/definitions#github) токена, с разрешением только для чтения публичных репозиториев. Используется для увеличения лимита загрузки публичных репозиториев с [Github](/definitions#github) с `60` в час до `5000` в час
`GITHUB_TOKEN_PAT` | - | [Github](/definitions#github) токен, с разрешением только для чтения публичных репозиториев. Используется для увеличения лимита загрузки публичных репозиториев с [Github](/definitions#github) с `60` в час до `5000` в час

:::info
Для тестирования [Backend](/definitions#backend) также выделены переменные:
- [Переменные интеграционного тестирования](/tests/integration-test#запуск)
- [Переменные нагрузочного тестирования MQTT](/tests/load-test#тестирование-mqtt)
- [Переменные нагрузочного тестирования REST и GQL](/tests/load-test#тестирование-rest-и-gql)
:::

## Backend Data Pipe

:::warning
Пример заполнения переменных есть в [Backend Data Pipe](/definitions#backend-data-pipe), файл `.env_example`. Обычно нужно заполнить только основные переменные т.к. есть [файл генерации .env файлов для сервисов](/deployment/docker)
:::

Переменная | По умолчанию | Зачем нужна?
-- | -- | -- 
`BACKEND_DOMAIN` | - | Доменное имя или `ip`. Влияет на ссылки которые генерирует [Backend](/definitions#backend). Позволяет [Unit](/definitions#unit) связываться с [Backend](/definitions#backend). Устанавливается в [Unit ENV](/developer/struct-env-json) - в поле `PEPEUNIT_URL`
`BACKEND_SECRET_KEY` | - | `32 байтовый ключ` в формате `base64`. Отвечает за подпись токенов авторизации. В случае изменения все `jwt` токены созданные до изменения - становятся не действительными
`SQLALCHEMY_DATABASE_URL` | - | Ссылка для подключения к [Postgresql](/deployment/dependencies#postgresql)
`CLICKHOUSE_DATABASE_URL` | - | Ссылка для подключения к [Clickhouse](/deployment/dependencies#clickhouse)
`REDIS_URL` | `redis://redis:6379/0` | Ссылка для доступа к [Redis](/deployment/dependencies#redis), которую использует [Backend](/definitions#backend) для соединения c [Redis](/deployment/dependencies#redis). Инстанс [Redis](/deployment/dependencies#redis) должен быть единым с `MQTT_REDIS_AUTH_URL`
`MQTT_HOST` | - | Доменное имя или `ip`. Позволяет [Backend](/definitions#backend) управлять и подписываться на топики [EMQX MQTT Broker](/definitions#mqtt-broker). Позволяет Unit связываться с [EMQX MQTT Broker](/definitions#mqtt-broker). Устанавливается в [Unit ENV](/developer/struct-env-json) - в поле `MQTT_URL`
`MQTT_PORT` | `1883` | Порт по которому [Unit](/definitions#unit) и [Backend](/definitions#backend) связываются c [EMQX MQTT Broker](/definitions#mqtt-broker). Устанавливается в [Unit ENV](/developer/struct-env-json) - в поле `MQTT_PORT`
`MQTT_KEEPALIVE` | `60` | Максимальный период в секундах между отправками `ping` от [Backend](/definitions#backend) до [EMQX MQTT Broker](/definitions#mqtt-broker)
`CONFIG_SYNC_INTERVAL` | `60` | Период времени в секундах между повторными запросами конфигурации [YML](/definitions#yml)
`NRECORDS_CLEANUP_INTERVAL` | `60` | Период времени в секундах между запусками задачи удаления накопившихся всверх предела записей `N Records`
`BUFFER_FLUSH_INTERVAL` | `5` | Период времени в секундах, по истечении которого, не зависимо от числа пришедших записей, данные будут сохранены в [Clickhouse](/deployment/dependencies#clickhouse) или [Postgresql](/deployment/dependencies#postgresql)
`BUFFER_MAX_SIZE` | `1000` | Предельная длинна очереди, при превышении которой запись в [Clickhouse](/deployment/dependencies#clickhouse) или [Postgresql](/deployment/dependencies#postgresql) выполняется не дожидаясь интервала `BUFFER_FLUSH_INTERVAL`

## Frontend

:::warning
У [Frontend](/definitions#frontend) нет значений по умолчанию.
:::

Переменная | Пример | Зачем нужна?
-- | -- | --
`VITE_INSTANCE_NAME` | `example.com` | Используется для генерации ссылок между разными `Node` основного графа
`VITE_SELF_URI` | `https://example.com/` | Используется для тегов `og:url` и `og:image` в `index.html`
`VITE_BACKEND_URI` | `https://example.com/pepeunit/graphql` | Используется для отправки [GQL](/definitions#gql) запросов к [Backend](/definitions#backend)
