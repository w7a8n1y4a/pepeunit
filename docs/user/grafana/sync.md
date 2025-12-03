# Синхронизация c Grafana

Когда [Dashboard](/definitions#dashboard) создан на стороне [Pepeunit](/conception/overview) его нужно синхронизировать с [Grafana](/deployment/dependencies/grafana). Для этого предусмотрена кнопка `Send Dashboard to Grafana`.

После её нажатия, [Pepeunit](/conception/overview) проводит множество проверок и отправляет [Dashboard](/definitions#dashboard) в `json` формате в [Grafana](/deployment/dependencies/grafana).

Данную кнопку можно нажимать множество раз, каждый раз [Grafana](/deployment/dependencies/grafana) будет присваивать новую версию.

Перейти в ваш график можно или из поиска по инстансу или нажав на ссылку в модальном окне [Dashboard](/definitions#dashboard).

:::warning
Вы можете полностью редактировать ваши [Dashboard](/definitions#dashboard) на стороне [Grafana](/deployment/dependencies/grafana), но учтите что при последующих синхронизациях, вам придётся заного всё редактировать. Для отката версий можно перейти в `settings.version` в [Grafana](/deployment/dependencies/grafana).
:::