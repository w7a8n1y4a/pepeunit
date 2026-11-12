# Deployment

The `Pepeunit Deploy` repository contains everything needed to run an instance with `docker compose`. The set of containers is described in [Dependencies](/deployment/dependencies/backend).

Install `Docker`, `Docker Compose`, `Python 3` and `git` beforehand: [Installing Docker and Docker Compose](/deployment/docker/install-docker).

```bash
git clone https://git.pepemoss.com/pepe/pepeunit/pepeunit_deploy.git
cd pepeunit_deploy
```

## Settings file

This is the only file you edit: everything else is built from it. Take the sample for your case:

- `.env.local.example` - local network, access by `ip` and `http`
- `.env.global.example` - public instance, access by domain and `https`

```bash
cp .env.local.example .env.local
```

Fill in the following:

Variable | What to set
-- | --
PU_DOMAIN | Domain or `ip` of the instance, for example `192.168.0.22` or `unit.pepeunit.com`
PU_SECURE | `True` if access is over `https`, otherwise `False`
PU_MQTT_HOST | Domain or `ip` of [EMQX](/deployment/dependencies/emqx), usually the same as in `PU_DOMAIN`. `127.0.0.1` will not do: the address must be reachable from the containers
PU_MQTT_SECURE | `True` if [EMQX](/deployment/dependencies/emqx) works behind `https`, otherwise `False`

:::danger
The passwords in the sample are public. Replace all logins and passwords with your own: `PU_SQLALCHEMY_DATABASE_URL`, `PU_CLICKHOUSE_DATABASE_URL`, `PU_MQTT_USERNAME`, `PU_MQTT_PASSWORD`, `PU_GRAFANA_ADMIN_USER`, `PU_GRAFANA_ADMIN_PASSWORD`.

Do not touch the secret keys `PU_SECRET_KEY` and `PU_ENCRYPT_KEY`: they are created automatically.
:::

Leave the rest as in the sample, more in [Backend environment variables](/deployment/env-variables/backend). Database logins and passwords are applied only when the data is first created, so set them right away. Telegram Bot, flags and limits are not needed in the file: the `Owner` configures them from the client, see [Instance settings](/deployment/instance-settings).

## Generating configs

```bash
python3 make_env.py
```

The script creates `.env` and the configs in `data/`. If something is missing, it stops and shows a list of errors.

:::danger
The files are created anew on every run: edits to `.env` and `data/` will be lost. Edit only the settings file. The settings file itself is included in the [backup](/deployment/docker/backup-update#working-with-backups).
:::

## Ports

Open `80` on the server for `http` and `443` for `https` if an [external Nginx](/deployment/nginx) stands in front of the instance. Also open `1883` (MQTT).

:::danger
`docker-compose.yml` publishes the ports of all services. On a public server, close everything except `80`, `443` and `1883` with a firewall.
:::

## Starting

```bash
docker compose up -d
docker logs -f backend
```

The first start downloads the images and takes several minutes. It is finished when the line `Application startup complete` appears in the [Backend](/deployment/dependencies/backend) log.

:::warning
If the log contains the line `[SUBACK] 1 (135,)` instead of `(0,)`, `Backend` did not subscribe to MQTT. Check that port `1883` is open and `PU_MQTT_HOST` is reachable from the containers.
:::

## Registration and Owner

Open `PU_DOMAIN` in a browser. Pepeunit has no passwords: an account is a pair of keys. Open `Account` → `Registration`, and the client will create the keys and register the account. Save the private key: without it, access is lost.

The first user does not become the owner; the `Owner` role is assigned by the server administrator. Find the `uuid` of your account (see `POSTGRES_USER` and `POSTGRES_DB` in `.env`):

```bash
docker exec -it postgres psql -U <POSTGRES_USER> -d <POSTGRES_DB> -c "SELECT uuid, LEFT(hash_public_key, 6) || '-' || RIGHT(hash_public_key, 6) AS hash_public_key, role, create_datetime FROM users;"
```

The query shows `uuid`, the first and last 6 characters of `hash_public_key` separated by `-`, the account role `role`, and the account creation date `create_datetime`.

Assign the owner by running the script as a module from `/app` so Python can import the `app` package:

```bash
docker exec -it -w /app backend python -m scripts.set_owner <uuid>
```

There is only one `Owner` in an instance: if you run it again with a different `uuid`, the previous owner becomes an ordinary [User](/development-pepeunit/mechanics/roles#user).

Further instance configuration is done in the client: [Instance settings](/deployment/instance-settings).
