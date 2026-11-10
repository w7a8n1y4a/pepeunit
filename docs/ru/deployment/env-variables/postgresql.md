# PostgreSQL

:::info
В файл настроек эти переменные не пишутся: `make_env.py` берёт их из `PU_SQLALCHEMY_DATABASE_URL` и передаёт контейнеру `postgres`.
:::

Полный список переменных: [документация PostgreSQL](https://www.postgresql.org/docs).

Переменная | Откуда берётся | Зачем нужна?
-- | -- | --
POSTGRES_USER | Имя пользователя из адреса | Имя пользователя базы данных
POSTGRES_PASSWORD | Пароль из адреса | Пароль пользователя базы данных
POSTGRES_DB | Имя базы из адреса | Название базы данных
POSTGRES_HOST_AUTH_METHOD | Задан в `docker-compose.yml`: md5 | Метод авторизации

:::warning
Значения применяются только при создании тома `postgres_data`. Позже их смена пароль в базе не меняет, см. [Файл настроек](/deployment/docker/deploy#файл-настроек).
:::
