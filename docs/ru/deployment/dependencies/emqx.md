# EMQX

[EMQX](https://docs.emqx.com/en/emqx/latest/) - MQTT брокер: через него Unit, [Backend](/deployment/dependencies/backend) и [DataPipe](/deployment/dependencies/datapipe) обмениваются сообщениями. Контейнер `emqx`, порт `1883`. [Переменные окружения](/deployment/env-variables/emqx)

Кто к каким топикам обращается (`example.com` - это `PU_DOMAIN`):

- Unit публикует и читает свои топики
- Backend читает все топики и по запросу [Пользователя](/development-pepeunit/mechanics/roles#user) отправляет команды в `Input` топики Unit
- DataPipe читает топики с данными Unit

## Как Backend настраивает EMQX

При каждом старте Backend заходит в REST API брокера под `PU_MQTT_USERNAME` и `PU_MQTT_PASSWORD` и:
1. Настраивает авторизацию Unit и Backend через [Redis](/deployment/dependencies/redis)
1. Применяет лимиты из [настроек инстанса](/deployment/instance-settings#mqtt)
1. Отключает `retainer`

Поэтому лимиты `EMQX` меняются в клиенте, а не в `docker-compose.yml`, и действуют после [перезапуска сервера](/deployment/instance-settings#применение-изменений).

:::warning
Как Backend находит REST API брокера, зависит от `PU_MQTT_SECURE`:
- `False` - по адресу `http://PU_MQTT_HOST:PU_MQTT_API_PORT`
- `True` - по адресу `https://PU_MQTT_HOST`, порт `443`

Для публичного инстанса это значит, что у `PU_MQTT_HOST` должно быть доменное имя с сертификатом, а внешний [Nginx](/deployment/nginx#emqx-api-за-https) должен передавать запросы на порт `18083`. Сами MQTT сообщения при этом идут без шифрования.
:::

Метрики [Prometheus](/deployment/dependencies/prometheus) читает с брокера без пароля, в `docker-compose.yml` это уже настроено.

Об MQTT:
- [Стандартные MQTT команды](/developer/mqtt/default-mqtt-command)
- [Стандартные MQTT топики состояния](/developer/mqtt/state-mqtt-send)
- [Структура сообщений в MQTT топиках](/developer/mqtt/struct-topic-messages)
