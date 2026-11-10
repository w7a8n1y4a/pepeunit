# Grafana

[Grafana](https://grafana.com/) - платформа для визуализации данных. Контейнер `grafana`, адрес `/grafana/` на том же домене, данные в томе `grafana_data`. [Переменные окружения](/deployment/env-variables/grafana)

:::info
В Pepeunit `Grafana` рисует графики данных [DataPipe](/deployment/dependencies/datapipe) и показывает [Мониторинг](/deployment/monitoring). Для мониторинга она берёт данные из [Prometheus](/deployment/dependencies/prometheus) и [Loki](/deployment/dependencies/loki).
:::

Панели [Пользователи](/development-pepeunit/mechanics/roles#user) создают прямо в клиенте, в разделе `Панели`: `Backend` сам создаёт в `Grafana` страницы и графики, к которым привязываются UnitIO.

## Вход в Grafana

Паролей у обычных пользователей нет: они открывают панель из клиента, и `Grafana` входит через `Pepeunit`. Для каждого [Пользователя](/development-pepeunit/mechanics/roles#user) `Backend` создаёт отдельную организацию с ролью `Editor`. Адреса входа `make_env.py` прописывает в `data/grafana/grafana.ini`.

Администратор входит по логину и паролю из `PU_GRAFANA_ADMIN_USER` и `PU_GRAFANA_ADMIN_PASSWORD`. Только он видит панели мониторинга, см. [Мониторинг](/deployment/monitoring#grafana-dashboards).

:::warning
Без `PU_GRAFANA_ADMIN_USER` и `PU_GRAFANA_ADMIN_PASSWORD` флаг `pu_ff_grafana_integration_enable` не включится.

`Backend` обращается к `Grafana` по адресу `PU_DOMAIN`, а не по имени контейнера. Этот адрес должен открываться изнутри контейнера `backend`, иначе панели не создадутся. Для публичного домена проверьте, что сервер видит сам себя.
:::

Подключения к [Prometheus](/deployment/dependencies/prometheus) и [Loki](/deployment/dependencies/loki) и готовые панели лежат в `data/grafana/provisioning` репозитория [Pepeunit Deploy](/deployment/docker/deploy).
