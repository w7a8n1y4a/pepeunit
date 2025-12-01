# Promtail

`Promtail` - агент сбора логов с открытым исходным кодом, входящий в стек `Grafana Loki`, который читает логи из файлов, системных журналов `systemd-journal`, `Kubernetes-подов` или `docker containers`, добавляет метки `labels` и отправляет их в [Loki](/deployment/dependencies/loki) для хранения и анализа.

:::info
`Promtail` в [Pepeunit](/conception/overview) используется для получения данных из `/var/lib/docker/containers:ro` и `/var/run/docker.sock:ro` с последующей отправкой в [Loki](/deployment/dependencies/loki).

Позволяет в отличии от  [Logporter](/deployment/dependencies/logporter) также получать информацию о используемых ресурсах.
:::