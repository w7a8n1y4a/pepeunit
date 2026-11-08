# Nginx

`Nginx` - высокопроизводительный открытый веб‑сервер, который умеет работать как `Api Gateway`, балансировщик нагрузки, обратный прокси и `HTTP`-кэш для приложений и других серверов.

:::info
В Pepeunit `Nginx` выполняет роль `Api Gateway` - сервиса, предоставляющего всем агентам единый интерфейс API для [Frontend](/deployment/dependencies/frontend), [Backend](/deployment/dependencies/backend) и [Grafana](/deployment/dependencies/grafana).

Все запросы REST и GQL к Pepeunit изначально проходят через `Nginx`.
:::
