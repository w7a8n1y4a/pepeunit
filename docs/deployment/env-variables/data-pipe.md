# Data Pipe

:::warning
Ручное заполнение обычно не требуется, нужно заполнить только основные переменные т.к. есть [файл генерации .env файлов для сервисов](/deployment/docker/deploy#заполнение-первичного-env-фаила)
:::

Переменная | По умолчанию | Зачем нужна?
-- | -- | -- 
`PU_DP_DOMAIN` | - | Доменное имя или `ip` - позволяет корректно подписаться на топики.
`PU_DP_SECRET_KEY` | - | `32 байтовый ключ` в формате `base64`. Отвечает за подпись токенов авторизации. В случае изменения все `jwt` токены созданные до изменения - становятся не действительными
`PU_DP_SQLALCHEMY_DATABASE_URL` | - | Ссылка для подключения к [PostgreSQL](/deployment/dependencies/postgresql)
`PU_DP_CLICKHOUSE_DATABASE_URL` | - | Ссылка для подключения к [ClickHouse](/deployment/dependencies/clickhouse)
`PU_DP_REDIS_URL` | `redis://redis:6379/0` | Ссылка для доступа к [Redis](/deployment/dependencies/redis) - используется для обмена конфигурациями [UnitNode](/definitions#unitnode) между [Backend](/deployment/dependencies/backend) и [DataPipe](/deployment/dependencies/datapipe)
`PU_DP_MQTT_HOST` | - | Доменное имя или `ip`. Позволяет корректно подключиться к [EMQX](/deployment/dependencies/emqx).
`PU_DP_MQTT_PORT` | `1883` | Порт позволяющий корректно подключиться к [EMQX](/deployment/dependencies/emqx).
`PU_DP_MQTT_KEEPALIVE` | `60` | Максимальный период в секундах между отправками `ping` от [DataPipe](/deployment/dependencies/datapipe) до [EMQX](/deployment/dependencies/emqx)
`PU_DP_CONFIG_SYNC_INTERVAL` | `60` | Период времени в секундах между повторными запросами конфигурации [YML](/definitions#yml)
`PU_DP_NRECORDS_CLEANUP_INTERVAL` | `60` | Период времени в секундах между запусками задачи удаления накопившихся всверх предела записей `N Records`
`PU_DP_BUFFER_FLUSH_INTERVAL` | `5` | Период времени в секундах, по истечении которого, не зависимо от числа пришедших записей, данные будут сохранены в [ClickHouse](/deployment/dependencies/clickhouse) или [PostgreSQL](/deployment/dependencies/postgresql)
`PU_DP_BUFFER_MAX_SIZE` | `1000` | Предельная длинна очереди, при превышении которой запись в [ClickHouse](/deployment/dependencies/clickhouse) или [PostgreSQL](/deployment/dependencies/postgresql) выполняется не дожидаясь интервала `PU_DP_BUFFER_FLUSH_INTERVAL`