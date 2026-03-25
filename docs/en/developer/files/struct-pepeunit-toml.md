# pepeunit.toml

::::info
[pepeunit.toml](/en/definitions#pepeunit-toml) will be used in the future to simplify searching across [RepositoryRegistry](/en/definitions#repositoryregistry) entries between [Pepeunit](/en/conception/overview) instances.
::::

```toml
[general]
name = "Fan Regulator ds18b20"
description = "Regulates fan speed depending on temperature. Publishes current temperature and `16bit` duty cycle. Allows turning the fan on for `N` seconds on command at any duty cycle"
language = "Micropython"
hardware = ["esp32", "esp32c3", "esp32s3", "ds18b20", "4pin fan", "4.7kOhm resistor", "wires"]
firmware = [
  {name = "RELEASE-1.1.1", link = "https://git.pepemoss.com/pepe/pepeunit/libs/pepeunit_micropython_client/-/releases/1.1.1"}
]
stack = ["pepeunit_micropython_client"]
version = "1.1.1"
license = "AGPL v3 License"
authors = [
    {name = "Ivan Serebrennikov", email = "admin@silberworks.com"}
]

[video]
video = {preview = "https://minio.pepemoss.com/public-data/video/base64_streaming_prev.jpg", link = "https://www.youtube.com/watch?v=r1CpkXD_MJY"}

[images]
schema = "https://minio.pepemoss.com/public-data/schema/schema_fan_4pin_unit.png"

[models]
models = [
  {version = "v0", description = "Example model", link = "https://minio.pepemoss.com/public-data/model/control_panel_sh1106/v3/stl/capsule_insert.stl"},
  {version = "v0", description = "Example model", link = "https://minio.pepemoss.com/public-data/model/control_panel_sh1106/v3/stl/capsule_panel.stl"}
]

[files]
"Delta `4Pin PWM` fan documentation" = "https://www.delta-fan.com/products/ffb1212eh.html"
"Noctua `4Pin PWM` fan documentation" = "https://www.noctua.at/en/products/nf-f12-industrialppc-3000-pwm/specifications"

[physical_io]
"client.settings.PIN_FAN" = "Duty cycle control for the fan"
"client.settings.PIN_DS18B20" = "Digital temperature value from the `ds18b20` sensor"

[env_description]
PIN_FAN = "`Pin` number responsible for the fan control signal"
PIN_FAN_PWM_FREQUENCY = "`PWM` signal frequency in hertz"
PIN_DS18B20 = "`Pin` number responsible for reading data from the `ds18b20` sensor"
REGULATOR_OPERATING_RANGE = "Regulator operating interval in milliseconds"
REGULATOR_DUTY_MIN = "Minimum `PWM 16bit` duty cycle that the regulator can set"
REGULATOR_DUTY_MAX = "Maximum `PWM 16bit` duty cycle that the regulator can set"
REGULATOR_TEMP_MIN = "Temperature in °C below which duty cycle will be `REGULATOR_DUTY_MIN`"
REGULATOR_TEMP_MAX = "Temperature in °C above which duty cycle will be `REGULATOR_DUTY_MAX`"
PUBLISH_SEND_INTERVAL = "Publish interval in milliseconds for `current_fan_speed_percentage/pepeunit` and `current_temp/pepeunit`"
PUC_WIFI_SSID = "`WiFi` network name"
PUC_WIFI_PASS = "`WiFi` network password"


[topic_assignment]
"set_fan_state/pepeunit" = "Accepts a `json` value – `{\"sleep\": 15, \"duty\": 65535}`, where `sleep` is the number of seconds the fan will run at `16 bit` duty cycle `duty`"
"current_fan_speed_percentage/pepeunit" = "Current duty cycle as text, e.g. `8192`"
"current_temp/pepeunit" = "Current temperature as text, e.g. `27.5`"

[work_algorithm]
steps = [
  "Connect to `WiFi`",
  "Connect to the `MQTT` Broker",
  "Initialize `ds18b20` sensor and `PWM`",
  "Start the main loop",
  "Every `PUBLISH_SEND_INTERVAL` milliseconds publish messages to `current_fan_speed_percentage/pepeunit` and `current_temp/pepeunit`",
  "Every `REGULATOR_OPERATING_RANGE` milliseconds the regulator linearly converts temperature to duty cycle using the algorithm from `main.py` `def convert_temp_to_duty`. The calculated value is set as the target for the fan",
  "When a command is received from `set_fan_state/pepeunit`, the `duty` is set as the target fan duty cycle and the device sleeps for `sleep` seconds, after which normal regulation resumes"
]

[installation]
steps = [
  "Flash the `Micropython` image specified in `firmware` onto the `esp32`, as described in the [guide](https://micropython.org/download/ESP32_GENERIC/)",
  "Create a `Unit` in `Pepeunit`",
  "Configure environment variables in `Pepeunit`",
  "Download the program archive from `Pepeunit`",
  "Unpack the archive into a directory",
  "Upload files from the directory to the physical device, e.g. with: `ampy -p /dev/ttyUSB0 -b 115200 put ./ .`",
  "Start the device by pressing the `reset` button"
]
```

::::warning
`.toml` files have several syntax rules:

1. Uniform list element format `[]`:
    Allowed | Not allowed
    -- | --
    `["esp32", "ds18b20", "4pin fan", "4.7kOhm resistor", "wires"]` | `["test", {name = "Ivan Serebrennikov"}]`
2. Keys containing special characters must be wrapped in `""`:
    Requires quotes | Does not require quotes
    -- | --
    `"current_temp/pepeunit" = "Current temperature as text – 27.5"` | `WIFI_SSID = "WiFi network name"`
::::

## pepeunit.toml structure

Section | Purpose | [readme.md](/en/definitions#readme-md) format
-- | -- | --
`general` | Basic information about the [Unit](/en/definitions#unit) | Rendered as a table at the top of [readme.md](/en/definitions#readme-md)
`video` | Displays a `preview` image with a link to the video `link`; the generated result renders correctly in [GitLab](/en/definitions#gitlab) and [GitHub](/en/definitions#github) | Renders a clickable image with a `## Video` tag
`images` | Visual information: diagrams, photos of the [Unit](/en/definitions#unit), or any other images | Each key–value pair becomes its own `##` section
`models` | Displays a table of models, allows specifying version and description | Renders a table
`files` | References to files such as `3D` models or additional materials | Each key–value pair becomes a numbered list item
`physical_io` | For microcontrollers: clearly describes which `IO Pin` is used for what | Renders a table
`env_description` | Describes every [env variable](/en/developer/files/struct-env-example-json) added by the [Unit Developer](/en/development-pepeunit/mechanics/roles#unit-developer) | Renders a table
`topic_assignment` | Describes each [UnitNode topic](/en/developer/files/struct-schema-example-json) added by the [Unit Developer](/en/development-pepeunit/mechanics/roles#unit-developer) | Renders a table
`work_algorithm` | Describes the [Unit](/en/definitions#unit) execution flow | Each key–value pair becomes a numbered list item
`installation` | Describes the steps required to correctly start the [Unit](/en/definitions#unit) | Each key–value pair becomes a numbered list item

::::warning
Nuances of `pepeunit.toml -> readme.md` generation:
1. If a section or an item within a section is not specified, it will not be added to [readme.md](/en/definitions#readme-md)
1. Since the text is parsed directly, you can use markdown formatting symbols inside the text, such as `**, ``, __`, etc.
1. Complex formatting constructs—code blocks, numbered lists, and tables—are not supported because they break generation due to parsing errors
1. If you need more advanced markdown, generate an initial version from [pepeunit.toml](/en/definitions#pepeunit-toml) and append a `## Additional information` section at the end. This way, the end [User](/en/development-pepeunit/mechanics/roles#user) will get all the benefits of the standard [readme.md](/en/definitions#readme-md) layout plus your custom additions.
::::

## Filling the `general` section of pepeunit.toml

Key | Example value | Comment
-- | -- | --
`name` | `"Fan Regulator ds18b20"` | Short [Unit](/en/definitions#unit) name containing only the most important information
`description` | `"Regulates fan speed depending on temperature. Publishes current temperature and duty cycle. Allows turning the fan on for \`N\` seconds on command"` | `1–5` sentences summarizing the [Unit](/en/definitions#unit) functionality
`language` | `"Micropython"` | Programming language used to implement the [Unit](/en/definitions#unit)
`hardware` | `["esp32", "ds18b20", "4pin fan", "4.7kOhm resistor", "wires"]` | Hardware components used
`firmware` | `[{name = "ESP32...0.0.bin", link = "https://git.pepe.../download"}]` | Data about binaries installed directly on the hardware: interpreters, firmware images, etc.
`stack` | `["pepeunit_micropython_client"]` | Libraries used by the [Unit](/en/definitions#unit)
`version` | `"1.0.0"` | Current [Unit](/en/definitions#unit) version
`license` | `"AGPL v3 License"` | See more about licenses in [LICENSE](/en/definitions#license)
`authors` | `[{name = "Ivan Serebrennikov", email = "admin@silberworks.com"}]` | List of [Unit](/en/definitions#unit) authors

::::warning
Notes:
1. `hardware`, `firmware`, and `stack` can use either plain string elements (as in the `hardware` example) or link objects (as in the `firmware` example), but the format must be uniform across all elements in a given list: either all strings or all objects
::::

## Filling sections after `general`

::::info
All other sections should be filled by following the [example](/en/definitions#pepeunit-toml).
::::
