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

Остальное меняет `Owner` в клиенте без перезапуска: флаги `pu_ff_datapipe_enable` и `pu_ff_notification_enable` в [флагах](/deployment/instance-settings#флаги), интервалы и размеры буфера в [настройках DataPipe](/deployment/instance-settings#datapipe). Если `pu_ff_datapipe_enable` выключен, процесс не запускается, а возможности `DataPipe` скрываются в клиенте. Если выключен `pu_ff_notification_enable`, конвейеры не пишут уведомления.

## Логи

Логи `DataPipe` идут вместе с логами сервера:
```bash
docker logs -f backend
```
