# Dashboards

:::info Где найти?
На главной странице [инстанса](/definitions#instance), найдите в верхнем левом углу кнопку поиска. Выберите сущность `Dashboard`. В нижней левой части модального окна, вы сможете нажать кнопку `Create Dashboard`
:::

## Требования к именам Dashboard и Panels

Требования:
1. Длинна от `4` до `20` символов
1. Разрешённые символы: `a-z, A-Z, 0-9 и _.-`

:::warning
Изменить имя нельзя
:::

## Создание Dashboard в Pepeunit

Создание состоит из трёх этапов:
1. Cоздание [Dashboard](/definitions#dashboard), для этого достаточно ввести имя 
2. Создание N [панелей](/definitions#visualization) для [Dashboard](/definitions#dashboard), тут достаточно вести имя и тип из списка. Типы соответствуют стандартным [Visualization](/definitions#visualization) в [Grafana](/deployment/dependencies/grafana) и одному дополнительному `Horly Heatmap`. Вы можете изменить тип в самом дешборде уже в интерфейса [Grafana](/deployment/dependencies/grafana), т.к. у вас будут права `modifier` в своей организации.
3. Линковка UnitNodes в [панель](/definitions#visualization). Нужно кликнуть на кнопку `UnitNodes` для конкретной панели, далее интерфейс выбора аналогичен связям `Output->Input`, за исключением того, что можно выбирать как `Input`
так и `Output`

На этапе линковки можно указать два флага:
1. `Only last value ?` - Позволят делать выборку для данного [UnitNode](/definitions#unitnode) только по последнему значению, независимо от выбраной политики в [DataPipe](/definitions#datapip)
1. `Value str to json ?` - Пытается преобразовать `value` строку в объект `dict`, полезно если в value хранятся графики например

:::warning
Слинковать можно любой [UnitNode](/definitions#unitnode), но отправить в [Grafana](/deployment/dependencies/grafana) получится только тот у которого корректно настроен [DataPipe](/definitions#datapip)
:::

:::info
Если у вашего [DataPipe](/definitions#datapip) уже есть данные, то при синхронизации, [Pepeunit](/conception/overview) вычленит ключи и запишет их в `columns`, что позволит не заполнять их руками
:::

## Синхронизация Dashboard c Grafana

Когда [Dashboard](/definitions#dashboard) создан на стороне [Pepeunit](/conception/overview) его нужно синхронизировать с [Grafana](/deployment/dependencies/grafana). Для этого предусмотрена кнопка `Send Dashboard to Grafana`.

После её нажатия, [Pepeunit](/conception/overview) проводит множество проверок и отправляет [Dashboard](/definitions#dashboard) в `json` формате в [Grafana](/deployment/dependencies/grafana).

Данную кнопку можно нажимать множество раз, каждый раз [Grafana](/deployment/dependencies/grafana) будет присваивать новую версию.

Перейти в ваш график можно или из поиска по инстансу или нажав на ссылку в модальном окне [Dashboard](/definitions#dashboard).

:::warning
Вы можете полностью редактировать ваши [Dashboard](/definitions#dashboard) на стороне [Grafana](/deployment/dependencies/grafana), но учтите что при последующих синхронизациях, вам придётся заного всё редактировать. Для отката версий можно перейти в `settings.version` в [Grafana](/deployment/dependencies/grafana).
:::