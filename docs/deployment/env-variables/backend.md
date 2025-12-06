# Backend

:::warning
Ручное заполнение обычно не требуется, нужно заполнить только основные переменные т.к. есть [файл генерации .env файлов для сервисов](/deployment/docker/deploy#заполнение-первичного-env-фаила)
:::

Переменная | По умолчанию | Зачем нужна?
-- | -- | --
`PU_FF_TELEGRAM_BOT_ENABLE` | `True` | Функциональный флаг, отвечает за то включен ли [Telegram Bot](/definitions#telegram-bot)
`PU_FF_GRAFANA_INTEGRATION_ENABLE` | `True` | Функциональный флаг, отвечает за то включена ли интеграция с `Grafana`
`PU_FF_DATAPIPE_DEFAULT_LAST_VALUE_ENABLE` | `True` | Функциональный флаг, отвечает за то будет ли устанавливаться по умолчанию [DataPipe](/deployment/dependencies/datapipe) с типом [LastValue](/user/datapipe/example#lastvalue) для [UnitNode](/definitions#unitnode)
`PU_FF_DATAPIPE_ENABLE` | `True` | Функциональный флаг, отвечает за то включены ли возможности [DataPipe](/deployment/dependencies/datapipe), когда флаг выключен нужно так же выключить [DataPipe](/deployment/dependencies/datapipe) сервис, т.к. он перестанет получать обновления конфигураций и тд
`PU_FF_PROMETHEUS_ENABLE` | `True` | Функциональный флаг, отвечает за то включен ли мониторинг запросов через [Prometheus](/deployment/dependencies/prometheus) или нет
`PU_LOG_FORMAT` | `json` | Определяет формат логов. В режиме `json` каждая запись лога будет одним `dict`. При использовании `plain` строки лога будут стандартными, но `traceback` будет писаться отдельными строками
`PU_MIN_LOG_LEVEL` | `INFO` | Минимальный уровень логов, который выводится в консоль. Все логи с более низким приоритетом выводиться не будут. Допустимые значения: `DEBUG`, `INFO`, `WARNING`, `ERROR` и `CRITICAL`
`PU_APP_PREFIX` | `/pepeunit` | Стандартный префикс, позволяющий дистанцировать навигацию от домена, обычно не требует изменений. Нужен для сложных встраиваемых систем
`PU_API_V1_PREFIX` | `/api/v1` | Префикс версии [REST API](/definitions#rest), нужен для возможности поддержки старых версий [REST API](/definitions#rest), а также для систем требующих поддержки нескольких версий одновременно
`PU_WORKER_COUNT` | `2` | Число воркеров Gunicorn, позволяет увеличить нагрузку, которую способен выдержать [Backend](/deployment/dependencies/backend)
`PU_DOMAIN` | - | Доменное имя или `ip`. Влияет на ссылки которые генерирует [Backend](/deployment/dependencies/backend). Позволяет [Unit](/definitions#unit) связываться с [Backend](/deployment/dependencies/backend). Устанавливается в [Unit ENV](/developer/files/struct-env-example-json) - как `PU_DOMAIN`
`PU_SECURE` | `True` | Если `True`, то [Backend](/deployment/dependencies/backend) будет генерировать ссылки с `https` для `PU_DOMAIN`. Устанавливается в [Unit ENV](/developer/files/struct-env-example-json) - в поле `PU_HTTP_TYPE`, но уже в формате `https/http`
`PU_AUTH_TOKEN_EXPIRATION` | `2678400` | Время жизни токенов авторизации [Пользователей](/development-pepeunit/mechanics/roles.html#user) в секундах
`PU_SAVE_REPO_PATH` | `repo_cache` | Путь по которому [Backend](/deployment/dependencies/backend) хранит внешние [Git](/definitions#git) репозитории. Устанавливается относительно корневой дирректории [Backend](/deployment/dependencies/backend)
`PU_SQLALCHEMY_DATABASE_URL` | - | Ссылка для подключения к [PostgreSQL](/deployment/dependencies/postgresql)
`PU_CLICKHOUSE_DATABASE_URL` | - | Ссылка для подключения к [ClickHouse](/deployment/dependencies/clickhouse)
`PU_SECRET_KEY` | - | `32 байтовый ключ` в формате `base64`. Отвечает за подпись токенов авторизации. В случае изменения все `jwt` токены созданные до изменения - становятся не действительными
`PU_ENCRYPT_KEY` | - | `32 байтовый ключ` в формате `base64`. Отвечает за шифрование всех данных. В случае изменения все шифрованные записи - становится невозможно расшифровать
`PU_STATIC_SALT` | - | `32 байтовый ключ` в формате `base64`. Отвечает за генерацию `hash` для паролей [Пользователей](/development-pepeunit/mechanics/roles.html#user). В случае изменения все учётные записи созданные до момента изменения - потеряют возможность авторизоваться
`PU_MIN_INTERVAL_SYNC_REPOSITORY` | `10` | Время в секундах, которое должно пройти перед следующим запросом обновления репозитория из внешнего ресурса
`PU_STATE_SEND_INTERVAL` | `60` | Частота в секундах с которой [Unit'ы](/definitions#unit) должны отправлять своё состояние. Устанавливается в [Unit ENV](/developer/files/struct-env-example-json) - в поле `STATE_SEND_INTERVAL`
`PU_MAX_EXTERNAL_REPO_SIZE` | `50` | Значение в `МБ`, ограничивающее размер внешних [Git](/definitions#git) репозиториев для скачивания
`PU_MAX_CIPHER_LENGTH` | `1000000` | Максимальная длинна в символах для шифруемой информации
`PU_MIN_TOPIC_UPDATE_TIME` | `30` | Частота обновления сообщений в `domain.com/+/pepeunit` топиках [MQTT](/definitions#mqtt)
`PU_UNIT_LOG_EXPIRATION` | `86400` | Вермя жизни логов, которые присылают [Unit](/definitions#unit) в секундах
`PU_MAX_PAGINATION_SIZE` | `500` | Максимальное количество объектов, которое можно получить за `1` запрос где есть пагинация
`PU_TELEGRAM_BOT_MODE` | `webhook` | Принимает значения: `webhook` или `pooling`. Позволяет указать как [Backend](/deployment/dependencies/backend) будет обмениваться информацией с [Telegram Bot](/definitions#telegram-bot). `pooling` позволяет работать без личного домена и `https`, в средах где есть доступ в интернет. `webhook` более производительный вариант, предназаначен для использования с `https` и личным доменом, ссылка на `webhook` устанавливает автоматически в момент старта приложения
`PU_TELEGRAM_DEL_OLD_WEBHOOK` | `True` | Удаляется ли `webhook` для [Telegram Bot](/definitions#telegram-bot), перед тем как создать новый
`PU_TELEGRAM_TOKEN` | - | Токен [Telegram Bot](/definitions#telegram-bot). Секретный, никому не показывайте
`PU_TELEGRAM_BOT_LINK` | - | Ссылка на [Telegram Bot](/definitions#telegram-bot) которым управляет [Backend](/deployment/dependencies/backend). Используется для генерации верификационных ссылок для [Пользователей](/development-pepeunit/mechanics/roles.html#user). Передаётся в `openapi.json`
`PU_TELEGRAM_ITEMS_PER_PAGE` | `7` | Число пагинируемых элементов при отображении за один раз в [Telegram Bot](/definitions#telegram-bot)
`PU_TELEGRAM_HEADER_ENTITY_LENGTH` | `15` | Предельная длинна наименований сущностей при отображении в [Telegram Bot](/definitions#telegram-bot)
`PU_TELEGRAM_GIT_HASH_LENGTH` | `8` | Предельная длинна `hash` [Git Commit](/definitions#git-commit) при отображении в [Telegram Bot](/definitions#telegram-bot)
`PU_PROMETHEUS_MULTIPROC_DIR` | `./prometheus_metrics` | Дирректория, которую [Prometheus](/deployment/dependencies/prometheus) использует для хранения статистик с нескольких `worker` - `uvicorn`. При старте приложения содержимое дирректории отчищается
`PU_REDIS_URL` | `redis://redis:6379/0` | Ссылка для доступа к [Redis](/deployment/dependencies/redis), которую использует [Backend](/deployment/dependencies/backend) для соединения c [Redis](/deployment/dependencies/redis). Инстанс [Redis](/deployment/dependencies/redis) должен быть единым с `MQTT_REDIS_AUTH_URL`
`PU_MQTT_HOST` | - | Доменное имя или `ip`. Позволяет [Backend](/deployment/dependencies/backend) управлять и подписываться на топики [EMQX](/deployment/dependencies/emqx). Позволяет Unit связываться с [EMQX](/deployment/dependencies/emqx). Устанавливается в [Unit ENV](/developer/files/struct-env-example-json) - в поле `PU_MQTT_HOST`
`PU_MQTT_SECURE` | `True` | Если `True`, то [Backend](/deployment/dependencies/backend) будет использовать `https` для настройки [EMQX](/deployment/dependencies/emqx)
`PU_MQTT_PORT` | `1883` | Порт по которому [Unit](/definitions#unit) и [Backend](/deployment/dependencies/backend) связываются c [EMQX](/deployment/dependencies/emqx). Устанавливается в [Unit ENV](/developer/files/struct-env-example-json) - в поле `PU_MQTT_PORT`
`PU_MQTT_API_PORT` | `18083` | Порт [API](/definitions#api) [EMQX](/deployment/dependencies/emqx), по которому [Backend](/deployment/dependencies/backend) производит настройку [EMQX](/deployment/dependencies/emqx)
`PU_MQTT_KEEPALIVE` | `60` | Максимальный период в секундах между отправками `ping` от [Backend](/deployment/dependencies/backend) до [EMQX](/deployment/dependencies/emqx)
`PU_MQTT_USERNAME` | - | Имя пользователя [EMQX](/deployment/dependencies/emqx). [Backend](/deployment/dependencies/backend) использует его для первичной настройки брокера
`PU_MQTT_PASSWORD` | - | Пароль пользователя [EMQX](/deployment/dependencies/emqx). [Backend](/deployment/dependencies/backend) использует его для первичной настройки брокера
`PU_MQTT_REDIS_AUTH_URL` | `redis://redis:6379/0` | Ссылка для доступа к [Redis](/deployment/dependencies/redis), которую использует [EMQX](/deployment/dependencies/emqx) для соединения c [Redis](/deployment/dependencies/redis). Инстанс [Redis](/deployment/dependencies/redis) должен быть единым с `REDIS_URL`
`PU_MQTT_MAX_CLIENTS` | `10000` | Максимальное число клиентов [EMQX](/deployment/dependencies/emqx)
`PU_MQTT_MAX_CLIENT_CONNECTION_RATE` | `20/s` | Максимальная скорость подписки клиентов [EMQX](/deployment/dependencies/emqx)
`PU_MQTT_MAX_CLIENT_ID_LEN` | `512` | Максимальная длинная `id` клиентов [EMQX](/deployment/dependencies/emqx)
`PU_MQTT_CLIENT_MAX_MESSAGES_RATE` | `30/s` | Максимальная частота отправки сообщений одним клиентом [EMQX](/deployment/dependencies/emqx)
`PU_MQTT_CLIENT_MAX_BYTES_RATE` | `1MB/s` | Максимальная скорость соединения с клиентом [EMQX](/deployment/dependencies/emqx)
`PU_MQTT_MAX_PAYLOAD_SIZE` | `256` | Максимальный размер в килобайтах, для данных передаваемых через топики [EMQX](/deployment/dependencies/emqx)
`PU_MQTT_MAX_QOS` | `2` | Максимальное качество обслуживания доступное в [EMQX](/deployment/dependencies/emqx)
`PU_MQTT_MAX_TOPIC_LEVELS` | `5` | Максимальная вложенность топиков [EMQX](/deployment/dependencies/emqx)
`PU_MQTT_MAX_LEN_MESSAGE_QUEUE` | `128` | Максимальная длинна очереди сообщений [EMQX](/deployment/dependencies/emqx)
`PU_MQTT_MAX_TOPIC_ALIAS` | `128` | Максимальное число топиков-ссылок [EMQX](/deployment/dependencies/emqx)
`PU_GITHUB_TOKEN_NAME` | - | Название [GitHub](/definitions#github) токена, с разрешением только для чтения публичных репозиториев. Используется для увеличения лимита загрузки публичных репозиториев с [GitHub](/definitions#github) с `60` в час до `5000` в час
`PU_GITHUB_TOKEN_PAT` | - | [GitHub](/definitions#github) токен, с разрешением только для чтения публичных репозиториев. Используется для увеличения лимита загрузки публичных репозиториев с [GitHub](/definitions#github) с `60` в час до `5000` в час
`PU_GRAFANA_ADMIN_USER` | - | Логин админа для [Grafana](/deployment/dependencies/grafana)
`PU_GRAFANA_ADMIN_PASSWORD` | - | Пароль админа для [Grafana](/deployment/dependencies/grafana)
`PU_GRAFANA_LIMIT_UNIT_NODE_PER_ONE_PANEL` | `10` | Максимальное число [UnitNode](/definitions#unitnode) для одной [Visualization](/definitions#visualization)

:::info
Для тестирования [Backend](/deployment/dependencies/backend) также выделены переменные:
- [Переменные интеграционного тестирования](/development-pepeunit/tests/integration-test#запуск)
- [Переменные нагрузочного тестирования MQTT](/development-pepeunit/tests/load-test#тестирование-mqtt)
- [Переменные нагрузочного тестирования REST и GQL](/development-pepeunit/tests/load-test#тестирование-rest-и-gql)
:::