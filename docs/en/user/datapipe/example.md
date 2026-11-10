# DataPipe examples

## LastValue

For example, we need to show only the most recent value on a `UnitIO`:

A configuration with a permanent active period will do. It does not allow updates more often than once every `5` seconds, has no uniqueness check, and sets the maximum text length to `100`. The storage policy is `LastValue`.

:::tip
Thanks to the `LastValue` policy, this configuration consumes almost no `CPU` and `RAM`, since only `1` record is stored all the time.
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

For example, we need to see some event-type occurrences: a gate opening or something being switched on. For this we need to keep N records and, as soon as there are more than a certain number, overwrite the old ones:

A configuration that starts working at a certain moment with no end limit, with the text data type, will do. We restrict the possible values through `WhiteList`, save all values, but ignore identical values in a row. `512` records are quite enough.

:::tip
Thanks to deduplication and `WhiteList`, this configuration consumes almost no `CPU` and `RAM`. Also, the policy itself does not allow more than `~= 512` records to be created.
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

For example, we want to track the dynamics of humidity in a room until a certain date, with a window of `1` day:

We set the date until which we take measurements. We define the limit of the possible humidity value from `0` to `100 %`. We limit the resolution to `1` minute, but take all values into account. We round to `2` significant digits. And we watch a window of `86400` seconds.

:::tip
Thanks to the `max_rate` limit, this configuration consumes almost no `CPU` and `RAM`. The number of records for this policy is constant, `~= 1440`.
```yml
active_period:
  type: ToDate
  end: '2030-11-15T00:00:00+00:00'
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

For example, we need to accumulate statistics from a `ds18b20` temperature sensor. We do not want to spend a large amount of memory, but we need data over a very long period with a resolution of `15` minutes:

A configuration with a set active period, a filter for erroneous values, a limit for real values, a check of all values, and deduplication will do. We limit it to `2` significant digits, since the sensor accuracy is `12 bit`. We set the period to `900` seconds and the calculation function to average.

:::tip
Thanks to aggregation, this configuration consumes almost no `CPU` and `RAM`. This `DataPipe` will create `96` records in the database per day.
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

## Alerts

For example, the temperature is already accumulated by the `LastValue` policy, and we need a notification when, after the transformations, the value is outside `18`–`26` three times in a row:

The notification goes to the creator of the `UnitIO`. While the temperature stays outside the range, the next one comes no more often than once a minute. A value inside the range resets the counter.

:::tip
The `alerts` block looks at the value that has passed `filters` and `transformations`. The pipeline itself keeps accumulating data meanwhile.
```yml
active_period:
  type: Permanent
filters:
  type_input_value: Number
  max_rate: 0
  last_unique_check: false
  max_size: 50
processing_policy:
  policy_type: LastValue
alerts:
  is_enabled: true
  type_value_threshold: Range
  threshold_min: 18
  threshold_max: 26
  consecutive_count: 3
  max_frequency: 60
```
:::