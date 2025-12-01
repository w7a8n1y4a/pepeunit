# Grafana Мониторинг

По умолчанию в `docker compose` добавлены:
- [Prometheus](/deployment/dependencies/prometheus)
- [Logporter](/deployment/dependencies/logporter)
- [loki](/deployment/dependencies/loki)
- [promtail](/deployment/dependencies/promtail)

Эти `4` контейнера вместе с [Grafana](/deployment/dependencies/grafana) позволяют создать набор `Grafana Dashboards` о состоянии [инстанса](/definitions#instance) [Pepeunit](/conception/overview)

## Grafana Dashboards

1. `Backend Load Metrics` - позволяет оценить нагрузку в запросах на самую важную часть системы: [Backend](/definitions#backend)
1. `EMQX Load Metrics` - показывает нагрузку на [EMQX MQTT Broker](/definitions#mqtt-broker) - основного менеджера данных в системе
1. `Docker Resource Metrics` - показывает какой объём ресурсов потребляет система в целом и для каждого контейенера в отдельности
1. `Docker Logs` - просмотр логов любых контейнеров

:::warning
Функционал мониторинга можно выключить используя следующие шаги:
1. Закоментировать указанные `4` сервиса в `docker compose`
1. Установить переменную окружения [EMQX_PROMETHEUS__METRICS__ENABLED](/deployment/env-variables/emqx) как `false`
1. Установить переменную окружения [PU_FF_PROMETHEUS_ENABLE](/deployment/env-variables/backend) как `False`
1. Удалив из репозитория развёртывания `json Dashboards` в дирректории `data/grafana/dashboards` все файлы с расширением `.json`
1. Перезапустить [Pepeunit](/conception/overview) при помощи [команд docker compose](/deployment/docker/commands)
:::