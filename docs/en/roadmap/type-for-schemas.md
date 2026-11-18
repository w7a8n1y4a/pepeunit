# Schema Typing

New concept:
| File | Created by | Contents |
| -- | -- | -- |
| `unit.yml` | Unit author | Unit description and type, settings, and Input/Output types |
| `.env` | Backend | Settings for a specific Unit |
| `io_topics.yml` | Backend; no longer included in the archive | Topics for a specific Unit |

What will rely on the new schemas:

1. Generation of `io_topics.yml` and `.env` from `unit.yml`
1. More precise Unit search based on `unit.yml.search`
1. Data validation within MessageProcessor
1. Unit conversions within MessageProcessor
1. QoS 0–1 handling throughout the stack, from the schema to the end Unit
1. `README.md` generation, similar to the existing endpoint
1. Partial typing for DataPipe, possibly with suggestions for some parameters (a separate endpoint)
1. IO compatibility analysis (a separate endpoint)
1. Validation when entering Input values (a separate endpoint)
1. Unit update hints (a separate endpoint)

- The endpoints must use a dedicated schema service and a separate router.

Basics:
- Only the code as binaries or raw files and `.env` are uploaded to the device; everything else is handled at runtime.
- `unit.yml` is retrieved from the target version as before.
- `is_compilable_unit` is now determined from `unit.yml`.
- When connecting `UnitIO` entries that represent the same quantity in different units, `messageProcessor` will convert values during forwarding.
- The `Backend` will calculate the maximum size of `.env`, making automated flashing much easier in the future.
- `unit.yml` and the schema dictionary must be written entirely in English. This is necessary to optimize `MCP` usage.
- `UnitIO` will record the processing error for its most recent message to explain why `MessageProcessor` rejected it.

## unit.yml

```yaml
version: 1

search:
  type: actor
  execution_type: interpreted
  name: pwm-4pin-fan
  platforms: [esp32, esp32s3, esp32c3]
  description: |
    `set_speed` sets PWM duty to `speed`% for `duration` seconds.
    New commands replace the previous one and restart the timer.
    On expiry, PWM is 0%. Reports requested PWM every second.
    Does not measure RPM or verify rotation.

docs:
  video:
    preview: https://minio.pepemoss.com/public-data/video/hotkey_bublik_prev.jpg
    link: https://youtu.be/kAPHAMLkP_A
  schema:
    link: https://minio.pepemoss.com/public-data/schema/schema_fan_4pin_unit.pn
  images:
    "Schema esp32s3 zero": https://minio.pepemoss.com/public-data/schema/control_panel_sh1106_esp32s3_zero.png
    "Schema esp32c3 super mini": https://minio.pepemoss.com/public-data/schema/control_panel_sh1106_esp32c3_super_mini.png
    "Schema esp8266 wemos d1 mini": https://minio.pepemoss.com/public-data/schema/control_panel_sh1106_esp8266_wemos_d1_mini.png
  models:
    "inside capsule": https://minio.pepemoss.com/public-data/model/control_panel_sh1106/v3/stl/capsule_insert.stl
    "capsule_panel": https://minio.pepemoss.com/public-data/model/control_panel_sh1106/v3/stl/capsule_panel.stl
  algorithm: |
    ### Command handling

    The Unit controls the fan through PWM. The `speed` value specifies
    the duty cycle as a percentage, and `duration` specifies seconds.

    1. Receive a `set_speed` command.
    2. Apply the requested PWM duty cycle.
    3. Start the timer for the requested duration.
    4. Set the PWM duty cycle to 0% when the timer expires.

    A new command replaces the previous command and restarts the timer.

    ### Reporting and limitations

    - Publish the requested duty cycle through the `speed` Output once per second.
    - Report the requested value, not measured RPM.
    - **Physical fan rotation is not verified.**

  installation: |
    ### Preparation

    - Choose a supported ESP32 board and a compatible runtime for the Unit.
    - Prepare a 4-pin fan, a suitable power supply, and a PWM driver.
    - Follow the wiring diagram provided in `docs.schema`.

    ### Setup

    1. Connect the fan and PWM driver according to the wiring diagram.
    2. Set `FAN_PIN` to the GPIO connected to the PWM driver.
    3. Set `WIFI_PASSWORD` to the Wi-Fi network password.
    4. Generate `.env` in Pepeunit for this Unit.
    5. Upload the Unit code and `.env` to the device, then start the program.

    The Unit downloads `io_topics.yml` at runtime and uses it to configure
    its Input subscriptions and Output publications.

    ### Verification

    1. Send `{"speed": 50, "duration": 10}` to the `set_speed` Input.
    2. Check that the `speed` Output reports `50` during the active command.
    3. Check that the reported value returns to `0` after 10 seconds.

    Observe the fan separately to verify its physical response.


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

`variants` is shorthand for an object with a required `action` field. The value of `action` selects exactly one variant and its required fields. Other fields are not allowed.

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

`nullable: true` allows the value `null`. The Unit's code determines what it means. In the `CLICK_MESSAGE` example, the Unit skips publication for `null` and publishes a message with an empty payload for an empty string.

### Universal Remote Control

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

### search and Unit Type

`search.type` specifies the Unit type:

| Type | Purpose | Example |
| -- | -- | -- |
| `sensor` | Only reads and publishes information; does not control physical devices | Temperature sensor |
| `actor` | Performs actions in the physical world | Fan, relay, actuator |
| `controller` | Receives information from `sensor` Units, makes decisions, and sends commands to `actor` Units | A regulator that turns on a fan based on temperature |
| `observer` | Analyzes or accumulates sensor information without controlling `actor` Units | Measurement history collector |
| `gateway` | Relays data and commands between Pepeunit and devices using an external protocol | ZigBee, LoRa, or Meshtastic gateway |

`search.execution_type` specifies how the Unit program runs:

| Value | Execution mode |
| -- | -- |
| `interpreted` | The Unit runs the program through an interpreter |
| `compiled` | The Unit runs a prebuilt binary program |

## .env

- Generated by the Backend. Secrets are placeholders, and only some standard variables are shown.

```dotenv
FAN_PIN=4
WIFI_PASSWORD=example-password
PU_DOMAIN=domain.com
PU_MQTT_HOST=emqx.domain.com
PU_MQTT_PORT=1883
PU_AUTH_TOKEN=example-token
PU_SCHEMA_REVISION=7
PU_CONFIG_REVISION=12
...
```

## io_topics.yml

```yaml
version: 1

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

## Platform Dictionary

- `dictionary.yml` defines allowed format values and base service Inputs/Outputs. Their schemas and behavior are shared across the platform.

```yaml
version: 1

unit_types: [sensor, actor, controller, observer, gateway]
execution_types: [interpreted, compiled]
types: [bool, int, float, string, object, array, any, bytes]
roles: [measurement, state, event, command]
platforms: [esp8266, esp32, esp32s3, esp32c6, esp32c3, linux, windows, macos]
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

### Enabling Base IOs

Base IOs are explicitly enabled in the existing `input` and `output` sections of `unit.yml`. For example, this fragment enables the complete base set:

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

## Unit conversions

- Only works between UnitIO entries representing the same physical quantity
- For example, converting from millions of seconds to thousands of seconds

## Type conversion and compatibility

General rules:

- Compatibility is checked in the Output → Input direction.
- After conversion, the message must conform to the Input schema, including ranges, required fields, and size limits.
- An incompatible message is rejected, and the error is recorded on UnitIO.

| Output ↓ / Input → | bool | int | float | string | object | array | any | bytes |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **bool** | 🟩 | 🟩 | 🟩 | 🟥 | 🟥 | 🟥 | 🟩 | 🟥 |
| **int** | 🟩 | 🟩 | 🟩 | 🟩 | 🟥 | 🟥 | 🟩 | 🟥 |
| **float** | 🟩 | 🟩 | 🟩 | 🟩 | 🟥 | 🟥 | 🟩 | 🟥 |
| **string** | 🟥 | 🟥 | 🟥 | 🟩 | 🟥 | 🟥 | 🟩 | 🟥 |
| **object** | 🟥 | 🟥 | 🟥 | 🟥 | 🟨 | 🟥 | 🟩 | 🟥 |
| **array** | 🟥 | 🟥 | 🟥 | 🟥 | 🟥 | 🟨 | 🟩 | 🟥 |
| **any** | 🟨 | 🟨 | 🟨 | 🟨 | 🟨 | 🟨 | 🟩 | 🟥 |
| **bytes** | 🟥 | 🟥 | 🟥 | 🟥 | 🟥 | 🟥 | 🟥 | 🟩 |

Details:

- 🟩 permits type conversion but does not override Input constraints: range, enum, format, size, and other conditions are checked after conversion.
- Numbers ↔ bool: false → 0, true → 1; zero → false, any nonzero number → true. No rounding is applied first: 0.1 → true.
- float → int: round to the nearest integer, with ties rounded away from zero: 1.5 → 2, -1.5 → -2. Overflow, NaN, and infinities are rejected.
- Numbers → string: decimal representation without thousands separators, using a period as the decimal separator. Reverse conversion is not supported.
- object → object: fields are matched by name and checked recursively using this table. `extra: true` on Input allows additional keys but does not waive required fields or validation of declared fields.
- array → array: compatibility depends on item schemas and length limits. Items are converted recursively; an error in any item rejects the entire message.
- any → a specific type: the link is allowed, but each message is evaluated using the value's actual type and this table. For example, a number from any can be passed to int, but an object cannot.
- any contains JSON values, including null, but not raw bytes. Passing null to a specific type requires `nullable: true`.
- Units and ranges: numeric conversion first converts units of the same physical quantity, then converts the type. Guaranteed compatibility requires the entire converted Output range to fit within the Input range.

## Schema capabilities

1. `README.md` generation, similar to the existing endpoint
1. Partial typing for DataPipe, possibly with suggestions for some parameters (a separate endpoint)
    - The schema validates `datapipe.yml` configuration.
    - Validation covers data types and numeric limits.
    - For example, an array type cannot use aggregation or the number type.
    - The client has an IDE for editing YAML.
1. IO compatibility analysis (a separate endpoint)
    - Type compatibility is defined above.
    - Declared ranges must be compatible: the Output range must fit within the Input range; otherwise, the link is incompatible.
1. Validation when entering Input values (a separate endpoint)
1. Unit update hints (a separate endpoint)
    - Compare the previous and target version schemas and highlight potential breaking changes, such as a type change.
    - Warn without blocking the update.
    - Only applies to manual updates; automatic updates have no place to display warnings.
