# Standard Pepeunit MQTT commands

:::warning
The commands a Unit supports must be listed in schema_example.json in the input_base_topic section. The Backend sends a command only to a topic that is listed there.

The Unit must be subscribed to these topics and, on receiving a message, behave as described below.
:::

Pepeunit has five commands, each with its own topic:
1. UPDATE: update/pepeunit
1. SCHEMA_UPDATE: schema_update/pepeunit
1. ENV_UPDATE: env_update/pepeunit
1. LOG_SYNC: log_sync/pepeunit
1. RESET: reset/pepeunit

In all the requests below, PU_HTTP_TYPE, PU_DOMAIN and PU_AUTH_TOKEN are taken from env.json. The token is passed in the x-auth-token header.

Any command can be triggered with a button in the client: `Units` → Unit → `Manage unit` → `Commands`, or [via REST](#sending-a-command-via-rest).

## UPDATE - update/pepeunit

The command asks the Unit to update: the Unit runs the algorithm below and switches to the new version of the program. Besides the button and REST, it is triggered by a manual Unit update and by an automatic one: after the Unit's settings change, hourly on a schedule, and at an administrator's request, for all Units at once.

### Message format for the update/pepeunit topic

The format differs for compiled and interpreted Units.

Compiled:

```json
{
    "COMMAND": "Update",
    "PU_COMMIT_VERSION": "ad1ddee1e559153f6ea4ae33790f5980e32d61cf",
    "COMPILED_FIRMWARE_LINK": "https://git.pepemoss.com/api/v4/projects/281/packages/generic/release/0.0.2/picker-linux-amd64"
}
```

Interpreted:

```json
{
    "COMMAND": "Update",
    "PU_COMMIT_VERSION": "ad1ddee1e559153f6ea4ae33790f5980e32d61cf"
}
```

### Unit algorithm

The algorithm differs for compiled and interpreted Units.

Compiled:

1. Compare PU_COMMIT_VERSION from the message with PU_COMMIT_VERSION from env.json. If they match, the update stops
1. Get the Unit uuid from the PU_AUTH_TOKEN token in env.json
1. Download a tgz, tar or zip archive with env.json and schema.json:
    - `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/firmware/tgz/{Unit.uuid}?wbits=9&level=9`
        - wbits: from -15 to -9, from 9 to 15, or from 25 to 31, 9 by default
        - level: from -1 to 9, 9 by default
    - `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/firmware/tar/{Unit.uuid}`
    - `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/firmware/zip/{Unit.uuid}`
1. Unpack env.json and schema.json
1. Download the new program from the COMPILED_FIRMWARE_LINK link, [more about compilation](/developer/release-assets)
1. Start the new program and stop the old one

Interpreted:

1. Compare the versions and get the Unit uuid the same way as for compiled Units (steps 1 and 2)
1. Download a tgz, tar or zip archive with the update, using the same addresses as for compiled Units above
1. Unpack all the files into a separate folder or memory area
1. Replace the current program with the files from the new folder
1. Restart the Unit

:::info
Pepeunit considers the update done when the Unit sends the required pu_commit_version in its [state](/developer/mqtt/state-mqtt-send). If that does not happen within two PU_STATE_SEND_INTERVAL intervals, the update is marked as failed.
:::

## SCHEMA_UPDATE - schema_update/pepeunit

The command asks the Unit to update schema.json.

### Message format for the schema_update/pepeunit topic

```json
{
    "COMMAND": "SchemaUpdate"
}
```

### Unit algorithm

1. Download the new schema.json: `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/get_current_schema/{Unit.uuid}`
1. Replace the current schema.json with it

## ENV_UPDATE - env_update/pepeunit

The command asks the Unit to update env.json.

### Message format for the env_update/pepeunit topic

```json
{
    "COMMAND": "EnvUpdate"
}
```

### Unit algorithm

1. Download the new env.json: `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/env/{Unit.uuid}`
1. Replace the current env.json with it

## LOG_SYNC - log_sync/pepeunit

The command asks the Unit to send all the logs it has locally. Before that, Pepeunit deletes this Unit's logs from [ClickHouse](/deployment/dependencies/clickhouse). The Unit collects all its logs and sends them over MQTT. The command is meant for debugging: not all errors can be received over MQTT at the moment they happen.

### Message format for the log_sync/pepeunit topic

```json
{
    "COMMAND": "LogSync"
}
```

### Unit algorithm

1. Prepare the logs in the required format: [the format is described in the section on the log/pepeunit topic](/developer/mqtt/state-mqtt-send#logpepeunit-output_base_topic)
1. Send them to the log/pepeunit topic from output_base_topic

## RESET - reset/pepeunit

The command asks the Unit to restart.

### Message format for the reset/pepeunit topic

```json
{
    "COMMAND": "Reset"
}
```

### Unit algorithm

1. Restart the device or the program

## Sending a command via REST

Any of the commands can be sent with a request. The command name is Update, SchemaUpdate, EnvUpdate, LogSync or Reset.

```bash
curl -X 'POST' \
'PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/send_command_to_input_base_topic/{Unit.uuid}?command=Update' \
-H 'x-auth-token: PU_AUTH_TOKEN'
```
