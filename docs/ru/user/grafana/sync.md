# Синхронизация c Grafana

:::info Где найти?
На главной странице инстанса, найдите в верхнем левом углу кнопку поиска. Выберите сущность [Dashboard](/definitions#dashboard). В нижней части модального окна есть кнопка - `Send Dashboard to Grafana` 
:::

После нажатия кнопки `Send Dashboard to Grafana` - [Pepeunit](/conception/overview) проводит множество проверок и отправляет [Dashboard](/definitions#dashboard) в `json` формате в [Grafana](/deployment/dependencies/grafana).

Перейти в ваш график можно или из поиска по инстансу или нажав на ссылку в модальном окне [Dashboard](/definitions#dashboard).

:::info
Данную кнопку можно нажимать множество раз, каждый раз [Grafana](/deployment/dependencies/grafana) будет присваивать новую версию.
:::

:::warning
Вы можете полностью редактировать ваши [Dashboard](/definitions#dashboard) на стороне [Grafana](/deployment/dependencies/grafana), но учтите что при последующих синхронизациях, вам придётся заного всё редактировать. Для отката версий можно перейти в `settings.version` в [Grafana](/deployment/dependencies/grafana).
:::