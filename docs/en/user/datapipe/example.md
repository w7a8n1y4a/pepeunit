# DataPipe examples

## LastValue

For example, we only need to show the very last value in the [UnitNode](/en/definitions#unitnode) interface:

We can use a configuration with a permanent active period that does not allow updates more often than once every `5` seconds, without uniqueness checks, with a maximum text length of `100`. The storage policy is `LastValue`:

::::tip
Thanks to the `LastValue` policy, this configuration almost does not consume `CPU` or `RAM`, because only `1` record is stored at any given time.
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
::::

## NRecords

For example, we need to see some event-like states: damper opening or switching something on. To do this, we need to store N records and, as soon as their number becomes greater than a defined value, overwrite the oldest ones:

We can use a configuration that starts working from a certain moment and has no time limit, with a text data type. We will restrict possible values using a `WhiteList`, store all values, but ignore consecutive duplicates. `512` records is more than enough.

::::tip
Thanks to deduplication and the `WhiteList`, this configuration almost does not consume `CPU` or `RAM`. Also, this policy itself does not allow you to create more than `~= 512` records.
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
::::

## TimeWindow

For example, we want to evaluate the humidity dynamics in a room over `1` week, using a window of `1` day:

We will set the date until which we plan to measure. Then we will define the possible humidity range from `0` to `100 %`. We will use a resolution of `1` minute, but consider all values. We will round to `2` significant digits and use a window size of `86400` seconds.

::::tip
Thanks to the `max_rate` resolution, this configuration almost does not consume `CPU` or `RAM`. The number of records for this policy will be constant at about `1440`.
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
::::

## Aggregation

For example, we need to accumulate statistics from a `ds18b20` temperature sensor. We do not want to use a lot of memory, but we need data for a very long period with a resolution of `15` minutes:

We can use a configuration with a defined active period, filtering out invalid values, restricting valid ranges, checking all values and deduplicating them. We will limit to `2` significant digits, since the sensor accuracy is `12 bits`. We will set the period to `900` seconds and use the average as the aggregation function.

::::tip
Thanks to applying aggregation, this configuration almost does not consume `CPU` or `RAM`. This `DataPipe` will create `96` records per day in the database.
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
::::


