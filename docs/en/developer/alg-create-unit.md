# Algorithm for creating a Unit

::::tip
1. [Working out the Unit idea](/en/developer/alg-create-unit#working-out-the-unit-idea)
1. [Creating a Git repository](/en/developer/alg-create-unit#creating-a-git-repository)
1. [Creating the basic file structure](/en/developer/alg-create-unit#creating-the-basic-file-structure)
1. [First commit](/en/developer/alg-create-unit#first-commit)
1. [Creating a test Unit in Pepeunit](/en/developer/alg-create-unit#creating-a-test-unit-in-pepeunit)
1. [Filling the Unit with program logic](/en/developer/alg-create-unit#filling-the-unit-with-program-logic)
1. [Creating pepeunit.toml and readme.md](/en/developer/alg-create-unit#creating-pepeunit-toml-and-readme-md)
1. [Assigning a Tag](/en/developer/alg-create-unit#assigning-a-tag)
::::

::::info
This guide is based on the ready-to-use [Fan Regulator ds18b20](https://git.pepemoss.com/pepe/pepeunit/units/esp32/fan-regulator-ds18b20.git).
::::

## Working out the Unit idea

Before you start developing a [Unit](/en/definitions#unit), answer the following questions:
1. What main task will the [Unit](/en/definitions#unit) solve?
1. What physical components will the [Unit](/en/definitions#unit) have?
1. What data will the [Unit](/en/definitions#unit) publish?
1. What kind of control actions will the [Unit](/en/definitions#unit) accept?
1. In which language will the [Unit](/en/definitions#unit) be written?

::::info For example
1. The [Unit](/en/definitions#unit) will regulate temperature using a fan.
1. You will need: `esp32`, a `4pin` fan, and a `ds18b20` temperature sensor.
1. It will publish the PWM duty cycle for the fan control signal and the measured temperature.
1. There will be a command to turn on the fan for `N` seconds at a given speed.
1. `Micropython`
::::

## Creating a Git repository

Choose a [GitLab](/en/definitions#gitlab) or [GitHub](/en/definitions#github) instance:
1. Create an empty repository.
1. Clone it to your workstation.

## Creating the basic file structure

::::tip
Create the following empty files in the root of the [Git](/en/definitions#git) repository:
::::

- [.gitignore](/en/definitions#gitignore)
- [.pepeignore](/en/definitions#pepeignore)
- [schema_example.json](/en/definitions#schema-example-json)
- [env_example.json](/en/definitions#env-example-json)
- [LICENSE](/en/definitions#license)

### .gitignore

```text
env.json
schema.json
tmp
.idea
.nvim
```

::::warning
Do not forget to specify the directory of your `IDE`; it can be `.idea`, `.nvim`, or any other.
::::

### .pepeignore

```text
.git
.gitignore
.pepeignore
LICENSE
env_example.json
schema_example.json
pepeunit.toml
readme.md
```

### schema_example.json

```json
{   
    "input_base_topic": [
        "update/pepeunit",
        "env_update/pepeunit",
        "schema_update/pepeunit",
        "log_sync/pepeunit"
    ],
    "output_base_topic": [
        "state/pepeunit",
        "log/pepeunit"
    ],
    "input_topic": [
        "set_fan_state/pepeunit"
    ],
    "output_topic": [
        "current_fan_speed_percentage/pepeunit",
        "current_temp/pepeunit"
    ]
}
```

To match the worked-out [Unit](/en/definitions#unit) concept, you need to add two more topic types to the standard `input_base_topic` and `output_base_topic`: `input_topic` and `output_topic`.

Topic type | Developer topic | Purpose
-- | -- | --
`input_topic` | `set_fan_state/pepeunit` | The [Unit](/en/definitions#unit) subscribes to it and receives control commands.
`output_topic` | `current_fan_speed_percentage/pepeunit` | Used to publish the PWM duty cycle.
`output_topic` | `current_temp/pepeunit` | Used to publish data from the `ds18b20` temperature sensor.

::::info
[More details about each topic type](/en/developer/files/struct-schema-example-json#структура)
::::

### env_example.json

```json
{   
    "WIFI_SSID": "ssid",
    "WIFI_PASS": "password",
    "PWM_FAN_PIN": 0,
    "DS18B20_PIN_NUM": 4,
    "REGULATOR_OPERATING_RANGE": 1000,
    "PUBLISH_SEND_INTERVAL": 1,
    "TEMP_MIN": 30,
    "TEMP_MAX": 60,
    "DUTY_MIN": 8192,
    "DUTY_MAX": 65535,
    "PU_DOMAIN": "unit.example.com",
    "PU_HTTP_TYPE": "https",
    "PU_APP_PREFIX": "/pepeunit",
    "PU_API_ACTUAL_PREFIX": "/api/v1",
    "PU_MQTT_HOST": "emqx.example.com",
    "PU_MQTT_PORT": 1883,
    "PU_MQTT_PING_INTERVAL": 30,
    "PU_AUTH_TOKEN": "jwt_token",
    "PU_SECRET_KEY": "32_bit_secret_key",
    "PU_ENCRYPT_KEY": "32_bit_encrypt_key",
    "PU_STATE_SEND_INTERVAL": 300,
    "PU_MIN_LOG_LEVEL": "Debug",
    "PU_MAX_LOG_LENGTH": 64
}
```

::::danger
All variables in [env_example.json](/en/definitions#env-example-json) must be anonymized.
::::

You need to think through what each variable controlled by the [Unit Developer](/en/development-pepeunit/mechanics/roles#unit-developer) will be responsible for:

Variable name | Purpose
-- | --
`WIFI_SSID` | Name of the `WiFi` network to connect to.
`WIFI_PASS` | Password of the `WiFi` network.
`PWM_FAN_PIN` | Allows changing the pin number the fan is connected to.
`DS18B20_PIN_NUM` | Allows changing the pin number used to read data from the `ds18b20` sensor.
`REGULATOR_OPERATING_RANGE` | Allows changing the regulator operating frequency/range.
`PUBLISH_SEND_INTERVAL` | Allows configuring the publish interval for the `current_fan_speed_percentage/pepeunit` and `current_temp/pepeunit` topics.
`DUTY_MIN` | Allows setting the minimum fan speed.
`DUTY_MAX` | Allows setting the maximum fan speed.
`TEMP_MIN` | Allows configuring the temperature from which the speed will be `DUTY_MIN`.
`TEMP_MAX` | Allows configuring the temperature from which the speed will be `DUTY_MAX`.

::::warning
Variables may change during development — this is absolutely normal. Add or remove variables in [env_example.json](/en/definitions#env-example-json) and keep [pepeunit.toml](/en/definitions#pepeunit-toml) and [readme.md](/en/definitions#readme-md) up to date.

[Pepeunit](/en/conception/overview) will show new variables to [Users](/en/development-pepeunit/mechanics/roles#user) for input when they change the [target version](/en/development-pepeunit/mechanics/update-system#algorithm-for-calculating-the-current-unit-version).
::::

## First commit

After you have filled in the minimum required files, it is time to commit them:
1. Open a terminal in your project directory.
1. Run `git add .` — add all files as candidates for a [commit](/en/definitions#git-commit).
1. Run `git commit -m "feat(init): initial files"` — [commit](/en/definitions#git-commit) the changes.
1. Run `git push` — push the changes to your remote [GitLab](/en/definitions#gitlab) or [GitHub](/en/definitions#github) hosting.

## Creating a test Unit in Pepeunit

To continue developing the [Unit](/en/definitions#unit), you need to interact with [Pepeunit](/en/conception/overview) via [MQTT](/en/definitions#mqtt) and obtain [env.json](/en/definitions#env-json) and [schema.json](/en/definitions#schema-json). Choose a [Pepeunit](/en/conception/overview) instance you trust and perform the following steps:
1. [Create a RepositoryRegistry](/en/user/git-repository/create-repository-registry#creating-a-repositoryregistry).
1. [Create a Repo](/en/user/git-repository/create-repo).
1. [Create a Unit](/en/user/unit/create-unit-pepeunit).
1. Configure the [Unit](/en/definitions#unit) for [manual updates](/en/user/unit/create-unit-pepeunit#auto-update-block) to strictly control the [target version](/en/development-pepeunit/mechanics/update-system#algorithm-for-calculating-the-current-unit-version).
1. [Fill in the Unit env](/en/user/unit/create-physic-unit#configuring-the-environment).
1. Download the [Archive](/en/developer/files/struct-archive-update) containing [env.json](/en/definitions#env-json) and [schema.json](/en/definitions#schema-json).

The obtained [env.json](/en/definitions#env-json) and [schema.json](/en/definitions#schema-json) files must be placed in the directory of your local [Git](/en/definitions#git) repository. These files will contain the data required to connect to [Pepeunit](/en/conception/overview) as well as the topics for publishing.

::::info
During development, you can open the test [Unit](/en/definitions#unit) and see:
- what data the [Unit](/en/definitions#unit) sends to the `Output` of the [UnitNode](/en/definitions#unitnode) through the [DataPipe](/en/deployment/dependencies/datapipe) system
- how to create control actions for the [Unit](/en/definitions#unit) through the `Input` of the [UnitNode](/en/definitions#unitnode)
::::

## Filling the Unit with program logic

::::warning
There is no universal algorithm for software development. Develop in the way that is most convenient for you. However, we recommend trying to follow common code quality practices.
::::

When your [Unit](/en/definitions#unit) in the local repository already has feedback from [Pepeunit](/en/conception/overview), try following this algorithm:
1. Test that the client libraries ([Micropython](/en/developer/libraries/micropython), [Golang](/en/developer/libraries/golang), and [Python](/en/developer/libraries/python)) correctly [send data](/en/developer/mqtt/default-mqtt-command) and receive [standard commands](/en/developer/mqtt/default-mqtt-command).
1. Retrieve data from your physical sensors, try printing values directly to the console without network complexity to ensure that the data really arrives.
1. Try sending your data to the `output_topic` specified in [schema_example.json](/en/definitions#schema-example-json).
1. Receive commands from `input_topic` and handle them according to your [Unit](/en/definitions#unit) concept.
1. Integrate environment variables from [env_example.json](/en/definitions#env-example-json) for remote configuration of your [Unit](/en/definitions#unit).

After these steps, you will have a working [Unit](/en/definitions#unit) that needs to be tested in different operating modes.

::::warning
During development, you can make many [commits](/en/definitions#git-commit) with both working and non-working functionality, create [branches](/en/definitions#git-branch), and use all the power of [Git](/en/definitions#git). However, at some point you will realize that everything works correctly and no further changes are required. At that moment, you can move on.
::::

## Creating pepeunit.toml and readme.md

::::info
[Pepeunit](/en/conception/overview) relies on a machine-readable description of a [Unit](/en/definitions#unit) in the [pepeunit.toml](/en/definitions#pepeunit-toml) file.
::::

To add a description for a [Unit](/en/definitions#unit), you need to:

1. Create the [pepeunit.toml](/en/definitions#pepeunit-toml) file in the root of the [Unit](/en/definitions#unit) repository.
1. Generate [readme.md](/en/definitions#readme-md) based on [pepeunit.toml](/en/definitions#pepeunit-toml).
1. Place the generated [readme.md](/en/definitions#readme-md) into the repository root. You do not need to write [readme.md](/en/definitions#readme-md) manually.

::::danger
Every [Unit](/en/definitions#unit) must have documentation so that [Users](/en/development-pepeunit/mechanics/roles#user) can work with it.
::::

## Assigning a Tag

[readme.md](/en/definitions#readme-md) and [pepeunit.toml](/en/definitions#pepeunit-toml) are filled in, the functionality is ready, and everything works correctly. It is time to assign a [Tag](/en/definitions#git-tag) to the latest [commit](/en/definitions#git-commit) in the repository:

1. Open a terminal in your project directory.
1. Run `git tag 1.0.0`.
1. Run `git push --tags` to push tags to the remote repository.

::::info Is there a restriction on the [Tag](/en/definitions#git-tag) format?
No, a [Tag](/en/definitions#git-tag) can have any structure.
::::

::::info
For example, [Pepeunit](/en/conception/overview) uses the `major.minor.fix` format everywhere.
::::

::::danger
The [Tag](/en/definitions#git-tag) signals to [Users](/en/development-pepeunit/mechanics/roles#user) that everything is ready for production use and has been tested by the [Unit Developer](/en/development-pepeunit/mechanics/roles#unit-developer).

[Users](/en/development-pepeunit/mechanics/roles#user) will expect that by choosing the latest [Tag](/en/definitions#git-tag) they will get the most stable and up-to-date version of the [Unit](/en/definitions#unit).
::::


