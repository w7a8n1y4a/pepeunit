# Simple Unit Schemas

A proposed format. Authors write concise YAML; the Backend checks it and builds validators. Support for this format has yet to be implemented.

| File | Created by | Contents |
| -- | -- | -- |
| `unit.yml` | Unit author | Unit description and type, settings, and Input/Output types |
| `.env` | Backend | Settings for a specific Unit |
| `io_topics.yml` | Backend | Topics for a specific Unit |

The Unit repository contains one author-maintained schema file at its root: `unit.yml`. The required overall `version` field appears at the beginning of the file at the same level as the four required sections: `search`, `env`, `input`, and `output`. Unused `env`, `input`, or `output` sections are empty maps `{}`.

Pepeunit reads `unit.yml` and generates `.env` for a specific physical Unit using its selected settings. The Unit starts with this `.env`, then downloads its own `io_topics.yml` from Pepeunit using the connection and authentication settings in `.env`. Once it has the topics, the Unit subscribes to its Inputs and publishes to its Outputs.

The device only needs `.env` and `io_topics.yml`. No `.env.example` is needed.

## unit.yml

An example of a new actuator Unit (`actor`) contract that controls a fan through incoming commands, not a ready-to-use configuration for existing firmware.

```yaml
version: 1

search:
  type: actor
  execution_type: compiled
  name: garage-fan
  summary: Controls a fan through incoming commands.
  tags: [garage, ventilation]
  platforms: [esp32]
  hardware:
    - Fan with a suitable PWM driver.
  behavior:
    manual: >
      set_speed sets the power level for duration seconds.
      A new command replaces the previous one and restarts the timer.
      When the timer expires, the power level is set to 0%.
      The power level represents the PWM duty cycle.
    reporting: Publishes the requested power level once per second.
    limitations: Does not measure RPM or confirm physical rotation.

env:
  FAN_PIN:
    type: int
    min: 0
    example: 4
    description: GPIO used to control the fan.
  WIFI_PASSWORD:
    type: string
    max_bytes: 128
    secret: true
    example: "example-password"
    description: Wi-Fi network password.

input:
  reset: {base: reset}

  set_speed:
    type: object
    role: command
    qos: 1
    description: Sets the fan power level for the specified duration.
    fields:
      speed: {type: int, min: 0, max: 100, unit: '%'}
      duration: {type: int, min: 1, max: 3600, unit: s}

output:
  state: {base: state}

  speed:
    type: int
    min: 0
    max: 100
    unit: '%'
    role: state
    description: Requested fan power level, not measured RPM.
```

Example message for `set_speed`:

```json
{"speed": 50, "duration": 60}
```

## Concise Syntax Rules

- All declared fields are required. `optional: true` allows omission; `nullable: true` allows `null`.
- Objects accept only the declared `fields`. `extra: true` allows additional fields with arbitrary JSON values.
- The Backend uses `default` inside an ENV schema when generating `.env`. Defaults are not automatically inserted into messages.
- The default encoding is JSON. Plain text requires `codec: utf8`; `type: bytes` always uses binary encoding.
- The broker sets the overall MQTT message size limit; schemas and `dictionary.yml` neither set nor override it.
- `max_bytes` is a required positive integer limiting an individual value for `string`, `bytes`, and `any`, as well as `object` with `extra: true`. It is declared directly in the value schema, including ENV, nested fields, and `items`, with no default. For `string`, it is required even with `enum` or `format`; `optional` and `nullable` do not waive the requirement either. Missing or invalid limits are rejected during registration.
- For `string`, count the UTF-8 bytes of the decoded string, excluding JSON quotes and escaping; for `bytes`, count the binary value's bytes. For `any` and `object` with `extra: true`, count the UTF-8 bytes of the entire value's JSON fragment in the received message, including keys, brackets, quotes, escaping, and internal whitespace. For `any`, `null` occupies 4 bytes; for other nullable types, `null` is exempt from the value size check.
- Arrays use `max_items` to limit their element count, and closed objects use `fields` or `variants` to restrict their structure; values inside them are checked against their own schemas. These types, as well as `bool`, `int`, and `float`, do not allow `max_bytes`. Value limits do not guarantee that the complete message fits within the broker limit.
- `role` and `description` are required in the resolved IO schema; `base` supplies them from the dictionary. They are not required for object fields or ENV settings; descriptions are recommended.
- Every variable in `env` requires `example`, including variables with `optional: true` or a `default`. The example must satisfy the variable's type and all constraints; `example: null` is allowed only with `nullable: true`. Missing or invalid examples are rejected during registration. `example` is a configuration hint and is not inserted into `.env` in place of a value or `default`. For `secret: true`, use a fictitious value.
- ENV supports scalar values: `bool`, `int`, `float`, and `string`, optionally with `nullable`. The Backend adds standard `PU_*` settings.
- Unknown keys, duplicate YAML keys, invalid types, and unsupported combinations are rejected during registration.

`version: 1` selects **one immutable revision of the format, metaschema, and dictionary**. There are no separate `profile` or `dictionary_version` fields. Changing the rules requires a new version; existing contracts continue using theirs.

## search and Unit Type

`search` contains discovery metadata: name, summary, tags, platforms, hardware, and behavior. The required `search.type` field specifies the Unit type.

| Type | Purpose | Example |
| -- | -- | -- |
| `sensor` | Only reads and publishes information; does not control physical devices | Temperature sensor |
| `actor` | Performs actions in the physical world | Fan, relay, actuator |
| `controller` | Receives information from `sensor` Units, makes decisions, and sends commands to `actor` Units | A regulator that turns on a fan based on temperature |
| `observer` | Analyzes or accumulates sensor information without controlling `actor` Units | Measurement history collector |
| `gateway` | Relays data and commands between Pepeunit and devices using an external protocol | ZigBee, LoRa, or Meshtastic gateway |

A Unit has exactly one of these five types. `search.type` is a string, not a list; missing types, unknown values, or multiple types are rejected during registration. The Unit type describes its purpose, while `role` describes an individual Input or Output. For example, an `actor` can publish its state while remaining an `actor`.

A ventilation system can be split as follows: a `sensor` publishes temperature, a `controller` receives it and sends commands to an `actor`, and an `observer` receives readings to store their history. The Unit type does not replace compatibility checks for individual IOs.

For a `gateway`, the schema describes only the gateway's own ENV and Input/Output on the Pepeunit side. Devices behind the gateway and their protocols are not described in this schema. Developers of `controller` Units that work through the gateway are responsible for handling those device protocols, constructing commands, and interpreting responses. Validating the gateway's IO does not confirm correct interaction with devices behind it.

The required `search.execution_type` field specifies how the Unit program runs:

| Value | Execution mode |
| -- | -- |
| `interpreted` | The Unit runs the program through an interpreter |
| `compiled` | The Unit runs a prebuilt program or firmware |

Exactly one value from `execution_types` is required. Missing fields, unknown values, and lists are rejected during registration. The value describes the execution mode of the specific Unit distribution; the Backend uses it to select the update workflow.

The registry stores `unit.yml` from the selected repository version. MCP can return behavior descriptions, settings, or a specific IO separately, without requiring the entire README to be read.

### Input/Output QoS

`qos` is an optional field at the root of an Input or Output schema: an integer `0`, `1`, or `2`. When omitted, it uses `defaults.qos` from `dictionary.yml`, which is `0` for every role. Authors can explicitly select another level. Command IO examples declare `qos: 1`; base commands inherit it from `dictionary.yml` when `base` is expanded. The `command` role does not change the default by itself. Other values and `qos` on nested fields or ENV settings are rejected during registration.

## .env

Generated by the Backend. Secrets are placeholders, and only some standard settings are shown.

```dotenv
FAN_PIN=4
WIFI_PASSWORD="example-password"
PU_DOMAIN="domain.com"
PU_MQTT_HOST="emqx.domain.com"
PU_MQTT_PORT=1883
PU_AUTH_TOKEN="example-token"
PU_SCHEMA_REVISION=7
PU_CONFIG_REVISION=12
```

Strings use JSON quoting and escaping. Numbers, booleans, and `null` are unquoted. Substitution and command execution are not supported.

## io_topics.yml

The Backend generates an object with required `topic` and optional `qos` fields for each IO. After expanding `base`, it writes `qos` only when it differs from `defaults.qos` in `dictionary.yml`. When omitted, the Unit uses the format default of `0` without downloading the dictionary. This object replaces the topic string representation.

Generated by the Backend for a specific Unit; the Unit downloads this file after startup. Its IO entries match the `input` and `output` sections in `unit.yml`.

```yaml
version: 1
schema_revision: 7
config_revision: 12
input:
  reset:
    topic: domain.com/9d0c2f4d-108e-488a-85e5-6040ef3d8425
    qos: 1
  set_speed:
    topic: domain.com/2d98b4ba-c935-4379-8e1a-520e76018c17
    qos: 1
output:
  state:
    topic: domain.com/7279d28d-53b6-4866-99da-0b81bc1cc025
  speed:
    topic: domain.com/d76b4234-3997-4a4a-a113-6d1c21d6b84a
```

`schema_revision` identifies the revision of the Unit's effective contract; `config_revision` identifies the revision of the `.env` and `io_topics.yml` bundle. When settings affecting IO change, the Backend checks the connections again.

MessageProcessor subscribes to `domain.com/+`: both Input and Output are covered by a single subscription. DataPipe operates in both directions. Output → Input connections are stored on the server; received Input messages are not routed again. A Unit publishes to its own Outputs and subscribes to its own Inputs.

Message rate limiting is enforced by the MQTT broker. The allowed message count is taken directly from the Pepeunit database for the specific Unit. This is a server setting; it is not part of `unit.yml`, the schema dictionary, or the generated `.env` and `io_topics.yml` files.

A Unit publishes each Output with its `qos` and subscribes to each Input requesting its `qos`. MessageProcessor requests QoS `2` for the shared `domain.com/+` subscription to support all allowed levels. When forwarding, it publishes with the target Input's `qos`; service command senders use the corresponding base Input's QoS. Changing `qos` requires updating `io_topics.yml` and the Unit subscriptions.

QoS applies to individual delivery hops: the level delivered to a subscriber is limited by the publication QoS and the subscription level granted by the broker. QoS `1` permits duplicate delivery, so command handlers must account for duplicates; MQTT acknowledgment does not confirm physical execution. [MQTT specification](https://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html).

## Other Data Types

Fragments from separate version 1 `unit.yml` files.

### Arbitrary JSON and an Object with Arbitrary Content

```yaml
output:
  anything:
    type: any
    max_bytes: 2048
    role: event
    description: Any JSON value, including null.

  event:
    type: object
    role: event
    description: An event with arbitrary content.
    fields:
      kind: {type: string, max_bytes: 16, enum: [measurement, alert]}
      data: {type: any, max_bytes: 2048}
      note: {type: string, max_bytes: 256, optional: true}
```

### Arrays, Text, and Bytes

```yaml
output:
  readings:
    type: array
    items: {type: float, min: -55, max: 125, unit: Cel}
    max_items: 16
    role: measurement
    description: An array of temperature readings.

  button:
    type: string
    max_bytes: 16
    codec: utf8
    enum: [Left, Right, One, Double, Long]
    role: event
    description: A user action expressed as text without JSON quotes.

  packet:
    type: bytes
    max_bytes: 220
    role: event
    description: An opaque radio packet.
```

### Command Variants

`variants` is shorthand for an object with a required `action` field. The value of `action` selects exactly one variant and its required fields. Other fields are rejected.

```yaml
input:
  relay:
    type: object
    role: command
    qos: 1
    description: Sets the state or turns the relay on for a specified duration.
    variants:
      set:
        enabled: {type: bool}
      pulse:
        duration: {type: int, min: 1, max: 60000, unit: ms}
```

```json
{"action": "set", "enabled": true}
```

```json
{"action": "pulse", "duration": 500}
```

### Nullable Setting

```yaml
env:
  CLICK_MESSAGE:
    type: string
    max_bytes: 256
    nullable: true
    default: null
    example: "click"
    description: null disables sending; an empty string sends an empty payload.
```

### Universal Controller

```yaml
output:
  send_command:
    type: object
    role: command
    qos: 1
    routing: selected-link
    description: Sends JSON to the Input of the selected connection.
    fields:
      link_id: {type: string, max_bytes: 36, format: uuid}
      data: {type: any, max_bytes: 2048}
```

The controller publishes to its own Output. MessageProcessor checks the UUID, permissions, and whether the connection belongs to that Output, then validates `data` against the selected Input's schema. Only `data` is forwarded to the recipient.

## Platform Dictionary

Unit authors do not write this file. This `dictionary.yml` example defines allowed format values and base service Inputs/Outputs. Their schemas and behavior are shared across the platform.

```yaml
version: 1

unit_types: [sensor, actor, controller, observer, gateway]
execution_types: [interpreted, compiled]
types: [bool, int, float, string, object, array, any, bytes]
codecs: [json, utf8, bytes]
roles: [measurement, state, event, command]
platforms: [esp8266, esp32, linux, windows, macos]
formats: [uuid]
routing: [broadcast, selected-link]

units_of_measurement:
  standard: UCUM
  version: '2.2'

input:
  update:
    type: object
    role: command
    qos: 1
    description: Update the Unit program to the specified version.
    fields:
      COMMAND: {type: string, max_bytes: 16, enum: [Update]}
      PU_COMMIT_VERSION: {type: string, max_bytes: 128}
      COMPILED_FIRMWARE_LINK: {type: string, max_bytes: 2048, optional: true}
  env_update:
    type: object
    role: command
    qos: 1
    description: Download and apply the current .env.
    fields:
      COMMAND: {type: string, max_bytes: 16, enum: [EnvUpdate]}
  schema_update:
    type: object
    role: command
    qos: 1
    description: Download the current io_topics.yml and update subscriptions.
    fields:
      COMMAND: {type: string, max_bytes: 16, enum: [SchemaUpdate]}
  log_sync:
    type: object
    role: command
    qos: 1
    description: Send stored logs through the log Output.
    fields:
      COMMAND: {type: string, max_bytes: 16, enum: [LogSync]}
  reset:
    type: object
    role: command
    qos: 1
    description: Restart the device or program.
    fields:
      COMMAND: {type: string, max_bytes: 16, enum: [Reset]}

output:
  state:
    type: object
    role: state
    description: Report the program version and system state.
    fields:
      pu_commit_version: {type: string, max_bytes: 128}
      millis: {type: float, min: 0, unit: ms, optional: true}
      mem_free: {type: float, min: 0, optional: true}
      mem_alloc: {type: float, min: 0, optional: true}
      freq: {type: float, min: 0, unit: Hz, optional: true}
      ifconfig:
        type: array
        items: {type: string, max_bytes: 45}
        min_items: 4
        max_items: 4
        optional: true
      statvfs:
        type: array
        items: {type: int, min: 0}
        min_items: 10
        max_items: 10
        optional: true
  log:
    type: array
    role: event
    description: Send a batch of log entries.
    min_items: 1
    items:
      type: object
      fields:
        level: {type: string, max_bytes: 16, enum: [Debug, Info, Warning, Error, Critical]}
        text: {type: string, max_bytes: 4096}
        create_datetime: {type: string, max_bytes: 64, optional: true}

defaults:
  codec: json
  optional: false
  nullable: false
  extra: false
  routing: broadcast
  qos: 0
```

`units_of_measurement` specifies the measurement unit standard (`standard`) and its revision (`version`, a string). The `unit` field contains a case-sensitive UCUM expression, such as `Cel`, `ms`, or `m/s`; the Backend validates it against the specified revision. Units and their names do not need to be listed in the dictionary. The UCUM revision is pinned to the Pepeunit format version; changing it requires a new format version.

`bytes` always uses binary encoding; `any` means any JSON value, not arbitrary bytes. `any` allows `null` regardless of `nullable`.

`float` is a numeric value that may have a fractional part: it accepts JSON numbers such as `1`, `1.5`, and `1e3`. `int` accepts only integer values. `NaN` and infinities are not allowed.

### Enabling Base IOs

Base IOs are explicitly enabled in the existing `input` and `output` sections of `unit.yml`. This fragment enables the complete base set:

```yaml
input:
  update: {base: update}
  env_update: {base: env_update}
  schema_update: {base: schema_update}
  log_sync: {base: log_sync}
  reset: {base: reset}
output:
  state: {base: state}
  log: {base: log}
```

- `base` selects an entry from the matching dictionary section for `version`. The Backend expands it into a complete schema before validation and topic generation. Sibling keys alongside `base` are forbidden: the standard contract cannot be overridden.
- Base IO names are reserved in their respective direction. The IO name must match the `base` value; unknown references or references from the other direction are rejected. Authors provide full schemas for other IOs, such as `set_speed` above.
- Base IOs are not added automatically. Declaring one means the firmware implements its behavior; the Backend only sends declared commands. `log_sync` requires the `log` Output, and `update` requires the `state` Output to confirm the program version.
- Base IOs are available to all five Unit types. Maintaining the Unit itself, including restarting a `sensor`, does not change its type.
- In `io_topics.yml`, base and author-defined IOs share the `input` and `output` sections and receive `domain.com/<uuid>` addresses. No additional sections or `/pepeunit` suffix are needed. The Backend retains the base IO designation: service commands, state, and logs are available to the Unit itself and authorized Pepeunit management, and do not participate in user Output → Input connections.

The base `reset` message is `{"COMMAND":"Reset"}`. Commands retain the existing protocol names and fields; `env_update` now updates `.env`, and `schema_update` updates `io_topics.yml`. With `search.execution_type: compiled`, the `update` handler additionally requires `COMPILED_FIRMWARE_LINK`; with `interpreted`, the link is optional. This condition is checked separately from the message schema using the Unit metadata.

`state` requires `pu_commit_version`; other fields are optional. `mem_free` and `mem_alloc` are measured in bytes, `ifconfig` contains IP, netmask, gateway, and DNS, and `statvfs` contains the ten filesystem state values from the current protocol. `millis` retains its semantics: milliseconds since startup or Unix time in milliseconds. Unknown fields are rejected under the new format's general rule.

In the new contract, `log` always sends a nonempty array, even for one entry. This simplifies the schema; the previous single-object form requires adaptation. `create_datetime` is an ISO 8601 time string; when absent, the Backend reception time is used. The handler validates the time format. Log batches must be split according to the broker message size limit; `max_bytes` on `text` limits only the text of a single entry.

## What the Metaschema Checks

The full machine-readable metaschema belongs in Pepeunit. Authors only need the rules below; this is a new Pepeunit format, not JSON Schema written in YAML.

| Fields | Allowed on | Rule |
| -- | -- | -- |
| `version` | `unit.yml` root | Required supported version of the entire format |
| `type` | `search` | Required string: one value from `unit_types` |
| `execution_type` | `search` | Required string: one value from `execution_types` |
| `base` | IO root | Reference to a base IO in the same direction; no sibling keys |
| `type` | ENV or IO value schema | Required after expanding `base`; selected from `types` |
| `min`, `max` | `int`, `float` | Inclusive bounds; `min <= max` |
| `enum` | Scalar | A nonempty list of distinct values of the declared type |
| `format` | `string` | Selected from the dictionary; UUID validation is explicitly enforced |
| `unit` | `int`, `float` | Case-sensitive UCUM expression using the revision specified in the dictionary's `units_of_measurement` |
| `fields` | `object` | A field map, which may be empty |
| `variants` | `object` | A nonempty variant map instead of `fields`; `action` is reserved |
| `extra` | Object with `fields` | Allows additional fields |
| `items` | `array` | Required item schema |
| `min_items`, `max_items` | `array` | Nonnegative integer length bounds |
| `optional` | Object field or ENV setting | Allows the field to be omitted |
| `nullable` | Any JSON type | Additionally allows `null` |
| `example` | ENV | Required; must pass the variable schema validation; never inserted automatically |
| `default`, `secret` | ENV | The default must pass validation; secrets are hidden in diagnostics |
| `description` | Any value | Text; required for IO |
| `max_bytes` | `string`, `bytes`, `any`; `object` with `extra: true` | Required positive integer value size limit in bytes; no default |
| `role`, `codec` | IO root | Role is required |
| `qos` | IO root | Optional integer `0`, `1`, or `2`; uses `defaults.qos` (`0`); omitted from `io_topics.yml` when equal to the default |
| `routing` | Output | Broadcast or selected connection; the latter requires the controller envelope |

An object specifies exactly one of `fields` or `variants`. `bytes` is allowed only at the IO root; `utf8` is allowed only for `string`. The Backend sets general validator resource limits. Allowed GPIO pins, cross-field ENV constraints, binary packet formats, and execution acknowledgments require separate rules; types alone do not check them.

## Connection Checks Through MCP

The agent searches for Units and proposes connections. The Backend checks roles, encoding, types, ranges, units, and individual value size limits. The overall message limit is determined by the broker settings. The response includes contract versions and a result: **data-compatible**, **conversion required**, **validation on delivery**, **incompatible**, or **insufficient information**.

Matching types do not prove matching purposes: humidity percentage and power percentage are different quantities. Descriptions help the agent choose a connection but are not formal proof. Until the purpose is confirmed, automatic compatibility of the entire system cannot be guaranteed. Message validation also does not confirm physical execution of a command.
