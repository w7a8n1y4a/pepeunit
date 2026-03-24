# Nginx

## Nginx Docker Compose

Combines [Backend](/en/deployment/dependencies/backend), [Frontend](/en/deployment/dependencies/frontend) and [Grafana](/en/deployment/dependencies/grafana) into a single `80` port.

```nginx.conf
events {
    worker_connections 1024;
}

http {
    # --- Internal network detection (Docker) ---
    geo $is_internal {
        default 0;
        10.0.0.0/8 1;
        172.16.0.0/12 1;
        192.168.0.0/16 1;
        127.0.0.0/8 1;
    }

    map $is_internal $limit_key {
        0 $binary_remote_addr;
        1 "";
    }

    # --- Rate Limiting Zones ---
    limit_req_zone $limit_key zone=general:10m rate=10r/s;
    limit_req_zone $limit_key zone=api:10m rate=5r/s;

    # --- Connection Limiting Zone ---
    limit_conn_zone $limit_key zone=conn_per_ip:10m;

    # --- Timeouts (Slowloris protection) ---
    client_body_timeout 10s;
    client_header_timeout 10s;
    send_timeout 10s;
    keepalive_timeout 30s;

    # --- Global defaults ---
    server_tokens off;
    client_max_body_size 3m;

    # Return 429 instead of 503 on rate limit hit
    limit_req_status 429;
    limit_conn_status 429;

    server {
        listen 80;

        # Max concurrent connections per IP
        limit_conn conn_per_ip 20;

        location /pepeunit {
            # API rate limit: 5 req/s, burst up to 10 without delay
            limit_req zone=api burst=10 nodelay;

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

            client_max_body_size 50M;
        }

        location / {
            # General rate limit: 10 req/s, burst up to 20 without delay
            limit_req zone=general burst=20 nodelay;

            proxy_pass http://frontend:80;
        }

        location /grafana/ {
            limit_req zone=general burst=20 nodelay;

            proxy_pass http://grafana:3000;

            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Script-Name /grafana;
        }
    }
}
```

## Nginx Reverse Proxy

Allows using an external `Nginx` as a reverse proxy to the internal `Nginx` inside `Docker Compose`. Supports `https` connections.

```conf
server {
    listen 443;
    server_name unit.pepeunit.com;

    location / {
        proxy_pass http://192.168.0.22:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host $host;

        client_max_body_size 20M;
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

::::warning
Redirecting from port `80` to port `80` is needed for `esp8266` microcontrollers, which do not have enough memory for an SSL certificate.
::::

## Nginx One Config

Single configuration for a standalone deployment with `https` support.

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

        client_max_body_size 20M;
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
        proxy_pass http://192.168.0.15:5291;
    }
}
```

::::warning
It is assumed that the `nginx` container is disabled in `docker-compose.yml`, IP addresses are used directly, and ports come from `Docker Compose`.
::::

