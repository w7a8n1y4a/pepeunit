# Nginx

`Nginx` - веб-сервер и обратный прокси. Контейнер `nginx`, порт `80`.

Он даёт единый вход для [Frontend](/deployment/dependencies/frontend) (`/`), [Backend](/deployment/dependencies/backend) (`/pepeunit`, префикс задаёт `PU_APP_PREFIX`) и [Grafana](/deployment/dependencies/grafana) (`/grafana/`). Через него идут все запросы клиента и Unit к API.

`https` в нём не настроен: для него нужен внешний `Nginx`, см. [Конфигурации Nginx](/deployment/nginx). Там же описан конфиг по умолчанию: `data/nginx/nginx.conf` руками не правится, его собирает `make_env.py` из `data/nginx/nginx.conf.template`.
