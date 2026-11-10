# Grafana Monitoring

## Services
Four monitoring services are started with the instance by default:
- [Prometheus](/deployment/dependencies/prometheus)
- [Logporter](/deployment/dependencies/logporter)
- [Loki](/deployment/dependencies/loki)
- [Promtail](/deployment/dependencies/promtail)

Together with [Grafana](/deployment/dependencies/grafana) they provide a set of panels about the state of the instance. Panels of [Users](/development-pepeunit/mechanics/roles#user) with UnitIO data charts are created from the client and are not related to them.

## Grafana Dashboards

Ready-made panels are connected automatically from the `data/grafana/provisioning/dashboards` directory into the `Main Org` organization. Data in [Grafana](/deployment/dependencies/grafana) is refreshed no more often than once a minute.

All panels are visible to the `Grafana` administrator; other [Users](/development-pepeunit/mechanics/roles#user) work in their own organization, see [Signing in to Grafana](/deployment/dependencies/grafana#signing-in-to-grafana).

Name | Access | Description
-- | -- | --
Docker Logs | Admin | Logs of any containers
Backend Aggregated Logs | Admin | `Backend` logs grouped by message with a level selector
Backend Load Metrics | View | `Backend` load
EMQX Load Metrics | View | `EMQX` load
Docker Resource Metrics | View | Resources consumed by the system and by each container

:::warning
The logs contain everything the containers write. Leave access to `Docker Logs` and `Backend Aggregated Logs` to the administrator only.
:::

## Turning off monitoring

1. In `docker-compose.yml`, comment out the four services, and remove `prometheus` from `depends_on` of `grafana`
1. Turn off the `pu_ff_prometheus_enable` flag in the [instance settings](/deployment/instance-settings#flags) and restart the server: [applying changes](/deployment/instance-settings#applying-changes)
1. Delete all `.json` files from `data/grafana/provisioning/dashboards`
1. Restart Pepeunit: [docker compose commands](/deployment/docker/commands)

:::warning
`Grafana` is needed for the panels of Users, do not turn it off.
:::
