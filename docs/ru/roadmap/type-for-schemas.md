# Типизация для схем

Новый концепт:
| Файл | Кто создаёт | Что внутри |
| -- | -- | -- |
| `unit.yml` | Автор Unit | Описание и тип Unit, настройки и типы Input/Output |
| `.env` | Backend | Значения настроек конкретного Unit |
| `io_topics.yml` | Backend, но в архив он больше не кладётся | Топики конкретного Unit |

Что в итоге будет завязано на новые схемы:
1. Генерация io_topics.yml и .env
1. Поиск по Unit
1. Валидация данных
1. Преобразование типов и размерностей
1. Часть типизирования datapipe, возможно предлагать параметры частично
1. Анализатор совместимости io
1. Валидация про вводе значений в input
1. Подсказки при обновлении
1. Эмуляторы устройств с ручной регулировкой значений
1. Подбор аналогов Unit для замены
1. Конструктор систем
1. Обработка qos

База:
- На устройство загружается только код в виде бинарников/raw и `.env` всё остальное уже в рантайме
- `unit.yml` берётся как и раньше и таргет версии
- `is_compilable_unit` теперь определяется из `unit.yml`
- Соединяя `UnitIO` у которых одна величина но разные размерности, `messageProcessor` будет делать преобразование при пересылке
- `Backend` научится считать максимальный размер `.env`, это сильно упростит автоматизированную прошивку в будущем
- `unit.yml` и словарь схем пишутся строго на английском. Вынужденная мера для оптимизации `MCP`
- добавляется ошибка обработки последнего сообщения у `UnitIO`, чтобы можно было понять почему `MessageProcessor` отклонил

## unit.yml

```yaml
version: 1

search:
  type: actor
  execution_type: interpreted
  name: pwm-4pin-fan
  summary: Controls a 4pin fan through incoming commands.
  platforms: [esp32, esp32s3, esp32c3]
  behavior:
    manual: >
      set_speed sets the power level for duration seconds.
      A new command replaces the previous one and restarts the timer.
      When the timer expires, the power level is set to 0%.
      The power level represents the PWM duty cycle.
    reporting: Publishes the requested power level once per second.
    limitations: Does not measure RPM or confirm physical rotation.

env:
  FAN_PIN:
    type: int
    min: 0
    example: 4
    description: GPIO used to control the fan.
  WIFI_PASSWORD:
    type: string
    max_bytes: 128
    secret: true
    example: "example-password"
    description: Wi-Fi network password.

input:
  reset: {base: reset}

  set_speed:
    type: object
    role: command
    qos: 1
    description: Sets the fan power level for the specified duration.
    fields:
      speed: {type: int, min: 0, max: 100, unit: '%'}
      duration: {type: int, min: 1, max: 3600, unit: s}

output:
  state: {base: state}

  speed:
    type: int
    min: 0
    max: 100
    unit: '%'
    role: state
    description: Requested fan power level, not measured RPM.
```

### Произвольный JSON и объект с произвольной частью

```yaml
output:
  anything:
    type: any
    max_bytes: 2048
    role: event
    description: Any JSON value, including null.

  event:
    type: object
    role: event
    description: An event with arbitrary content.
    fields:
      kind: {type: string, max_bytes: 16, enum: [measurement, alert]}
      data: {type: any, max_bytes: 2048}
      note: {type: string, max_bytes: 256, optional: true}
```

### Массив, текст и байты

```yaml
output:
  readings:
    type: array
    items: {type: float, min: -55, max: 125, unit: Cel}
    max_items: 16
    role: measurement
    description: An array of temperature readings.

  button:
    type: string
    max_bytes: 16
    codec: utf8
    enum: [Left, Right, One, Double, Long]
    role: event
    description: A user action expressed as text without JSON quotes.

  packet:
    type: bytes
    max_bytes: 220
    role: event
    description: An opaque radio packet.
```

### Команда с вариантами

`variants` — сокращение для объекта с обязательным полем `action`. Значение `action` выбирает единственный вариант и его обязательные поля. Другие поля запрещены.

```yaml
input:
  relay:
    type: object
    role: command
    qos: 1
    description: Sets the state or turns the relay on for a specified duration.
    variants:
      set:
        enabled: {type: bool}
      pulse:
        duration: {type: int, min: 1, max: 60000, unit: ms}
```

```json
{"action": "set", "enabled": true}
```

```json
{"action": "pulse", "duration": 500}
```

### Настройка с null

```yaml
env:
  CLICK_MESSAGE:
    type: string
    max_bytes: 256
    nullable: true
    default: null
    example: "click"
    description: null disables sending; an empty string sends an empty payload.
```

### Универсальный пульт

```yaml
output:
  send_command:
    type: object
    role: command
    qos: 1
    routing: selected-link
    description: Sends JSON to the Input of the selected connection.
    fields:
      link_id: {type: string, max_bytes: 36, format: uuid}
      data: {type: any, max_bytes: 2048}
```

### search и тип Unit

`search.type` задаёт тип Unit:

| Тип | Назначение | Пример |
| -- | -- | -- |
| `sensor` | Только считывает информацию и публикует её; не управляет физическими устройствами | Датчик температуры |
| `actor` | Выполняет действия в реальном мире | Вентилятор, реле, привод |
| `controller` | Получает информацию от `sensor`, принимает решения и отправляет команды `actor` | Регулятор, включающий вентилятор по температуре |
| `observer` | Анализирует или накапливает информацию от сенсоров, не управляя `actor` | Сборщик истории измерений |
| `gateway` | Передаёт данные и команды между Pepeunit и устройствами с внешним протоколом | Шлюз ZigBee, LoRa или Meshtastic |

`search.execution_type` задаёт способ исполнения программы Unit:

| Значение | Способ исполнения |
| -- | -- |
| `interpreted` | Интерпретируемый: Unit запускает программу через интерпретатор |
| `compiled` | Компилируемый: Unit запускает заранее собранную бинарную программу |

## .env

- Генерируется Backend. Секреты в примере условные, стандартные переменные показаны частично.

```dotenv
FAN_PIN=4
WIFI_PASSWORD=example-password
PU_DOMAIN=domain.com
PU_MQTT_HOST=emqx.domain.com
PU_MQTT_PORT=1883
PU_AUTH_TOKEN=example-token
PU_SCHEMA_REVISION=7
PU_CONFIG_REVISION=12
...
```

## io_topics.yml

```yaml
version: 1

input:
  reset:
    topic: domain.com/9d0c2f4d-108e-488a-85e5-6040ef3d8425
    qos: 1
  set_speed:
    topic: domain.com/2d98b4ba-c935-4379-8e1a-520e76018c17
    qos: 1
output:
  state:
    topic: domain.com/7279d28d-53b6-4866-99da-0b81bc1cc025
  speed:
    topic: domain.com/d76b4234-3997-4a4a-a113-6d1c21d6b84a
```

## Словарь платформы

- `dictionary.yml` описывает допустимые значения формата и базовые служебные Input/Output. Их схемы и поведение едины для платформы.

```yaml
version: 1

unit_types: [sensor, actor, controller, observer, gateway]
execution_types: [interpreted, compiled]
types: [bool, int, float, string, object, array, any, bytes]
roles: [measurement, state, event, command]
platforms: [esp8266, esp32, esp32s3, esp32c6, esp32c3, linux, windows, macos]
formats: [uuid]
routing: [broadcast, selected-link]

units_of_measurement:
  standard: UCUM
  version: '2.2'

input:
  update:
    type: object
    role: command
    qos: 1
    description: Update the Unit program to the specified version.
    fields:
      COMMAND: {type: string, max_bytes: 16, enum: [Update]}
      PU_COMMIT_VERSION: {type: string, max_bytes: 128}
      COMPILED_FIRMWARE_LINK: {type: string, max_bytes: 2048, optional: true}
  env_update:
    type: object
    role: command
    qos: 1
    description: Download and apply the current .env.
    fields:
      COMMAND: {type: string, max_bytes: 16, enum: [EnvUpdate]}
  schema_update:
    type: object
    role: command
    qos: 1
    description: Download the current io_topics.yml and update subscriptions.
    fields:
      COMMAND: {type: string, max_bytes: 16, enum: [SchemaUpdate]}
  log_sync:
    type: object
    role: command
    qos: 1
    description: Send stored logs through the log Output.
    fields:
      COMMAND: {type: string, max_bytes: 16, enum: [LogSync]}
  reset:
    type: object
    role: command
    qos: 1
    description: Restart the device or program.
    fields:
      COMMAND: {type: string, max_bytes: 16, enum: [Reset]}

output:
  state:
    type: object
    role: state
    description: Report the program version and system state.
    fields:
      pu_commit_version: {type: string, max_bytes: 128}
      millis: {type: float, min: 0, unit: ms, optional: true}
      mem_free: {type: float, min: 0, optional: true}
      mem_alloc: {type: float, min: 0, optional: true}
      freq: {type: float, min: 0, unit: Hz, optional: true}
      ifconfig:
        type: array
        items: {type: string, max_bytes: 45}
        min_items: 4
        max_items: 4
        optional: true
      statvfs:
        type: array
        items: {type: int, min: 0}
        min_items: 10
        max_items: 10
        optional: true
  log:
    type: array
    role: event
    description: Send a batch of log entries.
    min_items: 1
    items:
      type: object
      fields:
        level: {type: string, max_bytes: 16, enum: [Debug, Info, Warning, Error, Critical]}
        text: {type: string, max_bytes: 4096}
        create_datetime: {type: string, max_bytes: 64, optional: true}

defaults:
  codec: json
  optional: false
  nullable: false
  extra: false
  routing: broadcast
  qos: 0
```

### Подключение базовых IO

В `unit.yml` базовые IO включаются явно в существующих разделах `input` и `output`. Например, фрагмент с полным базовым набором:

```yaml
input:
  update: {base: update}
  env_update: {base: env_update}
  schema_update: {base: schema_update}
  log_sync: {base: log_sync}
  reset: {base: reset}
output:
  state: {base: state}
  log: {base: log}
```
