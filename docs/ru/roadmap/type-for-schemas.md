# Типизация для схем

Манифест Unit — единый контракт, который задаёт схемы `unit.yml` и `dictionary.yml` и правила их совместного применения. Оба файла указывают одну и ту же строку `contract_version`. Формы `v<major>` и `v<major>.<minor>` допускают, например, `v1`, `v1.2` и `v3`. Сейчас Backend поддерживает `v1`.

| Файл | Кто создаёт | Что внутри |
| -- | -- | -- |
| `unit.yml` | Автор Unit | Описание и тип Unit, настройки и типы Input/Output |
| `dictionary.yml` | Backend | Типы полей, базовые Input/Output и значения по умолчанию для контракта |
| `.env` | Backend | Значения настроек конкретного Unit |
| `io_topics.yml` | Backend, но в архив он больше не кладётся | Топики конкретного Unit |

Что в итоге будет завязано на новые схемы:
1. Генерация io_topics.yml и .env (на основе unit.yml)
1. Поиск по Unit (Более точный на основе unit.yml.search)
1. Валидация данных (внутри MessageProcessor)
1. Преобразование размерностей (внутри MessageProcessor)
1. Обработка qos 0-1 (на всех уровнях стека, от схемы до конечного unit)
1. Генерация README.md (аналог уже существующей ручки)
1. Часть типизирования datapipe, возможно предлагать параметры частично (отдельная ручка)
1. Анализатор совместимости io (отдельная ручка)
1. Валидация про вводе значений в input (отдельная ручка)
1. Подсказки при обновлении Unit (отдельная ручка)

- Ручки нужно вынести в отдельный сервис работы со схемой, route то же будет отдельный

База:
- На устройство загружается только код в виде бинарников/raw и `.env` всё остальное уже в рантайме
- `unit.yml` берётся как и раньше и таргет версии
- `is_compilable_unit` теперь определяется из `unit.yml`
- Соединяя `UnitIO` у которых одна величина но разные размерности, `messageProcessor` будет делать преобразование при пересылке
- `Backend` научится считать максимальный размер `.env`, это сильно упростит автоматизированную прошивку в будущем
- `unit.yml` и словарь схем пишутся строго на английском. Вынужденная мера для оптимизации `MCP`
- добавляется ошибка обработки последнего сообщения у `UnitIO`, чтобы можно было понять почему `MessageProcessor` отклонил

## unit.yml

Имена IO уникальны во всём файле: один и тот же ключ нельзя объявить дважды или одновременно в `input` и `output`. Имена из разделов `input` и `output` выбранного `dictionary.yml` зарезервированы вместе со своим направлением. Чтобы включить такой IO, автор пишет, например, `state: {}` в `output`. Его тип, ограничения, кодек и QoS берутся из словаря; любые свойства в объявлении зарезервированного IO, его перенос в другое направление и маркер `base` являются ошибкой. Обычный IO содержит собственное описание типа.

### Связь с UnitIO

Единственный источник определений IO — `unit.yml` точного целевого Git-коммита Unit и `dictionary.yml` указанного контракта. Таблица `units_io` хранит UUID, `unit_uuid`, направление `type`, имя `topic_name` и изменяемые параметры конкретного IO: доступ, состояние и DataPipe. Связи хранятся в `links`. `topic_name` — ключ из `unit.yml.input` или `unit.yml.output`, например `state`. Отдельные `base` и `io_schema` в таблице не нужны.

`target_commit` хранит ручной выбор коммита и допускает NULL. `resolve_auto_commit_and_tag` вычисляет `(resolved_commit, resolved_tag)` в локальном Git по `target_branch` и флагам обновления. `get_selected_commit_and_tag` возвращает `(selected_commit, selected_tag)` для обоих режимов. Это проверенный ручной выбор или коммит, вычисленный для автообновления, вместе с его тегом. `current_commit_version` хранит SHA, сообщённый устройством (`device_commit`). Создание и обновление проверяют `unit.yml` по `selected_commit`, затем одной транзакцией сохраняют настройки версии, тип исполнения и набор UnitIO. У IO с тем же именем и направлением сохраняются UUID, связи и параметры. При ошибке проверки или записи прежнее состояние сохраняется целиком.

Выдача файлов и команды используют манифест целевой версии. Если коммит или манифест недоступен, backend возвращает ошибку. Опубликованный словарь контракта неизменяем. Момент применения версии для снимка описан в [роадмапе MessageProcessor](./message-processor.md#синхронизация-схем).

```yaml
contract_version: v1

search:
  type: actor
  execution_type: interpreted
  name: pwm-4pin-fan
  platforms: [esp32, esp32s3, esp32c3]
  description: |
    `set_speed` sets PWM duty to `speed`% for `duration` seconds.
    New commands replace the previous one and restart the timer.
    On expiry, PWM is 0%. Reports requested PWM every second.
    Does not measure RPM or verify rotation.

docs:
  video:
    preview: https://minio.pepemoss.com/public-data/video/hotkey_bublik_prev.jpg
    link: https://youtu.be/kAPHAMLkP_A
  schema:
    link: https://minio.pepemoss.com/public-data/schema/schema_fan_4pin_unit.pn
  images:
    "Schema esp32s3 zero": https://minio.pepemoss.com/public-data/schema/control_panel_sh1106_esp32s3_zero.png
    "Schema esp32c3 super mini": https://minio.pepemoss.com/public-data/schema/control_panel_sh1106_esp32c3_super_mini.png
    "Schema esp8266 wemos d1 mini": https://minio.pepemoss.com/public-data/schema/control_panel_sh1106_esp8266_wemos_d1_mini.png
  models:
    "inside capsule": https://minio.pepemoss.com/public-data/model/control_panel_sh1106/v3/stl/capsule_insert.stl
    "capsule_panel": https://minio.pepemoss.com/public-data/model/control_panel_sh1106/v3/stl/capsule_panel.stl
  algorithm: |
    ### Command handling

    The Unit controls the fan through PWM. The `speed` value specifies
    the duty cycle as a percentage, and `duration` specifies seconds.

    1. Receive a `set_speed` command.
    2. Apply the requested PWM duty cycle.
    3. Start the timer for the requested duration.
    4. Set the PWM duty cycle to 0% when the timer expires.

    A new command replaces the previous command and restarts the timer.

    ### Reporting and limitations

    - Publish the requested duty cycle through the `speed` Output once per second.
    - Report the requested value, not measured RPM.
    - **Physical fan rotation is not verified.**

  installation: |
    ### Preparation

    - Choose a supported ESP32 board and a compatible runtime for the Unit.
    - Prepare a 4-pin fan, a suitable power supply, and a PWM driver.
    - Follow the wiring diagram provided in `docs.schema`.

    ### Setup

    1. Connect the fan and PWM driver according to the wiring diagram.
    2. Set `FAN_PIN` to the GPIO connected to the PWM driver.
    3. Set `WIFI_PASSWORD` to the Wi-Fi network password.
    4. Generate `.env` in Pepeunit for this Unit.
    5. Upload the Unit code and `.env` to the device, then start the program.

    The Unit downloads `io_topics.yml` at runtime and uses it to configure
    its Input subscriptions and Output publications.

    ### Verification

    1. Send `{"speed": 50, "duration": 10}` to the `set_speed` Input.
    2. Check that the `speed` Output reports `50` during the active command.
    3. Check that the reported value returns to `0` after 10 seconds.

    Observe the fan separately to verify its physical response.


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
  reset: {}

  set_speed:
    type: object
    qos: 1
    description: Sets the fan power level for the specified duration.
    fields:
      speed: {type: int, min: 0, max: 100, unit: '%'}
      duration: {type: int, min: 1, max: 3600, unit: s}

output:
  state: {}

  speed:
    type: int
    min: 0
    max: 100
    unit: '%'
    description: Requested fan power level, not measured RPM.
```

### Произвольный JSON и объект с произвольной частью

```yaml
output:
  anything:
    type: any
    max_bytes: 2048
    description: Any JSON value, including null.

  event:
    type: object
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
    description: An array of temperature readings.

  button:
    type: string
    max_bytes: 16
    codec: utf8
    enum: [Left, Right, One, Double, Long]
    description: A user action expressed as text without JSON quotes.

  packet:
    type: bytes
    max_bytes: 220
    description: An opaque radio packet.
```

### Команда с вариантами

`variants` — сокращение для объекта с обязательным полем `action`. Значение `action` выбирает единственный вариант и его обязательные поля. Другие поля запрещены.

```yaml
input:
  relay:
    type: object
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

`nullable: true` разрешает значение `null`. Его смысл определяет код Unit. В примере с `CLICK_MESSAGE` Unit пропускает публикацию при `null`, а при пустой строке публикует сообщение с пустой полезной нагрузкой.

### Универсальный пульт

```yaml
output:
  send_command:
    type: object
    qos: 1
    routing: selected-link
    description: Sends JSON to the linked Input identified by input_uuid.
    fields:
      input_uuid: {type: string, max_bytes: 36, format: uuid}
      data: {type: any, max_bytes: 2048}
```

Пульт берёт UUID своего Output из топика `send_command` в `io_topics.yml`. С токеном Unit он запрашивает `GET /unit_ios?output_uuid=<output_uuid>`, выбирает доступный связанный Input из списка `unit_ios` и записывает его `uuid` в поле `input_uuid`. Команду пульт публикует в свой топик `send_command`.

```json
{"input_uuid":"2d98b4ba-c935-4379-8e1a-520e76018c17","data":{"speed":50,"duration":10}}
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

- `dictionary.yml` описывает допустимые значения формата и базовые служебные Input/Output.
- Backend читает `contract_version` из `unit.yml` и открывает `app/schemas/unit_manifest/<contract_version>/dictionary.yml`. Для `contract_version: v1` это `app/schemas/unit_manifest/v1/dictionary.yml`. Значение `contract_version` в словаре должно совпадать со значением в `unit.yml`.
- Неизвестная версия контракта отклоняется до чтения словаря. Проверки `search`, раскрытие зарезервированных IO по имени и направлению, значения по умолчанию и генерация `.env` используют словарь запрошенного контракта.
- Раздел `env` словаря описывает стандартные переменные `PU_*` для файла `.env`. Автору Unit достаточно описать собственные настройки в `unit.yml`. При генерации Backend берёт актуальные параметры инстанса и значения конкретного Unit. Поле `default` указывает штатное значение, если оно предусмотрено.

```yaml
contract_version: v1

unit_types: [sensor, actor, controller, observer, gateway]
execution_types: [interpreted, compiled]
types: [bool, int, float, string, object, array, any, bytes]
platforms: [esp8266, esp32, esp32s3, esp32c6, esp32c3, linux, windows, macos]
formats: [uuid]
routing: [broadcast, selected-link]

units_of_measurement:
  standard: UCUM
  version: '2.2'

env:
  PU_DOMAIN:
    type: string
    description: Hostname or IP address of the Pepeunit instance.
  PU_HTTP_TYPE:
    type: string
    enum: [http, https]
    default: https
    description: URL scheme selected by the backend secure setting.
  PU_APP_PREFIX:
    type: string
    default: /pepeunit
    description: Application path prefix on the backend.
  PU_API_ACTUAL_PREFIX:
    type: string
    default: /api/v1
    description: Path prefix for the active backend API version.
  PU_MQTT_HOST:
    type: string
    description: Hostname or IP address of the MQTT broker.
  PU_MQTT_PORT:
    type: int
    min: 1
    max: 65535
    default: 1883
    description: MQTT broker port configured on the backend.
  PU_MQTT_PING_INTERVAL:
    type: int
    default: 20
    description: Interval between MQTT pings in seconds.
  PU_MQTT_KEEPALIVE:
    type: int
    default: 60
    description: MQTT keepalive interval in seconds from the instance settings.
  PU_AUTH_TOKEN:
    type: string
    secret: true
    description: Unit token for the backend API and MQTT broker.
  PU_SECRET_KEY:
    type: string
    secret: true
    description: Unit signing key encoded in Base64.
  PU_ENCRYPT_KEY:
    type: string
    secret: true
    description: Unit encryption key encoded in Base64.
  PU_STATE_SEND_INTERVAL:
    type: int
    default: 60
    description: Interval between Unit state reports in seconds from the instance settings.
  PU_MIN_LOG_LEVEL:
    type: string
    enum: [Debug, Info, Warning, Error, Critical]
    default: Debug
    description: Minimum severity of Unit log entries.
  PU_MAX_LOG_LENGTH:
    type: int
    default: 64
    description: Maximum number of log entries stored on the Unit.
  PU_COMMIT_VERSION:
    type: string
    description: Git commit selected for this Unit.

input:
  update:
    type: object
    qos: 1
    description: Update the Unit program to the specified version.
    fields:
      COMMAND: {type: string, max_bytes: 16, enum: [Update]}
      PU_COMMIT_VERSION: {type: string, max_bytes: 128}
      COMPILED_FIRMWARE_LINK: {type: string, max_bytes: 2048, optional: true}
  env_update:
    type: object
    qos: 1
    description: Download and apply the current .env.
    fields:
      COMMAND: {type: string, max_bytes: 16, enum: [EnvUpdate]}
  schema_update:
    type: object
    qos: 1
    description: Download the current io_topics.yml and update subscriptions.
    fields:
      COMMAND: {type: string, max_bytes: 16, enum: [SchemaUpdate]}
  log_sync:
    type: object
    qos: 1
    description: Send stored logs through the log Output.
    fields:
      COMMAND: {type: string, max_bytes: 16, enum: [LogSync]}
  reset:
    type: object
    qos: 1
    description: Restart the device or program.
    fields:
      COMMAND: {type: string, max_bytes: 16, enum: [Reset]}

output:
  state:
    type: object
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
  update: {}
  env_update: {}
  schema_update: {}
  log_sync: {}
  reset: {}
output:
  state: {}
  log: {}
```

- Ранее эти UnitIO не создавались как сущности UnitIO, теперь будут.

## Преобразование размерностей

- Работает только между UnitIO имеющих одинаковые физические величины
- миллионы секунд в тысячи секунд например

## Преобразование типов и совместимость

Общие правила:
- Совместимость проверяется в направлении Output → Input.
- После преобразования сообщение должно соответствовать схеме Input,
  включая диапазоны, обязательные поля и ограничения размера.
- Несовместимое сообщение отклоняется с сохранением ошибки у UnitIO.

| Output ↓ / Input → | bool | int | float | string | object | array | any | bytes |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **bool** | 🟩 | 🟩 | 🟩 | 🟥 | 🟥 | 🟥 | 🟩 | 🟥 |
| **int** | 🟩 | 🟩 | 🟩 | 🟩 | 🟥 | 🟥 | 🟩 | 🟥 |
| **float** | 🟩 | 🟩 | 🟩 | 🟩 | 🟥 | 🟥 | 🟩 | 🟥 |
| **string** | 🟥 | 🟥 | 🟥 | 🟩 | 🟥 | 🟥 | 🟩 | 🟥 |
| **object** | 🟥 | 🟥 | 🟥 | 🟥 | 🟨 | 🟥 | 🟩 | 🟥 |
| **array** | 🟥 | 🟥 | 🟥 | 🟥 | 🟥 | 🟨 | 🟩 | 🟥 |
| **any** | 🟨 | 🟨 | 🟨 | 🟨 | 🟨 | 🟨 | 🟩 | 🟥 |
| **bytes** | 🟥 | 🟥 | 🟥 | 🟥 | 🟥 | 🟥 | 🟥 | 🟩 |

Нюансы:
- 🟩 разрешает преобразование типов, но не отменяет ограничения Input: диапазон, enum, format, размер и прочие условия проверяются после преобразования.
- Числа ↔ bool: false → 0, true → 1; ноль → false, любое ненулевое число → true. Без предварительного округления: 0.1 → true.
- float → int: ближайшее целое; половины округляются от нуля: 1.5 → 2, -1.5 → -2. Переполнение, NaN и бесконечности отклоняются.
- Числа → string: десятичное представление без разделителей тысяч, дробный разделитель — точка. Обратного преобразования нет.
- object → object: поля сопоставляются по имени и проверяются рекурсивно по этой таблице. extra: true у Input разрешает дополнительные ключи, но не отменяет обязательные поля и проверку описанных.
- array → array: совместимость определяется схемами элементов и ограничениями длины. Элементы преобразуются рекурсивно; ошибка одного отклоняет всё сообщение.
- any → конкретный тип: связь разрешена, решение принимается для каждого сообщения по фактическому типу значения и этой таблице. Например, число из any можно передать в int, объект — нельзя.
- any содержит JSON-значения, включая null, но не сырые bytes. Передача null в конкретный тип требует nullable: true.
- Единицы и диапазоны: при числовом преобразовании сначала переводятся единицы одной физической величины, затем тип. Для гарантированной совместимости весь преобразованный диапазон Output должен помещаться в Input.

## Возможности схем

1. Генерация README.md (аналог уже существующей ручки)
1. Часть типизирования datapipe, возможно предлагать параметры частично (отдельная ручка)
  - схема валидирует заполеннеие datapipe.yml
  - по типам данных
  - по лимитам для чисел
  - например у type array не может быть агрегации и типа number 
  - в клиенте есть ide для заполнения yml
1. Анализатор совместимости io (отдельная ручка)
  - совместимость типов прописана выше
  - должны строго совпадать диапазоны если прописаны (если диапазон входит то окей, если не входит то уже извините)
1. Валидация про вводе значений в input (отдельная ручка)
1. Подсказки при обновлении Unit (отдельная ручка)
  - сравниваются две схемы, из прошлой версии и целевой, показывается где может сломаться, например изменнеие типа
  - предупреждает но не запрещает
  - только при ручных обновлениях, в авто обновлениях предупреждать будет негде
