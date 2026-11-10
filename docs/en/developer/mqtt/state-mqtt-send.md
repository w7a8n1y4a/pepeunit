# Standard MQTT state topics

:::warning
The topics a Unit sends its state to must be listed in schema_example.json in the output_base_topic section.

The Unit must send data in the format described below: Pepeunit processes it by a single rule.
:::

Pepeunit has two topics for sending state:
1. state/pepeunit: output_base_topic
1. log/pepeunit: output_base_topic

## state/pepeunit - output_base_topic

The Unit sends its state once every PU_STATE_SEND_INTERVAL seconds from env.json. Pepeunit shows it in the client: `Units` → Unit → `Information`. It can also be obtained through REST.

### Message format for the state/pepeunit topic

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

What each key means:
- ifconfig: network data in the format [ip, mask, gateway, dns]
- millis: time in milliseconds since the program started, or unix time, also in milliseconds
- mem_free: free RAM, in bytes
- mem_alloc: used RAM, in bytes
- freq: CPU frequency, in Hz
- statvfs: state of the file system in flash memory, used to calculate how much memory is used and how much is free:
    ```python
    [
        f_bsize,  # file system block size
        f_frsize,  # fragment size
        f_blocks,  # size of fs in f_frsize units
        f_bfree,  # number of free blocks
        f_bavail,  # number of free blocks for unprivileged users
        f_files,  # number of inodes
        f_ffree,  # number of free inodes
        f_favail,  # number of free inodes for unprivileged users
        f_flag,  # mount flags
        f_namemax,  # maximum filename length
    ]
    ```
- pu_commit_version: PU_COMMIT_VERSION from env.json. Pepeunit uses it to track [updates](/development-pepeunit/mechanics/update-system) and know the Unit's current version

:::danger
pu_commit_version is required: without it the message is rejected. It is also what gives the [UPDATE command](/developer/mqtt/default-mqtt-command#update-updatepepeunit) its success status.
:::

The other keys are optional: you can send only millis and pu_commit_version. Pepeunit discards unknown keys. The message size is limited, see [message structure](/developer/mqtt/struct-topic-messages).

:::warning
If the state is sent more often than once per PU_STATE_SEND_INTERVAL, the extra messages are discarded. The exception: a message with a new pu_commit_version, or one sent while an update command is waiting for a response, is always accepted.
:::

### Sending algorithm

1. Once every PU_STATE_SEND_INTERVAL seconds, poll the system state
1. Assemble the data into json
1. Send it to the state/pepeunit topic from output_base_topic specified in schema.json

## log/pepeunit - output_base_topic

The Unit sends data to this topic when it decides on its own to show the [User](/development-pepeunit/mechanics/roles#user) one or more logs, or when a command arrives in the log_sync/pepeunit topic, [more details](/developer/mqtt/default-mqtt-command#message-format-for-the-log_syncpepeunit-topic). Pepeunit shows the logs in the client: `Units` → Unit → `Manage unit` → `Logs`. They can also be obtained through REST.

### Message format for the log/pepeunit topic

Four formats are supported:

1. A single log:
    ```json
    {
        "level": "Info",
        "text": "Subscribed: 83 (0, 0, 0, 0, 0)",
        "create_datetime": "2025-04-08T11:27:52.044394"
    }
    ```
1. A single log without a time:
    ```json
    {
        "level": "Info",
        "text": "Subscribed: 83 (0, 0, 0, 0, 0)"
    }
    ```
1. Several logs:
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
        }
    ]
    ```
1. Several logs without a time:
    ```json
    [
        {
            "level": "Info",
            "text": "Subscribed: 5 (0, 0, 0, 0, 0)"
        },
        {
            "level": "Debug",
            "text": "Unit 7d99d194-fe09-4737-b991-0a67cff966d7 get msg from topic log_sync"
        }
    ]
    ```

Keys:
- level: the log level, one of Debug, Info, Warning, Error, Critical
- text: the log text, best kept within 256 characters so that it reads well in the client
- create_datetime: an optional log time, which is what is shown to the User. If the key is absent:
    1. For a single log, the time the message was received is used
    1. For several logs, the first gets the current time and each next one a second later, so that the order is preserved

The message size is limited the same way as for the state. Logs are stored for a limited time: the period is set by pu_instance_unit_log_expiration, 86400 seconds by default, that is one day, see [instance settings](/deployment/instance-settings#unit).

### Sending algorithm

1. Assemble the data into json
1. Send it to the log/pepeunit topic from output_base_topic specified in schema.json
