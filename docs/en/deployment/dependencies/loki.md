# Loki

`Loki` is an open-source log aggregation and storage system developed by `Grafana Labs`, designed for collecting, indexing and analyzing logs in distributed systems.

::::info
In [Pepeunit](/en/conception/overview), `Loki` is used to aggregate data from [Promtail](/en/deployment/dependencies/promtail) and to provide this data to [Grafana](/en/deployment/dependencies/grafana). The [Administrator](/en/development-pepeunit/mechanics/roles#admin) daily summary reads `ERROR` and `CRITICAL` groups of the [Backend](/en/deployment/dependencies/backend) for the last day from here. The address can be changed with `PU_NOTIFICATION_LOKI_URL`
::::

