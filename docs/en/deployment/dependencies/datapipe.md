# DataPipe

`DataPipe` receives Unit data from MQTT, passes it through pipelines (filters, transformations, retention policies, notifications) and writes it to [ClickHouse](/deployment/dependencies/clickhouse). How to set up a pipeline is described in the [user guide](/user/datapipe/datapipe).

:::info
`DataPipe` has no container of its own: it is part of the [Backend](/deployment/dependencies/backend) image and runs inside the `backend` container. It has no environment variables of its own either.
:::

## How it works

1. On start, `backend` launches `DataPipe` and watches it: if the process crashes, it is brought up again.
1. `DataPipe` takes pipeline configurations from [PostgreSQL](/deployment/dependencies/postgresql). New and changed pipelines are picked up automatically.
1. Data accumulates in a buffer and is written to [ClickHouse](/deployment/dependencies/clickhouse) in batches.

## Configuration

`DataPipe` takes its connections from the same [Backend environment variables](/deployment/env-variables/backend) as the server.

The rest is changed by `Owner` in the client without a restart: the `pu_ff_datapipe_enable` and `pu_ff_notification_enable` flags in [flags](/deployment/instance-settings#flags), intervals and buffer sizes in the [DataPipe settings](/deployment/instance-settings#datapipe). If `pu_ff_datapipe_enable` is off, the process is not started and the `DataPipe` features are hidden in the client. If `pu_ff_notification_enable` is off, pipelines do not write notifications.

## Logs

`DataPipe` logs go together with the server logs:
```bash
docker logs -f backend
```
