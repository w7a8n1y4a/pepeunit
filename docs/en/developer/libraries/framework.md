# Pepeunit Framework

[Links to library repositories](/en/development-pepeunit/maps.html#библиотеки)

::::info
Each library is a client [Framework](/en/definitions#framework) for working with [Pepeunit](/en/conception/overview).

The goal of the [Framework](/en/definitions#framework) is to simplify development of new [Units](/en/definitions#unit) by providing:

- core functionality for integration with [Pepeunit](/en/conception/overview)
- utilities for managing the application main loop
::::

## Feature set

1. Built‑in [MQTT](/en/definitions#mqtt) client:
    - bulk subscription to topics based on [schema.json](/en/definitions#schema-json)
    - bulk publishing to topics based on [schema.json](/en/definitions#schema-json)
1. Built‑in [REST](/en/definitions#rest) client:
    - download update archive
    - download [env.json](/en/definitions#env-json)
    - download [schema.json](/en/definitions#schema-json)
    - set [state storage](/en/developer/state-storage-unit)
    - get [state storage](/en/developer/state-storage-unit)
    - get a list of [Units](/en/definitions#unit) by a list of [UnitNode](/en/definitions#unitnode).uuid values
    - get `Input` [UnitNodes](/en/definitions#unitnode) for a given `Output` [UnitNode](/en/definitions#unitnode)
1. Receiving and correctly handling [standard Pepeunit MQTT commands](/en/developer/mqtt/default-mqtt-command)
1. Sending and generating [Unit state](/en/developer/mqtt/state-mqtt-send)
1. Functionality for working with [schema.json](/en/definitions#schema-json):
    - dynamic updates
    - search across all four topic types
    - search topics by [UnitNode](/en/definitions#unitnode).uuid or by full physical topic name
1. Functionality for working with [env.json](/en/definitions#env-json):
    - dynamic updates
    - obtaining [Unit](/en/definitions#unit).uuid from the token
    - accessing any variable as an attribute of a settings class
1. Logging functionality:
    - 5 log levels: `debug`, `info`, `warning`, `error`, `critical`
    - sending logs over [MQTT](/en/definitions#mqtt)
    - saving logs to [log.json](#logjson)
    - ability to clear logs
1. Setting a custom update `handler` for the [Unit](/en/definitions#unit)
1. Setting an `Input` [MQTT](/en/definitions#mqtt) message handler
1. Setting an `Output` [MQTT](/en/definitions#mqtt) message handler
1. Ability to choose multiple update strategies
1. `aes-gcm-256` encryption with `16/24/32`‑byte keys (for manual use)
1. Main application loop control:
    - start
    - stop
    - dynamic `handler` changes

## log.json

::::info
The [Unit](/en/definitions#unit) "black box" – stores the last `N` log entries regardless of network state.
::::

Logs are stored in `ndjson` format, where each line separated by `\n` is a JSON object:

```ndjson
{"create_datetime":"2025-11-12T19:43:53Z","level":"Info","text":"MQTT connected successfully"}
{"create_datetime":"2025-11-12T19:44:37Z","level":"Info","text":"MQTT client connected successfully"}
{"create_datetime":"2025-11-12T22:00:10Z","level":"Info","text":"Get base MQTT command: update/pepeunit"}
{"create_datetime":"2025-11-12T22:00:10Z","level":"Warning","text":"COMPILED_FIRMWARE_LINK is missing in update payload"}
{"create_datetime":"2025-11-12T23:00:10Z","level":"Info","text":"Get base MQTT command: update/pepeunit"}
{"create_datetime":"2025-11-12T23:00:10Z","level":"Warning","text":"COMPILED_FIRMWARE_LINK is missing in update payload"}
{"create_datetime":"2025-11-12T23:08:50Z","level":"Info","text":"Get base MQTT command: update/pepeunit"}
{"create_datetime":"2025-11-12T23:08:50Z","level":"Warning","text":"COMPILED_FIRMWARE_LINK is missing in update payload"}
{"create_datetime":"2025-11-12T23:25:41Z","level":"Info","text":"MQTT client connected successfully"}
{"create_datetime":"2025-11-12T23:25:41Z","level":"Info","text":"Connected to MQTT Broker"}
{"create_datetime":"2025-11-12T23:25:42Z","level":"Info","text":"Success subscribed to 4 topics"}
```

The buffer capacity is controlled by the `PU_MAX_LOG_LENGTH` environment variable; new entries are appended at the end of the file, and old entries are removed from the beginning once their index from the end exceeds `PU_MAX_LOG_LENGTH`.

You can access this file physically (via device ports) or via the [log_sync](/en/developer/mqtt/default-mqtt-command.html#log-sync-log-sync-pepeunit) command.


