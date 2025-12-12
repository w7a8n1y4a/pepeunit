# pepeunit.toml

::::info
[pepeunit.toml](/en/definitions#pepeunit-toml) will be used in the future to simplify searching across [RepositoryRegistry](/en/definitions#repositoryregistry) entries between [Pepeunit](/en/conception/overview) instances.
::::

```toml
[general]
name = "Fan Regulator ds18b20"
description = "Regulates fan speed depending on temperature. Publishes current temperature and PWM duty cycle. Allows you to turn the fan on for `N` seconds on command."
language = "Micropython"
hardware = ["esp32", "ds18b20", "4pin fan", "4.7kOhm resistor", "wires"]
firmware = [
  {name = "ESP32_GENERIC-v1.26.1-PEPEUNIT-v1.0.0.bin", link = "https://git.pepemoss.com/pepe/pepeunit/libs/pepeunit_micropython_client/-/package_files/52/download"}
]
stack = ["pepeunit_micropython_client"]
version = "1.0.0"
license = "AGPL v3 License"
authors = [
    {name = "Ivan Serebrennikov", email = "admin@silberworks.com"}
]

[images]
schema = "https://i.ibb.co/QQJ6h70/schema-fan-4pin-unit.png"

[files]
"4Pin fan documentation" = "https://www.delta-fan.com/products/ffb1212eh.html"

[physical_io]
"client.settings.PWM_FAN_PIN" = "PWM duty control for the fan"
"client.settings.DS18B20_PIN_NUM" = "Digital temperature value from the `ds18b20` sensor"

[env_description]
WIFI_SSID = "WiFi network name"
WIFI_PASS = "WiFi network password"
PWM_FAN_PIN = "`Pin` number used to control the fan"
DS18B20_PIN_NUM = "`Pin` number used to read data from the `ds18b20` sensor"
REGULATOR_OPERATING_RANGE = "Regulator operating interval in milliseconds"
PUBLISH_SEND_INTERVAL = "Publish interval (seconds) for `current_fan_speed_percentage/pepeunit` and `current_temp/pepeunit`"
DUTY_MIN = "Minimum `PWM 16bit` duty cycle that can be set"
DUTY_MAX = "Maximum `PWM 16bit` duty cycle that can be set"
TEMP_MIN = "Temperature in °C below which duty cycle will be `DUTY_MIN`"
TEMP_MAX = "Temperature in °C above which duty cycle will be `DUTY_MAX`"

[topic_assignment]
"set_fan_state/pepeunit" = "Accepts `json` value – `{\"sleep\": 15, \"duty\": 65535}`, where `sleep` is the number of seconds the fan will run at duty `duty`."
"current_fan_speed_percentage/pepeunit" = "Current duty cycle as text, e.g. `8192`"
"current_temp/pepeunit" = "Current temperature as text, e.g. `27.5`"

[work_algorithm]
steps = [
  "Connect to `WiFi`",
  "Initialize `pepeunit_micropython_client`",
  "Initialize `ds18b20` sensor and `PWM`",
  "Start the main loop",
  "Every `PUBLISH_SEND_INTERVAL` seconds publish messages to `current_fan_speed_percentage/pepeunit` and `current_temp/pepeunit`",
  "Every `REGULATOR_OPERATING_RANGE` ms linearly convert temperature to duty, using `def convert_temp_to_duty` in `main.py`, and set the calculated duty as the fan target",
  "When a command is received from `set_fan_state/pepeunit`, set `duty` as the fan target duty and put the device to sleep for `sleep` seconds"
]

[installation]
steps = [
  "Flash the `Micropython` image from `firmware` onto the `esp32`, as described in the [guide](https://micropython.org/download/ESP32_GENERIC/).",
  "Create a `Unit` in `Pepeunit`.",
  "Configure environment variables in `Pepeunit`.",
  "Download the program archive from `Pepeunit`.",
  "Unpack the archive into a directory.",
  "Upload files from the directory to the physical device, e.g. with: `ampy -p /dev/ttyUSB0 -b 115200 put ./ .`",
  "Start the device by pressing the `reset` button."
]
```

::::warning
`.toml` files have several syntax rules:

1. **Uniform list element format `[]`:**

    Allowed | Not allowed
    -- | --
    `["esp32", "ds18b20", "4pin fan", "4.7kOhm resistor", "wires"]` | `["test", {name = "Ivan Serebrennikov"}]`

2. **Keys containing special characters must be wrapped in `""`:**

    Requires quotes | Does not require quotes
    -- | --
    `"current_temp/pepeunit" = "Current temperature as text – 27.5"` | `WIFI_SSID = "WiFi network name"`
::::

## pepeunit.toml structure

Section | Purpose | [readme.md](/en/definitions#readme-md) format
-- | -- | --
`general` | Basic information about the [Unit](/en/definitions#unit) | Rendered as a table at the top of [readme.md](/en/definitions#readme-md)
`images` | Visual information: diagrams, photos of the [Unit](/en/definitions#unit), or any other images | Each key–value pair becomes its own `##` section
`files` | References to files such as 3D models or additional materials | Each key–value pair becomes a numbered list item
`physical_io` | For microcontrollers: clearly describes which `IO Pin` is used for what | Each key–value pair becomes a bullet list item
`env_description` | Describes every [env variable](/en/developer/files/struct-env-example-json) added by the [Unit Developer](/en/development-pepeunit/mechanics/roles#unit-developer) | Each key–value pair becomes a numbered list item
`topic_assignment` | Describes each [UnitNode topic](/en/developer/files/struct-schema-example-json) added by the [Unit Developer](/en/development-pepeunit/mechanics/roles#unit-developer) | Each key–value pair becomes a bullet list item
`work_algorithm` | Describes the [Unit](/en/definitions#unit) execution flow | Each key–value pair becomes a numbered list item
`installation` | Describes the steps required to correctly start the [Unit](/en/definitions#unit) | Each key–value pair becomes a numbered list item

::::warning
Nuances of `pepeunit.toml -> readme.md` generation:

1. If a section or an item within a section is not specified, it will not be added to [readme.md](/en/definitions#readme-md).
1. Since the text is parsed directly, you can use markdown formatting symbols inside the text, such as `**`, `` ` ``, `__`, etc.
1. Complex formatting constructs—code blocks, nested lists, and tables—are not supported because they can break generation due to parsing errors.
1. If you need more advanced markdown, generate an initial version from [pepeunit.toml](/en/definitions#pepeunit-toml) and append a `## Additional information` section at the end. This way, the end [User](/en/development-pepeunit/mechanics/roles.html#user) will get all the benefits of the standard [readme.md](/en/definitions#readme-md) layout plus your custom additions.
::::

## Filling the `general` section of pepeunit.toml

Key | Example value | Comment
-- | -- | --
`name` | `"Fan Regulator ds18b20"` | Short [Unit](/en/definitions#unit) name containing only the most important information.
`description` | `"Regulates fan speed depending on temperature. Publishes current temperature and duty cycle. Allows turning the fan on for \`N\` seconds on command."` | `1–5` sentences summarizing the [Unit](/en/definitions#unit) functionality.
`language` | `"Micropython"` | Programming language used to implement the [Unit](/en/definitions#unit).
`hardware` | `["esp32", "ds18b20", "4pin fan", "4.7kOhm resistor", "wires"]` | Hardware components used.
`firmware` | `[{name = "ESP32...0.0.bin", link = "https://git.pepe.../download"}]` | Data about binaries installed directly on the hardware: interpreters, firmware images, etc.
`stack` | `["pepeunit_micropython_client"]` | Libraries used by the [Unit](/en/definitions#unit).
`version` | `"1.0.0"` | Current [Unit](/en/definitions#unit) version.
`license` | `"AGPL v3 License"` | See more about licenses in [LICENSE](/en/definitions#license).
`authors` | `[{name = "Ivan Serebrennikov", email = "admin@silberworks.com"}]` | List of [Unit](/en/definitions#unit) authors.

::::warning
Notes:

1. `hardware`, `firmware`, and `stack` can use either plain string elements (as in the `hardware` example) or objects (as in the `firmware` example), but the format must be uniform across all elements in a given list: either all strings or all objects.
::::

## Filling sections after `general`

::::info
All other sections should be filled by following the [example](/en/definitions#pepeunit-toml).
::::


