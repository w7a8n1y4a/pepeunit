# Readme и его основные элементы

:::warning
`Readme` - самый важный элемент вашего репозитория и будущих [Unit](/definitions#unit), от того как вы его заполните будет зависеть лёгкость эксплуатации [Unit](/definitions#unit) другими людьми. Старайтесь заполнить каждый из пунктов содержищихся в данном разделе.
:::

Пример стандартного заполнения `readme` для различных [Unit](/definitions#unit):
1. [Wifi 4pin PWM вентилятор](https://git.pepemoss.com/pepe/pepeunit/units/wifi_pc_fan_4_pin)

## Description

Когда другие [Пользователи](/mechanics/roles.html#user) [Pepeunit](/conception/overview) переходят по ссылке на репозиторий, они первым делом захотят прочитать описание будущего [Unit](/definitions#unit). Опишите в данном пункте функциональные возможности устройства, желательно просто привести возможности по пунктам, чтобы читать было проще.

:::info Пример легко читаемого функционального описания

- Регулирует обороты вентилятора в зависимости от температуры, чем больше температура тем больше обороты.
- Публикует текущую температуру и скважность.
- Позволяет включить вентилятор на `N` секунд по команде.
:::

:::info Пример тяжело читаемого описания:

Аппаратно-программный комплекс предназначен для управления вентиляционным узлом с учетом термодинамических параметров окружающей среды. Система реализует интеллектуальную адаптацию вращательных характеристик вентилятора: повышение температуры приводит к пропорциональному увеличению частоты вращения устройства, обеспечивая эффективное охлаждение. Одновременно предусмотрена возможность публикации телеметрических данных, включая текущие значения температурного показателя и коэффициента скважности, что осуществляется посредством стандартизированных протоколов передачи данных. Кроме того, комплекс поддерживает функционал кратковременной активации вентилятора, позволяя включать его на заданный интервал времени `N` секунд по внешним управляющим командам. Такое решение обеспечивает высокоадаптивное управление тепловыми процессами и возможность интеграции в сложные инфраструктурные системы.
:::

## Software platform

Укажите программную платформу на основе которой работает данное устройстве, здесь [Пользователи](/mechanics/roles.html#user) будут ожидать увидеть язык программирования или фреймворк на основе которого был создан [Unit](/definitions#unit), желательно указывать версию.

:::info Примеры
- `Python v3.11`
- `Micropython v1.24.1`
- `GO v1.23.4`
- `Vue v3.5.13`
- `React v19.0`
- `C++ v23`
- ...
:::

## Firmware format

Чтобы [Пользователи](/mechanics/roles.html#user) могли быстро понять [Компилируемый](/definitions#compilable) ваш [Unit](/definitions#unit) или [Интерпритируемый](/definitions#interpreterable) добавьте в данном пункте один из двух возможных вариантов:
- Интерпритируемый
- Компилируемый

Данный параметр при создании [Repo](/definitions#repo) в [Pepeunit](/conception/overview) влияет на [первую установку](/user/create-unit#получение-фаилов-развертывания) и [способ доставки программных обновлений](/developer/update-system)

## Hardware platform

Здесь указывается тип физических устройств на которые [Пользователи](/mechanics/roles.html#user) могут ориентироваться при создании физического [Unit](/definitions#unit)

:::info Примеры
- `esp32` (требуется >= 1МБ `flash` памяти)
- `PC` - `Linux`, `Mac`, `Win`
- `Rpi 3B+`
:::

## Required physical components

Опишите какие физические компаненты потребуются, чтобы воспроизвести [Unit](/definitions#unit). Данный пункт облегчает [Пользователям](/mechanics/roles.html#user) поиск номенклатуры материалов для закупок.

:::info Пример
- Микроконтроллер `esp32`
- `PWM` `4pin` вентилятор, например `FFB1212EH`
- Датчик температуры `DS18B20`
- `1х` резистор `4.7кОм`
- Провода
:::

## Operating Scheme

[Пользователи](/mechanics/roles.html#user) ожидают увидеть в данном пункте схемы работы [Unit](/definitions#unit), это могут быть электрические схемы, схема работы топиков или схема подключения нескольких [Unit](/definitions#unit) к [Pepeunit](/conception/overview).
Видя схему [Пользователю](/mechanics/roles.html#user) легче понять как работает ваш [Unit](/definitions#unit) и воспроизвести его.

:::warning
Ввиду того что картинки достаточно большие по размеру, а объём пространства репозитория будет нарастать с каждым новым изменением. Гораздо проще воспользоваться внешними хостингами картинок, которые позволяют получить статическую ссылку на изображение.
:::

:::info Пример вставки картинки в md
```md
![img](https://i.ibb.co/QQJ6h70/schema-fan-4pin-unit.png)
```
Эта же картинка но уже с рендером

![img](https://i.ibb.co/QQJ6h70/schema-fan-4pin-unit.png)
:::

## Physical IO

Данный пункт актуален только для [Unit](/definitions#unit) на основе микроконтроллеров, так как здесь нужно описать какие физические `IO` пины используются.

:::info Пример
- `machine.Pin(0)` настроен на отдачу `PWM` сигнала c частотой `10000Гц` и разрешением `16бит`
- `machine.Pin(4)` настроен на получение цифрового значения температуры от датчика `DS18B20`
:::

## env_example.json

Отобразите [env_example.json](/definitions#env-example-json). Это нужно для опытных [Пользователей](/mechanics/roles.html#user) - по переменным окружения можно оценить возможности настройки [Unit](/definitions#unit). [Подробное описание структуры env_example.json](/developer/struct-schema-json#schema-example-json).

:::info Пример
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
:::

### Env variable assignment

Опишите какие переменные, отличные от стандартных, вы добавили в [env_example.json](/definitions#env-example-json). Чем подробнее тем лучше.

:::info Пример
1. `WIFI_SSID` - имя сети `WiFi` в которой будет работать устройство
1. `WIFI_PASS` - пароль от сети `WiFI` в которой будет работать устройство
1. `PUBLISH_SEND_INTERVAL` - частота публикации данных в `current_fan_speed_percentage/pepeunit` и `current_temp/pepeunit` указывать нужно в секундах
1. `DUTY_MIN` - минимальная скважность `PWM 16bit`, которую можно установить 
1. `DUTY_MAX` - максимальная скважность `PWM 16bit`, которую можно установить 
1. `TEMP_MIN` - температура в градусах цельсия, ниже которой скважность будет `DUTY_MIN`
1. `TEMP_MAX` - температура в градусах цельсия, выше которой скважность будет соответствовать `DUTY_MAX`
:::

## schema_example.json

Отобразите [schema_example.json](/definitions#schema-example-json) . Это нужно для опытных [Пользователей](/mechanics/roles.html#user) - по данной схеме можно очень быстро оценить, что может [Unit](/definitions#unit). [Подробное описание структуры schema_example.json](/developer/struct-env-json#env-example-json).

:::info Пример
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
:::

### Assignment of Device Topics

Опишите какие форматы данных отдают ваши `Output` и какие форматы принимают `Input`. Постарайтесь добавить примеры.

:::info Пример
- `input` `set_fan_state/pepeunit` - принимает в качестве значения `json` - `{"sleep": 15, "duty": 65535}`, где `sleep` сообщаяет в течении скольки секунд вентилятор будет включен со скважностью `duty`
- `output` `current_fan_speed_percentage/pepeunit` - текущее значение скважности в текстовом формате - `8192`
- `output` `current_temp/pepeunit` - текущая температура в текстовом формате - `27.5`
:::

## Work algorithm

Расскижите о логике работы вашего [Unit](/definitions#unit), возможно другие [Пользователи](/mechanics/roles.html#user) захотят внести вклад и им будет гораздо проще, если они будут знать подробности о том как работают различные режимы вашего [Unit](/definitions#unit).

:::info Пример
Алгоритм работы с момента нажатия кнопки включения:
1. Подключение к `WiFI`
1. Инициализация датчика `DS18B20`
1. Подключение к `MQTT Брокеру`
1. Каждые `PUBLISH_SEND_INTERVAL` секунд публикуются сообщения в `current_fan_speed_percentage/pepeunit` и `current_temp/pepeunit`
1. Каждую секунду температура линейно преобразуется в скважность выхода, по следующему алгоритму:
    ```python
        def convert_temp_to_duty(x) -> int:
        temp_min = settings.TEMP_MIN
        temp_max = settings.TEMP_MAX
        duty_min = settings.DUTY_MIN
        duty_max = settings.DUTY_MAX
        
        if x < temp_min:
            return 8192
        
        if x > temp_max:
            return 65532
        
        y = ((x - temp_min) * (duty_max - duty_min)) / (temp_max - temp_min) + duty_min
        return int(round(y))
    ```

Алгоритм работы в момент получения сообщения из `set_fan_state/pepeunit`
1. Устройство получает сообщение формата `{"sleep": 15, "duty": 65535}`
1. Устанавливается скважность равная `duty`
1. Устойство засыпает на `sleep` секунд
:::