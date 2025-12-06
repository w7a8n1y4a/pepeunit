# pepeunit.toml

:::info
[pepeunit.toml](/definitions#pepeunit-toml) будет использован в будущем для упрощения поиска по [RepositoryRegisty](/definitions#repositoryregistry) между инстансами [Pepeunit](/conception/overview).
:::

```toml
[general]
name = "Fan Regulator ds18b20"
description = "Регулирует обороты вентилятора в зависимости от температуры. Публикует текущую температуру и скважность. Позволяет включить вентилятор на `N` секунд по команде"
language = "Micropython"
hardware = ["esp32", "ds18b20", "4pin fan", "резистор 4.7кОм", "wires"]
firmware = [
  {name = "Поменять на 1.0.0 esp32 GENERIC", link = "https://git.pepemoss.com/pepe/pepeunit/libs/pepeunit_micropython_client/-/package_files/43/download"}
]
stack = ["pepeunit_micropython_client"]
version = "0.0.0"
license = "AGPL v3 License"
authors = [
    {name = "Ivan Serebrennikov", email = "admin@silberworks.com"}
]

[images]
schema = "https://i.ibb.co/QQJ6h70/schema-fan-4pin-unit.png"

[files]
"Документация `4Pin` вентилятора" = "https://www.delta-fan.com/products/ffb1212eh.html"

[physical_io]
"client.settings.PWM_FAN_PIN" = "Управление скважностью для работы Вентилятора"
"client.settings.DS18B20_PIN_NUM" = "Цифровое значение температуры от датчика `ds18b20`"

[env_description]
WIFI_SSID = "Имя сети WiFi"
WIFI_PASS = "Пароль от сети WiFi"
PWM_FAN_PIN = "Номер `Pin` отвечающий за управляющее воздействие на Вентилятор"
DS18B20_PIN_NUM = "Номер `Pin` отвечающий за получение данных от датчика `ds18b20`"
REGULATOR_OPERATING_RANGE = "Частота работы регулятора в миллисекундах"
PUBLISH_SEND_INTERVAL = "Частота публикации данных в `current_fan_speed_percentage/pepeunit` и `current_temp/pepeunit` в секундах"
DUTY_MIN = "Минимальная скважность `PWM 16bit`, которую можно установить"
DUTY_MAX = "Максимальная скважность `PWM 16bit`, которую можно установить" 
TEMP_MIN = "Температура в градусах цельсия, ниже которой скважность будет `DUTY_MIN`"
TEMP_MAX = "Температура в градусах цельсия, выше которой скважность будет соответствовать `DUTY_MAX`"

[topic_assignment]
"set_fan_state/pepeunit" = "Принимает в качестве значения `json` - `{\"sleep\": 15, \"duty\": 65535}`, где `sleep` сообщаяет в течении скольки секунд вентилятор будут включен со скважностью `duty`"
"current_fan_speed_percentage/pepeunit" = "Текущее значение скважности в текстовом формате - `8192`"
"current_temp/pepeunit" = "Текущая температура в текстовом формате - `27.5`"

[work_algorithm]
steps = [
  "Подключение к `WiFi`",
  "Инициализация клиета `pepeunit_micropython_client`",
  "Инициализация датчика `ds18b20` и `PWM`",
  "Запуск основного цикла",
  "Каждые `PUBLISH_SEND_INTERVAL` секунд публикуются сообщения в `current_fan_speed_percentage/pepeunit` и `current_temp/pepeunit`",
  "Каждые `REGULATOR_OPERATING_RANGE` миллисекунд регулятор линейно преобразует температуру в скважность, по алгоритму из функции `main.py` `def convert_temp_to_duty`. Вычисленное значение устанавливается для Вентилятора как целевое",
  "При получении команды из `set_fan_state/pepeunit`, скважность `duty` устанавливается как целевая для Вентилятора и устройство засыпает на `sleep` секунд"
]

[installation]
steps = [
  "Установите образ `Micropython` указанный в `firmware` на `esp32`, как это сделано в [руководстве](https://micropython.org/download/ESP32_GENERIC/)",
  "Создайте `Unit` в `Pepeunit`",
  "Установите переменные окружения в `Pepeunit`",
  "Скачайте архив c программой из `Pepeunit`",
  "Распакуйте архив в дирректорию",
  "Загрузите файлы из дирреткории на физическое устройство, например командой: `ampy -p /dev/ttyUSB0 -b 115200 put ./ .`",
  "Запустить устройство нажатием кнопки `reset`"
]
```

:::warning
Файлы `.toml` имеют ряд синтаксических правил заполнения:

1. Единый формат элементов списка `[]`:
    Допустимо | Не допустимо
    -- | --
    `["esp32", "ds18b20", "4pin fan", "резистор 4.7кОм", "wires"]` | `["test", {name = "Ivan Serebrennikov"}]`
2. Ключи, в которых есть особые символы, требуют обёртки `""`:
    Требует | Не требует
    -- | --
    `"current_temp/pepeunit" = "Текущая температура в текстовом формате - 27.5"` | `WIFI_SSID = "Имя сети WiFi"`
:::

## Структура pepeunit.toml

Раздел | Предназначение | [readme.md](/definitions#readme-md) формат
-- | -- | --
`general` | Содержит базовую информацию о [Unit](/definitions#unit) | Формируется таблица в шапке [readme.md](/definitions#readme-md)
`images` | Предназначен для отображения визуальной информации, здесь могут быть схемы работы [Unit](/definitions#unit), фото готового [Unit](/definitions#unit) или любая другая визуальная информация | Каждая пара ключ-значение будет выделена в отдельный элемент c уровнем `##`
`files` | Позволяет указывать файлы, например, `3D` модели или дополнительные материалы | Каждая пара ключ-значение будет отдельным элементом нумерованного списка
`physical_io` | Нужен для микроконтрллеров, даёт чёткое понимание, какой `IO Pin` для чего предназначен | Каждая пара ключ-значение станет элементом не нумерованного списка
`env_description` | Описывает каждую [env переменную](/developer/files/struct-env-example-json), добавленную [Разработчиком Unit](/development-pepeunit/mechanics/roles#unit-developer) | Каждая пара ключ-значение будет отдельным элементом нумерованного списка
`topic_assignment` | Описывает каждый [UnitNode топик](/developer/files/struct-schema-example-json), добавленный [Разработчиком Unit](/development-pepeunit/mechanics/roles#unit-developer) | Каждая пара ключ-значение станет элементом не нумерованного списка
`work_algorithm` | Описывает последовательность работы [Unit](/definitions#unit) | Каждая пара ключ-значение будет отдельным элементом нумерованного списка
`installation` | Описывает последовательность шагов для корректного запуска [Unit](/definitions#unit) | Каждая пара ключ-значение будет отдельным элементом нумерованного списка

:::warning
Нюансы генерации `pepeunit.toml → readme.md`:
1. Если раздел или элемент раздела не указан, то он не будет добавлен в [readme.md](/definitions#readme-md)
1. Т.к. текст парсится напрямую, можно указывать в тексте `md` символы форматирования, например: `**, ``, __` и т.д.
1. Сложные элементы форматирования, наподобие блоков кода, нумерованных списков и таблиц, недоступны, т.к. ломают генерацию из-за ошибок парсинга
1. Если вам требуются расширенные возможности `md`, то сгенерируйте первичную версию на основе [pepeunit.toml](/definitions#pepeunit-toml) с добавлением в конец дополнительного блока `## Additional information`. Таким образом, конечный [Пользователь](/development-pepeunit/mechanics/roles.html#user) получит все преимущества ожидаемой схемы [readme.md](/definitions#readme-md) и ваше особое доплнение.
:::

## Заполнение pepeunit.toml general

Ключ | Пример значения | Комментарий
-- | -- | --
`name` | `"Fan Regulator ds18b20"` | Короткое название [Unit](/definitions#unit), должно содержать только самую важную информацию
`description` | `"Регулирует обороты вентилятора в зависимости от температуры. Публикует текущую температуру и скважность. Позволяет включить вентилятор на `N` секунд по команде"` | `1-5` предложений, отражающих основной функционал [Unit](/definitions#unit)
`language` | `"Micropython"` | Язык программирования, на котором написан [Unit](/definitions#unit)
`hardware` | `["esp32", "ds18b20", "4pin fan", "резистор 4.7кОм", "wires"]` | Используемые физические компаненты
`firmware` | `[{name = "ESP32...0.0.bin", link = "https://git.pepe.../download"}]` | Набор данных о бинарных файлах, устанавливаемых напрямую на физические компаненты: интерпретаторы, бинарные файлы и т.д.ы
`stack` | `["pepeunit_micropython_client"]` | Набор библиотек, используемых в программе [Unit](/definitions#unit)
`version` | `"0.0.0"` | Текущая версия [Unit](/definitions#unit)
`license` | `"AGPL v3 License"` | Подробнее о лицензиях [LICENSE](/definitions#license)
`authors` | `[{name = "Ivan Serebrennikov", email = "admin@silberworks.com"}]` | Список авторов [Unit](/definitions#unit)

:::warning
Особенности:
1. `hardware`, `firmware` и `stack` могут быть заполнены как текстовыми ключами, в примере для `hardware`, так и ссылками, как в примере для `firmware`. Но формат всех элементов списка должен быть единым: или все элементы текстовые, или все элменты ссылки
:::

## Заполнение блоков после general

:::info
Заполнение всех остальных блоков, происходит на основе [примера](/definitions#pepeunit-toml)
:::