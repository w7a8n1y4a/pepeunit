# Backups and updates

## Working with backups

### Creating a backup
1. Start `Pepeunit` so that the `backup` script has access to the databases and the `backend` version:
    ```bash
    docker compose up -d
    ```
1. Run backup creation without stopping the containers:
    ```bash
    sudo ./backup.sh backup
    ```

### Restoring from a backup
1. Stop the instance:
    ```bash
    docker compose down
    ```
1. Restore the version from a `backup`:
    ```bash
    sudo ./backup.sh restore backups/backup_name.tar
    ```
1. Start `Pepeunit`:
    ```bash
    docker compose up -d
    ```

## Updating

1. Create a `backup`:
    ```bash
    sudo ./backup.sh backup
    ```
1. Update the repository:
    ```bash
    git pull
    ```
1. Update `env` variables. Existing secret `32‑byte keys` will NOT be changed. Other variables will be generated just like during the first generation. If you manually edited files in `env/.env.<service-name>`, your changes will be **REMOVED**, so be sure to make a `backup` before running this command. If you have very fine‑tuned settings, change them manually by editing the files in `env/.env.<service-name>`.
    ```bash
    python make_env.py
    ```
1. Start `Pepeunit`:
    ```bash
    docker compose up -d
    ```
1. After the backend starts correctly, run [integration tests](/en/user/operation-task/integration-tests) as an [Administrator](/en/development-pepeunit/mechanics/roles#admin). If errors appear, check the [related container logs](/en/deployment/docker/commands) or open an `issue`

## Updating `1.2.1` -> `1.3.0`

::::info
This update is more involved because `PostgreSQL` changed its directory layout when going from `17.6` to `18.6`
::::

::::danger
`ClickHouse` `26.8.2` requires the `x86-64-v3` CPU instruction set or newer. If you want to run the instance on CPUs without those instructions, use version `25.8.32` in `docker-compose.yml`: `clickhouse:25.8.32`.
::::

In a regular update, `backup` is a safety net. Here `backup` is used directly: old data from `1.2.1` is restored on top of the `1.3.0` `compose`.

1. Create a `backup`
    ```bash
    sudo ./backup.sh backup
    ```
1. Stop the instance completely
    ```bash
    docker compose down
    ```
1. Remove the old `volume`s
    ```bash
    docker volume rm pepeunit_deploy_postgres_data pepeunit_deploy_clickhouse_data pepeunit_deploy_emqx_log pepeunit_deploy_emqx_data
    ```
1. Update the repository
    ```bash
    git pull
    ```
1. Pull the new images
    ```bash
    docker compose pull
    ```
1. Restore the `1.2.1` data on top of the `1.3.0` `compose`. Substitute your `backup` file name:
    ```bash
    sudo ./backup.sh restore backups/2026-09-12_04-05-00_v1.2.1_pepeunit_backup.tar
    ```
1. After the backend starts correctly, run [integration tests](/en/user/operation-task/integration-tests) as an [Administrator](/en/development-pepeunit/mechanics/roles#admin). If errors appear, check the [related container logs](/en/deployment/docker/commands) or open an `issue`

