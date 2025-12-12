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

