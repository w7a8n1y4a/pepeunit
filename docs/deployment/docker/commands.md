# Полезные команды

- Остановить `docker compose`
    ```bash
    docker compose down
    ```
- Запустить `docker compose` в фоновом режиме
    ```bash
    docker compose up -d
    ```
- Посмотреть логи конкретного контейнера
    ```bash
    docker logs postgres
    ```
- Подключение к оболочкам контейнеров `docker`:
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
- Зайти в консоль базы данных, `POSTGRES_USER` и `POSTGRES_DB` можно найти в `env/.env.postgres`
    ```bash
    docker exec -it postgres psql -U <POSTGRES_USER> -d <POSTGRES_DB>
    psql -U <POSTGRES_USER> -d <POSTGRES_DB>
    ```
- Отправить запрос в `ClickHouse` через `curl`:
    ```bash
    curl "http://admin:mypassword@127.0.0.1:8123/?query=SHOW+TABLES"
    ```