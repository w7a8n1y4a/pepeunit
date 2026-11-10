# Backend

:::warning
Заполнять вручную обычно не нужно: все переменные лежат в одном [файле настроек](/deployment/docker/deploy#файл-настроек), а `make_env.py` собирает из него `.env`. Если переменная не задана, [Backend](/deployment/dependencies/backend) подставит значение по умолчанию.
:::

:::info
Здесь только то, что нельзя изменить на работающем инстансе. Флаги, лимиты, Telegram Bot и логи меняются из клиента: [Настройки инстанса](/deployment/instance-settings). Если переменная указана неверно, [Backend](/deployment/dependencies/backend) выведет ошибки в лог и не запустится.
:::

## Адрес и запуск

Переменная | По умолчанию | Значения | Зачем нужна?
-- | -- | -- | --
PU_DOMAIN | - | hostname, до 128 символов | Домен или `ip` инстанса без `http://`. Попадает в ссылки, [Unit ENV](/developer/files/struct-env-example-json) и имена MQTT топиков
PU_SECURE | True | True / False | Если True, ссылки строятся с `https`
PU_APP_PREFIX | /pepeunit | начинается с `/`, не заканчивается на `/` | Префикс адреса [Backend](/deployment/dependencies/backend), обычно не меняется
PU_API_V1_PREFIX | /api/v1 | начинается с `/` | Префикс версии REST API
PU_WORKER_COUNT | 2 | 2–128 | Число воркеров. Больше воркеров - выше нагрузка, которую выдержит [Backend](/deployment/dependencies/backend)
PU_SAVE_REPO_PATH | repo_cache | до 128 символов | Каталог для скачанных Git репозиториев, к нему подключён том `backend_repo_cache`
PU_PROMETHEUS_MULTIPROC_DIR | ./prometheus_metrics | до 128 символов | Каталог для метрик [Prometheus](/deployment/dependencies/prometheus), очищается при старте

## Секретные ключи

Переменная | По умолчанию | Значения | Зачем нужна?
-- | -- | -- | --
PU_SECRET_KEY | - | 16–128 символов | Ключ подписи токенов авторизации. После смены все выданные токены перестают работать
PU_ENCRYPT_KEY | - | base64, 16, 24 или 32 байта | Ключ шифрования данных. После смены зашифрованные данные не расшифровать

:::info
В файле настроек оставьте у обоих ключей значение `<32-bit-key>`: `make_env.py` создаст ключи при первом запуске и больше не тронет.
:::

## Базы данных

Переменная | По умолчанию | Значения | Зачем нужна?
-- | -- | -- | --
PU_SQLALCHEMY_DATABASE_URL | - | postgresql, postgresql+psycopg2 или postgresql+asyncpg | Адрес [PostgreSQL](/deployment/dependencies/postgresql). Из него `make_env.py` берёт `POSTGRES_USER`, `POSTGRES_PASSWORD` и `POSTGRES_DB`
PU_CLICKHOUSE_DATABASE_URL | - | clickhouse+native://user:password@host:port/db | Адрес [ClickHouse](/deployment/dependencies/clickhouse). Из него берутся `CLICKHOUSE_USER`, `CLICKHOUSE_PASSWORD` и `CLICKHOUSE_DB`
PU_REDIS_URL | redis://redis:6379/0 | redis или rediss | Адрес [Redis](/deployment/dependencies/redis) для [Backend](/deployment/dependencies/backend). Должен совпадать с `PU_MQTT_REDIS_AUTH_URL`

## EMQX

Переменная | По умолчанию | Значения | Зачем нужна?
-- | -- | -- | --
PU_MQTT_HOST | - | hostname, до 128 символов | Домен или `ip` [EMQX](/deployment/dependencies/emqx) без `http://`. По нему подключаются Unit и [Backend](/deployment/dependencies/backend)
PU_MQTT_SECURE | True | True / False | Как [Backend](/deployment/dependencies/backend) находит REST API [EMQX](/deployment/dependencies/emqx): при True по `https`, иначе по `http`. Подробнее в [EMQX](/deployment/dependencies/emqx#как-backend-настраивает-emqx)
PU_MQTT_PORT | 1883 | 1–65535 | MQTT порт для Unit и [Backend](/deployment/dependencies/backend). Если меняете, поменяйте и порт `emqx` в `docker-compose.yml`
PU_MQTT_API_PORT | 18083 | 1–65535 | Порт REST API [EMQX](/deployment/dependencies/emqx) при `PU_MQTT_SECURE=False`
PU_MQTT_USERNAME | - | не пусто | Имя администратора [EMQX](/deployment/dependencies/emqx)
PU_MQTT_PASSWORD | - | не пусто | Пароль администратора [EMQX](/deployment/dependencies/emqx)
PU_MQTT_REDIS_AUTH_URL | redis://redis:6379/0 | redis или rediss | Адрес [Redis](/deployment/dependencies/redis) для [EMQX](/deployment/dependencies/emqx). Должен совпадать с `PU_REDIS_URL`

## Grafana и Loki

Переменная | По умолчанию | Значения | Зачем нужна?
-- | -- | -- | --
PU_GRAFANA_ADMIN_USER | пусто | до 128 символов | Логин администратора [Grafana](/deployment/dependencies/grafana). Без него и без пароля [интеграцию с Grafana](/deployment/instance-settings#флаги) включить нельзя
PU_GRAFANA_ADMIN_PASSWORD | пусто | до 128 символов | Пароль администратора [Grafana](/deployment/dependencies/grafana)
PU_NOTIFICATION_LOKI_URL | http://loki:3100 | http или https | Адрес [Loki](/deployment/dependencies/loki) для ежедневной сводки ошибок

## Тестирование

:::info
Переменные `PU_TEST_*` и `LOCUST_*` нужны только при запуске тестов, контейнеру их никто не передаёт:
- [Интеграционные тесты](/development-pepeunit/tests/integration-test#переменные-интеграционного-тестирования)
- [Нагрузочные тесты MQTT](/development-pepeunit/tests/load-test#тестирование-mqtt)
- [Нагрузочные тесты REST](/development-pepeunit/tests/load-test#тестирование-rest)
:::
