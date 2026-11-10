# Grafana Мониторинг

## Сервисы
Вместе с инстансом по умолчанию запускаются четыре сервиса мониторинга:
- [Prometheus](/deployment/dependencies/prometheus)
- [Logporter](/deployment/dependencies/logporter)
- [Loki](/deployment/dependencies/loki)
- [Promtail](/deployment/dependencies/promtail)

Вместе с [Grafana](/deployment/dependencies/grafana) они дают набор панелей о состоянии инстанса. Панели [Пользователей](/development-pepeunit/mechanics/roles#user) с графиками данных UnitIO создаются из клиента и с ними не связаны.

## Grafana Dashboards

Готовые панели подключаются сами из каталога `data/grafana/provisioning/dashboards` в организацию `Main Org`. Данные в [Grafana](/deployment/dependencies/grafana) обновляются не чаще раза в минуту.

Все панели видит администратор `Grafana`, остальные [Пользователи](/development-pepeunit/mechanics/roles#user) работают в своей организации, см. [Вход в Grafana](/deployment/dependencies/grafana#вход-в-grafana).

Название | Доступ | Описание
-- | -- | --
Docker Logs | Admin | Логи любых контейнеров
Backend Aggregated Logs | Admin | Логи `Backend` с группировкой по сообщениям и выбором уровня
Backend Load Metrics | View | Нагрузка на `Backend`
EMQX Load Metrics | View | Нагрузка на `EMQX`
Docker Resource Metrics | View | Ресурсы, которые потребляют система и каждый контейнер

:::warning
В логах есть всё, что пишут контейнеры. Доступ к `Docker Logs` и `Backend Aggregated Logs` оставьте только администратору.
:::

## Выключение мониторинга

1. В `docker-compose.yml` закомментируйте четыре сервиса, а у `grafana` уберите `prometheus` из `depends_on`
1. Выключите флаг `pu_ff_prometheus_enable` в [настройках инстанса](/deployment/instance-settings#флаги) и перезапустите сервер: [применение изменений](/deployment/instance-settings#применение-изменений)
1. Удалите из `data/grafana/provisioning/dashboards` все файлы `.json`
1. Перезапустите Pepeunit: [команды docker compose](/deployment/docker/commands)

:::warning
`Grafana` нужна для панелей Пользователей, её не выключайте.
:::
