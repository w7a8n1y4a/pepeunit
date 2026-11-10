# Backend

You do not need to fill in `.env` by hand: all variables live in one [settings file](/deployment/docker/deploy#settings-file), and `make_env.py` builds `.env` from it. If a variable is not set, [Backend](/deployment/dependencies/backend) uses the default value. If it is set incorrectly, it prints errors to the log and does not start.

This lists only what cannot be changed on a running instance. Flags, limits, the Telegram Bot and logs are changed from the client: [Instance settings](/deployment/instance-settings).

## Address and startup

Variable | Default | Values | What is it for?
-- | -- | -- | --
PU_DOMAIN | - | hostname, up to 128 characters | Domain or `ip` of the instance without `http://`. It ends up in links, in the [Unit ENV](/developer/files/struct-env-example-json) and in MQTT topic names
PU_SECURE | True | True / False | If True, links are built with `https`
PU_APP_PREFIX | /pepeunit | starts with `/`, does not end with `/` | Address prefix of [Backend](/deployment/dependencies/backend), usually not changed
PU_API_V1_PREFIX | /api/v1 | starts with `/` | REST API version prefix
PU_WORKER_COUNT | 2 | 2–128 | Number of workers. More workers - more load Backend can handle
PU_SAVE_REPO_PATH | repo_cache | up to 128 characters | Directory for downloaded Git repositories, the `backend_repo_cache` volume is mounted to it
PU_PROMETHEUS_MULTIPROC_DIR | ./prometheus_metrics | up to 128 characters | Directory for [Prometheus](/deployment/dependencies/prometheus) metrics, cleared on start

## Secret keys

Variable | Default | Values | What is it for?
-- | -- | -- | --
PU_SECRET_KEY | - | 16–128 characters | Key for signing authorization tokens. After it is changed, all issued tokens stop working
PU_ENCRYPT_KEY | - | base64, 16, 24 or 32 bytes | Data encryption key. After it is changed, encrypted data cannot be decrypted

:::info
In the settings file, leave `<32-bit-key>` as the value of both keys: `make_env.py` will create the keys on the first run and will not touch them again.
:::

## Databases

Variable | Default | Values | What is it for?
-- | -- | -- | --
PU_SQLALCHEMY_DATABASE_URL | - | postgresql, postgresql+psycopg2 or postgresql+asyncpg | Address of [PostgreSQL](/deployment/dependencies/postgresql). `make_env.py` takes `POSTGRES_USER`, `POSTGRES_PASSWORD` and `POSTGRES_DB` from it
PU_CLICKHOUSE_DATABASE_URL | - | clickhouse+native://user:password@host:port/db | Address of [ClickHouse](/deployment/dependencies/clickhouse). `CLICKHOUSE_USER`, `CLICKHOUSE_PASSWORD` and `CLICKHOUSE_DB` are taken from it
PU_REDIS_URL | redis://redis:6379/0 | redis or rediss | Address of [Redis](/deployment/dependencies/redis) for Backend. Must match `PU_MQTT_REDIS_AUTH_URL`

## EMQX

Variable | Default | Values | What is it for?
-- | -- | -- | --
PU_MQTT_HOST | - | hostname, up to 128 characters | Domain or `ip` of [EMQX](/deployment/dependencies/emqx) without `http://`. Unit and Backend connect through it
PU_MQTT_SECURE | True | True / False | How [Backend](/deployment/dependencies/backend) finds the EMQX REST API: with True over `https`, otherwise over `http`. More in [How Backend configures EMQX](/deployment/dependencies/emqx#how-backend-configures-emqx)
PU_MQTT_PORT | 1883 | 1–65535 | MQTT port for Unit and Backend. If you change it, also change the `emqx` port in `docker-compose.yml`
PU_MQTT_API_PORT | 18083 | 1–65535 | EMQX REST API port when `PU_MQTT_SECURE=False`
PU_MQTT_USERNAME | - | not empty | EMQX administrator name
PU_MQTT_PASSWORD | - | not empty | EMQX administrator password
PU_MQTT_REDIS_AUTH_URL | redis://redis:6379/0 | redis or rediss | Redis address for EMQX. Must match `PU_REDIS_URL`

## Grafana and Loki

Variable | Default | Values | What is it for?
-- | -- | -- | --
PU_GRAFANA_ADMIN_USER | empty | up to 128 characters | [Grafana](/deployment/dependencies/grafana) administrator login. Without it and the password, the [Grafana integration](/deployment/instance-settings#flags) cannot be turned on
PU_GRAFANA_ADMIN_PASSWORD | empty | up to 128 characters | Grafana administrator password
PU_NOTIFICATION_LOKI_URL | http://loki:3100 | http or https | Address of [Loki](/deployment/dependencies/loki) for the daily error digest

## Testing

:::info
The `PU_TEST_*` and `LOCUST_*` variables are needed only when running tests; nobody passes them to the container:
- [Integration tests](/development-pepeunit/tests/integration-test#integration-test-variables)
- [MQTT load tests](/development-pepeunit/tests/load-test#mqtt-testing)
- [REST load tests](/development-pepeunit/tests/load-test#rest-testing)
:::
