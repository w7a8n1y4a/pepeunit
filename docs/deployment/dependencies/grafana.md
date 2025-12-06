# Grafana

[Grafana](https://grafana.com/) - платформа с открытым исходным кодом, предназначенная для визуализации данных и их анализа. [Подробнее о переменных окружения](/deployment/env-variables/grafana)

:::info
`Grafana` встроена в структуру работы [Pepeunit](/conception/overview) для визуализации данных из [DataPipe](/deployment/dependencies/datapipe) и отображения данных [Мониторинга](/deployment/monitoring).
:::

Настройки визуализации можно делать напрямую с [Frontend](/deployment/dependencies/frontend), для этого там определён следующий набор сущностей:
- [Datasource](/definitions#datasourcee)
- [Visualization](/definitions#visualization)
- [Dashboard](/definitions#dashboard)

:::info
`Grafana` получает данные из [Backend](/deployment/dependencies/backend) для визуализации [DataPipe](/deployment/dependencies/datapipe) при помощи `yesoreyeram-infinity-datasource`

Для визуализации данных [Мониторинга](/deployment/monitoring) используется [Prometheus](/deployment/dependencies/prometheus) и [Loki](/deployment/dependencies/loki)
:::
