# EMQX

:::info
В файл настроек эти переменные не пишутся: имя и пароль `docker-compose.yml` берёт из `PU_MQTT_USERNAME` и `PU_MQTT_PASSWORD`, остальное в нём уже задано.
:::

:::warning
Полный список переменных в [документации EMQX](https://docs.emqx.com/en/emqx/latest/)
:::

Переменная | Значение | Зачем нужна?
-- | -- | --
EMQX_DASHBOARD__DEFAULT_USERNAME | PU_MQTT_USERNAME | Имя администратора [EMQX](/deployment/dependencies/emqx), под ним [Backend](/deployment/dependencies/backend) настраивает брокер
EMQX_DASHBOARD__DEFAULT_PASSWORD | PU_MQTT_PASSWORD | Пароль администратора [EMQX](/deployment/dependencies/emqx)
EMQX_PROMETHEUS__ENABLE_BASIC_AUTH | false | Отключает пароль на метриках, чтобы [Prometheus](/deployment/dependencies/prometheus) мог их читать

:::danger
Пароль администратора задаётся при создании тома `emqx_data`. Позже меняйте его одновременно в самом [EMQX](/deployment/dependencies/emqx) и в `PU_MQTT_PASSWORD`.
:::
