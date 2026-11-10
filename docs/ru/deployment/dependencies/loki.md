# Loki

`Loki` - система хранения логов от `Grafana Labs`. Контейнер `loki`, порт `3100`, данные в томе `loki_data`.

:::info
`Loki` принимает логи от [Promtail](/deployment/dependencies/promtail) и отдаёт их в [Grafana](/deployment/dependencies/grafana). Логи хранятся 7 дней.
:::

Ежедневная сводка ошибок для [Администратора](/development-pepeunit/mechanics/roles#admin) читает из `Loki` записи `ERROR` и `CRITICAL` за сутки. Адрес можно сменить через `PU_NOTIFICATION_LOKI_URL`.

:::warning
Сводка читает логи как `JSON`. Если в [настройках инстанса](/deployment/instance-settings#логи) выбрать формат `plain`, она перестанет находить ошибки.
:::

Том `loki_data` не входит в [резервные копии](/deployment/docker/backup-update).
