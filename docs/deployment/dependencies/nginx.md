# Nginx

`Nginx` - высокопроизводительный открытый веб‑сервер, который умеет работать как `Api Gateway`, балансировщик нагрузки, обратный прокси и `HTTP`-кэш для приложений и других серверов.

:::info
В [Pepeunit](/conception/overview) `Nginx` выполняет роль `Api Gateway` - сервиса, предоставляющего всем агентам единый интерфейс [API](/definitions#api) для [Frontend](/deployment/dependencies/frontend), [Backend](/deployment/dependencies/backend), [Grafana](/deployment/dependencies/grafana).

Все запросы [REST](/definitions#rest) и [GQL](/definitions#gql) к [Pepeunit](/conception/overview) изначально проходят через `Nginx`.
:::
