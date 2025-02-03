# Nginx

## Nginx Docker Compose

Объединяет [Backend](/definitions#backend) и [Frontend](/definitions#frontend) в единый `80` порт.

```nginx.conf
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name 192.168.0.22;

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

            proxy_pass http://backend:5000;
            proxy_read_timeout 90;
            proxy_connect_timeout 90;
            proxy_redirect off;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host $host;
            proxy_set_header X-NginX-Proxy true;
            proxy_set_header Connection "";
        }

        location / {
            proxy_pass http://frontend:80;
        }
    }
}
```

## Nginx Reverse Proxy

Позволяет при помощи промежуточного `Nginx` проксировать запросы на внутренний `Nginx` внутри `Docker Compose`. Поддерживает `https` соединение.

```conf
server {
        listen 443;
        server_name unit.pepeunit.com;

        location / {
                proxy_pass http://192.168.0.22:80;
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

        }
}
```

:::warning
Перенаправление c `80` порта на `80` порт нужно для микроконтроллеров серии `esp8266`, у них сертификат не влезает в память.
:::

## Nginx One Config

Конфиг для единого развёртывания c поддержкой `https`

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
                        return 204; break;
                }

                proxy_pass http://192.168.0.22:5291;
                proxy_read_timeout 90;
                proxy_connect_timeout 90;
                proxy_redirect off;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header Host blog.example.com;
                proxy_set_header X-NginX-Proxy true;
                proxy_set_header Connection "";
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
        server_name devunit.pepeunit.com;

        location /pepeunit {
                proxy_pass http://192.168.0.15:5291;

        }
}

```

:::warning
Подразумевается что контейнер `nginx` отключен - `ip` взяты напрямую, порты взяты из `Docker Compose`.
:::