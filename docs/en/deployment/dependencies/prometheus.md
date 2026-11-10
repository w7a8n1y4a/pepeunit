# Prometheus

`Prometheus` is a metrics collection system. Container `prometheus`, port `9090`.

:::info
It collects data for [Monitoring](/deployment/monitoring) and serves it to [Grafana](/deployment/dependencies/grafana):

What it collects | Interval
-- | --
[Backend](/deployment/dependencies/backend) | 5 s
[EMQX](/deployment/dependencies/emqx) | 10 s
[Logporter](/deployment/dependencies/logporter) | 15 s
`Prometheus` itself | 15 s
:::

`Backend` metrics are published while the `pu_ff_prometheus_enable` flag is on in the [instance settings](/deployment/instance-settings).

The `data/prometheus/prometheus.yml` config is built by `make_env.py` from the `prometheus.yml.template` template. Edit the template, not the generated file.
