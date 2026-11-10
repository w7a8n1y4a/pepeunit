# Promtail

`Promtail` is an agent from the `Grafana Loki` stack: it reads logs and sends them to [Loki](/deployment/dependencies/loki). Container `promtail`.

:::info
In Pepeunit it collects the logs of all containers. `backend` logs get the label `app="backend"`; the `Backend Aggregated Logs` dashboard and the daily error digest rely on it.
:::
