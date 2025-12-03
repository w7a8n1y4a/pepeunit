# Примеры DataPipe

## LastValue

Например нам нужно отображать только самое последнее значение в [UnitNode](/definitions#unitnode) интерфейсе:

Подойдёт конфигурация с постоянным временем действия, которая бы не позволяла обновляться чаще чем `1` раз в `5` секунд, без проверки на уникальность, с максимальной длинной текста `100`. Политика cохранения `LastValue`:

:::tip
Данная конфигурация почти не потребляет `CPU` и `RAM`. За счёт политики `LastValue`. Ведь постоянно хранится только `1` запись.
```yml
active_period:
  type: Permanent
filters:
  type_input_value: Text
  max_rate: 5
  last_unique_check: false
  max_size: 100
processing_policy:
  policy_type: LastValue
```
:::

## NRecords

Например нам нужно увидеть некоторые ивентовые события, открытие заслонки или включение чего-либо. Для этого нужно хранить N записей, и как только их становится больше определённого числа, затирать старые:

Подойдёт конфигурация которая начнёт действовать в определённый момент и без лимита. С текстовым типом данных. Ограничим возможные значения через `WhiteList`, будем сохранять все значения, но одинаковые подряд будем игнорировать. `512` записей вполне подойдёт.

:::tip
Данная конфигурация почти не потребляет `CPU` и `RAM`. За счёт дедупликации и `WhiteList`. Так же сама политика не позволяет создать больше `~= 512` записей.
```yml
active_period:
  type: FromDate
  start: '2023-11-15T00:00:00+00:00'
filters:
  type_input_value: Text
  type_value_filtering: WhiteList
  filtering_values:
  - Alarm
  - Error
  - Warning
  max_rate: 0
  last_unique_check: true
  max_size: 100
processing_policy:
  policy_type: NRecords
  n_records_count: 512
```
:::

## TimeWindow

Например мы хотим в течении `1` недели оценивать динамику влажности в комнате с окном в `1` день:

Мы установим до какой даты мы будем проводить замеры. Определим ограничение возможного значения влажности от `0` до `100 %`. Ограничимся разрешением в `1` минуту, но будем учитывать все значения. Округлим до значащих `2` цифр. И будем наблюдать за окном в `86400` секунд.

:::tip
Данная конфигурация почти не потребляет `CPU` и `RAM`, за счёт разрешения `max_rate`. Число записей для данной политики будет постоянным `~= 1440`.
```yml
active_period:
  type: ToDate
  end: '2025-11-15T00:00:00+00:00'
filters:
  type_input_value: Number
  type_value_threshold: Range
  threshold_min: 0
  threshold_max: 100
  max_rate: 60
  last_unique_check: false
  max_size: 50
transformations:
  round_decimal_point: 2
processing_policy:
  policy_type: TimeWindow
  time_window_size: 86400
```
:::

## Aggregation

Например нам нужно накапливать статистику с датчика температуры `ds18b20`, мы не хотим тратить большой обьём памяти, но нам нужны данные за очень длительный период c разрешением `15` минут:

Подойдёт конфигурация с заданным периодом действия, ограничением ошибочных значений, ограничением реальных значений, проверкой всех значений, дедупликацией. Ограничим до `2` значащих цифр, ведь точность датчика `12 бит`. Выставим период `900` секунд, а функцию расчёта как среднее.

:::tip
Данная конфигурация почти не потребяет `CPU` и `RAM`, за счёт применения агрегации. Данный `DataPipe` будет создвать `96` записей в бд в день.
```yml
active_period:
  type: DateRange
  start: '2023-11-15T00:00:00+00:00'
  end: '2200-11-15T00:00:00+00:00'
filters:
  type_input_value: Number
  type_value_filtering: BlackList
  filtering_values:
  - -127.00
  - 85.00
  type_value_threshold: Range
  threshold_min: -50
  threshold_max: 120
  max_rate: 0
  last_unique_check: true
  max_size: 100
transformations:
  round_decimal_point: 2
processing_policy:
  policy_type: Aggregation
  time_window_size: 900
  aggregation_functions: Avg
```
:::