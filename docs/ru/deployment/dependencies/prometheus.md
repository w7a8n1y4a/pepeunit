# Prometheus

`Prometheus` - система сбора метрик. Контейнер `prometheus`, порт `9090`.

:::info
Он собирает данные для [Мониторинга](/deployment/monitoring) и отдаёт их в [Grafana](/deployment/dependencies/grafana):

Что собирает | Период
-- | --
[Backend](/deployment/dependencies/backend) | 5 с
[EMQX](/deployment/dependencies/emqx) | 10 с
[Logporter](/deployment/dependencies/logporter) | 15 с
Сам `Prometheus` | 15 с
:::

Метрики `Backend` публикуются, пока включён флаг `pu_ff_prometheus_enable` в [настройках инстанса](/deployment/instance-settings).

Конфиг `data/prometheus/prometheus.yml` собирает `make_env.py` из шаблона `prometheus.yml.template`. Правьте шаблон, а не готовый файл.
