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
`BACKEND_DOMAIN` | - | Доменное имя или `ip`. Влияет на ссылки которые генерирует [Backend](/definitions#backend). Позволяет [Unit](/definitions#unit) связываться с [Backend](/definitions#backend). Устанавливается в [Unit ENV](/developer/struct-env-json) - в поле `PEPEUNIT_URL`
`BACKEND_SECURE` | `True` | Если `True`, то [Backend](/definitions#backend) будет генерировать ссылки с `https` для `BACKEND_DOMAIN`. Устанавливается в [Unit ENV](/developer/struct-env-json) - в поле `HTTP_TYPE`, но уже в формате `https/http`
`BACKEND_AUTH_TOKEN_EXPIRATION` | `2678400` | Время жизни токенов авторизации [Пользователей](/mechanics/roles.html#user) в секундах
`BACKEND_SAVE_REPO_PATH` | `repo_cache` | Путь по которому [Backend](/definitions#backend) хранит внешние [Git](/definitions#git) репозитории. Устанавливается относительно корневой дирректории [Backend](/definitions#backend)
`SQLALCHEMY_DATABASE_URL` | - | Ссылка для подключения к [Postgresql](/deployment/dependencies#postgresql)
`BACKEND_SECRET_KEY` | - | `32 байтовый ключ` в формате `base64`. Отвечает за подпись токенов авторизации. В случае изменения все `jwt` токены созданные до изменения - становятся не действительными
`BACKEND_ENCRYPT_KEY` | - | `32 байтовый ключ` в формате `base64`. Отвечает за шифрование всех данных. В случае изменения все шифрованные записи - становится невозможно расшифровать
`BACKEND_STATIC_SALT` | - | `32 байтовый ключ` в формате `base64`. Отвечает за генерацию `hash` для паролей пользователей. В случае изменения все учётные записи созданные до момента изменения - потеряют возможность авторизоваться
`BACKEND_STATE_SEND_INTERVAL` | `60` | Частота в секундах с которой [Unit'ы](/definitions#unit) должны отправлять своё состояние. Устанавливается в [Unit ENV](/developer/struct-env-json) - в поле `STATE_SEND_INTERVAL`
`BACKEND_MAX_EXTERNAL_REPO_SIZE` | `50` | Значение в `МБ`, ограничивающее размер внешних [Git](/definitions#git) репозиториев для скачивания
`BACKEND_MAX_CIPHER_LENGTH` | `50000` | Максимальная длинна в символах для шифруемой информации
`TELEGRAM_TOKEN` | - | Токен `Telegram Bot API`, можно получить через `Telegram Bot Father`. Секретный, никому не показывайте
`TELEGRAM_BOT_LINK` | - | Ссылка на `Telegram Bot` которым управляет [Backend](/definitions#backend). Используется для генерации верификационных ссылок для пользователей бота. Передаётся в `openapi.json`
`MQTT_HOST` | - | Доменное имя или `ip`. Позволяет [Backend](/definitions#backend) управлять и подписываться на топики [EMQX MQTT Broker](/definitions#mqtt-broker). Позволяет Unit связываться с [EMQX MQTT Broker](/definitions#mqtt-broker). Устанавливается в [Unit ENV](/developer/struct-env-json) - в поле `MQTT_URL`
`MQTT_SECURE` | `True` | Если `True`, то [Backend](/definitions#backend) будет использовать `https` для настройки [EMQX MQTT Broker](/definitions#mqtt-broker)
`MQTT_PORT` | `1883` | Порт по которому [Unit](/definitions#unit) и [Backend](/definitions#backend) связываются c [EMQX MQTT Broker](/definitions#mqtt-broker). Устанавливается в [Unit ENV](/developer/struct-env-json) - в поле `MQTT_PORT`
`MQTT_API_PORT` | `18083` | Порт [API](/definitions#api) [EMQX MQTT Broker](/definitions#mqtt-broker), по которому [Backend](/definitions#backend) производит настройку [EMQX MQTT Broker](/definitions#mqtt-broker)
`MQTT_USERNAME` | - | Имя пользователя [EMQX MQTT Broker](/definitions#mqtt-broker). [Backend](/definitions#backend) использует его для первичной настройки брокера
`MQTT_PASSWORD` | - | Пароль пользователя [EMQX MQTT Broker](/definitions#mqtt-broker). [Backend](/definitions#backend) использует его для первичной настройки брокера
`MQTT_KEEPALIVE` | `60` | Максимальный период в секундах между отправками `ping` от [Backend](/definitions#backend) до [EMQX MQTT Broker](/definitions#mqtt-broker)
`MQTT_MAX_PAYLOAD_SIZE` | `50000` | Максимальный размер в символах, для данных передаваемых через топики [EMQX MQTT Broker](/definitions#mqtt-broker)
`MQTT_REDIS_AUTH_URL` | `redis://redis:6379/0` | Ссылка для доступа к [Redis](/deployment/dependencies#redis), которую использует [EMQX MQTT Broker](/definitions#mqtt-broker) для соединения c [Redis](/deployment/dependencies#redis). Инстанс [Redis](/deployment/dependencies#redis) должен быть единым с `REDIS_URL`
`REDIS_URL` | `redis://redis:6379/0` | Ссылка для доступа к [Redis](/deployment/dependencies#redis), которую использует [Backend](/definitions#backend) для соединения c [Redis](/deployment/dependencies#redis). Инстанс [Redis](/deployment/dependencies#redis) должен быть единым с `MQTT_REDIS_AUTH_URL`

## Frontend

:::warning
На фронтенде нет значений по умолчанию.
:::

Переменная | Пример | Зачем нужна?
-- | -- | --
`VITE_INSTANCE_NAME` | `example.com` | Используется для генерации ссылок между разными `Node` основного графа
`VITE_SELF_URI` | `https://example.com/` | Используется для тегов `og:url` и `og:image` в `index.html`
`VITE_BACKEND_URI` | `https://example.com/pepeunit/graphql` | Используется для отправки [GQL](/definitions#gql) запросов к [Backend](/definitions#backend)
