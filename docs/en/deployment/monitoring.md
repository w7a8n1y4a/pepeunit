# Grafana Monitoring

By default, the following services are added to `docker compose`:
- [Prometheus](/en/deployment/dependencies/prometheus)
- [Logporter](/en/deployment/dependencies/logporter)
- [Loki](/en/deployment/dependencies/loki)
- [Promtail](/en/deployment/dependencies/promtail)

These `4` containers together with [Grafana](/en/deployment/dependencies/grafana) provide a set of `Grafana Dashboards` describing the state of a [Pepeunit](/en/conception/overview) instance.

## Grafana Dashboards

These dashboards are available by default in `Main Org`. Regular [Users](/en/development-pepeunit/mechanics/roles#user) have `View` access. `Admin` access is available only when logging in with `GF_SECURITY_ADMIN_USER` and `GF_SECURITY_ADMIN_PASSWORD`.

Name | Required access | Description
-- | -- | --
`Docker Logs` | `Admin` | View logs of any container
`Backend Aggregated Logs` | `Admin` | View [Backend](/en/deployment/dependencies/backend) logs aggregated by message with the ability to filter by log levels
`Backend Load Metrics` | `View` | Shows request load on the most important part of the system – the [Backend](/en/deployment/dependencies/backend)
`EMQX Load Metrics` | `View` | Shows load on [EMQX](/en/deployment/dependencies/emqx), the main data manager in the system
`Docker Resource Metrics` | `View` | Shows resource usage by the system as a whole and by each container separately

::::warning
You can disable monitoring functionality by following these steps:
1. Comment out the 4 services listed above in `docker compose`
1. Set environment variable [EMQX_PROMETHEUS__METRICS__ENABLED](/en/deployment/env-variables/emqx) to `false`
1. Set environment variable [PU_FF_PROMETHEUS_ENABLE](/en/deployment/env-variables/backend) to `False`
1. Remove from the deployment repository all `.json` `Dashboard` files in the `data/grafana/dashboards` directory
1. Restart [Pepeunit](/en/conception/overview) using the [docker compose commands](/en/deployment/docker/commands)
::::

