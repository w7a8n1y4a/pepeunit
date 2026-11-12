# Полезные команды

- Остановить
    ```bash
    docker compose down
    ```
- Запустить в фоне
    ```bash
    docker compose up -d
    ```
- Состояние контейнеров
    ```bash
    docker compose ps
    ```
- Логи контейнера
    ```bash
    docker logs -f backend
    ```
- Версия работающего [Backend](/deployment/dependencies/backend)
    ```bash
    curl http://127.0.0.1:5291/pepeunit/api/v1/instances/current
    ```
- Открыть оболочку контейнера
    ```bash
    docker exec -it backend /bin/bash
    docker exec -it emqx /bin/bash
    docker exec -it postgres /bin/bash
    docker exec -it redis /bin/bash
    docker exec -it clickhouse /bin/bash
    docker exec -it frontend /bin/sh
    docker exec -it nginx /bin/sh
    ```
- Консоль [PostgreSQL](/deployment/dependencies/postgresql), `POSTGRES_USER` и `POSTGRES_DB` смотрите в `.env`
    ```bash
    docker exec -it postgres psql -U <POSTGRES_USER> -d <POSTGRES_DB>
    ```
- Запрос в [ClickHouse](/deployment/dependencies/clickhouse)
    ```bash
    docker exec -it clickhouse clickhouse-client --query "SHOW TABLES"
    ```
- Назначить `Owner`, см. [Регистрация и Owner](/deployment/docker/deploy#регистрация-и-owner)
    ```bash
    docker exec -it -w /app backend python -m scripts.set_owner <uuid>
    ```
- Пересобрать конфиги после изменения файла настроек
    ```bash
    python3 make_env.py && docker compose up -d
    ```
