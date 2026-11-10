# Unit creation algorithm

This guide is based on the finished [Fan Regulator ds18b20](https://git.pepemoss.com/pepe/pepeunit/units/esp32/fan-regulator-ds18b20.git).

## Developing the Unit idea

Before writing code, answer these questions:
1. What problem does the Unit solve?
1. What physical components does it consist of?
1. What data does it publish?
1. What commands does it accept?
1. What language is it written in?

:::info For example
1. Controls the temperature with a fan
1. Needs an esp32, a 4-pin fan and a ds18b20 temperature sensor
1. Publishes the PWM duty cycle and the temperature
1. Accepts a command: turn on for N seconds at a given speed
1. Micropython
:::

## Creating a Git repository

1. Create an empty repository on GitLab or GitHub
1. Clone it to your computer

## Creating the basic file structure

Create empty files in the repository root and fill them in following the examples in the articles. All the files are described in the [Git repository structure](/developer/files/struct-git-repo).

- [.gitignore](/developer/files/struct-gitignore#example): add the folder of your IDE if it is not in the list. env.json and schema.json contain instance secrets and must not be published
- [.pepeignore](/developer/files/struct-pepeignore): everything that must not end up on the device
- [schema_example.json](/developer/files/struct-schema-example-json#structure): the standard topics and your own. Fan Regulator adds `set_fan_state/pepeunit` to input_topic, and `current_fan_speed_percentage/pepeunit` and `current_temp/pepeunit` to output_topic
- [env_example.json](/developer/files/struct-env-example-json#structure): Pepeunit fills in the standard variables with the PU_ prefix itself, you come up with the rest
- LICENSE

:::warning
Variables can be changed during development. Update env_example.json, pepeunit.toml and readme.md. [Users](/development-pepeunit/mechanics/roles#user) will see the new variables when they move to the new version.
:::

## First commit

```bash
git add .
git commit -m "feat(init): initial files"
git push
```

## Creating a test Unit in Pepeunit

To develop a Unit, you need a live MQTT connection to Pepeunit, as well as env.json and schema.json. Choose an instance you trust and do the following in the client:
1. `Repositories` → `Add repository`: specify the link to your repository. A private one requires credentials, that is, a username and an access token
1. Open the repository → `Create unit`: a Unit is created from a Repo
1. In `Updates`, choose manual update so that you decide which [version](/development-pepeunit/mechanics/update-system#algorithm-for-calculating-the-current-unit-version) the Unit has
1. Open the Unit → `Environment variables` and fill them in
1. `Manage unit` → `Program archives`: download the [archive](/developer/files/struct-archive-update) with env.json and schema.json

Put env.json and schema.json into the repository folder: they contain the instance address, the token and the topic addresses.

During development, the Unit shows what it sends to Output UnitIO, including through [DataPipe](/deployment/dependencies/datapipe), and you can send a command to Input UnitIO.

## Implementing the Unit functionality

There is no universal development algorithm, work however is convenient for you, but follow the general rules of clean code. Once there is a connection to Pepeunit, proceed like this:
1. Check that the client [library](/developer/libraries/framework) receives the [standard commands](/developer/mqtt/default-mqtt-command) and sends the [state](/developer/mqtt/state-mqtt-send)
1. Read the sensors and print the data to the console, without the network: this shows that the data is real
1. Send the data to output_topic from schema_example.json
1. Receive the commands from input_topic and handle them
1. Connect the variables from env_example.json so the Unit can be configured remotely

Commit however you like: branches, working and non-working versions, everything is allowed. When everything works, move on.

## Creating pepeunit.toml and readme.md

1. Create pepeunit.toml in the repository root, the format is described in [pepeunit.toml](/developer/files/struct-pepeunit-toml). Fan Regulator describes its topics and variables there too, in the example
1. [Generate](/developer/files/struct-readme#generating-readmemd) readme.md from it and put it in the repository root. There is no need to write it by hand

:::danger
Every Unit must have documentation, otherwise [Users](/development-pepeunit/mechanics/roles#user) will not understand how to use it.
:::

## Assigning a Tag

When pepeunit.toml and readme.md are ready and the Unit works, put a Tag on the last commit:

```bash
git tag 1.0.0
git push --tags
```

The Tag format is not restricted, Pepeunit itself uses major.minor.fix everywhere.

:::danger
A Tag tells [Users](/development-pepeunit/mechanics/roles#user) that the version is ready and has been checked by the [Unit Developer](/development-pepeunit/mechanics/roles#unit-developer). By choosing the latest Tag, they expect the most working and up-to-date version.
:::
