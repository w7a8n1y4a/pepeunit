# Nginx

`Nginx` is a web server and reverse proxy. Container `nginx`, port `80`.

It provides a single entry point for [Frontend](/deployment/dependencies/frontend) (`/`), [Backend](/deployment/dependencies/backend) (`/pepeunit`, the prefix is set by `PU_APP_PREFIX`) and [Grafana](/deployment/dependencies/grafana) (`/grafana/`). All client and Unit requests to the API go through it.

`https` is not configured in it: that needs an external `Nginx`, see [Nginx configurations](/deployment/nginx). The default config is described there too: `data/nginx/nginx.conf` is not edited by hand, it is built by `make_env.py` from `data/nginx/nginx.conf.template`.
