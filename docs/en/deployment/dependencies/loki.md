# Loki

`Loki` is a log storage system from `Grafana Labs`. Container `loki`, port `3100`, data in the `loki_data` volume.

:::info
`Loki` receives logs from [Promtail](/deployment/dependencies/promtail) and serves them to [Grafana](/deployment/dependencies/grafana). Logs are kept for 7 days.
:::

The daily error digest for the [Admin](/development-pepeunit/mechanics/roles#admin) reads `ERROR` and `CRITICAL` records for the last day from `Loki`. The address can be changed with `PU_NOTIFICATION_LOKI_URL`.

:::warning
The digest reads logs as `JSON`. If you choose the `plain` format in the [instance settings](/deployment/instance-settings#logs), it will stop finding errors.
:::

The `loki_data` volume is not included in [backups](/deployment/docker/backup-update).
