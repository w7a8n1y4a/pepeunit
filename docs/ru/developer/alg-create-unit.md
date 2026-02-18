# Алгоритм создания Unit

:::tip
1. [Проработка идеи Unit](/developer/alg-create-unit#проработка-идеи-unit)
1. [Создание репозитория Git](/developer/alg-create-unit#создание-репозитория-git)
1. [Создание базовой файловой структуры](/developer/alg-create-unit#создание-базовои-фаиловои-структуры)
1. [Первый коммит](/developer/alg-create-unit#первыи-коммит)
1. [Создание тестового Unit в Pepeunit](/developer/alg-create-unit#создание-тестового-unit-в-pepeunit)
1. [Наполнение Unit программным функционалом](/developer/alg-create-unit#наполнение-unit-программным-функционалом)
1. [Создание pepeunit.toml и readme.md](/developer/alg-create-unit#создание-pepeunit-toml-и-readme-md)
1. [Присвоение Тега](/developer/alg-create-unit#присвоение-тега)
:::

:::info
Данное руководство составлено на основе готового к работе [Fan Regulator ds18b20](https://git.pepemoss.com/pepe/pepeunit/units/esp32/fan-regulator-ds18b20.git)
:::

## Проработка идеи Unit

Перед началом разработки [Unit](/definitions#unit) ответьте себе на следующие вопросы:
1. Какую основную задачу будет решать [Unit](/definitions#unit) ?
1. Какие физические элементы будут у [Unit](/definitions#unit) ?
1. Какие данные [Unit](/definitions#unit) будет публиковать ?
1. Какое управляющее воздействие будет допускать [Unit](/definitions#unit) ?
1. На каком языке будет написан [Unit](/definitions#unit) ?

:::info Например
1. [Unit](/definitions#unit) будет регулировать температуру при помощи вентилятора
1. Понадобятся: `esp32`, `4pin` вентилятор, температурный датчик `ds18b20`
1. Будет публиковаться: скважность `PWM` сигнала управления вентилятором и температура на датчике
1. Будет команда: включение на `N` секунд с заданной скоростью вращения
1. `Micropython`
:::

## Создание репозитория Git

Выберите инстанс [GitLab](/definitions#gitlab) или [GitHub](/definitions#github):
1. Создайте пустой репозиторий
1. Склонируйте его на свою `ЭВМ`

## Создание базовой файловой структуры

:::tip
Создайте в корне [Git](/definitions#git) репозитория следующие пустые файлы:
:::

- [.gitignore](/definitions#gitignore)
- [.pepeignore](/definitions#pepeignore)
- [schema_example.json](/definitions#schema-example-json)
- [env_example.json](/definitions#env-example-json)
- [LICENSE](/definitions#license)

### .gitignore

```text
env.json
schema.json
tmp
.idea
.nvim
```

:::warning
Не забудьте указать папку с вашей `IDE`, это может быть: `.idea`, `.nvim` или любая другая
:::

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

Для соответствия проработанной идее [Unit](/definitions#unit), к стандартным топикам `input_base_topic` и `output_base_topic` потребуются добавить ещё два типа топиков: `input_topic` и `output_topic`

Тип топика | Топик разработчика | Назначение
-- | -- | --
`input_topic` | `set_fan_state/pepeunit` | [Unit](/definitions#unit) подпишется на него и будет получать управляющие команды
`output_topic` | `current_fan_speed_percentage/pepeunit` | Будет использоваться для публикации скважности `PWM`
`output_topic` | `current_temp/pepeunit` | Будет использоваться для публикации данных с датчика температуры `ds18b20`

:::info
[Подробнее о назначении каждого типа топиков](/developer/files/struct-schema-example-json#структура)
:::

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
    "PU_MQTT_PING_INTERVAL": 20,
    "PU_MQTT_KEEPALIVE": 60,
    "PU_AUTH_TOKEN": "jwt_token",
    "PU_SECRET_KEY": "32_bit_secret_key",
    "PU_ENCRYPT_KEY": "32_bit_encrypt_key",
    "PU_STATE_SEND_INTERVAL": 300,
    "PU_MIN_LOG_LEVEL": "Debug",
    "PU_MAX_LOG_LENGTH": 64
}
```

:::danger
Все переменные в [env_example.json](/definitions#env-example-json) должны быть обезличены
:::

Нужно продумать, за что будут отвечать переменные [Разработчика Unit](/development-pepeunit/mechanics/roles#unit-developer):
Название переменной | Назначение
-- | --
`WIFI_SSID` | Название `WiFi` сети для подключения
`WIFI_PASS` | Пароль от `WiFi` сети для подключения
`PWM_FAN_PIN` | Позволит менять номер контакта подключения вентилятора
`DS18B20_PIN_NUM` | Позволит менять номер контакта, отвечающего за получение данных от датчика `ds18b20`
`REGULATOR_OPERATING_RANGE` | Позволит изменять частоту работы регулятора
`PUBLISH_SEND_INTERVAL` | Позволит настраивать скорость публикации в топик `current_fan_speed_percentage/pepeunit` и `current_temp/pepeunit`
`DUTY_MIN` | Позволит устанавливать минимальную скорость вентилятора
`DUTY_MAX` | Позволит устанавливать максимальную скорость вентилятора
`TEMP_MIN` | Позволит настраивать температуру, начиная с которой скорость будет `DUTY_MIN`
`TEMP_MAX` | Позволит настраивать температуру, начиная с которой скорость будет `DUTY_MAX`

:::warning
Переменные могут поменяться в процессе разработки - это абсолютно нормально. Добавьте или удалите переменные в [env_example.json](/definitions#env-example-json) и актуализируйте [pepeunit.toml](/definitions#pepeunit-toml) и [readme.md](/definitions#readme-md).

[Pepeunit](/conception/overview) отобразит новые переменные [Пользователям](/development-pepeunit/mechanics/roles#user) для ввода, когда они изменят [таргет версию](/development-pepeunit/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit).
:::


## Первый коммит

После заполнения минимально нужных файлов, пора их закоммитить:
1. Переходим в консоль директории вашего проекта
1. `git add .` - добавляем все файлы в кандидаты на [коммит](/definitions#git-commit)
1. `git commit -m "feat(init): initial files"` - [коммитим](/definitions#git-commit) изменения
1. `git push` - отправляем изменения в ваш удалённый хостинг [GitLab](/definitions#gitlab) или [GitHub](/definitions#github)

## Создание тестового Unit в Pepeunit

Чтобы продолжить разработку [Unit](/definitions#unit), нужно взаимодействовать с [Pepeunit](/conception/overview) через [MQTT](/definitions#mqtt), а также получить [env.json](/definitions#env-json) и [schema.json](/definitions#schema-json). Выбирите подходящий инстанс [Pepeunit](/conception/overview), которому вы доверяете. Выполните следующие шаги:
1. [Создайте RepositoryRegistry](/user/git-repository/create-repository-registry#создание-repositoryregistry)
1. [Создайте Repo](/user/git-repository/create-repo)
1. [Создайте Unit](/user/unit/create-unit-pepeunit)
1. Настройте [Unit](/definitions#unit) для [обновлений в ручную](/user/unit/create-unit-pepeunit#блок-автообновлении), чтобы чётко контролировать [таргет версию](/development-pepeunit/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit)
1. [Заполните env у Unit](/user/unit/create-physic-unit#настроика-окружения)
1. Скачайте [Архив](/developer/files/struct-archive-update) с [env.json](/definitions#env-json) и [schema.json](/definitions#schema-json)

Полученные файлы [env.json](/definitions#env-json) и [schema.json](/definitions#schema-json) нужно будет поместить в каталог вашего локального [Git](/definitions#git) репозитория. Данные файлы будут содержать данные для подключения к [Pepeunit](/conception/overview), а также топики для публикации.

:::info
В процессе разработки можно заходить в тестовый [Unit](/definitions#unit) и видеть:
- какие данные [Unit](/definitions#unit) отправляет в `Output` [UnitNode](/definitions#unitnode) через систему [DataPipe](/deployment/dependencies/datapipe)
- создавать для [Unit](/definitions#unit) управляющее воздействие через `Input` [UnitNode](/definitions#unitnode)
:::

## Наполнение Unit программным функционалом

:::warning
Не существует универсального алгоритма разработки Программного обеспечения. Разрабатывайте так, как удобно именно вам. Однако рекомендуем стараться следовать стандартным правилам частоты кода.
:::

Когда у [Unit](/definitions#unit) в локальном репозитории есть обратная связь с [Pepeunit](/conception/overview), попробуйте следовать следующему алгоритму:
1. Протестировать, что клиентские библиотеки ([Micropython](/developer/libraries/micropython), [Golang](/developer/libraries/golang) и [Python](/developer/libraries/python)) корректно [отправляют данные](/developer/mqtt/default-mqtt-command) и получают [стандартные команды](/developer/mqtt/default-mqtt-command)
1. Получите данные от ваших физических датчиков, попробуйте вывести значения напрямую в консоль, без сетевых усложнений, чтобы понять что данные действительно поступают
1. Попробуйте отправить свои данные в `output_topic`, указанные в [schema_example.json](/definitions#schema-example-json)
1. Получите команды из `input_topic` и обработайте их так, как задумано в концепции вашего [Unit](/definitions#unit)
1. Внедрите переменные окружения из [env_example.json](/definitions#env-example-json) для удалённой настройки вашего [Unit](/definitions#unit)

После этих шагов вы получите рабочий [Unit](/definitions#unit), которой нужно протестировать в различных режимах работы.

:::warning
В процессе разработки можно делать множество [коммитов](/definitions#git-commit) с рабочим и не рабочим функционалом, создавать [ветки](/definitions#git-branch) и делать всё, что позволяет [Git](/definitions#git). Однако настенет момент, когда вы поймёте, что всё работает корректно, и доработки больше не требуются. В этот случае можно двигаться дальше.
:::

## Создание pepeunit.toml и readme.md

:::info
[Pepeunit](/conception/overview) расчитывает на машиночитаемое описание [Unit](/definitions#unit) в файле [pepeunit.toml](/definitions#pepeunit-toml).
:::

Чтобы добавить описание для [Unit](/definitions#unit), нужно:

1. Создать в корне репозитория [Unit](/definitions#unit) файл [pepeunit.toml](/definitions#pepeunit-toml)
1. Сгенерировать [readme.md](/definitions#readme-md) на основе [pepeunit.toml](/definitions#pepeunit-toml)
1. Поместить сгенерированный [readme.md](/definitions#readme-md) в корень репозитория. Писать [readme.md](/definitions#readme-md) в ручную не требуется

:::danger
У всех [Unit](/definitions#unit) должна быть документация, чтобы [Пользователи](/development-pepeunit/mechanics/roles#user) могли ими пользоваться.
:::

## Присвоение Тега

[readme.md](/definitions#readme-md) и [pepeunit.toml](/definitions#pepeunit-toml) заполнены, функционал готов, всё работает корректно. Время присвоить [Тег](/definitions#git-tag) для последнего [коммита](/definitions#git-commit) в репозитории:

1. Перейдите в консоль в директории вашего проекта
1. Выполните команду `git tag 1.0.0`
1. Выполните команду отправки во внешний репозиторий `git push --tags`

:::info Есть ли ограничение на формат [Тега](/definitions#git-tag) ?
Нет, [Тег](/definitions#git-tag) может иметь любую структуру.
:::

:::info
[Pepeunit](/conception/overview) например использует везде: `major.minor.fix`:
:::

:::danger
[Тег](/definitions#git-tag) будет сигнализировать [Пользователям](/development-pepeunit/mechanics/roles#user), что всё готово к эксплуатации и протестировано [Разработчиком Unit](/development-pepeunit/mechanics/roles#unit-developer).

[Пользователи](/development-pepeunit/mechanics/roles#user) будут ожидать, что выбрав последний [Тег](/definitions#git-tag), получат самую рабочую, самую актуальную версию [Unit](/definitions#unit).
:::