# Настройки инстанса

## Параметры инстанса

Бывают двух типов:
- Переменные окружения [Backend](/deployment/env-variables/backend): адрес, ключи, подключения к базам. Лежат в [файле настроек](/deployment/docker/deploy#файл-настроек) и на работающем инстансе не меняются.
- Настройки инстанса: флаги, лимиты, сроки, Telegram Bot и прочее. Хранятся в [PostgreSQL](/deployment/dependencies/postgresql), входят в [резервные копии](/deployment/docker/backup-update) и меняются без правки файлов.

## Кто и как меняет

Менять настройки может только `Owner`, как его назначить - в разделе [Регистрация и Owner](/deployment/docker/deploy#регистрация-и-owner). В клиенте: `Сеть` → избранный инстанс → `Настройки`. Допустимый диапазон виден под полем ввода. То же доступно через REST API [Backend](/deployment/dependencies/backend): `GET` и `PATCH` на `/instances/settings`.

При первом запуске настройки получают значения по умолчанию, они указаны в таблицах ниже. Значения из `.env` файлов версий до `1.5.0` не переносятся, см. [обновление с 1.4.0 на 1.5.0](/deployment/docker/backup-update#обновление-с-140-на-150).

## Применение изменений

Новое значение сохраняется сразу, но не всё подхватывается на лету:

Что меняется | Когда вступает в силу
-- | --
Настройки [DataPipe](/deployment/dependencies/datapipe) | Сразу
Лимиты, сроки, размеры и таймауты `pu_instance_*` | Сразу
Telegram Bot, [Prometheus](/deployment/dependencies/prometheus), лимиты [EMQX](/deployment/dependencies/emqx), логи | После перезапуска сервера

Перезапуск сервера: `Сеть` → избранный инстанс → `Настройки` → `Перезапуск`. Перезапускается только сервер внутри контейнера `backend`, на несколько секунд он становится недоступен. Когда всё готово, `Owner` получит уведомление. Если после изменения поведение не поменялось, перезапустите сервер.

## Флаги

Настройка | По умолчанию | Что включает
-- | -- | --
pu_ff_federation_enable | True | Федерацию: связи с другими инстансами (`Peer`)
pu_ff_prometheus_enable | True | Метрики [Backend](/deployment/dependencies/backend) для [Prometheus](/deployment/dependencies/prometheus)
pu_ff_grafana_integration_enable | True | Связь с [Grafana](/deployment/dependencies/grafana): вход и панели [Пользователей](/development-pepeunit/mechanics/roles#user). Не включится, пока пусты `PU_GRAFANA_ADMIN_USER` или `PU_GRAFANA_ADMIN_PASSWORD`
pu_ff_datapipe_enable | True | [DataPipe](/deployment/dependencies/datapipe) и его настройки в клиенте
pu_ff_notification_enable | True | Уведомления
pu_ff_telegram_bot_enable | False | Telegram Bot. Пока [поля подключения](#telegram-bot) не заполнены, включить бота нельзя

## Инстанс

### Базовые

Настройка | По умолчанию | Диапазон | Назначение
-- | -- | -- | --
pu_instance_cipher_max_length | 1000000 | 100000..5000000 | Максимальный размер шифрованных данных, в байтах
pu_instance_http_connect_timeout | 15.0 | 1..60 | Таймаут соединения для исходящих `HTTP` запросов, в секундах
pu_instance_http_timeout | 30.0 | 1..120 | Общий таймаут исходящих `HTTP` запросов, в секундах
pu_instance_max_pagination_size | 100 | 1..500 | Наибольшее число записей на странице списка
pu_instance_max_state_size | 4096 | 4096..65536 | Максимальный размер ответа другого инстанса, в байтах. Большие ответы отклоняются
pu_instance_retention_days | 60 | 1..120 | Через сколько дней без ответа удаляется `Peer` (другой инстанс сети)

### Пользователи

Настройка | По умолчанию | Диапазон | Назначение
-- | -- | -- | --
pu_instance_user_max_count | 1024 | 1..1000000 | Сколько Пользователей может быть в инстансе
pu_instance_user_max_group | 16 | 8..32 | Сколько групп может создать один аккаунт
pu_instance_user_auth_token_expiration | 2678400 | 600..11059200 | Срок жизни токена авторизации, в секундах (по умолчанию 31 день)

### Репозитории

Настройка | По умолчанию | Диапазон | Назначение
-- | -- | -- | --
pu_instance_repo_max_size | 50 | 1..1024 | Максимальный размер Repo, в мегабайтах
pu_instance_repo_min_interval_sync | 10 | 1..1800 | Минимальный интервал между синхронизациями Repo, в секундах

### Unit

Настройка | По умолчанию | Диапазон | Назначение
-- | -- | -- | --
pu_instance_unit_log_expiration | 86400 | 60..604800 | Сколько секунд хранятся логи Unit
pu_instance_unit_state_send_interval | 60 | 1..600 | Как часто Unit отправляет своё состояние, в секундах. Попадает в `PU_STATE_SEND_INTERVAL` файла [env.json](/developer/files/struct-env-example-json)

### Контакты

Настройка | По умолчанию | Назначение
-- | -- | --
pu_instance_owner_email | пусто | Почта владельца, видна другим инстансам
pu_instance_owner_tg | пусто | Контакт в Telegram, например `@username`
pu_instance_lat, pu_instance_lon | пусто | Широта (-90..90) и долгота (-180..180) инстанса, необязательно

### GitHub

Настройка | По умолчанию | Назначение
-- | -- | --
pu_instance_github_token_name | пусто | Имя аккаунта токена `GitHub`
pu_instance_github_token_pat | пусто | Токен `GitHub` только для чтения публичных репозиториев. Поднимает лимит скачивания с 60 до 5000 запросов в час

Имя и токен заполняются только вместе.

## MQTT

Ограничения, которые [Backend](/deployment/dependencies/backend) устанавливает в [EMQX](/deployment/dependencies/emqx) при старте, подробнее в [Как Backend настраивает EMQX](/deployment/dependencies/emqx#как-backend-настраивает-emqx).

Настройка | По умолчанию | Диапазон | Назначение
-- | -- | -- | --
pu_mqtt_keepalive | 60 | 1..600 | Период `keepalive`, в секундах
pu_mqtt_max_qos | 2 | 0..2 | Наибольший `QoS`
pu_mqtt_max_len_message_queue | 128 | 1..1024 | Длина очереди сообщений клиента
pu_mqtt_max_payload_size | 256 | 1..4096 | Максимальный размер сообщения, в килобайтах
pu_mqtt_max_topic_alias | 128 | 0..256 | Число псевдонимов топика
pu_mqtt_max_topic_levels | 5 | 5..32 | Число уровней топика
pu_mqtt_max_client_id_len | 512 | 1..1024 | Наибольшая длина `Client ID`
pu_mqtt_max_clients | 1024 | 1..1024 | Сколько клиентов могут быть подключены
pu_mqtt_client_max_bytes_rate | 1MB/s | - | Лимит трафика одного клиента. Формат: число, единица (`B`, `KB`, `MB`, `GB`) и период (`s`, `m`, `h`), например `500KB/m`
pu_mqtt_client_max_messages_rate | 30/s | - | Лимит сообщений одного клиента. Формат: число и период (`s`, `m`, `h`)
pu_mqtt_max_client_connection_rate | 20/s | - | Лимит новых подключений. Формат тот же

## DataPipe

Доступна при включённом `pu_ff_datapipe_enable`. Как работает [DataPipe](/deployment/dependencies/datapipe).

Настройка | По умолчанию | Диапазон | Назначение
-- | -- | -- | --
pu_datapipe_buffer_flush_interval | 5 | 1..3600 | Как часто буфер записывается в [ClickHouse](/deployment/dependencies/clickhouse), в секундах
pu_datapipe_buffer_max_size | 1000 | 1..1000000 | Размер буфера, при котором запись происходит раньше срока
pu_datapipe_config_sync_interval | 60 | 1..86400 | Как часто конвейеры перечитываются из базы, в секундах
pu_datapipe_default_last_value_enable | True | - | Использовать ли последнее значение по умолчанию
pu_datapipe_limit_unit_io_per_one_panel | 10 | 1..32 | Сколько `UnitIO` можно привязать к одной панели
pu_datapipe_nrecords_cleanup_interval | 3600 | 1..604800 | Как часто удаляются лишние записи политики `NRecords`, в секундах
pu_datapipe_mqtt_keepalive | 60 | 1..600 | Период проверки связи с [EMQX](/deployment/dependencies/emqx), в секундах

## Уведомления

Доступна при включённом `pu_ff_notification_enable`.

Настройка | По умолчанию | Диапазон | Назначение
-- | -- | -- | --
pu_notification_data_pipe_alert_batch | 100 | 1..1000 | Сколько уведомлений конвейеров обрабатывается за раз
pu_notification_small_text_limit | 48 | 1..96 | Длина короткого текста уведомления
pu_notification_stream_maxlen | 100 | 1..10000 | Сколько последних уведомлений хранится для живой ленты

Экран `Телеграм бот` доступен, когда включены уведомления и Telegram Bot:

Настройка | По умолчанию | Диапазон | Назначение
-- | -- | -- | --
pu_notification_telegram_alert_text_limit | 4000 | 1..4096 | Длина текста уведомления в Telegram
pu_notification_telegram_instance_rate | 20 | 1..30 | Общий лимит частоты сообщений бота по всему инстансу
pu_notification_telegram_user_interval_seconds | 2 | 1..60 | Минимальный интервал между сообщениями одному Пользователю, в секундах

## Telegram Bot

Настройка | По умолчанию | Назначение
-- | -- | --
pu_telegram_token | пусто | Токен бота от `@BotFather`, вида `123456:ABC-def`
pu_telegram_bot_mode | pooling | `pooling` не требует своего домена и `https`, нужен только выход сервера в интернет. `webhook` быстрее, но нужны `https` и свой домен
pu_telegram_bot_link | пусто | Ссылка на бота, например `https://t.me/bot`
pu_telegram_git_hash_length | 8 | Длина короткого `git` хеша в сообщениях, 1..16
pu_telegram_proxy_url | пусто | Прокси для запросов к Telegram, например `socks5://...`
pu_telegram_header_entity_length | 15 | Длина заголовка сущности в сообщениях, 1..64
pu_telegram_items_per_page | 7 | Записей на странице списка в боте, 1..20

Список команд для `@BotFather` (`/setcommands`):

```text
repo - Repo
unit - Unit Actions
dashboard - Dashboard List url
peers - Peer List
alerts - Alerts and operation status
info - Instance Metrics
help - About Instance
control - Admin Operations
```

## Логи

Настройка | По умолчанию | Значения | Назначение
-- | -- | -- | --
pu_instance_log_format | json | json, plain | Формат логов [Backend](/deployment/dependencies/backend) и [DataPipe](/deployment/dependencies/datapipe)
pu_instance_log_min_level | INFO | DEBUG, INFO, WARNING, ERROR, CRITICAL | Наименьший уровень записываемых сообщений

:::warning
Ежедневная сводка ошибок для [Администраторов](/development-pepeunit/mechanics/roles#admin) и панель `Backend Aggregated Logs` в [Мониторинге](/deployment/monitoring) читают логи как `JSON`. Если используете [Loki](/deployment/dependencies/loki), оставьте формат `json`.
:::
