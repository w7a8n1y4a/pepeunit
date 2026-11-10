# Backend

## Backend in the broad sense

This is five containers: `backend`, [PostgreSQL](/deployment/dependencies/postgresql), [ClickHouse](/deployment/dependencies/clickhouse), [Redis](/deployment/dependencies/redis) and [EMQX](/deployment/dependencies/emqx). [DataPipe](/deployment/dependencies/datapipe) also runs inside `backend`. Together they implement the Pepeunit logic and talk to the outside world:

- [Users](/development-pepeunit/mechanics/roles#user) and [Frontend](/deployment/dependencies/frontend)
- Unit
- GitLab and GitHub
- Telegram
- other Pepeunit instances (Peer)

## Backend service

The main one of these containers. Image `w7a8n1y4a/pepeunit-server`, container `backend`, sources in [`pepeunit_server`](/development-pepeunit/maps). It serves the REST API (`swagger` documentation at `/pepeunit/docs`), MQTT and the Telegram Bot.

The `/pepeunit` prefix is set by `PU_APP_PREFIX`. The server version and the public state of the instance can be requested without authorization: `GET /pepeunit/api/v1/instances/current`.

### Starting the container

On start, `backend` waits for PostgreSQL by itself, applies database migrations, configures EMQX and Grafana, and starts DataPipe and the server. Nothing needs to be done by hand.

The server can be restarted without stopping the container: `Owner` does this in the client, see [Instance settings](/deployment/instance-settings#applying-changes).

### What is configured where

Source | What it stores
-- | --
[Environment variables](/deployment/env-variables/backend) | Address, keys, connections to databases, EMQX and Grafana. Changed only in the [settings file](/deployment/docker/deploy#settings-file)
[Instance settings](/deployment/instance-settings) | Flags, limits, Telegram Bot, DataPipe and everything that `Owner` changes from the client. Stored in PostgreSQL

### Volumes and ports

The port in the container is 5000, on the host 5291. The `backend_repo_cache` volume stores downloaded Git repositories.
