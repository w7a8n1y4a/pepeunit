# Grafana

[Grafana](https://grafana.com/) - платформа с открытым исходным кодом, для визуализации данных и их анализа.

:::info
Встроена в структуру работы [Pepeunit](/conception/overview) для визуализации данных из [DataPipe](/definitions#datapipe) и отображения данных [Мониторинга](/deployment/monitoring).
:::

Настройки визуализации можно делать напрямую с [Frontend](/deployment/dependencies/frontend), для этого там определён следующий набор сущностей:
- [Datasource](/definitions#datasourcee)
- [Visualization](/definitions#visualization)
- [Dashboard](/definitions#dashboard)

:::info
`Grafana` получает данные из [Backend](/deployment/dependencies/backend) для визуализации [DataPipe](/definitions#datapipe) при помощи `yesoreyeram-infinity-datasource`

Для визуализации данных [Мониторинга](/deployment/monitoring) используется [Prometheus](/deployment/dependencies/prometheus) и [Loki](/deployment/dependencies/loki)
:::
