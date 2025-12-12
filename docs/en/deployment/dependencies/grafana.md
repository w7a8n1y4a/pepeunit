# Grafana

[Grafana](https://grafana.com/) is an open-source platform designed for data visualization and analytics. [More about environment variables](/en/deployment/env-variables/grafana)

::::info
`Grafana` is integrated into the [Pepeunit](/en/conception/overview) workflow to visualize data from [DataPipe](/en/deployment/dependencies/datapipe) and to display [Monitoring](/en/deployment/monitoring) data.
::::

Visualization settings can be configured directly from the [Frontend](/en/deployment/dependencies/frontend). For this purpose, the following entities are available there:
- [Datasource](/en/definitions#datasourcee)
- [Visualization](/en/definitions#visualization)
- [Dashboard](/en/definitions#dashboard)

::::info
`Grafana` receives data from the [Backend](/en/deployment/dependencies/backend) for visualizing [DataPipe](/en/deployment/dependencies/datapipe) via `yesoreyeram-infinity-datasource`.

To visualize [Monitoring](/en/deployment/monitoring) data, [Prometheus](/en/deployment/dependencies/prometheus) and [Loki](/en/deployment/dependencies/loki) are used.
::::

