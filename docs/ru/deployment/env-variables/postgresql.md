# PostgreSQL

:::warning
Ручное заполнение обычно не требуется, нужно заполнить только основные переменные т.к. есть [файл генерации .env файлов для сервисов](/deployment/docker/deploy#заполнение-первичного-env-фаила)
:::

:::warning
Полный список переменных окружения доступен в [документации PostgreSQL](https://www.postgresql.org/docs)
:::

Переменная | Пример | Зачем нужна?
-- | -- | --
`POSTGRES_USER` | `myuser` | Имя пользователя базы данных
`POSTGRES_PASSWORD` | `mypassword` | Пароль пользователя базы данных
`POSTGRES_DB` | `pepeunit` | Название базы данных
`POSTGRES_HOST_AUTH_METHOD` | `md5` | Метод авторизации хоста
