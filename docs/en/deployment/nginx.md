# Nginx

:::warning
Notifications arrive over a long-lived connection (`/pepeunit/api/v1/notifications/stream`). Every `nginx` on the way to [Backend](/deployment/dependencies/backend) must disable buffering (`proxy_buffering off`, `proxy_cache off`) and keep long timeouts (`proxy_read_timeout`, `send_timeout`). Otherwise notifications will not appear in the client. This is already configured in the examples below.
:::

:::info
In the examples, `/pepeunit` is the default `PU_APP_PREFIX`. If you changed it, change it in the configs too.
:::

## Nginx Docker Compose

The default config. The `nginx` container gets it by itself: `make_env.py` builds `data/nginx/nginx.conf` from `data/nginx/nginx.conf.template`. Edit only the template.

It combines everything on port `80`:

Address | Where it leads
-- | --
/pepeunit | [Backend](/deployment/dependencies/backend), up to 50 MB in the request body
/ | [Frontend](/deployment/dependencies/frontend)
/grafana/ | [Grafana](/deployment/dependencies/grafana)

Besides the routes, the config limits the request rate and the number of connections from one `IP` (internal networks are unrestricted), answers `429` when the limit is exceeded, does not buffer `Backend` responses, and allows CORS for the API.

The limit for the client is higher than for the API: on first load it requests dozens of files in a row, and a `429` refusal would keep it from starting.

## Nginx Reverse Proxy

An external `Nginx` accepts `https` and passes requests to the internal `Nginx` from `Docker Compose`. This is the main option for a public instance; in the settings file, set `PU_SECURE=True`.

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

The block on port `80` is needed for `esp8266`: on these microcontrollers the certificate does not fit in memory.

:::warning
The internal `Nginx` accepts API requests up to `50M`, so the external `client_max_body_size` must not be smaller, otherwise large files will fail to upload.
:::

## Nginx One Config

A single external `Nginx` leads directly to [Backend](/deployment/dependencies/backend) (port `5291`), [Frontend](/deployment/dependencies/frontend) (`5292`) and [Grafana](/deployment/dependencies/grafana) (`3000`), with `https`. The ports are the same as in `Docker Compose`, and the `nginx` container in `docker-compose.yml` is turned off.

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

## EMQX API over HTTPS

If `PU_MQTT_SECURE=True`, [Backend](/deployment/dependencies/backend) calls the REST API of [EMQX](/deployment/dependencies/emqx) at `https://PU_MQTT_HOST`. Therefore `PU_MQTT_HOST` must be a separate domain (for example `emqx.pepeunit.com`, not `PU_DOMAIN`), open over `https`, and lead to port `18083` of the `emqx` container:

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

MQTT messages of Units and `Backend` are not encrypted and go to the port `PU_MQTT_PORT` (`1883` by default). `https` is needed only for the `EMQX` REST API.

:::danger
The `EMQX` admin panel is reachable through this address. Change the sample password and, if possible, allow access only from the `ip` of the `Backend` server.
:::
