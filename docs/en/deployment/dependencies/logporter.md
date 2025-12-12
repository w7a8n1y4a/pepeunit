# Logporter

`Logporter` is a simple and lightweight tool for collecting basic metrics from `Docker` containers. It gathers information about load and other parameters from container logs. It serves as an alternative to `cAdvisor`, providing Docker monitoring based on metrics extracted from logs.

::::info
In [Pepeunit](/en/conception/overview), `Logporter` is used to collect logs from all containers accessible via `/var/run/docker.sock:ro` and to send the collected data to [Prometheus](/en/deployment/dependencies/prometheus).
::::

