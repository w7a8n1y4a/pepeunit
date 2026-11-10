# Logporter

`Logporter` is a lightweight replacement for `cAdvisor`: it collects container metrics through the `Docker API`. Container `logporter`, port `9333`.

:::info
It watches all containers: CPU, memory, network, disk, uptime. [Prometheus](/deployment/dependencies/prometheus) picks up this data for the `Docker Resource Metrics` dashboard in [Grafana](/deployment/dependencies/grafana).
:::
