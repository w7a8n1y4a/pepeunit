# Promtail

`Promtail` - агент из стека `Grafana Loki`: читает логи и отправляет их в [Loki](/deployment/dependencies/loki). Контейнер `promtail`.

:::info
В Pepeunit он собирает логи всех контейнеров. Логи `backend` получают метку `app="backend"`, по ней работают панель `Backend Aggregated Logs` и ежедневная сводка ошибок.
:::
