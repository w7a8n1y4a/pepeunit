# Standard Pepeunit MQTT commands

::::warning
Commands supported by a [Unit](/en/definitions#unit) must be listed in [schema_example.json](/en/definitions#schema-example-json) under `input_base_topic`.

The [Unit](/en/definitions#unit) must subscribe to these topics. When it receives a message, the [Unit](/en/definitions#unit) must follow the unified behavior pattern described in this section.
::::

There are four command topics in [Pepeunit](/en/conception/overview):

1. `UPDATE` – `update/pepeunit`
1. `SCHEMA_UPDATE` – `schema_update/pepeunit`
1. `ENV_UPDATE` – `env_update/pepeunit`
1. `LOG_SYNC` – `log_sync/pepeunit`

## UPDATE - update/pepeunit

::::info When is this command sent?
1. When a [Unit](/en/definitions#unit) is updated manually.
1. When a [Unit](/en/definitions#unit) is updated automatically.
1. When the command is triggered via the dedicated button in the [Unit](/en/definitions#unit) UI.
1. When the command is triggered via [REST](/en/definitions#rest) or [GQL](/en/definitions#gql).
::::

This command tells the [Unit](/en/definitions#unit) to perform an update. The [Unit](/en/definitions#unit) must then execute a specific sequence of actions that results in switching the program code to a new version.

### Message format for the `update/pepeunit` topic

::::danger
The message format differs for [Compilable](/en/definitions#compilable) and [Interpretable](/en/definitions#interpretable) [Repos](/en/definitions#repo):
::::

[Compilable](/en/definitions#compilable):

```json
{
    "COMMAND": "Update",
    "PU_COMMIT_VERSION": "ad1ddee1e559153f6ea4ae33790f5980e32d61cf",
    "COMPILED_FIRMWARE_LINK": "https://git.pepemoss.com/api/v4/projects/281/packages/generic/release/0.0.2/picker-linux-amd64"
}
```

[Interpretable](/en/definitions#interpretable):

```json
{
    "COMMAND": "Update",
    "PU_COMMIT_VERSION": "ad1ddee1e559153f6ea4ae33790f5980e32d61cf"
}
```

### Unit behavior algorithm

::::danger
The [Unit](/en/definitions#unit) algorithm differs for [Compilable](/en/definitions#compilable) and [Interpretable](/en/definitions#interpretable) [Repos](/en/definitions#repo).
::::

[Compilable](/en/definitions#compilable):

1. Compare the `PU_COMMIT_VERSION` from the message with the current `PU_COMMIT_VERSION` from [env.json](/en/definitions#env-json).  
   - If they match, abort the update.  
   - If they differ, start the update process.
1. Compute the [Unit](/en/definitions#unit) `uuid` from the `PU_AUTH_TOKEN` JWT in [env.json](/en/definitions#env-json).
1. Download a `tgz`, `tar`, or `zip` archive with [env.json](/en/definitions#env-json) and [schema.json](/en/definitions#schema-json) via [REST](/en/definitions#rest). The `PU_HTTP_TYPE` and `PU_DOMAIN` variables are available in [env.json](/en/definitions#env-json):
    - `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/firmware/tgz/{Unit.uuid}?wbits=9&level=9`  
        - allowed `wbits`: `(from -15 to -8) (from 9 to 16) (from 25 to 32)`  
        - allowed `level`: `(from -1 to 10)`
    - `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/firmware/tar/{Unit.uuid}`
    - `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/firmware/zip/{Unit.uuid}`
1. Extract [env.json](/en/definitions#env-json) and [schema.json](/en/definitions#schema-json) from the archive.
1. Download the new compiled binary from `COMPILED_FIRMWARE_LINK`. See [precompiled releases](/en/developer/release-assets) for details.
1. Run the new compiled binary and stop the old one.

[Interpretable](/en/definitions#interpretable):

1. Compare the `PU_COMMIT_VERSION` from the message with the current `PU_COMMIT_VERSION` from [env.json](/en/definitions#env-json).  
   - If they match, abort the update.  
   - If they differ, start the update process.
1. Compute the [Unit](/en/definitions#unit) `uuid` from the `PU_AUTH_TOKEN` JWT in [env.json](/en/definitions#env-json).
1. Download a `tgz`, `tar`, or `zip` update archive via [REST](/en/definitions#rest). The `PU_HTTP_TYPE` and `PU_DOMAIN` variables are available in [env.json](/en/definitions#env-json):
    - `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/firmware/tgz/{Unit.uuid}?wbits=9&level=9`  
        - allowed `wbits`: `(from -15 to -8) (from 9 to 16) (from 25 to 32)`  
        - allowed `level`: `(from -1 to 10)`
    - `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/firmware/tar/{Unit.uuid}`
    - `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/firmware/zip/{Unit.uuid}`
1. Extract all files from the archive into a separate directory or memory area.
1. Replace the current program files with the files from the new directory or memory area.
1. Restart the [Unit](/en/definitions#unit).

## ENV_UPDATE - env_update/pepeunit

::::info When is this command sent?
1. When the command is triggered via the dedicated button in the [Unit](/en/definitions#unit) UI.
1. When the command is triggered via [REST](/en/definitions#rest) or [GQL](/en/definitions#gql).
::::

This command tells the [Unit](/en/definitions#unit) to update [schema.json](/en/definitions#schema-json). The [Unit](/en/definitions#unit) must then execute a sequence of actions that results in replacing the current [schema.json](/en/definitions#schema-json) with a new one.

### Message format for the `schema_update/pepeunit` topic

```json
{
    "COMMAND": "SchemaUpdate"
}
```

### Unit behavior algorithm

1. Download the new [schema.json](/en/definitions#schema-json) via [REST](/en/definitions#rest). The `PU_HTTP_TYPE` and `PU_DOMAIN` variables are available in [env.json](/en/definitions#env-json):
    - `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/get_current_schema/{Unit.uuid}`
1. Replace the current [schema.json](/en/definitions#schema-json) state in the [Unit](/en/definitions#unit) with the new version.

## ENV_UPDATE – `env_update/pepeunit`

::::info When is this command sent?
1. When the command is triggered via the dedicated button in the [Unit](/en/definitions#unit) UI.
1. When the command is triggered via [REST](/en/definitions#rest) or [GQL](/en/definitions#gql).
::::

This command tells the [Unit](/en/definitions#unit) to update [env.json](/en/definitions#env-json). The [Unit](/en/definitions#unit) must then execute a sequence of actions that results in replacing the current [env.json](/en/definitions#env-json) with a new one.

### Message format for the `env_update/pepeunit` topic

```json
{
    "COMMAND": "EnvUpdate"
}
```

### Unit behavior algorithm

1. Download the new [env.json](/en/definitions#env-json) via [REST](/en/definitions#rest). The `PU_HTTP_TYPE` and `PU_DOMAIN` variables are available in the *current* [env.json](/en/definitions#env-json):
    - `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/env/{Unit.uuid}`
1. Replace the current [env.json](/en/definitions#env-json) state in the [Unit](/en/definitions#unit) with the new version.

## LOG_SYNC - log_sync/pepeunit

::::info When is this command sent?
1. When the command is triggered via the dedicated button in the [Unit](/en/definitions#unit) UI.
1. When the command is triggered via [REST](/en/definitions#rest) or [GQL](/en/definitions#gql).
::::

This command tells the [Unit](/en/definitions#unit) to synchronize all logs it currently has locally. At the same time, [Pepeunit](/en/conception/overview) forcibly deletes all logs for this [Unit](/en/definitions#unit) from [ClickHouse](/en/deployment/dependencies/clickhouse). In response, the [Unit](/en/definitions#unit) must collect all existing logs and send them via [MQTT](/en/definitions#mqtt) back to [Pepeunit](/en/conception/overview).

### Message format for the `log_sync/pepeunit` topic

```json
{
    "COMMAND": "LogSync"
}
```

### Unit behavior algorithm

1. Prepare logs in the required format (see the [`log/pepeunit` topic section](/en/developer/mqtt/state-mqtt-send#log-pepeunit-output-base-topic) for details).
1. Send the prepared logs to the `log/pepeunit` topic from the `output_base_topic` section.

::::info
This command exists to simplify debugging and monitoring of [Units](/en/definitions#unit). Not every error can be seen in real time via [MQTT](/en/definitions#mqtt) at the moment it occurs.
::::


