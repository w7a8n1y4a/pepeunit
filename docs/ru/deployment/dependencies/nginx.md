# Nginx

`Nginx` - веб-сервер и обратный прокси. Контейнер `nginx`, порт `80`.

:::info
В Pepeunit он даёт всем единый вход для [Frontend](/deployment/dependencies/frontend), [Backend](/deployment/dependencies/backend) и [Grafana](/deployment/dependencies/grafana):

Адрес | Куда ведёт
-- | --
/ | [Frontend](/deployment/dependencies/frontend)
/pepeunit | [Backend](/deployment/dependencies/backend): REST API, `swagger`, метрики. Префикс задаёт `PU_APP_PREFIX`
/grafana/ | [Grafana](/deployment/dependencies/grafana)

Через `Nginx` идут все запросы клиента и Unit к API. `https` в нём не настроен: для него нужен внешний `Nginx`, [примеры](/deployment/nginx).
:::

Конфиг `data/nginx/nginx.conf` руками не правится: `make_env.py` собирает его из `data/nginx/nginx.conf.template`. Для тонкой настройки меняйте шаблон и запускайте `python3 make_env.py`. Подробнее в [Конфигурациях Nginx](/deployment/nginx#nginx-docker-compose).

Конфиг по умолчанию:
- ограничивает частоту запросов и число соединений с одного `IP`, внутренние сети без ограничений
- защищает от медленных запросов короткими таймаутами
- при превышении лимита отвечает `429`
