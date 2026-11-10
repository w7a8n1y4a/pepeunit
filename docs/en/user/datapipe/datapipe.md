# DataPipe

[DataPipe](/deployment/dependencies/datapipe) is a pipeline that takes the values of a `UnitIO` topic, filters and transforms them, and stores them under the chosen policy. Every `UnitIO` has its own pipeline, and it is described by a YAML config.

The way to it: `Units` → `Unit` → `Inputs and outputs` → the `UnitIO` you need → `DataPipe`. The creator of the `UnitIO` gets the cell if DataPipe is enabled on the instance (`pu_ff_datapipe_enable`) and the topic ends with `/pepeunit`.

## Enabling

1. Turn on the `DataPipe` cell: while it is `off`, the other cells do not work
1. `Editor`: an empty config starts with the `LastValue` template. Set the one you need and press `Save`
1. `Upload data`, `Download data` and `Delete all data` work with the accumulated records, see [Data import](/user/datapipe/import)

If the instance setting `pu_datapipe_default_last_value_enable` is on, such `UnitIO` are created with the `LastValue` policy right away.

## Editor

Button | What it does
-- | --
`Save` | Validates and saves the config. Unavailable while the text has errors
`Check` | Checks the syntax and the rules without saving anything
`Upload` | Loads the config from a `YML` file into the editor
`Download` | Saves the editor text to a `YML` file
`LastValue`, `NRecords`, `TimeWindow`, `Aggregation`, `Alerts` | Copy a ready-made [example](/user/datapipe/example) to the clipboard, the editor text does not change

The text is checked as you type: the `YML` syntax right away, the pipeline rules by the server. Errors are shown under the editor.

## Parameter reference

Required pipeline stages: `active_period`, `filters`, `processing_policy`. Optional: `transformations` and `alerts`

## active_period

Limits the time of data collection: for a period, from a date, until a date, or permanently.

Parameter name | Possible values | Required? | Comment
-- | -- | -- | --
`type` | `DateRange`, `FromDate`, `ToDate`, `Permanent` | Yes | Choice of the time limit
`start` | Date in the format `2023-11-15T12:43:56Z` | Required for the types: `DateRange` and `FromDate` | Start of the `DateRange` period or start of work for `FromDate`. For `DateRange` it is less than `end`
`end` | Date in the format `2023-11-15T12:43:56Z` | Required for the types: `DateRange` and `ToDate` | End of the `DateRange` period or end of work for `ToDate`

## filters

Parameter name | Possible values | Required? | Comment
-- | -- | -- | --
`type_input_value` | `Text` or `Number` | Yes | Type of the processed data. `Number` is `float64` from Golang
`type_value_filtering` | `WhiteList` and `BlackList` | No | Type of value filtering
`filtering_values` | A list of only numeric or only text values | Required if `type_value_filtering` is set | The check depends on the type from `type_input_value`
`type_value_threshold` | `Min`, `Max` or `Range` | No | Type of range filtering of numeric values
`threshold_min` | Integer | Required if `type_value_threshold` is set with the types `Min` and `Range` | Works only with `type_input_value` = `Number`. For `Range` it is less than `threshold_max`
`threshold_max` | Integer | Required if `type_value_threshold` is set with the types `Max` and `Range` | Works only with `type_input_value` = `Number`
`max_rate` | `0 <= max_rate <= 86400`, integers only | Yes | After how many seconds the next message will be processed. `0` means no limit
`last_unique_check` | `true`, `false` | Yes | If `true`, a value passes only if it differs from the previous one. `false` by default
`max_size` | `0 <= max_size <= pu_mqtt_max_payload_size * 1024` | Yes | Maximum message length in characters, a longer one is skipped. `0` means no limit. `pu_mqtt_max_payload_size` is an [instance setting](/deployment/instance-settings#mqtt)

## transformations

The parameters depend on `type_input_value` from `filters`.

For `type_input_value` = `Number`:
Parameter name | Possible values | Required? | Comment
-- | -- | -- | --
`multiplication_ratio` | `float64` from Golang | No | The given value can be multiplied by this number - a linear transformation
`round_decimal_point` | `0 <= round_decimal_point <= 7` | No | How many digits remain after the decimal point

For `type_input_value` = `Text`:
Parameter name | Possible values | Required? | Comment
-- | -- | -- | --
`slice_start` | Integer | No | Works like the first element of a slice in `python3` - `any_list[slice_start:]`
`slice_end` | Integer | No | Works like the second element of a slice in `python3` - `any_list[:slice_end]`

## processing_policy

Parameter name | Possible values | Required? | Comment
-- | -- | -- | --
`policy_type` | `LastValue`, `NRecords`, `TimeWindow`, `Aggregation` | Yes | One of the `4` processing policies
`n_records_count` | Number of stored records `0 < n_records_count =< 1024` | Required only for `policy_type` = `NRecords` | Defines how many records will be stored
`time_window_size` | One of the values: `[60, 300, 600, 900, 1200, 1800, 3600, 7200, 10800, 14400, 21600, 28800, 43200, 86400]` | Required for `policy_type` = `TimeWindow` or `Aggregation` | Window size in seconds, it must divide `86400` evenly
`aggregation_functions` | `Avg`, `Min`, `Max`, `Sum` | Required for `policy_type` = `Aggregation` | The function used to calculate the final value over `time_window_size`

## alerts

Checks a value that has already passed `filters` and `transformations`, and writes a notification to the creator of the `UnitIO`. The condition matches the `filters` stage: a notification is sent for a value that the same filter would have let through.

`WhiteList` fires when the value is in `filtering_values`. `BlackList` fires when the value is not in the list. `Min` fires when the value is greater than or equal to `threshold_min`, `Max` when the value is less than or equal to `threshold_max`, `Range` when the value is inside both bounds. If both a list and a threshold are set, the value must pass both rules. If neither `type_value_filtering` nor `type_value_threshold` is set, a notification is created for any value: `is_enabled` is enough.

`max_rate` and `last_unique_check` from `filters` decide which values reach this check at all. The first notification is sent after `consecutive_count` matches in a row. While the value keeps matching, the next notification of the same `UnitIO` comes no more often than once every `max_frequency` seconds. A value that does not match the rule resets the `consecutive_count` counter.

The stage works when the instance setting `pu_ff_notification_enable` is on. If you turn off `DataPipe` in the [notification settings](/user/alerts#settings), the rule stays in the pipeline, but notifications stop coming.

Parameter name | Possible values | Required? | Comment
-- | -- | -- | --
`is_enabled` | `true`, `false` | No, `true` by default | `false` turns the check off
`type_value_filtering` | `WhiteList`, `BlackList` | No | Type of the list
`filtering_values` | A list of numbers or strings | Required if `type_value_filtering` is set | The type of values is taken from `filters.type_input_value`
`type_value_threshold` | `Min`, `Max`, `Range` | No | Only with `filters.type_input_value` = `Number`
`threshold_min` | Integer | Required for `Min` and `Range` | For `Range` it is less than `threshold_max`
`threshold_max` | Integer | Required for `Max` and `Range` | For `Range` it is greater than `threshold_min`
`consecutive_count` | Integer `1`–`1024`, `1` by default | No | How many matches in a row are needed before the first notification
`max_frequency` | Integer `10`–`86400`, `10` by default | No | Minimum seconds between two notifications of one `UnitIO`