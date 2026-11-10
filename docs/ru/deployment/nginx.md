# Nginx

:::warning
Уведомления приходят по долгому соединению (`/pepeunit/api/v1/notifications/stream`). Каждый `nginx` на пути к [Backend](/deployment/dependencies/backend) должен отключить буферизацию (`proxy_buffering off`, `proxy_cache off`) и держать длинные таймауты (`proxy_read_timeout`, `send_timeout`). Иначе уведомления в клиенте не появятся. В примерах ниже это уже настроено.
:::

:::info
В примерах `/pepeunit` - это `PU_APP_PREFIX` по умолчанию. Если вы его меняли, замените и в конфигах.
:::

## Nginx Docker Compose

Конфиг по умолчанию. Контейнер `nginx` получает его сам: `make_env.py` собирает `data/nginx/nginx.conf` из `data/nginx/nginx.conf.template`. Править нужно только шаблон.

Он объединяет всё на порту `80`:

Адрес | Куда ведёт
-- | --
/pepeunit | [Backend](/deployment/dependencies/backend), до 50 МБ в теле запроса
/ | [Frontend](/deployment/dependencies/frontend)
/grafana/ | [Grafana](/deployment/dependencies/grafana)

Кроме маршрутов, конфиг:
- ограничивает частоту запросов и число соединений с одного `IP`, внутренние сети без ограничений
- при превышении лимита отвечает `429`
- не буферизует ответы [Backend](/deployment/dependencies/backend), чтобы работали уведомления
- разрешает CORS для API

Для клиента лимит выше, чем для API: при первой загрузке он запрашивает десятки файлов подряд, и отказ `429` не даст ему запуститься.

## Nginx Reverse Proxy

Внешний `Nginx` принимает `https` и передаёт запросы во внутренний `Nginx` из `Docker Compose`. Это основной вариант для публичного инстанса, в файле настроек укажите `PU_SECURE=True`.

```conf
server {
    listen 443;
    server_name unit.pepeunit.com;

    location / {
        proxy_pass http://192.168.0.22:80;
        proxy_http_version 1.1;
        proxy_buffering off;
        proxy_cache off;
        proxy_read_timeout 3600s;
        send_timeout 3600s;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header Connection "";

        client_max_body_size 50M;
    }

    ssl_certificate /etc/letsencrypt/live/pepeunit.com-0001/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/pepeunit.com-0001/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}

server {
    listen 80;
    server_name unit.pepeunit.com;

    location /pepeunit {
        proxy_pass http://192.168.0.22:80;
        proxy_http_version 1.1;
        proxy_buffering off;
        proxy_cache off;
        proxy_read_timeout 3600s;
        send_timeout 3600s;
        proxy_set_header Connection "";
    }
}
```

:::warning
Блок на порту `80` нужен для `esp8266`: у этих микроконтроллеров сертификат не помещается в память.
:::

:::warning
Внутренний `Nginx` принимает запросы к API до `50M`, поэтому внешний `client_max_body_size` не должен быть меньше, иначе крупные файлы не загрузятся.
:::

## Nginx One Config

Один внешний `Nginx` напрямую ведёт на [Backend](/deployment/dependencies/backend), [Frontend](/deployment/dependencies/frontend) и [Grafana](/deployment/dependencies/grafana), с `https`.

```conf
server {
    listen 443;
    server_name unit.pepeunit.com;

    location /pepeunit {
        add_header 'Access-Control-Allow-Origin' "$http_origin" always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;

        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Credentials' 'true';
            add_header 'Access-Control-Allow-Methods' '*';
            add_header 'Access-Control-Allow-Headers' '*';
            add_header 'Access-Control-Max-Age' 86400;
            add_header 'Content-Type' 'text/plain charset=UTF-8';
            add_header 'Content-Length' 0;
            return 204;
        }

        proxy_pass http://192.168.0.22:5291;
        proxy_http_version 1.1;
        proxy_buffering off;
        proxy_cache off;
        proxy_read_timeout 3600s;
        proxy_connect_timeout 90;
        send_timeout 3600s;
        proxy_redirect off;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $host;
        proxy_set_header X-NginX-Proxy true;
        proxy_set_header Connection "";

        client_max_body_size 50M;
    }

    location /grafana/ {
        proxy_pass http://192.168.0.22:3000;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Script-Name /grafana;
    }

    location / {
        proxy_pass http://192.168.0.22:5292;
    }

    ssl_certificate /etc/letsencrypt/live/pepeunit.com-0001/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/pepeunit.com-0001/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}

server {
    listen 80;
    server_name unit.pepeunit.com;

    location /pepeunit {
        proxy_pass http://192.168.0.22:5291;
        proxy_http_version 1.1;
        proxy_buffering off;
        proxy_cache off;
        proxy_read_timeout 3600s;
        send_timeout 3600s;
        proxy_set_header Connection "";
    }
}
```

:::warning
Контейнер `nginx` в `docker-compose.yml` при этом отключается. Порты те же, что в `Docker Compose`: `5291` - [Backend](/deployment/dependencies/backend), `5292` - [Frontend](/deployment/dependencies/frontend), `3000` - [Grafana](/deployment/dependencies/grafana).
:::

## EMQX API за HTTPS

Если `PU_MQTT_SECURE=True`, [Backend](/deployment/dependencies/backend) обращается к REST API [EMQX](/deployment/dependencies/emqx) по `https://PU_MQTT_HOST`. Поэтому `PU_MQTT_HOST` должен быть отдельным доменом (например `emqx.pepeunit.com`, не `PU_DOMAIN`), открываться по `https` и вести на порт `18083` контейнера `emqx`:

```conf
server {
    listen 443;
    server_name emqx.pepeunit.com;

    location / {
        proxy_pass http://192.168.0.22:18083;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }

    ssl_certificate /etc/letsencrypt/live/emqx.pepeunit.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/emqx.pepeunit.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}
```

:::info
MQTT сообщения Unit и [Backend](/deployment/dependencies/backend) не шифруются и идут на порт `PU_MQTT_PORT` (по умолчанию `1883`). `https` нужен только для REST API [EMQX](/deployment/dependencies/emqx).
:::

:::danger
Через этот адрес доступна панель администратора [EMQX](/deployment/dependencies/emqx). Смените пароль из образца и, если можно, разрешите доступ только с `ip` сервера [Backend](/deployment/dependencies/backend).
:::
