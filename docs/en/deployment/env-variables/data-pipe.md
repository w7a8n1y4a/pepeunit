# Data Pipe

::::warning
Manual editing is usually not required; you typically only need to fill in the main variables because there is a [file that generates .env files for services](/en/deployment/docker/deploy#filling-the-primary-env-file).
::::

Variable | Default | Purpose
-- | -- | -- 
`PU_DP_DOMAIN` | - | Domain name or IP – used to correctly subscribe to topics
`PU_DP_SECRET_KEY` | - | `32‑byte key` in `base64` format. Used to sign auth tokens. If changed, all previously issued `jwt` tokens become invalid
`PU_DP_SQLALCHEMY_DATABASE_URL` | - | Connection URL for [PostgreSQL](/en/deployment/dependencies/postgresql)
`PU_DP_CLICKHOUSE_DATABASE_URL` | - | Connection URL for [ClickHouse](/en/deployment/dependencies/clickhouse)
`PU_DP_REDIS_URL` | `redis://redis:6379/0` | [Redis](/en/deployment/dependencies/redis) connection URL used to exchange [UnitNode](/en/definitions#unitnode) configurations between [Backend](/en/deployment/dependencies/backend) and [DataPipe](/en/deployment/dependencies/datapipe)
`PU_DP_MQTT_HOST` | - | Domain name or IP used to connect to [EMQX](/en/deployment/dependencies/emqx)
`PU_DP_MQTT_PORT` | `1883` | Port used to connect to [EMQX](/en/deployment/dependencies/emqx)
`PU_DP_MQTT_KEEPALIVE` | `60` | Maximum period in seconds between `ping` messages from [DataPipe](/en/deployment/dependencies/datapipe) to [EMQX](/en/deployment/dependencies/emqx)
`PU_DP_CONFIG_SYNC_INTERVAL` | `60` | Interval in seconds between repeated [YML](/en/definitions#yml) configuration requests
`PU_DP_NRECORDS_CLEANUP_INTERVAL` | `60` | Interval in seconds between cleanup runs that remove excess `N Records` data
`PU_DP_BUFFER_FLUSH_INTERVAL` | `5` | Interval in seconds after which data will be flushed to [ClickHouse](/en/deployment/dependencies/clickhouse) or [PostgreSQL](/en/deployment/dependencies/postgresql) regardless of the number of accumulated records
`PU_DP_BUFFER_MAX_SIZE` | `1000` | Maximum queue size; when exceeded, data is written to [ClickHouse](/en/deployment/dependencies/clickhouse) or [PostgreSQL](/en/deployment/dependencies/postgresql) immediately without waiting for `PU_DP_BUFFER_FLUSH_INTERVAL`


