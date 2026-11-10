# Pepeunit Framework

[Links to the library repositories](/development-pepeunit/maps#libraries)

Each of the libraries is a client Framework for working with Pepeunit. It makes developing new Units easier: it handles the basic integration with Pepeunit and manages the execution cycle.

## Features

1. Built-in MQTT client:
    - bulk subscription to topics based on schema.json
    - bulk sending of data to topics based on schema.json
1. Built-in REST client:
    - downloading the update archive
    - downloading env.json
    - downloading schema.json
    - setting the [storage](/developer/state-storage-unit) state
    - getting the [storage](/developer/state-storage-unit) state
    - getting a list of Units from a list of UnitIO.uuid
    - getting the `Input` UnitIO by an `Output` UnitIO
1. Receiving and correctly handling the [standard Pepeunit MQTT commands](/developer/mqtt/default-mqtt-command)
1. Sending and generating the [Unit state](/developer/mqtt/state-mqtt-send)
1. Functionality for working with schema.json:
    - Dynamic update
    - Search across all `4` topic types
    - Search for topics by UnitIO.uuid or by the full name of a specific topic
1. Functionality for working with env.json:
    - Dynamic update
    - Getting Unit.uuid from the token
    - Getting any variable as a class attribute
1. Functionality for working with logs:
    - Support for `5` log levels: `debug`, `info`, `warning`, `error`, `critical`
    - Support for sending logs over MQTT
    - Support for saving logs to the [log.json](#logjson) file
    - Ability to clear the logs
1. Setting a custom `handler` for updating the Unit
1. Setting a `handler` for MQTT `Input` messages
1. Setting a `handler` for MQTT `Output` messages
1. Ability to choose several update types
1. `aes-gcm-256` encryption supporting a `16/24/32` byte key, works only when used manually
1. Functionality for working with the application's main cycle:
    - Start
    - Stop
    - Dynamic change of the `handler`

## log.json

The Unit's "black box" stores the last `N` logs regardless of the network state. Logs are stored in the `ndjson` format: each line, separated by `\n`, is a new dictionary:

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

The buffer capacity is set by the `PU_MAX_LOG_LENGTH` environment variable: new entries are appended to the end of the file, and entries whose ordinal number counted from the end is greater than `PU_MAX_LOG_LENGTH` are deleted.

The file can be accessed physically through the device ports or with the [log_sync](/developer/mqtt/default-mqtt-command#log_sync-log_syncpepeunit) command