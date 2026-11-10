# Useful commands

- Stop
    ```bash
    docker compose down
    ```
- Start in the background
    ```bash
    docker compose up -d
    ```
- Container status
    ```bash
    docker compose ps
    ```
- Container logs
    ```bash
    docker logs -f backend
    ```
- Version of the running [Backend](/deployment/dependencies/backend)
    ```bash
    curl http://127.0.0.1:5291/pepeunit/api/v1/instances/current
    ```
- Open a container shell
    ```bash
    docker exec -it backend /bin/bash
    docker exec -it emqx /bin/bash
    docker exec -it postgres /bin/bash
    docker exec -it redis /bin/bash
    docker exec -it clickhouse /bin/bash
    docker exec -it frontend /bin/sh
    docker exec -it nginx /bin/sh
    ```
- [PostgreSQL](/deployment/dependencies/postgresql) console, see `POSTGRES_USER` and `POSTGRES_DB` in `.env`
    ```bash
    docker exec -it postgres psql -U <POSTGRES_USER> -d <POSTGRES_DB>
    ```
- Query in [ClickHouse](/deployment/dependencies/clickhouse)
    ```bash
    docker exec -it clickhouse clickhouse-client --query "SHOW TABLES"
    ```
- Assign the `Owner`, see [Registration and Owner](/deployment/docker/deploy#registration-and-owner)
    ```bash
    docker exec -it backend python scripts/set_owner.py <uuid>
    ```
- Rebuild the configs after changing the settings file
    ```bash
    python3 make_env.py && docker compose up -d
    ```
