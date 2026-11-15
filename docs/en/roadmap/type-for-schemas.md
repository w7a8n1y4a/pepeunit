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
    secret: true
    example: "example-password"
    description: Wi-Fi network password.

input:
  reset: {base: reset}

  set_speed:
    type: object
    role: command
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
- The default message limit is 4096 bytes. Set `max_bytes` on an IO to override it; the limit is checked before decoding.
- `role` and `description` are required in the resolved IO schema; `base` supplies them from the dictionary. They are not required for object fields or ENV settings; descriptions are recommended.
- Every variable in `env` requires `example`, including variables with `optional: true` or a `default`. The example must satisfy the variable's type and all constraints; `example: null` is allowed only with `nullable: true`. Missing or invalid examples are rejected during registration. `example` is a configuration hint and is not inserted into `.env` in place of a value or `default`. For `secret: true`, use a fictitious value.
- ENV supports scalar values: `bool`, `int`, `number`, and `string`, optionally with `nullable`. The Backend adds standard `PU_*` settings.
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

A Unit has exactly one of these four types. `search.type` is a string, not a list; missing types, unknown values, or multiple types are rejected during registration. The Unit type describes its purpose, while `role` describes an individual Input or Output. For example, an `actor` can publish its state while remaining an `actor`.

A ventilation system can be split as follows: a `sensor` publishes temperature, a `controller` receives it and sends commands to an `actor`, and an `observer` receives readings to store their history. The Unit type does not replace compatibility checks for individual IOs.

The required `search.execution_type` field specifies how the Unit program runs:

| Value | Execution mode |
| -- | -- |
| `interpreted` | The Unit runs the program through an interpreter |
| `compiled` | The Unit runs a prebuilt program or firmware |

Exactly one value from `execution_types` is required. Missing fields, unknown values, and lists are rejected during registration. The value describes the execution mode of the specific Unit distribution; the Backend uses it to select the update workflow.

The registry stores `unit.yml` from the selected repository version. MCP can return behavior descriptions, settings, or a specific IO separately, without requiring the entire README to be read.

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

Generated by the Backend for a specific Unit; the Unit downloads this file after startup. Its IO entries match the `input` and `output` sections in `unit.yml`.

```yaml
version: 1
schema_revision: 7
config_revision: 12
input:
  reset: domain.com/9d0c2f4d-108e-488a-85e5-6040ef3d8425
  set_speed: domain.com/2d98b4ba-c935-4379-8e1a-520e76018c17
output:
  state: domain.com/7279d28d-53b6-4866-99da-0b81bc1cc025
  speed: domain.com/d76b4234-3997-4a4a-a113-6d1c21d6b84a
```

`schema_revision` identifies the revision of the Unit's effective contract; `config_revision` identifies the revision of the `.env` and `io_topics.yml` bundle. When settings affecting IO change, the Backend checks the connections again.

MessageProcessor subscribes to `domain.com/+`: both Input and Output are covered by a single subscription. DataPipe operates in both directions. Output → Input connections are stored on the server; received Input messages are not routed again. A Unit publishes to its own Outputs and subscribes to its own Inputs.

Message rate limiting is enforced by the MQTT broker. The allowed message count is taken directly from the Pepeunit database for the specific Unit. This is a server setting; it is not part of `unit.yml`, the schema dictionary, or the generated `.env` and `io_topics.yml` files.

## Other Data Types

Fragments from separate version 1 `unit.yml` files.

### Arbitrary JSON and an Object with Arbitrary Content

```yaml
output:
  anything:
    type: any
    role: event
    description: Any JSON value, including null.

  event:
    type: object
    role: event
    description: An event with arbitrary content.
    fields:
      kind: {type: string, enum: [measurement, alert]}
      data: {type: any}
      note: {type: string, optional: true}
```

### Arrays, Text, and Bytes

```yaml
output:
  readings:
    type: array
    items: {type: number, min: -55, max: 125, unit: Cel}
    max_items: 16
    role: measurement
    description: An array of temperature readings.

  button:
    type: string
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
    routing: selected-link
    description: Sends JSON to the Input of the selected connection.
    fields:
      link_id: {type: string, format: uuid}
      data: {type: any}
```

The controller publishes to its own Output. MessageProcessor checks the UUID, permissions, and whether the connection belongs to that Output, then validates `data` against the selected Input's schema. Only `data` is forwarded to the recipient.

## Platform Dictionary

Unit authors do not write this file. This `dictionary.yml` example defines allowed format values and base service Inputs/Outputs. Their schemas and behavior are shared across the platform.

```yaml
version: 1

unit_types: [sensor, actor, controller, observer]
execution_types: [interpreted, compiled]
types: [bool, int, number, string, object, array, any, bytes]
codecs: [json, utf8, bytes]
roles: [measurement, state, event, command]
platforms: [esp8266, esp32, linux, windows, macos]
formats: [uuid]
routing: [broadcast, selected-link]

units:
  Cel: Degree Celsius
  '%': Percent
  s: Second
  ms: Millisecond
  Hz: Hertz

input:
  update:
    type: object
    role: command
    description: Update the Unit program to the specified version.
    fields:
      COMMAND: {type: string, enum: [Update]}
      PU_COMMIT_VERSION: {type: string}
      COMPILED_FIRMWARE_LINK: {type: string, optional: true}
  env_update:
    type: object
    role: command
    description: Download and apply the current .env.
    fields:
      COMMAND: {type: string, enum: [EnvUpdate]}
  schema_update:
    type: object
    role: command
    description: Download the current io_topics.yml and update subscriptions.
    fields:
      COMMAND: {type: string, enum: [SchemaUpdate]}
  log_sync:
    type: object
    role: command
    description: Send stored logs through the log Output.
    fields:
      COMMAND: {type: string, enum: [LogSync]}
  reset:
    type: object
    role: command
    description: Restart the device or program.
    fields:
      COMMAND: {type: string, enum: [Reset]}

output:
  state:
    type: object
    role: state
    description: Report the program version and system state.
    fields:
      pu_commit_version: {type: string}
      millis: {type: number, min: 0, unit: ms, optional: true}
      mem_free: {type: number, min: 0, optional: true}
      mem_alloc: {type: number, min: 0, optional: true}
      freq: {type: number, min: 0, unit: Hz, optional: true}
      ifconfig:
        type: array
        items: {type: string}
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
        level: {type: string, enum: [Debug, Info, Warning, Error, Critical]}
        text: {type: string}
        create_datetime: {type: string, optional: true}

defaults:
  codec: json
  max_bytes: 4096
  optional: false
  nullable: false
  extra: false
  routing: broadcast
```

Unit codes come from the supported UCUM subset. `bytes` always uses binary encoding; `any` means any JSON value, not arbitrary bytes. `any` allows `null` regardless of `nullable`.

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
- Base IOs are available to all four Unit types. Maintaining the Unit itself, including restarting a `sensor`, does not change its type.
- In `io_topics.yml`, base and author-defined IOs share the `input` and `output` sections and receive `domain.com/<uuid>` addresses. No additional sections or `/pepeunit` suffix are needed. The Backend retains the base IO designation: service commands, state, and logs are available to the Unit itself and authorized Pepeunit management, and do not participate in user Output → Input connections.

The base `reset` message is `{"COMMAND":"Reset"}`. Commands retain the existing protocol names and fields; `env_update` now updates `.env`, and `schema_update` updates `io_topics.yml`. With `search.execution_type: compiled`, the `update` handler additionally requires `COMPILED_FIRMWARE_LINK`; with `interpreted`, the link is optional. This condition is checked separately from the message schema using the Unit metadata.

`state` requires `pu_commit_version`; other fields are optional. `mem_free` and `mem_alloc` are measured in bytes, `ifconfig` contains IP, netmask, gateway, and DNS, and `statvfs` contains the ten filesystem state values from the current protocol. `millis` retains its semantics: milliseconds since startup or Unix time in milliseconds. Unknown fields are rejected under the new format's general rule.

In the new contract, `log` always sends a nonempty array, even for one entry. This simplifies the schema; the previous single-object form requires adaptation. `create_datetime` is an ISO 8601 time string; when absent, the Backend reception time is used. The handler validates the time format. Log batches must be split so that each fits within `max_bytes`.

## What the Metaschema Checks

The full machine-readable metaschema belongs in Pepeunit. Authors only need the rules below; this is a new Pepeunit format, not JSON Schema written in YAML.

| Fields | Allowed on | Rule |
| -- | -- | -- |
| `version` | `unit.yml` root | Required supported version of the entire format |
| `type` | `search` | Required string: one value from `unit_types` |
| `execution_type` | `search` | Required string: one value from `execution_types` |
| `base` | IO root | Reference to a base IO in the same direction; no sibling keys |
| `type` | ENV or IO value schema | Required after expanding `base`; selected from `types` |
| `min`, `max` | `int`, `number` | Inclusive bounds; `min <= max` |
| `enum` | Scalar | A nonempty list of distinct values of the declared type |
| `format` | `string` | Selected from the dictionary; UUID validation is explicitly enforced |
| `unit` | `int`, `number` | Selected from the dictionary |
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
| `role`, `codec`, `max_bytes` | IO root | Role is required; the byte limit must be positive |
| `routing` | Output | Broadcast or selected connection; the latter requires the controller envelope |

An object specifies exactly one of `fields` or `variants`. `bytes` is allowed only at the IO root; `utf8` is allowed only for `string`. The Backend sets general validator resource limits. Allowed GPIO pins, cross-field ENV constraints, binary packet formats, and execution acknowledgments require separate rules; types alone do not check them.

## Connection Checks Through MCP

The agent searches for Units and proposes connections. The Backend checks roles, encoding, types, ranges, units, and size limits. The response includes contract versions and a result: **data-compatible**, **conversion required**, **validation on delivery**, **incompatible**, or **insufficient information**.

Matching types do not prove matching purposes: humidity percentage and power percentage are different quantities. Descriptions help the agent choose a connection but are not formal proof. Until the purpose is confirmed, automatic compatibility of the entire system cannot be guaranteed. Message validation also does not confirm physical execution of a command.
