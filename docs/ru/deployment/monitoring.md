# Grafana Мониторинг

Вместе с инстансом по умолчанию запускаются четыре сервиса мониторинга:
- [Prometheus](/deployment/dependencies/prometheus)
- [Logporter](/deployment/dependencies/logporter)
- [Loki](/deployment/dependencies/loki)
- [Promtail](/deployment/dependencies/promtail)

Вместе с [Grafana](/deployment/dependencies/grafana) они дают набор панелей о состоянии инстанса.

## Grafana Dashboards

Готовые панели подключаются сами из каталога `data/grafana/provisioning/dashboards` в организацию `Main Org`. Данные в [Grafana](/deployment/dependencies/grafana) обновляются не чаще раза в минуту.

Все панели видит администратор [Grafana](/deployment/dependencies/grafana): он входит по логину и паролю `PU_GRAFANA_ADMIN_USER` и `PU_GRAFANA_ADMIN_PASSWORD`. Обычные [Пользователи](/development-pepeunit/mechanics/roles#user) входят через `Pepeunit` и работают в своей организации, где создают собственные панели.

Название | Доступ | Описание
-- | -- | --
Docker Logs | Admin | Логи любых контейнеров
Backend Aggregated Logs | Admin | Логи [Backend](/deployment/dependencies/backend) с группировкой по сообщениям и выбором уровня
Backend Load Metrics | View | Нагрузка на [Backend](/deployment/dependencies/backend)
EMQX Load Metrics | View | Нагрузка на [EMQX](/deployment/dependencies/emqx)
Docker Resource Metrics | View | Ресурсы, которые потребляют система и каждый контейнер

:::warning
В логах есть всё, что пишут контейнеры. Доступ к `Docker Logs` и `Backend Aggregated Logs` оставьте только администратору.
:::

:::info
Панели [Пользователей](/development-pepeunit/mechanics/roles#user) с графиками данных UnitIO создаются из клиента и с этими панелями не связаны, см. [Grafana](/deployment/dependencies/grafana).
:::

## Выключение мониторинга

1. В `docker-compose.yml` закомментируйте четыре сервиса, а у `grafana` уберите `prometheus` из `depends_on`
1. Выключите флаг `pu_ff_prometheus_enable` в [настройках инстанса](/deployment/instance-settings#флаги) и перезапустите сервер: [применение изменений](/deployment/instance-settings#применение-изменений)
1. Удалите из `data/grafana/provisioning/dashboards` все файлы `.json`
1. Перезапустите Pepeunit: [команды docker compose](/deployment/docker/commands)

:::warning
[Grafana](/deployment/dependencies/grafana) нужна для панелей [Пользователей](/development-pepeunit/mechanics/roles#user). Выключать её не нужно, даже если вы отключаете мониторинг.
:::
