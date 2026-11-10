# pepeunit.toml

:::info
pepeunit.toml describes a Unit in a machine-readable form. readme.md is generated from it, and in the future it will be useful for finding a Repo across instances.
:::

```toml
[general]
name = "Fan Regulator ds18b20"
description = "Adjusts the fan speed depending on the temperature. Publishes the current temperature and the 16bit duty cycle. Allows turning the fan on for N seconds on command with any duty cycle"
language = "Micropython"
hardware = ["esp32", "esp32c3", "esp32s3", "ds18b20", "4pin fan", "4.7kOhm resistor", "wires"]
firmware = [
  {name = "RELEASE-1.3.0", link = "https://git.pepemoss.com/pepe/pepeunit/libs/pepeunit_micropython_client/-/releases/1.3.0"}
]
stack = ["pepeunit_micropython_client"]
version = "1.3.0"
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
"Delta 4Pin PWM fan documentation" = "https://www.delta-fan.com/products/ffb1212eh.html"
"Noctua 4Pin PWM fan documentation" = "https://www.noctua.at/en/products/nf-f12-industrialppc-3000-pwm/specifications"

[physical_io]
"client.settings.PIN_FAN" = "Duty cycle control for the Fan"
"client.settings.PIN_DS18B20" = "Digital temperature value from the ds18b20 sensor"

[env_description]
PIN_FAN = "Pin number responsible for the control action on the Fan"
PIN_FAN_PWM_FREQUENCY = "PWM signal frequency in hertz"
PIN_DS18B20 = "Pin number responsible for receiving data from the ds18b20 sensor"
REGULATOR_OPERATING_RANGE = "Regulator operating period in milliseconds"
REGULATOR_DUTY_MIN = "Minimum 16bit PWM duty cycle the regulator can set"
REGULATOR_DUTY_MAX = "Maximum 16bit PWM duty cycle the regulator can set"
REGULATOR_TEMP_MIN = "Temperature in degrees Celsius below which the duty cycle will be REGULATOR_DUTY_MIN"
REGULATOR_TEMP_MAX = "Temperature in degrees Celsius above which the duty cycle will be REGULATOR_DUTY_MAX"
PUBLISH_SEND_INTERVAL = "Period of publishing data to current_fan_speed_percentage/pepeunit and current_temp/pepeunit in milliseconds"
PUC_WIFI_SSID = "WiFi network name"
PUC_WIFI_PASS = "WiFi network password"

[topic_assignment]
"set_fan_state/pepeunit" = "Accepts json {\"sleep\": 15, \"duty\": 65535}: sleep - for how many seconds to turn the fan on, duty - 16bit duty cycle"
"current_fan_speed_percentage/pepeunit" = "Current duty cycle value in text format - 8192"
"current_temp/pepeunit" = "Current temperature in text format - 27.5"

[work_algorithm]
steps = [
  "Connect to WiFi",
  "Connect to the MQTT broker",
  "Initialize the ds18b20 sensor and PWM",
  "Start the main loop",
  "Every PUBLISH_SEND_INTERVAL milliseconds messages are published to current_fan_speed_percentage/pepeunit and current_temp/pepeunit",
  "Every REGULATOR_OPERATING_RANGE milliseconds the regulator linearly converts the temperature to a duty cycle and sets it on the fan",
  "On a command from set_fan_state/pepeunit the fan runs with the given duty cycle for sleep seconds, then returns to normal regulation"
]

[installation]
steps = [
  "Install the Micropython image specified in firmware on the esp32, as in the [guide](https://micropython.org/download/ESP32_GENERIC/)",
  "Create a Unit in Pepeunit",
  "Set the environment variables",
  "Download the archive with the program",
  "Unpack the archive into a directory",
  "Upload the files to the device, for example: ampy -p /dev/ttyUSB0 -b 115200 put ./ .",
  "Restart the device with the reset button"
]
```

:::warning
TOML has writing rules:

1. All elements of a list are of one kind. In hardware, firmware and stack either all texts or all links:
    Allowed | Not allowed
    -- | --
    ["esp32", "ds18b20", "4pin fan"] | ["test", {name = "Ivan Serebrennikov"}]
2. A key with special characters must be quoted:
    Quotes needed | Quotes not needed
    -- | --
    "current_temp/pepeunit" = "Current temperature" | WIFI_SSID = "WiFi network name"
:::

## pepeunit.toml structure

Section | What it describes | In readme.md
-- | -- | --
general | Basic information about the Unit | Table under the title
video | The preview image with a link to the video link | Clickable image, the Video section
images | Diagrams, photos of the finished Unit and other images | A separate section for each key-value pair
models | Models: version, description and link | Table
files | Files, for example 3D models and documentation | Numbered list
physical_io | For microcontrollers: which pin is needed for what | Table
env_description | Each [env variable](/developer/files/struct-env-example-json) added by the [Unit Developer](/development-pepeunit/mechanics/roles#unit-developer) | Table
topic_assignment | Each [Developer topic](/developer/files/struct-schema-example-json) added by the Developer | Table
work_algorithm | The order in which the Unit works | Numbered list
installation | Steps to launch the Unit | Numbered list

:::warning
How readme.md is built:
1. If a section or an element is missing, it will not be in readme.md either
1. The text is taken as is, so simple md markup works in it, for example bold or code
1. Code blocks, numbered lists and tables inside values are not supported: they break parsing
1. Need extended markup? Generate readme.md and add an Additional information block at the end. The User gets both the familiar layout and your addition
:::

## Filling in general

Key | Limit | Comment
-- | -- | --
name | 50 characters | A short name, only the most important. Becomes the readme.md title
description | 400 characters | 1-5 sentences about the main functionality
language | 50 characters | The Unit programming language
hardware | 30 elements | Physical components
firmware | 30 elements | Binary files installed directly on the device: interpreters and others
stack | 30 elements | Libraries the Unit uses
version | 30 characters | Current Unit version
license | 50 characters | License, see more in LICENSE
authors | 30 elements | Unit authors

See the example above for the value format, fill in the other sections following it. The whole file must not be larger than 10000 characters, otherwise the generator will refuse it.
