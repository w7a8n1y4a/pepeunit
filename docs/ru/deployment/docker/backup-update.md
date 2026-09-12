# Бэкапы и обновление

## Работа с бэкапами

### Создание бэкапа
1. Запустите `Pepeunit`, чтобы скрипт `backup` имел доступ до баз данных и версии `backend`
    ```bash
    docker compose up -d
    ```
1. Запустите создание `backup`, не прерывая работу контейнеров
    ```bash
    sudo ./backup.sh backup
    ```

### Восстановление из бэкапа
1. Выключите инстанс
    ```bash
    docker compose down
    ```
1. Разверните версию из `backup`
    ```bash
    sudo ./backup.sh restore backups/backup_name.tar
    ```
1. Запустите `Pepeunit`
    ```bash
    docker compose up -d
    ```

## Обновление

1. Создайте `backup`
    ```bash
    sudo ./backup.sh backup
    ```
1. Выполните обновление репозитория
    ```bash
    git pull
    ```
1. Выполните обновление `env` переменных. Существующие секретные `32-битные ключи` изменены не будут. Остальные переменные будут сгенерированы, как при первой генерации. Если вы выполняли ручной ввод данных в `env/.env.<service-name>` файлы, то ваши изменения будут **УДАЛЕНЫ**, поэтому обязательно делайте `backup` перед запуском команды. Если у вас очень тонкая настройка, изменяйте настройки вручную путем изменения файлов в `env/.env.<service-name>`.
    ```bash
    python make_env.py
    ```
1. Выполните запуск `Pepeunit`
    ```bash
    docker compose up -d
    ```
1. После корректного запуска бекенда, выполните от имени [Администратора](/development-pepeunit/mechanics/roles#admin) запуск [интеграционных тестов](/user/operation-task/integration-tests). Если будут возникать ошибки, посмотрите [логи связанных контейнеров](/deployment/docker/commands) или напишите `issue`

## Обновление `1.2.1` -> `1.3.0`

:::info
Сложность этого обновления связана с тем, что `PostgreSQL` изменил структуру каталогов при переходе версий  `17.6 -> 18.6`
:::

:::danger
`ClickHouse` `26.8.2` требует инструкции процессора `x86-64-v3` и выше. Если вы хотите запустить инстанс на процессорах без этих инструкций, используйте версию `25.8.32` в `docker-compose.yml`: `clickhouse:25.8.32`.
:::

В обычном обновлении `backup` нужен для страховки. Здесь `backup` используется напрямую: старые данные из `1.2.1` восстанавливаются поверх `compose` версии `1.3.0`.

1. Создайте `backup`
    ```bash
    sudo ./backup.sh backup
    ```
1. Полностью остановите инстанс
    ```bash
    docker compose down
    ```
1. Удалите старые `volume`
    ```bash
    docker volume rm pepeunit_deploy_postgres_data pepeunit_deploy_clickhouse_data pepeunit_deploy_emqx_log pepeunit_deploy_emqx_data
    ```
1. Выполните обновление репозитория
    ```bash
    git pull
    ```
1. Скачайте новые образы
    ```bash
    docker compose pull
    ```
1. Восстановите данные `1.2.1` поверх `compose` версии `1.3.0`. Подставьте имя своего `backup` файла:
    ```bash
    sudo ./backup.sh restore backups/2026-09-12_04-05-00_v1.2.1_pepeunit_backup.tar
    ```
1. После корректного запуска бекенда, выполните от имени [Администратора](/development-pepeunit/mechanics/roles#admin) запуск [интеграционных тестов](/user/operation-task/integration-tests). Если будут возникать ошибки, посмотрите [логи связанных контейнеров](/deployment/docker/commands) или напишите `issue`
