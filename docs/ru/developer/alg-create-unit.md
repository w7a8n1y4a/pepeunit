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
Руководство составлено на основе готового [Fan Regulator ds18b20](https://git.pepemoss.com/pepe/pepeunit/units/esp32/fan-regulator-ds18b20.git)
:::

## Проработка идеи Unit

Прежде чем писать код, ответьте себе на вопросы:
1. Какую задачу решает Unit?
1. Из каких физических элементов он состоит?
1. Какие данные публикует?
1. Какие команды принимает?
1. На каком языке написан?

:::info Например
1. Регулирует температуру вентилятором
1. Нужны esp32, вентилятор с 4 pin и датчик температуры ds18b20
1. Публикует скважность PWM сигнала и температуру
1. Принимает команду: включиться на N секунд с заданной скоростью
1. Micropython
:::

## Создание репозитория Git

1. Создайте пустой репозиторий на GitLab или GitHub
1. Склонируйте его на свой компьютер

## Создание базовой файловой структуры

Создайте в корне репозитория пустые файлы:

- .gitignore
- .pepeignore
- schema_example.json
- env_example.json
- LICENSE

Подробнее о каждом файле: [Структура Git репозитория](/developer/files/struct-git-repo).

### .gitignore

```text
env.json
schema.json
tmp
.idea
.nvim
```

:::warning
Добавьте папку своей IDE, если её нет в списке. env.json и schema.json содержат секреты инстанса, их нельзя публиковать.
:::

### .pepeignore

Здесь перечислено всё, что не должно попасть на устройство:

```text
.git
.gitignore
.pepeignore
LICENSE
env_example.json
schema_example.json
pepeunit.toml
README.md
```

### schema_example.json

```json
{
    "input_base_topic": [
        "update/pepeunit",
        "env_update/pepeunit",
        "schema_update/pepeunit",
        "log_sync/pepeunit",
        "reset/pepeunit"
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

К стандартным топикам добавлены топики разработчика:

Тип | Топик | Назначение
-- | -- | --
input_topic | set_fan_state/pepeunit | Unit получает по нему команды
output_topic | current_fan_speed_percentage/pepeunit | Unit публикует скважность PWM
output_topic | current_temp/pepeunit | Unit публикует температуру с датчика

:::info
[Подробнее о типах топиков](/developer/files/struct-schema-example-json#структура)
:::

### env_example.json

```json
{
    "PIN_FAN": 0,
    "PIN_FAN_PWM_FREQUENCY": 10000,
    "PIN_DS18B20": 4,
    "REGULATOR_OPERATING_RANGE": 1000,
    "REGULATOR_TEMP_MIN": 30,
    "REGULATOR_TEMP_MAX": 60,
    "REGULATOR_DUTY_MIN": 8192,
    "REGULATOR_DUTY_MAX": 65535,
    "PUBLISH_SEND_INTERVAL": 1000,
    "PUC_WIFI_SSID": "ssid",
    "PUC_WIFI_PASS": "password",
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
Значения в env_example.json должны быть обезличены: файл лежит в публичном репозитории.
:::

Переменные с префиксом PU_ стандартные, Pepeunit заполнит их сам. Остальные придумываете вы, например:

Переменная | Назначение
-- | --
PIN_FAN, PIN_DS18B20 | Номера контактов вентилятора и датчика
REGULATOR_OPERATING_RANGE | Как часто работает регулятор
REGULATOR_TEMP_MIN, REGULATOR_TEMP_MAX | Температуры, между которыми скорость растёт от минимума до максимума
REGULATOR_DUTY_MIN, REGULATOR_DUTY_MAX | Наименьшая и наибольшая скважность
PUBLISH_SEND_INTERVAL | Как часто публикуются данные
PUC_WIFI_SSID, PUC_WIFI_PASS | Данные WiFi сети

:::warning
Переменные можно менять в процессе разработки. Обновите env_example.json, pepeunit.toml и readme.md. [Пользователи](/development-pepeunit/mechanics/roles#user) увидят новые переменные, когда перейдут на новую версию.
:::

## Первый коммит

```bash
git add .
git commit -m "feat(init): initial files"
git push
```

## Создание тестового Unit в Pepeunit

Чтобы разрабатывать Unit, нужны живая связь с Pepeunit по MQTT, а также env.json и schema.json. Выберите инстанс, которому доверяете, и в клиенте:
1. `Репозитории` → `Добавить репозиторий`: укажите ссылку на ваш репозиторий. Для приватного понадобятся креды, то есть имя и токен доступа
1. Откройте репозиторий → `Создать аппарат`: Unit создаётся из Repo
1. В `Обновления` выберите ручное обновление, чтобы самим решать, какая [версия](/development-pepeunit/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit) у Unit
1. Откройте Unit → `Переменные окружения` и заполните их
1. `Управление аппаратом` → `Архивы программ`: скачайте [архив](/developer/files/struct-archive-update) с env.json и schema.json

Положите env.json и schema.json в папку репозитория: в них адрес инстанса, токен и адреса топиков.

:::info
Во время разработки в Unit видно:
- что Unit присылает в Output UnitIO, в том числе через [DataPipe](/deployment/dependencies/datapipe)
- можно отправить команду в Input UnitIO
:::

## Наполнение Unit программным функционалом

:::warning
Универсального алгоритма разработки нет, работайте как удобно. Но придерживайтесь общих правил чистоты кода.
:::

Когда есть связь с Pepeunit, двигайтесь так:
1. Проверьте, что клиентская [библиотека](/developer/libraries/framework) получает [стандартные команды](/developer/mqtt/default-mqtt-command) и отправляет [состояние](/developer/mqtt/state-mqtt-send)
1. Получите данные с датчиков и выведите их в консоль, без сети: так видно, что данные настоящие
1. Отправьте данные в output_topic из schema_example.json
1. Получите команды из input_topic и обработайте их
1. Подключите переменные из env_example.json, чтобы Unit можно было настроить удалённо

Коммитьте как угодно: ветки, рабочие и нерабочие версии, всё допустимо. Когда всё работает, переходите дальше.

## Создание pepeunit.toml и readme.md

:::info
Pepeunit читает описание Unit из файла pepeunit.toml: он машиночитаемый.
:::

1. Создайте в корне репозитория pepeunit.toml, формат описан в [pepeunit.toml](/developer/files/struct-pepeunit-toml)
1. Сгенерируйте по нему readme.md в клиенте: `Библиотека` → `Инструменты` → `Генератор README`
1. Положите readme.md в корень репозитория. Вручную его писать не нужно

:::danger
У каждого Unit должна быть документация, иначе [Пользователи](/development-pepeunit/mechanics/roles#user) не поймут, как им пользоваться.
:::

## Присвоение Тега

Когда pepeunit.toml и readme.md готовы, а Unit работает, поставьте Тег на последний коммит:

```bash
git tag 1.0.0
git push --tags
```

:::info Есть ли ограничения на формат Тега?
Нет, Тег может быть любым. Сам Pepeunit везде использует формат major.minor.fix.
:::

:::danger
Тег говорит [Пользователям](/development-pepeunit/mechanics/roles#user), что версия готова и проверена [Разработчиком Unit](/development-pepeunit/mechanics/roles#unit-developer). Выбирая последний Тег, они ждут самую рабочую и актуальную версию.
:::
