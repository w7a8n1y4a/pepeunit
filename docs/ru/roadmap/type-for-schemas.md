# Простые схемы Unit

Проект нового формата. Автор пишет короткий YAML; Backend проверяет его и строит валидаторы. Поддержку формата ещё нужно реализовать.

| Файл | Кто создаёт | Что внутри |
| -- | -- | -- |
| `serach.yml` | Автор Unit | Назначение, платформы, оборудование, алгоритм |
| `unit_schema.yml` | Автор Unit | Настройки и типы Input/Output |
| `.env` | Backend | Значения настроек конкретного Unit |
| `io_topics.yml` | Backend | Топики конкретного Unit |

На устройстве нужны только `.env` и `io_topics.yml`. `.env.example` не нужен.

## unit_schema.yml

Пример нового контракта регулятора вентилятора, а не готовая конфигурация существующей прошивки.

```yaml
version: 1

env:
  FAN_PIN:
    type: int
    min: 0
    description: GPIO управления вентилятором.
  TARGET_TEMP:
    type: number
    min: 0
    max: 80
    unit: Cel
    default: 30
    description: Температура включения вентилятора.
  WIFI_PASSWORD:
    type: string
    secret: true
    description: Пароль Wi-Fi сети.

input:
  reset:
    type: object
    fields: {}
    role: command
    description: Перезапускает Unit при получении пустого объекта.

  set_speed:
    type: object
    role: command
    description: Задаёт мощность вентилятора на указанное время.
    fields:
      speed: {type: int, min: 0, max: 100, unit: '%'}
      duration: {type: int, min: 1, max: 3600, unit: s}

output:
  temperature:
    type: number
    min: -55
    max: 125
    unit: Cel
    role: measurement
    description: Температура с датчика.

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
- `default` используется Backend при генерации `.env`. В сообщения значения автоматически не подставляются.
- Кодирование по умолчанию — JSON. Для обычного текста нужен `codec: utf8`, для `type: bytes` кодирование всегда бинарное.
- Предел сообщения по умолчанию — 4096 байт. `max_bytes` на IO меняет его; ограничение проверяется до декодирования.
- `role` и `description` обязательны у IO. У полей объекта и ENV они не требуются; описание рекомендуется.
- ENV содержит скалярные значения: `bool`, `int`, `number`, `string`, с возможностью `nullable`. Стандартные `PU_*` добавляет Backend.
- Неизвестные ключи, дубли YAML-ключей, неверные типы и неподдерживаемые сочетания отклоняются при регистрации.

`version: 1` выбирает **единую неизменяемую редакцию формата, метасхемы и словаря**. Отдельных `profile` и `dictionary_version` нет. Обновление правил требует новой версии; существующие контракты продолжают использовать свою.

## serach.yml

```yaml
version: 1
name: garage-fan
summary: Включает вентиляцию по температуре и принимает ручные команды.
tags: [garage, ventilation, temperature]
platforms: [esp32]
hardware:
  - Датчик температуры DS18B20.
  - Вентилятор с подходящим PWM-драйвером.
behavior:
  automatic: >
    При температуре выше TARGET_TEMP устанавливает мощность 100%,
    иначе 0%. Мощность означает заполнение PWM.
  manual: >
    set_speed задаёт мощность на duration секунд.
    Новая команда заменяет предыдущую и запускает срок заново.
    После истечения срока возвращается автоматический режим.
  reporting: Публикует температуру и заданную мощность раз в секунду.
  limitations: Не измеряет обороты и не подтверждает физическое вращение.
```

Реестр хранит оба файла из одной версии репозитория. MCP может выдавать отдельно описание поведения, настройки или конкретный IO — читать весь README не требуется.

## .env

Генерируется Backend. Секреты в примере условные, стандартные переменные показаны частично.

```dotenv
FAN_PIN=4
TARGET_TEMP=30
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

Генерируется Backend. Состав IO соответствует `unit_schema.yml`.

```yaml
version: 1
schema_revision: 7
config_revision: 12
input:
  reset: domain.com/9d0c2f4d-108e-488a-85e5-6040ef3d8425
  set_speed: domain.com/2d98b4ba-c935-4379-8e1a-520e76018c17
output:
  temperature: domain.com/7279d28d-53b6-4866-99da-0b81bc1cc025
  speed: domain.com/d76b4234-3997-4a4a-a113-6d1c21d6b84a
```

`schema_revision` — редакция итогового контракта Unit; `config_revision` — редакция комплекта `.env` и `io_topics.yml`. При изменении влияющих на IO настроек Backend перепроверяет связи.

MessageProcessor подписывается на `domain.com/+`: Input и Output попадают в одну подписку. DataPipe работает на обоих направлениях. Связи Output → Input хранятся на сервере; полученный Input повторно не маршрутизируется. Unit публикует собственные Output и подписывается на собственные Input.

## Другие типы данных

Фрагменты независимых `unit_schema.yml` версии 1.

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

Автор Unit этот файл не пишет. Пример `dictionary.yml` описывает допустимые значения формата, без перечня устройств и их назначений.

```yaml
version: 1

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

defaults:
  codec: json
  max_bytes: 4096
  optional: false
  nullable: false
  extra: false
  routing: broadcast
```

Коды единиц — поддерживаемый набор UCUM. У `bytes` всегда бинарное кодирование; `any` означает любое JSON-значение, не произвольные байты. У `any` допустим `null` независимо от `nullable`.

## Что проверяет метасхема

Полная машинная метасхема хранится в Pepeunit. Автору достаточно этих правил; это новый формат Pepeunit, а не JSON Schema в YAML.

| Поля | Где разрешены | Правило |
| -- | -- | -- |
| `type` | Любое значение | Обязателен, выбирается из словаря |
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
| `default`, `secret` | ENV | Значение проходит проверку; секрет скрывается в диагностике |
| `description` | Любое значение | Текст, обязателен у IO |
| `role`, `codec`, `max_bytes` | Корень IO | Роль обязательна; положительный предел байт |
| `routing` | Output | Обычная рассылка либо выбор связи; второй режим требует оболочки пульта |

Объект задаёт ровно одно из `fields` или `variants`. `bytes` допустим только в корне IO; `utf8` — только для `string`. Общие ограничения ресурсов валидатора задаёт Backend. Допустимые GPIO, межполевые условия ENV, форматы бинарных пакетов и подтверждение исполнения требуют отдельных правил; типы сами их не проверяют.

## Проверка связи через MCP

Агент ищет Unit и предлагает связи. Backend проверяет роли, кодирование, типы, диапазоны, единицы и ограничения размера. Ответ содержит версии контрактов и результат: **совместимо по данным**, **нужно преобразование**, **проверка при доставке**, **несовместимо** или **недостаточно данных**.

Одинаковые типы не доказывают одинаковое назначение: процент влажности и процент мощности — разные вещи. Описание помогает агенту выбрать связь, но не является формальным доказательством. Пока назначение не подтверждено, нельзя обещать автоматическую совместимость всей системы. Проверка сообщений также не подтверждает физическое исполнение команды.
