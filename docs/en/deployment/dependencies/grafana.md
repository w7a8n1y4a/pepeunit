# Grafana

[Grafana](https://grafana.com/) is a data visualization platform. Container `grafana`, address `/grafana/` on the same domain, data in the `grafana_data` volume. [Environment variables](/deployment/env-variables/grafana)

:::info
In Pepeunit, `Grafana` draws charts of [DataPipe](/deployment/dependencies/datapipe) data and shows [Monitoring](/deployment/monitoring). For monitoring it takes data from [Prometheus](/deployment/dependencies/prometheus) and [Loki](/deployment/dependencies/loki).
:::

[Users](/development-pepeunit/mechanics/roles#user) create dashboards right in the client, in the `Dashboards` section: `Backend` itself creates in `Grafana` the pages and charts that UnitIO are bound to.

## Signing in to Grafana

Regular users have no passwords: they open a dashboard from the client, and `Grafana` signs them in through `Pepeunit`. For each [User](/development-pepeunit/mechanics/roles#user), `Backend` creates a separate organization with the `Editor` role. `make_env.py` writes the sign-in addresses into `data/grafana/grafana.ini`.

The administrator signs in with the login and password from `PU_GRAFANA_ADMIN_USER` and `PU_GRAFANA_ADMIN_PASSWORD`. Only the administrator sees the monitoring dashboards, see [Monitoring](/deployment/monitoring#grafana-dashboards).

:::warning
Without `PU_GRAFANA_ADMIN_USER` and `PU_GRAFANA_ADMIN_PASSWORD`, the `pu_ff_grafana_integration_enable` flag cannot be turned on.

`Backend` reaches `Grafana` at the `PU_DOMAIN` address, not by container name. This address must open from inside the `backend` container, otherwise dashboards will not be created. For a public domain, check that the server can see itself.
:::

Connections to [Prometheus](/deployment/dependencies/prometheus) and [Loki](/deployment/dependencies/loki) and the ready-made dashboards are in `data/grafana/provisioning` of the [Pepeunit Deploy](/deployment/docker/deploy) repository.
