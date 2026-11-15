# Простые схемы Unit

Проект нового формата. Автор пишет короткий YAML; Backend проверяет его и строит валидаторы. Поддержку формата ещё нужно реализовать.

| Файл | Кто создаёт | Что внутри |
| -- | -- | -- |
| `unit.yml` | Автор Unit | Описание и тип Unit, настройки и типы Input/Output |
| `.env` | Backend | Значения настроек конкретного Unit |
| `io_topics.yml` | Backend | Топики конкретного Unit |

В корне репозитория Unit хранится один авторский файл схем — `unit.yml`. Общее обязательное поле `version` находится в начале файла на одном уровне с четырьмя обязательными разделами: `search`, `env`, `input`, `output`. Неиспользуемые `env`, `input` или `output` задаются пустым словарём `{}`.

Pepeunit читает `unit.yml` и генерирует `.env` для конкретного физического Unit с учётом выбранных настроек. Unit запускается с этим `.env`, затем сам скачивает из Pepeunit свой `io_topics.yml`, используя параметры подключения и авторизации из `.env`. После получения топиков Unit подписывается на свои Input и публикует свои Output.

На устройстве нужны только `.env` и `io_topics.yml`. `.env.example` не нужен.

## unit.yml

Пример нового контракта исполнительного Unit (`actor`), управляющего вентилятором по входящим командам. Это не готовая конфигурация существующей прошивки.

```yaml
version: 1

search:
  type: actor
  execution_type: compiled
  name: garage-fan
  summary: Управляет вентилятором по входящим командам.
  tags: [garage, ventilation]
  platforms: [esp32]
  hardware:
    - Вентилятор с подходящим PWM-драйвером.
  behavior:
    manual: >
      set_speed задаёт мощность на duration секунд.
      Новая команда заменяет предыдущую и запускает срок заново.
      После истечения срока мощность устанавливается в 0%.
      Мощность означает заполнение PWM.
    reporting: Публикует заданную мощность раз в секунду.
    limitations: Не измеряет обороты и не подтверждает физическое вращение.

env:
  FAN_PIN:
    type: int
    min: 0
    example: 4
    description: GPIO управления вентилятором.
  WIFI_PASSWORD:
    type: string
    secret: true
    example: "example-password"
    description: Пароль Wi-Fi сети.

input:
  reset: {base: reset}

  set_speed:
    type: object
    role: command
    description: Задаёт мощность вентилятора на указанное время.
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
    description: Заданная мощность вентилятора, не измеренные обороты.
```

Пример сообщения для `set_speed`:

```json
{"speed": 50, "duration": 60}
```

## Правила короткой записи

- Все перечисленные поля обязательны. `optional: true` разрешает отсутствие, `nullable: true` — значение `null`.
- В объекте разрешены только перечисленные `fields`. `extra: true` разрешает дополнительные поля с произвольными JSON-значениями.
- `default` внутри схемы ENV используется Backend при генерации `.env`. В сообщения значения автоматически не подставляются.
- Кодирование по умолчанию — JSON. Для обычного текста нужен `codec: utf8`, для `type: bytes` кодирование всегда бинарное.
- Предел сообщения по умолчанию — 4096 байт. `max_bytes` на IO меняет его; ограничение проверяется до декодирования.
- `role` и `description` обязательны в итоговой схеме IO; при использовании `base` они берутся из словаря. У полей объекта и ENV они не требуются; описание рекомендуется.
- Каждая переменная в `env` требует `example`, в том числе при `optional: true` или наличии `default`. Пример должен соответствовать типу и всем ограничениям переменной; `example: null` допустим только при `nullable: true`. Отсутствующий или невалидный пример отклоняется при регистрации. `example` служит подсказкой при настройке и не подставляется в `.env` вместо значения или `default`. Для `secret: true` указывается вымышленное значение.
- ENV содержит скалярные значения: `bool`, `int`, `number`, `string`, с возможностью `nullable`. Стандартные `PU_*` добавляет Backend.
- Неизвестные ключи, дубли YAML-ключей, неверные типы и неподдерживаемые сочетания отклоняются при регистрации.

`version: 1` выбирает **единую неизменяемую редакцию формата, метасхемы и словаря**. Отдельных `profile` и `dictionary_version` нет. Обновление правил требует новой версии; существующие контракты продолжают использовать свою.

## search и тип Unit

`search` содержит метаданные для поиска: имя, краткое описание, теги, платформы, оборудование и поведение. Обязательное поле `search.type` задаёт тип Unit.

| Тип | Назначение | Пример |
| -- | -- | -- |
| `sensor` | Только считывает информацию и публикует её; не управляет физическими устройствами | Датчик температуры |
| `actor` | Выполняет действия в реальном мире | Вентилятор, реле, привод |
| `controller` | Получает информацию от `sensor`, принимает решения и отправляет команды `actor` | Регулятор, включающий вентилятор по температуре |
| `observer` | Анализирует или накапливает информацию от сенсоров, не управляя `actor` | Сборщик истории измерений |
| `gateway` | Передаёт данные и команды между Pepeunit и устройствами с внешним протоколом | Шлюз ZigBee, LoRa или Meshtastic |

Unit имеет ровно один из этих пяти типов. `search.type` — строка, а не список; отсутствие типа, неизвестное значение или несколько типов отклоняются при регистрации. Тип описывает назначение Unit, а `role` — назначение отдельного Input или Output. Например, `actor` может публиковать своё состояние, оставаясь `actor`.

Пример разделения системы вентиляции: `sensor` публикует температуру, `controller` принимает её и отправляет команду `actor`, а `observer` получает показания для хранения истории. Тип Unit не заменяет проверку совместимости конкретных IO.

Для `gateway` схема описывает только собственные ENV и Input/Output шлюза на стороне Pepeunit. Устройства за шлюзом и их протоколы в этой схеме не описываются. Разработчики `controller` Unit, работающих через шлюз, отвечают за учёт протокола этих устройств, формирование команд и интерпретацию ответов. Проверка IO шлюза не подтверждает корректность взаимодействия с устройствами за ним.

Обязательное поле `search.execution_type` задаёт способ исполнения программы Unit:

| Значение | Способ исполнения |
| -- | -- |
| `interpreted` | Интерпретируемый: Unit запускает программу через интерпретатор |
| `compiled` | Компилируемый: Unit запускает заранее собранную программу или прошивку |

Указывается ровно одно значение из `execution_types`. Отсутствующее поле, неизвестное значение или список отклоняются при регистрации. Значение выбирается по способу исполнения конкретной поставки Unit; Backend использует его для выбора сценария обновления.

Реестр хранит `unit.yml` из выбранной версии репозитория. MCP может выдавать отдельно описание поведения, настройки или конкретный IO — читать весь README не требуется.

## .env

Генерируется Backend. Секреты в примере условные, стандартные переменные показаны частично.

```dotenv
FAN_PIN=4
WIFI_PASSWORD="example-password"
PU_DOMAIN="domain.com"
PU_MQTT_HOST="emqx.domain.com"
PU_MQTT_PORT=1883
PU_AUTH_TOKEN="example-token"
PU_SCHEMA_REVISION=7
PU_CONFIG_REVISION=12
```

Строки используют JSON-кавычки и экранирование. Числа, boolean и `null` записываются без кавычек. Подстановок и выполнения команд нет.

## io_topics.yml

Генерируется Backend для конкретного Unit; Unit сам скачивает этот файл после запуска. Состав IO соответствует разделам `input` и `output` в `unit.yml`.

```yaml
version: 1
schema_revision: 7
config_revision: 12
input:
  reset: domain.com/9d0c2f4d-108e-488a-85e5-6040ef3d8425
  set_speed: domain.com/2d98b4ba-c935-4379-8e1a-520e76018c17
output:
  state: domain.com/7279d28d-53b6-4866-99da-0b81bc1cc025
  speed: domain.com/d76b4234-3997-4a4a-a113-6d1c21d6b84a
```

`schema_revision` — редакция итогового контракта Unit; `config_revision` — редакция комплекта `.env` и `io_topics.yml`. При изменении влияющих на IO настроек Backend перепроверяет связи.

MessageProcessor подписывается на `domain.com/+`: Input и Output попадают в одну подписку. DataPipe работает на обоих направлениях. Связи Output → Input хранятся на сервере; полученный Input повторно не маршрутизируется. Unit публикует собственные Output и подписывается на собственные Input.

Ограничение частоты сообщений применяется на уровне MQTT-брокера. Допустимое число сообщений берётся напрямую из БД Pepeunit для конкретного Unit. Это серверная настройка; она не входит в `unit.yml`, словарь схем или генерируемые `.env` и `io_topics.yml`.

## Другие типы данных

Фрагменты независимых `unit.yml` версии 1.

### Произвольный JSON и объект с произвольной частью

```yaml
output:
  anything:
    type: any
    role: event
    description: Любое JSON-значение, включая null.

  event:
    type: object
    role: event
    description: Событие с произвольным содержимым.
    fields:
      kind: {type: string, enum: [measurement, alert]}
      data: {type: any}
      note: {type: string, optional: true}
```

### Массив, текст и байты

```yaml
output:
  readings:
    type: array
    items: {type: number, min: -55, max: 125, unit: Cel}
    max_items: 16
    role: measurement
    description: Массив показаний температуры.

  button:
    type: string
    codec: utf8
    enum: [Left, Right, One, Double, Long]
    role: event
    description: Действие пользователя; текст без JSON-кавычек.

  packet:
    type: bytes
    max_bytes: 220
    role: event
    description: Непрозрачный радиопакет.
```

### Команда с вариантами

`variants` — сокращение для объекта с обязательным полем `action`. Значение `action` выбирает единственный вариант и его обязательные поля. Другие поля запрещены.

```yaml
input:
  relay:
    type: object
    role: command
    description: Установить состояние или включить на время.
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
    nullable: true
    default: null
    example: "click"
    description: null отключает отправку, пустая строка отправляет пустой payload.
```

### Универсальный пульт

```yaml
output:
  send_command:
    type: object
    role: command
    routing: selected-link
    description: Отправить JSON в Input выбранной связи.
    fields:
      link_id: {type: string, format: uuid}
      data: {type: any}
```

Пульт публикует в собственный Output. MessageProcessor проверяет UUID, права и принадлежность связи этому Output, затем проверяет `data` по схеме выбранного Input. Получателю передаётся только `data`.

## Словарь платформы

Автор Unit этот файл не пишет. Пример `dictionary.yml` описывает допустимые значения формата и базовые служебные Input/Output. Их схемы и поведение едины для платформы.

```yaml
version: 1

unit_types: [sensor, actor, controller, observer, gateway]
execution_types: [interpreted, compiled]
types: [bool, int, number, string, object, array, any, bytes]
codecs: [json, utf8, bytes]
roles: [measurement, state, event, command]
platforms: [esp8266, esp32, linux, windows, macos]
formats: [uuid]
routing: [broadcast, selected-link]

units:
  Cel: Градус Цельсия
  '%': Процент
  s: Секунда
  ms: Миллисекунда
  Hz: Герц

input:
  update:
    type: object
    role: command
    description: Обновить программу Unit до указанной версии.
    fields:
      COMMAND: {type: string, enum: [Update]}
      PU_COMMIT_VERSION: {type: string}
      COMPILED_FIRMWARE_LINK: {type: string, optional: true}
  env_update:
    type: object
    role: command
    description: Скачать и применить актуальный .env.
    fields:
      COMMAND: {type: string, enum: [EnvUpdate]}
  schema_update:
    type: object
    role: command
    description: Скачать актуальный io_topics.yml и обновить подписки.
    fields:
      COMMAND: {type: string, enum: [SchemaUpdate]}
  log_sync:
    type: object
    role: command
    description: Отправить накопленные логи через Output log.
    fields:
      COMMAND: {type: string, enum: [LogSync]}
  reset:
    type: object
    role: command
    description: Перезапустить устройство или программу.
    fields:
      COMMAND: {type: string, enum: [Reset]}

output:
  state:
    type: object
    role: state
    description: Сообщить версию программы и состояние системы.
    fields:
      pu_commit_version: {type: string}
      millis: {type: number, min: 0, unit: ms, optional: true}
      mem_free: {type: number, min: 0, optional: true}
      mem_alloc: {type: number, min: 0, optional: true}
      freq: {type: number, min: 0, unit: Hz, optional: true}
      ifconfig:
        type: array
        items: {type: string}
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
    description: Передать пакет записей журнала.
    min_items: 1
    items:
      type: object
      fields:
        level: {type: string, enum: [Debug, Info, Warning, Error, Critical]}
        text: {type: string}
        create_datetime: {type: string, optional: true}

defaults:
  codec: json
  max_bytes: 4096
  optional: false
  nullable: false
  extra: false
  routing: broadcast
```

Коды единиц — поддерживаемый набор UCUM. У `bytes` всегда бинарное кодирование; `any` означает любое JSON-значение, не произвольные байты. У `any` допустим `null` независимо от `nullable`.

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

- `base` выбирает запись из одноимённого раздела словаря версии `version`. Backend разворачивает её в полную схему до валидации и генерации топиков. Соседние ключи у `base` запрещены: стандартный контракт нельзя переопределить.
- Имена базовых IO зарезервированы в соответствующем направлении. Имя IO должно совпадать со значением `base`; неизвестная ссылка или ссылка из другого направления отклоняется. Остальные IO автор описывает полной схемой, как `set_speed` в примере выше.
- Автоматически базовые IO не добавляются. Объявление означает, что прошивка реализует соответствующее поведение; Backend отправляет только объявленные команды. `log_sync` требует Output `log`, а `update` — Output `state` для подтверждения версии.
- Базовые IO доступны всем пяти типам Unit. Обслуживание самого Unit, включая перезапуск `sensor`, не меняет его тип.
- В `io_topics.yml` базовые и авторские IO находятся в общих `input` и `output` и получают адреса `domain.com/<uuid>`. Дополнительные разделы и постфикс `/pepeunit` не нужны. Backend сохраняет признак базового IO: служебные команды, состояние и логи доступны самому Unit и авторизованному управлению Pepeunit, не участвуют в пользовательских связях Output → Input.

Для базового `reset` сообщение — `{"COMMAND":"Reset"}`. Команды сохраняют существующие имена и поля протокола; `env_update` теперь обновляет `.env`, а `schema_update` — `io_topics.yml`. При `search.execution_type: compiled` обработчик `update` дополнительно требует `COMPILED_FIRMWARE_LINK`; при `interpreted` ссылка не обязательна. Это условие проверяется отдельно от схемы сообщения с учётом метаданных Unit.

`state` содержит обязательный `pu_commit_version`; остальные поля необязательны. `mem_free` и `mem_alloc` измеряются в байтах, `ifconfig` содержит IP, маску, шлюз и DNS, `statvfs` — десять значений состояния файловой системы из текущего протокола. `millis` сохраняет его семантику: миллисекунды с запуска либо Unix-время в миллисекундах. Неизвестные поля отклоняются по общему правилу нового формата.

В новом контракте `log` всегда передаёт непустой массив, даже для одной записи. Это упрощает схему: прежний вариант с одиночным объектом требует адаптации. `create_datetime` — строка времени в ISO 8601; при отсутствии используется время приёма Backend. Проверка формата времени выполняется обработчиком. Пакеты логов нужно делить так, чтобы каждый укладывался в `max_bytes`.

## Что проверяет метасхема

Полная машинная метасхема хранится в Pepeunit. Автору достаточно этих правил; это новый формат Pepeunit, а не JSON Schema в YAML.

| Поля | Где разрешены | Правило |
| -- | -- | -- |
| `version` | Корень `unit.yml` | Обязательная поддерживаемая версия всего формата |
| `type` | `search` | Обязательная строка: одно значение из `unit_types` |
| `execution_type` | `search` | Обязательная строка: одно значение из `execution_types` |
| `base` | Корень IO | Ссылка на базовый IO того же направления; без соседних ключей |
| `type` | Схема значения ENV или IO | Обязателен после раскрытия `base`, выбирается из `types` |
| `min`, `max` | `int`, `number` | Включительные границы; `min <= max` |
| `enum` | Скаляр | Непустой список разных значений указанного типа |
| `format` | `string` | Значение из словаря; UUID проверяется явно |
| `unit` | `int`, `number` | Значение из словаря |
| `fields` | `object` | Словарь полей, в том числе пустой |
| `variants` | `object` | Непустой словарь вариантов вместо `fields`; имя `action` зарезервировано |
| `extra` | Объект с `fields` | Разрешает дополнительные поля |
| `items` | `array` | Обязательная схема элемента |
| `min_items`, `max_items` | `array` | Неотрицательные целые границы длины |
| `optional` | Поле объекта или ENV | Разрешает отсутствие поля |
| `nullable` | Любой JSON-тип | Дополнительно разрешает `null` |
| `example` | ENV | Обязателен; значение проходит проверку по схеме переменной, автоматически не подставляется |
| `default`, `secret` | ENV | Значение проходит проверку; секрет скрывается в диагностике |
| `description` | Любое значение | Текст, обязателен у IO |
| `role`, `codec`, `max_bytes` | Корень IO | Роль обязательна; положительный предел байт |
| `routing` | Output | Обычная рассылка либо выбор связи; второй режим требует оболочки пульта |

Объект задаёт ровно одно из `fields` или `variants`. `bytes` допустим только в корне IO; `utf8` — только для `string`. Общие ограничения ресурсов валидатора задаёт Backend. Допустимые GPIO, межполевые условия ENV, форматы бинарных пакетов и подтверждение исполнения требуют отдельных правил; типы сами их не проверяют.

## Проверка связи через MCP

Агент ищет Unit и предлагает связи. Backend проверяет роли, кодирование, типы, диапазоны, единицы и ограничения размера. Ответ содержит версии контрактов и результат: **совместимо по данным**, **нужно преобразование**, **проверка при доставке**, **несовместимо** или **недостаточно данных**.

Одинаковые типы не доказывают одинаковое назначение: процент влажности и процент мощности — разные вещи. Описание помогает агенту выбрать связь, но не является формальным доказательством. Пока назначение не подтверждено, нельзя обещать автоматическую совместимость всей системы. Проверка сообщений также не подтверждает физическое исполнение команды.
