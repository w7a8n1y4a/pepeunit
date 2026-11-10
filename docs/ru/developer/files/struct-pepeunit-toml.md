# pepeunit.toml

:::info
pepeunit.toml описывает Unit в машиночитаемом виде. По нему генерируется readme.md, а в будущем он пригодится для поиска Repo между инстансами.
:::

```toml
[general]
name = "Fan Regulator ds18b20"
description = "Регулирует обороты вентилятора в зависимости от температуры. Публикует текущую температуру и 16bit скважность. Позволяет включить вентилятор на N секунд по команде с любой скважностью"
language = "Micropython"
hardware = ["esp32", "esp32c3", "esp32s3", "ds18b20", "4pin fan", "резистор 4.7кОм", "wires"]
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
  {version = "v0", description = "Пример модели", link = "https://minio.pepemoss.com/public-data/model/control_panel_sh1106/v3/stl/capsule_insert.stl"},
  {version = "v0", description = "Пример модели", link = "https://minio.pepemoss.com/public-data/model/control_panel_sh1106/v3/stl/capsule_panel.stl"}
]

[files]
"Документация 4Pin PWM вентилятора Delta" = "https://www.delta-fan.com/products/ffb1212eh.html"
"Документация 4Pin PWM вентилятора Noctua" = "https://www.noctua.at/en/products/nf-f12-industrialppc-3000-pwm/specifications"

[physical_io]
"client.settings.PIN_FAN" = "Управление скважностью для работы Вентилятора"
"client.settings.PIN_DS18B20" = "Цифровое значение температуры от датчика ds18b20"

[env_description]
PIN_FAN = "Номер Pin, отвечающий за управляющее воздействие на Вентилятор"
PIN_FAN_PWM_FREQUENCY = "Частота PWM сигнала в герцах"
PIN_DS18B20 = "Номер Pin, отвечающий за получение данных от датчика ds18b20"
REGULATOR_OPERATING_RANGE = "Частота работы регулятора в миллисекундах"
REGULATOR_DUTY_MIN = "Минимальная скважность PWM 16bit, которую может установить регулятор"
REGULATOR_DUTY_MAX = "Максимальная скважность PWM 16bit, которую может установить регулятор"
REGULATOR_TEMP_MIN = "Температура в градусах цельсия, ниже которой скважность будет REGULATOR_DUTY_MIN"
REGULATOR_TEMP_MAX = "Температура в градусах цельсия, выше которой скважность будет REGULATOR_DUTY_MAX"
PUBLISH_SEND_INTERVAL = "Частота публикации данных в current_fan_speed_percentage/pepeunit и current_temp/pepeunit в миллисекундах"
PUC_WIFI_SSID = "Имя сети WiFi"
PUC_WIFI_PASS = "Пароль от сети WiFi"

[topic_assignment]
"set_fan_state/pepeunit" = "Принимает json {\"sleep\": 15, \"duty\": 65535}: sleep - на сколько секунд включить вентилятор, duty - 16bit скважность"
"current_fan_speed_percentage/pepeunit" = "Текущее значение скважности в текстовом формате - 8192"
"current_temp/pepeunit" = "Текущая температура в текстовом формате - 27.5"

[work_algorithm]
steps = [
  "Подключение к WiFi",
  "Подключение к MQTT брокеру",
  "Инициализация датчика ds18b20 и PWM",
  "Запуск основного цикла",
  "Каждые PUBLISH_SEND_INTERVAL миллисекунд публикуются сообщения в current_fan_speed_percentage/pepeunit и current_temp/pepeunit",
  "Каждые REGULATOR_OPERATING_RANGE миллисекунд регулятор линейно преобразует температуру в скважность и устанавливает её вентилятору",
  "При команде из set_fan_state/pepeunit вентилятор работает с заданной скважностью sleep секунд, затем возвращается к обычному регулированию"
]

[installation]
steps = [
  "Установите образ Micropython, указанный в firmware, на esp32, как в [руководстве](https://micropython.org/download/ESP32_GENERIC/)",
  "Создайте Unit в Pepeunit",
  "Установите переменные окружения",
  "Скачайте архив с программой",
  "Распакуйте архив в директорию",
  "Загрузите файлы на устройство, например: ampy -p /dev/ttyUSB0 -b 115200 put ./ .",
  "Перезапустите устройство кнопкой reset"
]
```

:::warning
У TOML есть правила записи:

1. Все элементы списка одного вида. В hardware, firmware и stack или все тексты, или все ссылки:
    Можно | Нельзя
    -- | --
    ["esp32", "ds18b20", "4pin fan"] | ["test", {name = "Ivan Serebrennikov"}]
2. Ключ со специальными символами нужно взять в кавычки:
    Нужны кавычки | Не нужны
    -- | --
    "current_temp/pepeunit" = "Текущая температура" | WIFI_SSID = "Имя сети WiFi"
:::

## Структура pepeunit.toml

Раздел | Что описывает | В readme.md
-- | -- | --
general | Основную информацию о Unit | Таблица под заголовком
video | Картинку preview со ссылкой на видео link | Кликабельная картинка, раздел Video
images | Схемы, фото готового Unit и другие картинки | Отдельный раздел на каждую пару ключ-значение
models | Модели: версию, описание и ссылку | Таблица
files | Файлы, например 3D модели и документацию | Нумерованный список
physical_io | Для микроконтроллеров: какой контакт зачем нужен | Таблица
env_description | Каждую [переменную env](/developer/files/struct-env-example-json), которую добавил [Разработчик Unit](/development-pepeunit/mechanics/roles#unit-developer) | Таблица
topic_assignment | Каждый [топик Разработчика](/developer/files/struct-schema-example-json), который добавил Разработчик | Таблица
work_algorithm | Порядок работы Unit | Нумерованный список
installation | Шаги для запуска Unit | Нумерованный список

:::warning
Как строится readme.md:
1. Если раздела или элемента нет, в readme.md их тоже не будет
1. Текст берётся как есть, поэтому в нём работает простая разметка md, например выделение жирным или кодом
1. Блоки кода, нумерованные списки и таблицы внутри значений не поддерживаются: они ломают разбор
1. Нужна расширенная разметка? Сгенерируйте readme.md и допишите в конец блок Additional information. Пользователь получит и привычную схему, и ваше дополнение
:::

## Заполнение general

Ключ | Предел | Комментарий
-- | -- | --
name | 50 символов | Короткое название, только самое важное. Становится заголовком readme.md
description | 400 символов | 1-5 предложений об основном функционале
language | 50 символов | Язык программирования Unit
hardware | 30 элементов | Физические компоненты
firmware | 30 элементов | Бинарные файлы, которые ставятся прямо на устройство: интерпретаторы и другое
stack | 30 элементов | Библиотеки, которые использует Unit
version | 30 символов | Текущая версия Unit
license | 50 символов | Лицензия, подробнее в LICENSE
authors | 30 элементов | Авторы Unit

Формат значений смотрите в примере выше, остальные разделы заполняйте по нему же. Весь файл не должен быть больше 10000 символов, иначе генератор откажет.
