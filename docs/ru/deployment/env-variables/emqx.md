# EMQX

:::warning
Ручное заполнение обычно не требуется, нужно заполнить только основные переменные т.к. есть [файл генерации .env файлов для сервисов](/deployment/docker/deploy#заполнение-первичного-env-фаила)
:::

:::warning
Полный список переменных окружения доступен в [документации EMQX](https://docs.emqx.com/en/emqx/latest/)
:::

Переменная | Пример | Зачем нужна?
-- | -- | --
`EMQX_DASHBOARD__DEFAULT_USERNAME` | `admin` | Имя пользователя для сервисного аккаунта
`EMQX_DASHBOARD__DEFAULT_PASSWORD` | `password` | Пароль пользователя для сервисного аккаунта
`EMQX_PROMETHEUS__METRICS__ENABLED` | `true` | Признак включения метрик нагрузки
