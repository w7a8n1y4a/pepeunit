# Instance settings

## Instance parameters

There are two kinds:
- [Backend](/deployment/env-variables/backend) environment variables: address, keys, database connections. They live in the [settings file](/deployment/docker/deploy#settings-file) and do not change on a running instance.
- Instance settings: flags, limits, expiration periods, Telegram Bot and more. They are stored in [PostgreSQL](/deployment/dependencies/postgresql), are included in [backups](/deployment/docker/backup-update), and change without editing any files.

## Who changes them and how

Only the `Owner` can change the settings; how to assign one is described in [Registration and Owner](/deployment/docker/deploy#registration-and-owner). In the client: `Network` → favorite instance → `Settings`. The allowed range is shown under the input field. The same is available through the [Backend](/deployment/dependencies/backend) REST API: `GET` and `PATCH` on `/instances/settings`.

On first start the settings get their default values, listed in the tables below. Values from `.env` files of versions before `1.5.0` are not carried over, see [updating from 1.4.0 to 1.5.0](/deployment/docker/backup-update#updating-from-140-to-150).

## Applying changes

A new value is saved immediately, but not everything is picked up on the fly:

What changes | When it takes effect
-- | --
[DataPipe](/deployment/dependencies/datapipe) settings | Immediately
Limits, expiration periods, sizes and timeouts `pu_instance_*` | Immediately
Telegram Bot, [Prometheus](/deployment/dependencies/prometheus), [EMQX](/deployment/dependencies/emqx) limits, logs | After a server restart

Restarting the server: `Network` → favorite instance → `Settings` → `Reboot`. Only the server inside the `backend` container is restarted, and it is unavailable for a few seconds. When everything is ready, the `Owner` receives a notification. If the behavior did not change after an edit, restart the server.

## Flags

Setting | Default | What it enables
-- | -- | --
pu_ff_federation_enable | True | Federation: links with other instances (`Peer`)
pu_ff_prometheus_enable | True | [Backend](/deployment/dependencies/backend) metrics for [Prometheus](/deployment/dependencies/prometheus)
pu_ff_grafana_integration_enable | True | Integration with [Grafana](/deployment/dependencies/grafana): sign-in and panels of [Users](/development-pepeunit/mechanics/roles#user). Will not turn on while `PU_GRAFANA_ADMIN_USER` or `PU_GRAFANA_ADMIN_PASSWORD` is empty
pu_ff_datapipe_enable | True | [DataPipe](/deployment/dependencies/datapipe) and its settings in the client
pu_ff_notification_enable | True | Notifications
pu_ff_telegram_bot_enable | False | Telegram Bot. The bot cannot be enabled until the [connection fields](#telegram-bot) are filled in

## Instance

### Basic

Setting | Default | Range | Purpose
-- | -- | -- | --
pu_instance_cipher_max_length | 1000000 | 100000..5000000 | Maximum size of encrypted data, in bytes
pu_instance_http_connect_timeout | 15.0 | 1..60 | Connection timeout for outgoing `HTTP` requests, in seconds
pu_instance_http_timeout | 30.0 | 1..120 | Overall timeout for outgoing `HTTP` requests, in seconds
pu_instance_max_pagination_size | 100 | 1..500 | Maximum number of records on a list page
pu_instance_max_state_size | 4096 | 4096..65536 | Maximum size of another instance's response, in bytes. Larger responses are rejected
pu_instance_retention_days | 60 | 1..120 | After how many days without a response a `Peer` (another instance of the network) is deleted

### Users

Setting | Default | Range | Purpose
-- | -- | -- | --
pu_instance_user_max_count | 1024 | 1..1000000 | How many Users the instance can have
pu_instance_user_max_group | 16 | 8..32 | How many groups one account can create
pu_instance_user_auth_token_expiration | 2678400 | 600..11059200 | Lifetime of an authorization token, in seconds (31 days by default)

### Repositories

Setting | Default | Range | Purpose
-- | -- | -- | --
pu_instance_repo_max_size | 50 | 1..1024 | Maximum size of a Repo, in megabytes
pu_instance_repo_min_interval_sync | 10 | 1..1800 | Minimum interval between Repo syncs, in seconds

### Unit

Setting | Default | Range | Purpose
-- | -- | -- | --
pu_instance_unit_log_expiration | 86400 | 60..604800 | How many seconds Unit logs are kept
pu_instance_unit_state_send_interval | 60 | 1..600 | How often a Unit sends its state, in seconds. Goes into `PU_STATE_SEND_INTERVAL` of the [env.json](/developer/files/struct-env-example-json) file

### Contacts

Setting | Default | Purpose
-- | -- | --
pu_instance_owner_email | empty | The owner's email, visible to other instances
pu_instance_owner_tg | empty | Telegram contact, for example `@username`
pu_instance_lat, pu_instance_lon | empty | Latitude (-90..90) and longitude (-180..180) of the instance, optional

### GitHub

Setting | Default | Purpose
-- | -- | --
pu_instance_github_token_name | empty | Account name of the `GitHub` token
pu_instance_github_token_pat | empty | `GitHub` token for read-only access to public repositories. Raises the download limit from 60 to 5000 requests per hour

The name and the token are filled in only together.

## MQTT

Limits that [Backend](/deployment/dependencies/backend) sets in [EMQX](/deployment/dependencies/emqx) at startup, more in [How Backend configures EMQX](/deployment/dependencies/emqx#how-backend-configures-emqx).

Setting | Default | Range | Purpose
-- | -- | -- | --
pu_mqtt_keepalive | 60 | 1..600 | `keepalive` period, in seconds
pu_mqtt_max_qos | 2 | 0..2 | Highest `QoS`
pu_mqtt_max_len_message_queue | 128 | 1..1024 | Length of a client's message queue
pu_mqtt_max_payload_size | 256 | 1..4096 | Maximum message size, in kilobytes
pu_mqtt_max_topic_alias | 128 | 0..256 | Number of topic aliases
pu_mqtt_max_topic_levels | 5 | 5..32 | Number of topic levels
pu_mqtt_max_client_id_len | 512 | 1..1024 | Maximum length of `Client ID`
pu_mqtt_max_clients | 1024 | 1..1024 | How many clients can be connected
pu_mqtt_client_max_bytes_rate | 1MB/s | - | Traffic limit of one client. Format: a number, a unit (`B`, `KB`, `MB`, `GB`) and a period (`s`, `m`, `h`), for example `500KB/m`
pu_mqtt_client_max_messages_rate | 30/s | - | Message limit of one client. Format: a number and a period (`s`, `m`, `h`)
pu_mqtt_max_client_connection_rate | 20/s | - | Limit of new connections. Same format

## DataPipe

Available when `pu_ff_datapipe_enable` is on. How [DataPipe](/deployment/dependencies/datapipe) works.

Setting | Default | Range | Purpose
-- | -- | -- | --
pu_datapipe_buffer_flush_interval | 5 | 1..3600 | How often the buffer is written to [ClickHouse](/deployment/dependencies/clickhouse), in seconds
pu_datapipe_buffer_max_size | 1000 | 1..1000000 | Buffer size at which the write happens ahead of schedule
pu_datapipe_config_sync_interval | 60 | 1..86400 | How often pipelines are reread from the database, in seconds
pu_datapipe_default_last_value_enable | True | - | Whether to use the last value by default
pu_datapipe_limit_unit_io_per_one_panel | 10 | 1..32 | How many `UnitIO` can be bound to one panel
pu_datapipe_nrecords_cleanup_interval | 3600 | 1..604800 | How often extra records of the `NRecords` policy are deleted, in seconds
pu_datapipe_mqtt_keepalive | 60 | 1..600 | Period of the connection check with [EMQX](/deployment/dependencies/emqx), in seconds

## Notifications

Available when `pu_ff_notification_enable` is on.

Setting | Default | Range | Purpose
-- | -- | -- | --
pu_notification_data_pipe_alert_batch | 100 | 1..1000 | How many pipeline notifications are processed at a time
pu_notification_small_text_limit | 48 | 1..96 | Length of the short notification text
pu_notification_stream_maxlen | 100 | 1..10000 | How many recent notifications are kept for the live feed

The `Telegram Bot` screen is available when notifications and Telegram Bot are enabled:

Setting | Default | Range | Purpose
-- | -- | -- | --
pu_notification_telegram_alert_text_limit | 4000 | 1..4096 | Length of the notification text in Telegram
pu_notification_telegram_instance_rate | 20 | 1..30 | Overall message rate limit of the bot across the whole instance
pu_notification_telegram_user_interval_seconds | 2 | 1..60 | Minimum interval between messages to one User, in seconds

## Telegram Bot

Setting | Default | Purpose
-- | -- | --
pu_telegram_token | empty | Bot token from `@BotFather`, like `123456:ABC-def`
pu_telegram_bot_mode | pooling | `pooling` needs neither your own domain nor `https`, only the server's access to the internet. `webhook` is faster, but needs `https` and your own domain
pu_telegram_bot_link | empty | Link to the bot, for example `https://t.me/bot`
pu_telegram_git_hash_length | 8 | Length of the short `git` hash in messages, 1..16
pu_telegram_proxy_url | empty | Proxy for requests to Telegram, for example `socks5://...`
pu_telegram_header_entity_length | 15 | Length of the entity title in messages, 1..64
pu_telegram_items_per_page | 7 | Records per list page in the bot, 1..20

## Logs

Setting | Default | Values | Purpose
-- | -- | -- | --
pu_instance_log_format | json | json, plain | Log format of [Backend](/deployment/dependencies/backend) and [DataPipe](/deployment/dependencies/datapipe)
pu_instance_log_min_level | INFO | DEBUG, INFO, WARNING, ERROR, CRITICAL | Lowest level of messages that are recorded

:::warning
The daily error summary for [Admins](/development-pepeunit/mechanics/roles#admin) and the `Backend Aggregated Logs` panel in [Monitoring](/deployment/monitoring) read logs as `JSON`. If you use [Loki](/deployment/dependencies/loki), keep the `json` format.
:::
