# Grafana Мониторинг

По умолчанию в `docker compose` добавлены:
- [Prometheus](/deployment/dependencies/prometheus)
- [Logporter](/deployment/dependencies/logporter)
- [loki](/deployment/dependencies/loki)
- [promtail](/deployment/dependencies/promtail)

Эти `4` контейнера вместе с [Grafana](/deployment/dependencies/grafana) позволяют создать набор `Grafana Dashboards` о состоянии инстанса [Pepeunit](/conception/overview).

## Grafana Dashboards

Данные `Dashboards` доступны по умолчанию в `Main Org`. Обычные [Пользователи](/development-pepeunit/mechanics/roles.html#user) имеют доступ `View`. `Admin` доступ есть только при входе с `GF_SECURITY_ADMIN_USER` и `GF_SECURITY_ADMIN_PASSWORD`                       

Название | Требуемый доступ | Описание
-- | -- | --
`Docker Logs` | `Admin` | Просмотр логов любых контейнеров
`Backend Aggregated Logs` | `Admin` | Просмотр логов [Backend](/deployment/dependencies/backend) с группировкой по сообщениям и возможностью выбора уровней логов
`Backend Load Metrics` | `View` | Позволяет оценить нагрузку в запросах на самую важную часть системы: [Backend](/deployment/dependencies/backend)
`EMQX Load Metrics` | `View` | Показывает нагрузку на [EMQX](/deployment/dependencies/emqx) - основного менеджера данных в системе
`Docker Resource Metrics` | `View` | Показывает какой объём ресурсов потребляет система в целом и для каждого контейенера в отдельности

:::warning
Функционал мониторинга можно выключить используя следующие шаги:
1. Закоментировать указанные `4` сервиса в `docker compose`
1. Установить переменную окружения [EMQX_PROMETHEUS__METRICS__ENABLED](/deployment/env-variables/emqx) как `false`
1. Установить переменную окружения [PU_FF_PROMETHEUS_ENABLE](/deployment/env-variables/backend) как `False`
1. Удалив из репозитория развёртывания `json Dashboards` в дирректории `data/grafana/dashboards` все файлы с расширением `.json`
1. Перезапустить [Pepeunit](/conception/overview) при помощи [команд docker compose](/deployment/docker/commands)
:::