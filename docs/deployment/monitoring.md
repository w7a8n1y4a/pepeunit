# Grafana Мониторинг

По умолчанию в `docker compose` добавлены:
1. `promtail` - парсинг логов из `Docker`
1. `logporter` - парсинг нагрузки на контейнеры из `Docker`
1. `loki` - агрегатор данных для [Grafana](/deployment/dependencies#grafana), используется для `promtail`
1. `prometheus` - агрегатор данных для [Grafana](/deployment/dependencies#grafana), используется для [Backend](/definitions#backend), [EMQX MQTT Broker](/definitions#mqtt-broker), `logporter`

Эти 4 контейнера вместе с [Grafana](/deployment/dependencies#grafana) позволяют мониторить состояние [инстанса](/definitions#instance) [Pepeunit](/conception/overview)

## Grafana Dashboards

1. `Backend Load Metrics` - позволяет оценить нагрузку в запросах на самую важную часть системы: [Backend](/definitions#backend)
1. `EMQX Load Metrics` - показывает нагрузку на [EMQX MQTT Broker](/definitions#mqtt-broker) - основного менеджер данных в системе
1. `Docker Resource Metrics` - показывает какой объём ресурсов потребляет система в целом и для каждого контейенера
1. `Docker Logs` - просмотр логов любых контейнеров
