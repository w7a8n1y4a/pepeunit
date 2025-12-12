# Promtail

`Promtail` is an open-source log collection agent that is part of the `Grafana Loki` stack. It reads logs from files, `systemd-journal`, `Kubernetes pods` or `docker containers`, adds `labels` and sends them to [Loki](/en/deployment/dependencies/loki) for storage and analysis.

::::info
In [Pepeunit](/en/conception/overview), `Promtail` is used to read data from `/var/lib/docker/containers:ro` and `/var/run/docker.sock:ro` and then send it to [Loki](/en/deployment/dependencies/loki).

Unlike [Logporter](/en/deployment/dependencies/logporter), it also allows retrieving information about resource usage.
::::

