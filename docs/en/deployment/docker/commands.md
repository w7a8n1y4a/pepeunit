# Useful commands

- Stop `docker compose`:
    ```bash
    docker compose down
    ```
- Start `docker compose` in detached mode:
    ```bash
    docker compose up -d
    ```
- View logs of a specific container:
    ```bash
    docker logs postgres
    ```
- Attach to shells of `docker` containers:
    ```bash
    docker exec -it frontend /bin/sh
    docker exec -it backend /bin/bash
    docker exec -it datapipe /bin/sh
    docker exec -it emqx /bin/bash
    docker exec -it postgres /bin/bash
    docker exec -it redis /bin/bash
    docker exec -it nginx /bin/bash
    docker exec -it clickhouse /bin/bash
    ```
- Open a database console; `POSTGRES_USER` and `POSTGRES_DB` can be found in `env/.env.postgres`:
    ```bash
    docker exec -it postgres psql -U <POSTGRES_USER> -d <POSTGRES_DB>
    psql -U <POSTGRES_USER> -d <POSTGRES_DB>
    ```
- Send a query to `ClickHouse` via `curl`:
    ```bash
    curl "http://admin:mypassword@127.0.0.1:8123/?query=SHOW+TABLES"
    ```

