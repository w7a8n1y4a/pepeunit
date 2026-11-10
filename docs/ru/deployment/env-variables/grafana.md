# Grafana

:::info
В файл настроек эти переменные не пишутся: логин и пароль `docker-compose.yml` берёт из `PU_GRAFANA_ADMIN_USER` и `PU_GRAFANA_ADMIN_PASSWORD`, домен из `PU_DOMAIN`, остальное в нём уже задано. Вход через `Pepeunit` настроен в `data/grafana/grafana.ini`, его собирает `make_env.py`.
:::

Полный список переменных: [документация Grafana](https://grafana.com/docs/).

Переменная | Значение | Зачем нужна?
-- | -- | --
GF_SECURITY_ADMIN_USER | PU_GRAFANA_ADMIN_USER | Логин администратора
GF_SECURITY_ADMIN_PASSWORD | PU_GRAFANA_ADMIN_PASSWORD | Пароль администратора
GF_USERS_ALLOW_SIGN_UP | false | Запрещает самостоятельную регистрацию: пользователи входят через `Pepeunit`
GF_SERVER_DOMAIN | PU_DOMAIN | Домен Grafana
GF_SERVER_ROOT_URL | %(protocol)s://%(domain)s/grafana/ | Корневой адрес с префиксом `/grafana/`
GF_SERVER_SERVE_FROM_SUB_PATH | true | Сообщает, что Grafana работает под префиксом
GF_LOG_LEVEL | error | Минимальный уровень логов
GF_PLUGINS_PREINSTALL_SYNC | yesoreyeram-infinity-datasource,marcusolsson-hourly-heatmap-panel | Плагины, которые ставятся при запуске
