# Frontend

## Frontend in the broad sense

Two services: `Frontend` and [Grafana](/deployment/dependencies/grafana). Together they give [Users](/development-pepeunit/mechanics/roles#user) access to [Backend](/deployment/dependencies/backend).

## Frontend service

The web version of the Pepeunit client. Image `w7a8n1y4a/pepeunit`, container `frontend`, sources in [`pepeunit`](/development-pepeunit/maps). The client is written in `Flutter` and served as a set of static files. The port in the container is 80, on the host 5292. It stores nothing itself and talks to `Backend` over REST. [Environment variables](/deployment/env-variables/frontend)

The same sources are built into native apps for `Android`, `iOS`, `Linux`, `macOS` and `Windows`. They are not part of `docker compose`; in them the instance is chosen in the `Network` section. Links to the builds are in the client: `Library` → `About`.

The client and `Backend` must be compatible: this client version works with `Backend` `1.5.x`.

After the image is updated, the user gets the new version without clearing the cache.

### How the client finds its instance

`make_env.py` builds the instance address from the settings file, and the web client connects to it on load. If the address is empty, the client has no favorite instance and the person picks one in the instance search.
