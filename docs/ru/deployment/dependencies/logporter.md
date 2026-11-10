# Logporter

`Logporter` - лёгкая замена `cAdvisor`: собирает метрики контейнеров через `Docker API`. Контейнер `logporter`, порт `9333`.

:::info
Он следит за всеми контейнерами: процессор, память, сеть, диск, время работы. [Prometheus](/deployment/dependencies/prometheus) забирает эти данные для панели `Docker Resource Metrics` в [Grafana](/deployment/dependencies/grafana).
:::
