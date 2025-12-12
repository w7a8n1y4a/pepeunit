# Standard MQTT state topics

::::warning
Supported state topics must be listed in [schema_example.json](/en/definitions#schema-example-json) under `output_base_topic`.

The [Unit](/en/definitions#unit) must send formatted data to the specified topics. [Pepeunit](/en/conception/overview) processes these messages according to the unified pattern described in this section.
::::

There are two state topics in [Pepeunit](/en/conception/overview):

1. `state/pepeunit` – `output_base_topic`
1. `log/pepeunit` – `output_base_topic`

## state/pepeunit - output_base_topic

::::info When does a [Unit](/en/definitions#unit) send data to this topic?
1. Every `PU_STATE_SEND_INTERVAL` seconds as specified in [env.json](/en/definitions#env-json).
::::

The data sent by the [Unit](/en/definitions#unit) is converted by [Pepeunit](/en/conception/overview) into a state view in the [Unit](/en/definitions#unit) menu. This state can also be retrieved via [REST](/en/definitions#rest) and [GQL](/en/definitions#gql).

### Message format for the `state/pepeunit` topic

```json
{
    "ifconfig": ["192.168.0.3", "255.255.255.0", "192.168.0.1", "192.168.0.1"],
    "millis": 595925249.0,
    "mem_free": 12368.0,
    "mem_alloc": 25648.0,
    "freq": 80000000.0,
    "statvfs": [4096, 4096, 763, 716, 716, 0, 0, 0, 0, 255],
    "pu_commit_version": "7f1b6564c4885432a17e5892e3c98f3a2ad33658"
}
```

Field breakdown:

- `ifconfig` – network connection data, `[ip, subnet, gateway, dns]`.
- `millis` – milliseconds since program start or Unix time in milliseconds.
- `mem_free` – free `RAM` in bytes.
- `mem_alloc` – allocated `RAM` in bytes.
- `freq` – CPU clock frequency in Hz.
- `statvfs` – `flash` file system state; lets you compute used/available `flash`:

    ```python
    [
        f_bsize,   # file system block size
        f_frsize,  # fragment size
        f_blocks,  # size of fs in f_frsize units
        f_bfree,   # number of free blocks
        f_bavail,  # number of free blocks for unprivileged users
        f_files,   # number of inodes
        f_ffree,   # number of free inodes
        f_favail,  # number of free inodes for unprivileged users
        f_flag,    # mount flags
        f_namemax, # maximum filename length
    ]
    ```

- `pu_commit_version` – the `PU_COMMIT_VERSION` value from the [Unit](/en/definitions#unit) [env.json](/en/definitions#env-json). This key is used by the [Pepeunit](/en/conception/overview) [update system](/en/development-pepeunit/mechanics/update-system) to track the current [Unit](/en/definitions#unit) version.

::::danger
To correctly display update statuses for a [Unit](/en/definitions#unit), you **must** send `pu_commit_version`.
::::

::::warning
The size of a state message sent by a [Unit](/en/definitions#unit) is limited by `PU_MQTT_MAX_PAYLOAD_SIZE` in the [Backend ENV](/en/deployment/env-variables/backend).
::::

::::info
[Pepeunit](/en/conception/overview) does not require you to send all keys shown in the example. You can, for instance, send only `millis` and `pu_commit_version`.
::::

### Sending algorithm

1. Every `PU_STATE_SEND_INTERVAL` seconds, gather system state data.
1. Format the data as `json`.
1. Send the data to the `state/pepeunit` topic from `output_base_topic` as defined in [schema.json](/en/definitions#schema-json).

## log/pepeunit - output_base_topic

::::info When does a [Unit](/en/definitions#unit) send data to this topic?
1. Whenever the [Unit](/en/definitions#unit) decides to send a log or batch of logs to display to the [User](/en/development-pepeunit/mechanics/roles#user).
2. When the `log_sync/pepeunit` command is received (see details [here](/en/developer/mqtt/default-mqtt-command#log-sync-log-sync-pepeunit)).
::::

The logs sent by the [Unit](/en/definitions#unit) are converted into the [Unit](/en/definitions#unit) log view in [Pepeunit](/en/conception/overview). These logs are also accessible via [REST](/en/definitions#rest) and [GQL](/en/definitions#gql).

### Message format for the `log/pepeunit` topic

Several formats are supported:

1. Sending a single log entry:

    ```json
    {
        "level": "Info",
        "text": "Subscribed: 83 (0, 0, 0, 0, 0)",
        "create_datetime": "2025-04-08T11:27:52.044394"
    }
    ```

1. Sending a single log entry without timestamp:

    ```json
    {
        "level": "Info",
        "text": "Subscribed: 83 (0, 0, 0, 0, 0)"
    }
    ```

1. Sending multiple logs:

    ```json
    [
        {
            "level": "Info",
            "text": "Subscribed: 5 (0, 0, 0, 0, 0)",
            "create_datetime": "2025-04-08T11:37:55.087036"
        },
        {
            "level": "Debug",
            "text": "Unit 7d99d194-fe09-4737-b991-0a67cff966d7 get msg from topic log_sync",
            "create_datetime": "2025-04-08T11:38:22.828806"
        },
        {
            "level": "Debug",
            "text": "Unit 7d99d194-fe09-4737-b991-0a67cff966d7 get msg from topic env_update",
            "create_datetime": "2025-04-08T11:41:15.974031"
        }
    ]
    ```

1. Sending multiple logs without timestamps:

    ```json
    [
        {
            "level": "Info",
            "text": "Subscribed: 5 (0, 0, 0, 0, 0)"
        },
        {
            "level": "Debug",
            "text": "Unit 7d99d194-fe09-4737-b991-0a67cff966d7 get msg from topic log_sync"
        },
        {
            "level": "Debug",
            "text": "Unit 7d99d194-fe09-4737-b991-0a67cff966d7 get msg from topic env_update"
        }
    ]
    ```

Field breakdown and behavior in [Pepeunit](/en/conception/overview):

- `level` – log level; one of: `Debug`, `Info`, `Warning`, `Error`, `Critical`.
- `text` – log message text; should ideally not exceed `256` characters for correct display in the [Frontend](/en/deployment/dependencies/frontend).
- `create_datetime` – optional timestamp. If omitted, [Pepeunit](/en/conception/overview) uses:
    1. For a single log: the time when [Pepeunit](/en/conception/overview) received the message.
    1. For multiple logs: the current time for the first list element, then adds 1 second for each subsequent element to preserve the log order received from the [Unit](/en/definitions#unit).

::::warning
The size of a log message sent by a [Unit](/en/definitions#unit) through [EMQX](/en/deployment/dependencies/emqx) is limited by the `PU_MQTT_MAX_PAYLOAD_SIZE` variable in the [Backend ENV](/en/deployment/env-variables/backend).

By default, logs live for `86400` seconds (~1 day). This is controlled by the `PU_UNIT_LOG_EXPIRATION` variable in the [Backend ENV](/en/deployment/env-variables/backend).
::::

### Sending algorithm

1. Format log data as `json`.
1. Send data to the `log/pepeunit` topic from `output_base_topic` as specified in [schema.json](/en/definitions#schema-json).


