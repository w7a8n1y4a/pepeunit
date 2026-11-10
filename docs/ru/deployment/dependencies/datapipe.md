# DataPipe

`DataPipe` принимает данные Unit из MQTT, пропускает их через конвейеры (фильтры, преобразования, политики хранения, уведомления) и записывает в [ClickHouse](/deployment/dependencies/clickhouse). Как настроить конвейер, описано в [руководстве пользователя](/user/datapipe/datapipe).

:::info
Отдельного контейнера у `DataPipe` нет: он входит в образ [Backend](/deployment/dependencies/backend) и работает внутри контейнера `backend`. Собственных переменных окружения тоже нет.
:::

## Как работает

1. При старте `backend` запускает `DataPipe` и следит за ним: если процесс упал, он поднимается заново.
1. Конфигурации конвейеров `DataPipe` берёт из [PostgreSQL](/deployment/dependencies/postgresql). Новые и изменённые конвейеры подхватываются сами.
1. Данные накапливаются в буфере и пишутся в [ClickHouse](/deployment/dependencies/clickhouse) пачками.

## Настройка

Подключения `DataPipe` берёт из тех же [переменных окружения Backend](/deployment/env-variables/backend), что и сервер.

Остальное меняет `Owner` в клиенте, см. [настройки инстанса](/deployment/instance-settings#datapipe). Изменения подхватываются без перезапуска сервера.

Настройка | Что делает
-- | --
pu_ff_datapipe_enable | Включает `DataPipe`. Если выключена, процесс не запускается, а его возможности скрываются в клиенте
pu_ff_notification_enable | Если выключена, `DataPipe` не пишет уведомления конвейеров
pu_datapipe_buffer_flush_interval | Как часто буфер записывается в [ClickHouse](/deployment/dependencies/clickhouse), в секундах
pu_datapipe_buffer_max_size | Размер буфера, при котором запись происходит раньше срока
pu_datapipe_config_sync_interval | Как часто конфигурации конвейеров перечитываются из базы, в секундах
pu_datapipe_nrecords_cleanup_interval | Как часто удаляются лишние записи политики `NRecords`, в секундах
pu_datapipe_mqtt_keepalive | Период проверки связи с [EMQX](/deployment/dependencies/emqx), в секундах

## Логи

Логи `DataPipe` идут вместе с логами сервера:
```bash
docker logs -f backend
```
