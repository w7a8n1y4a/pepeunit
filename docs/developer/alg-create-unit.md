# Алгоритм создания Unit

Пройдя последовательно данный алгоритм, вы создадите свой первый [Unit](/definitions#unit)

## Проработка идеи

Перед началом разработки [Unit](/definitions#unit) ответьте себе на следующие вопросы:
1. Какую основную задачу будет решать ваш [Unit](/definitions#unit) ?
1. Какие физические элементы будут у вашего [Unit](/definitions#unit) ?
1. Какие данные [Unit](/definitions#unit) будет публиковать ?
1. Какое управляющее воздействие будет допускать [Unit](/definitions#unit) ?
1. [Компилируемый](/definitions#compilable) или [Интерпритируемый](/definitions#interpreterable) будет ваш [Unit](/definitions#unit) ?

:::info Например
1. Регулирование температуры при помощи вентилятора
1. `esp32`, `4pin` вентилятор, температурный датчик `DS18B20`
1. Скважность `PWM` сигнала управления Вентилятором и Температуру на датчике
1. Включение на `N` секунд заданной скорости вращения
1. Интерпритируемый
:::

## Создание удалённого репозитория

Перейдите в удобный вам [инстанс](/definitions#instance) [Gitlab](/definitions#gitlab) или [Github](/definitions#github):
1. Создайте пустой репозиторий
1. Склонируйте его на свою `ЭВМ`

## Создание файловой структуры

1. Откройте склонированный репозиторий любым удобным для вас редактором кода
1. Создайте следующий минимальный набор пустых файлов:
    - `env_example.json`
    - `.gitignore`
    - `LICENSE` - на ваш вкус
    - `readme.md`
    - `schema_example.json`

## Заполнение .gitignore

Впишите следующий набор дирректорий и файлов:
```gitignore
env.json
schema.json
tmp
```

Не забудьте указать папку с вашей `IDE` это может быть `.idea`, `.nvim` или любая другая. Более подробно о [заполнении .gitignore](/developer/struct-git-repo#как-заполнить-gitignore).

## Заполнение schema_example.json

:::info
[Подробно о заполнении schema_example.json](/developer/struct-schema-json#schema-example-json)
:::

Копируем в файл [schema_example.json](/definitions#schema-example-json) стандартные топики:

```json
{
    "input_base_topic": [
        "update/pepeunit",
        "schema_update/pepeunit",
        "env_update/pepeunit"
    ],
    "output_base_topic": [
        "state/pepeunit"
    ]
}
```

### Стандартные топики
Какие топики хочется реализовать?
- Хочется рабочую [систему обновлений](/developer/update-system)
- Хочется обновлять схему и окружение при помощи [стандартных MQTT команд](/developer/default-mqtt-command)
- Хочется отправлять [состояние](/developer/state-mqtt-send), чтобы его потом читать в меню [Pepeunit](/conception/overview)

Исходя из хотелок - оставляем все топики, которые мы уже добавили на схему, вы можете удалить те, которые вам не хочется реализовывать

### Пользовательские топики

- В `input_topic` добавим `set_fan_state/pepeunit`, [Unit](/definitions#unit) подпишется на него и будет получать управляющие команды
- В `output_topic` добавим два: `current_fan_speed_percentage/pepeunit`, `current_temp/pepeunit` - в эти топики будем публиковать текущее состояние

Добавляем нужные топики в [schema_example.json](/definitions#schema-example-json):
```json
{
    "input_base_topic": [
        "update/pepeunit",
        "schema_update/pepeunit"
    ],
    "output_base_topic": [
        "state/pepeunit"
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

:::warning
В процессе разработки может потребоваться изменение [schema_example.json](/definitions#schema-example-json) - это абсолютно нормально. Добавьте или удалите топики и актуализируйте [Readme](/developer/struct-readme). [Pepeunit](/conception/overview) подстроится и добавит/удалит [UnitNode](/definitions#unitnode).
:::

## Заполнение env_example.json

:::info
[Подробно о заполнении env_example.json](/developer/struct-env-json#env-example-json)
:::

Копируем в файл [env_example.json](/definitions#env-example-json) стандартные переменные [Pepeunit](/conception/overview), так как это пример для заполнения [Пользователями](/mechanics/roles.html#user) - все значения должны быть обезличены:
```json
{
    "PEPEUNIT_URL": "unit.example.com",
    "HTTP_TYPE": "https",
    "MQTT_URL": "emqx.example.com",
    "PEPEUNIT_TOKEN": "jwt_token",
    "SYNC_ENCRYPT_KEY": "32_bit_encrypt_key",
    "SECRET_KEY": "32_bit_secret_key",
    "PING_INTERVAL": 30,
    "STATE_SEND_INTERVAL": 300
}
```

Мотивация для добавления дополнительных переменных:
- `WIFI_SSID` - для подключения к `WiFi` точно понадобится название сети
- `WIFI_PASS` - для подключения к `WiFi` точно будет нужен пароль
- `PUBLISH_SEND_INTERVAL` - хочу настраивать частоту отравки сообщений в [Pepeunit](/conception/overview)
- `DUTY_MIN` - хочу иметь возможность ограничить минимальную скорость вентилятора
- `DUTY_MAX` - хочу иметь возможность ограничить максимальную скорость вентилятора
- `TEMP_MIN` - хочу настраивать температуру ниже которой скорость будет `DUTY_MIN`
- `TEMP_MAX` - хочу настраивать температуру выше которой скорость будет `TEMP_MAX`

Теперь добавляем данные переменные в обезличенном виде в [env_example.json](/definitions#env-example-json), получится следующее:

```json
{
    "WIFI_SSID": "My_Perfect_Wifi_SSID",
    "WIFI_PASS": "Strong_Password",
    "PUBLISH_SEND_INTERVAL": 10,
    "DUTY_MIN": 8192,
    "DUTY_MAX": 65535,
    "TEMP_MIN": 30,
    "TEMP_MAX": 60,
    "PEPEUNIT_URL": "unit.pepemoss.com",
    "HTTP_TYPE": "https",
    "MQTT_URL": "emqx.pepemoss.com",
    "PEPEUNIT_TOKEN": "jwt_token",
    "SYNC_ENCRYPT_KEY": "32_bit_encrypt_key",
    "SECRET_KEY": "32_bit_secret_key",
    "PING_INTERVAL": 30,
    "STATE_SEND_INTERVAL": 300
}
```

:::warning
Переменные могут поменяться в процессе разработки - это абсолютно нормально. Добавьте или удалите переменные в [env_example.json](/definitions#env-example-json) и актуализируйте [Readme](/developer/struct-readme). [Pepeunit](/conception/overview) отобразит новые переменные [Пользователям](/mechanics/roles.html#user) для ввода, когда они изменят [таргет версию](/developer/update-system#алгоритм-вычисления-текущеи-версии-unit)
:::

## Первичное заполнение Readme

Используя [документацию по общей структуре Readme](/developer/struct-readme) заполните пункты:
- `Description`
- `Firmware format`
- `Hardware platform`
- `Required physical components`
- `env_example.json`
- `schema_example.json`

## Первый коммит и git push

Вы заполнили минимально нужные файлы, пора их закомитить:
1. Переходим в консоль дирректории вашего проекта
1. `git add .` - добавляем все файлы в кандидаты на [коммит](/definitions#git-commit)
1. `git commit -m "feat(init): initial files"` - [коммитим](/definitions#git-commit) изменения
1. `git push` - отправляем изменения в ваш удалённый хостинг [Gitlab](/definitions#gitlab) или [Github](/definitions#github)

## Создание тестового Unit в Pepeunit

Для продолжения разработки нам нужно будет отправлять и получать управляющее воздействие на [Unit](/definitions#unit). Очень удобно для этого использовать [инстанс](/definitions#instance) [Pepeunit](/conception/overview), которому вы доверяете. Нужно выполнить два шага на этом [инстасе](/definitions#instance):
1. Создайте [Repo](/definitions#repo) на основе вашего [Git](/definitions#git) репозитория из [Gitlab](/definitions#gitlab) и [Github](/definitions#github)
1. Создайте [Unit](/definitions#unit):
    - Обязательно [сделайте его обновляемым в ручную](/user/create-unit), чтобы чётко контролировать [таргет версию](/developer/update-system#алгоритм-вычисления-текущеи-версии-unit)
    - Заполните [переменные окружения](/user/create-unit.html)
    - Скачайте [архив](/developer/struct-archive-update) с [env.json](/definitions#env-json) и [schema.json](/definitions#schema-json)

Полученные файлы [env.json](/definitions#env-json) и [schema.json](/definitions#schema-json) нужно будет поместить в каталог вашего локального [Git](/definitions#git) репозитория. Данные файлы будут содержать данные для подключения к [инстансу](/definitions#instance), а также топики для публикации. По сути теперь вы готовы разрабатывать программный код вашего [Unit](/definitions#unit).

:::info
В процессе разработки вы сможете заходить в тестовый [Unit](/definitions#unit) и видеть какие данные он отправляет в `Output` [UnitNode](/definitions#unitnode), создавать для него управляющее воздействие через `Input` [UnitNode](/definitions#unitnode), а также же отлаживать [систему обновлений](/developer/update-system).
:::

## Наполнение Unit функционалом

Для создания функционала - итеративно прорабатывайте аспекты работы вашего кода, начните c тестирования библиотек получения данных с датчиков и постепенно идите в сторону реализации отправки данных, получения управляющего воздействия и интеграции с [Pepeunit](/conception/overview).

Здесь всё индивидуально, разработчики [Pepeunit](/conception/overview) могут лишь облегчить вам работу предоставив примеры для разных языков программирования:

- [esp32 Micropython](https://git.pepemoss.com/pepe/pepeunit/units/wifi_pc_fan_4_pin.git)
- [esp8266 Micropython](https://git.pepemoss.com/pepe/pepeunit/units/wifi_temp_sensor.git)
- [go](https://git.pepemoss.com/pepe/pepeunit/units/go_hotkeys.git)

:::info
Вы можете делать множество [коммитов](/definitions#git-commit) с рабочим и не рабочим функционалом, создавать [ветки](/definitions#git-branch) и делать всё что позволяет [Git](/definitions#git), но настенет момент во времени когда вы увидите, что всё что вы задумали корректно работает. В этот момент нужно перейти в следующему пункту.
:::

## Актуализация документации

Актуализируйте и дозаполните все пункты документации, согласно [руководству](/developer/struct-readme). [Пользователи](/mechanics/roles.html#user) скажут вам `Большое Спасибо`.

## Присвоение Тега

:::info Есть ли ограничение на формат Тега ?
[Тег](/definitions#git-tag) может иметь любую структуру.
:::

:::info
[Pepeunit](/conception/overview) использует везде: `major.minor.fix`:
- `< 1.0.0` являются `beta` версиями
- `>= 1.0.0` стабильны
:::

[Readme](/developer/struct-readme) заполнен, функционал готов, всё работает корректно. Самое время присвоить [Тег](/definitions#git-tag) для вашего последнего [коммита](/definitions#git-commit):

1. Переходим в консоль дирректории вашего проекта
1. Выполняем команду `git tag 1.0.0`
1. Выполняем команду отправки во внешний репозиторий `git push --tags`

:::danger
[Тег](/definitions#git-tag) будет сигнализировать [Пользователям](/mechanics/roles.html#user), что всё готово к эксплуатации и протестировано разработчиком.

[Пользователи](/mechanics/roles.html#user) будут ожидать, что выбрав последний [Тег](/definitions#git-tag) - получат самую рабочую, самую актуальную версию [Unit](/definitions#unit).
:::