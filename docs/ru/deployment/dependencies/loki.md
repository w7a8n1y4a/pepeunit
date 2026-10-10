# Loki

`Loki` — система агрегации и хранения логов с открытым исходным кодом, разработанная `Grafana Labs`, предназначенная для сбора, индексации и анализа логов в распределённых системах.

:::info
`Loki` в [Pepeunit](/conception/overview) используется для агрегации данных из [Promtail](/deployment/dependencies/promtail) и предоставления этих данных для [Grafana](/deployment/dependencies/grafana). Ежедневная сводка [Администратора](/development-pepeunit/mechanics/roles#admin) читает отсюда группы `ERROR` и `CRITICAL` [Backend](/deployment/dependencies/backend) за последние сутки. Адрес можно изменить при помощи `PU_NOTIFICATION_LOKI_URL`
:::
