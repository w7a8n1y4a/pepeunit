# Backups and updating

## Working with backups

A backup is a single `tar` archive in the `backups/` directory named `<date>_v<version>_pepeunit_backup.tar`. It contains everything needed for recovery: the [PostgreSQL](/deployment/dependencies/postgresql) and [ClickHouse](/deployment/dependencies/clickhouse) databases, the repository cache, [Grafana](/deployment/dependencies/grafana) data, and the settings file. Logs ([Loki](/deployment/dependencies/loki)) are not included in the backup.

:::danger
The archive contains keys and passwords. Store it as carefully as the server itself.
:::

### Creating a backup

The instance must be running; there is no need to stop it:

```bash
docker compose up -d
sudo ./backup.sh backup
```

### Restoring from a backup

:::danger
Restoring **deletes all project volumes** and replaces the settings file with the one from the archive.
:::

The script stops the instance by itself, recreates the volumes and starts Pepeunit:

```bash
sudo ./backup.sh restore backups/<file name>.tar
docker logs -f backend
```

## Update

```bash
sudo ./backup.sh backup
git pull
python3 make_env.py
docker compose up -d --remove-orphans
docker logs -f backend
```

[Backend](/deployment/dependencies/backend) updates the databases itself; wait for `Application startup complete`. If `make_env.py` asked for new required variables, add them from the current `.env.*.example`.

After the update, check the server version:

```bash
curl http://127.0.0.1:5291/pepeunit/api/v1/instances/current
```

If something went wrong, look at the [container logs](/deployment/docker/commands) or file an `issue`.

:::info
The client and the server are compatible within `1.5.x`. Update [Frontend](/deployment/dependencies/frontend) and `Backend` together: image versions are pinned in `docker-compose.yml`.
:::

## Updating from 1.4.0 to 1.5.0

In `1.5.0` all variables are collected in a single settings file, and Telegram Bot, limits and flags moved to the database and are configured from the client. Old values are not carried over, see [Instance settings](/deployment/instance-settings). The images were replaced with `pepeunit-server` and `pepeunit`, and the `datapipe` container no longer exists.

```bash
sudo ./backup.sh backup
git pull
mv .env.local .env.local.old
cp .env.local.example .env.local
```

Carry over the values from the old file to the new one: the domain, `PU_MQTT_*`, `PU_GRAFANA_ADMIN_*`, as well as the login, password and database in `PU_SQLALCHEMY_DATABASE_URL` and `PU_CLICKHOUSE_DATABASE_URL`. They **must match** the old ones, otherwise the databases will not let [Backend](/deployment/dependencies/backend) reach the data.

Leave the keys `PU_SECRET_KEY` and `PU_ENCRYPT_KEY` as `<32-bit-key>`: `make_env.py` will take the current ones from `env/.env.backend`. If there is no `env/` directory, carry the keys over manually.

```bash
python3 make_env.py
docker compose up -d --remove-orphans
```

Then assign the `Owner` and configure the instance: [Registration and Owner](/deployment/docker/deploy#registration-and-owner).

## Updating from versions before 1.3.0

When moving from `17` to `18`, [PostgreSQL](/deployment/dependencies/postgresql) changed its directory structure, so the old volume does not work. Data is carried over through a backup.

:::danger
New versions of `ClickHouse` require a processor with `x86-64-v3` or higher. If your processor is older, pin an older version in `docker-compose.yml`, for example `clickhouse:25.8.32`.
:::

```bash
sudo ./backup.sh backup
docker compose down
git pull
docker compose pull
sudo ./backup.sh restore backups/<file name>.tar
```

Then follow the [update](#update) instructions up to the version you need.
