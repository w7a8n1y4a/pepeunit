# Grafana

:::warning
Ручное заполнение обычно не требуется, нужно заполнить только основные переменные т.к. есть [файл генерации .env файлов для сервисов](/deployment/docker/deploy#заполнение-первичного-env-фаила)
:::

:::warning
Полный список переменных окружения доступен в [документации Grafana](https://grafana.com/docs/)
:::

Переменная | Пример | Зачем нужна?
-- | -- | --
`GF_SECURITY_ADMIN_USER` | `admin` | Имя пользователя для сервисного аккаунта
`GF_SECURITY_ADMIN_PASSWORD` | `grafanapassword` | Пароль пользователя для сервисного аккаунта
`GF_USERS_ALLOW_SIGN_UP` | `false` | Признак разрешения авторизации обычным пользователям через логин пароль
`GF_SERVER_DOMAIN` | `unit.example.com` | Домен, на котором будет работать [Grafana](/deployment/dependencies/grafana)
`GF_SERVER_ROOT_URL` | `%(protocol)s://%(domain)s/grafana/` | Корневой путь до [Grafana](/deployment/dependencies/grafana), используется чтобы сместить его, например, дополнительным префиксом `grafana/`
`GF_SERVER_SERVE_FROM_SUB_PATH` | `true` | Указываает [Grafana](/deployment/dependencies/grafana), что она работает с префиксом в `url`
`GF_LOG_LEVEL` | `error` | Уровень логов, ниже которого ничего не пишется
`GF_INSTALL_PLUGINS` | `yesoreyeram-infinity-datasource,marcusolsson-hourly-heatmap-panel` | Установленные по умолчанию `plugins`
