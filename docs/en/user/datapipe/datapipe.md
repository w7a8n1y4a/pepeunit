# DataPipe

::::info How to find DataPipe?
1. Find the [Unit](/en/definitions#unit) you are interested in visually or via the search tab
1. Right-click (`RMB`) on the [Unit](/en/definitions#unit) if [UnitNode](/en/definitions#unitnode) has not yet been displayed
1. Left-click (`LMB`) on the `Input` or `Output` [UnitNode](/en/definitions#unitnode)
1. Click the yellow [DataPipe](/en/deployment/dependencies/datapipe) button
::::

Name of the button | Purpose
-- | --
`Import YML Config` | Upload a pipeline from your local device into the editor
`Export YML Config` | Download the pipeline that is currently active on the server
`Import CSV Data` | Upload data from your local device into [DataPipe](/en/deployment/dependencies/datapipe)
`Export CSV Data` | Download all accumulated data in `CSV` format; if there is no data, an error will be returned
`Set Config` | Send a new pipeline configuration to the server
`Del Saved Pipe Data` | Delete all data that was produced by the pipeline for this [UnitNode](/en/definitions#unitnode)

Editor features:
1. The editor shows basic [YML](/en/definitions#yml) syntax errors
1. The editor can show `business errors` if the format does not match the structure expected by the server
1. When you try to send an invalid [YML](/en/definitions#yml) config, an error will also be shown

## Meaning of parameters

There are 4 main stages of the pipeline: `active_period`, `filtres`, `transformations` and `processing_policy`

## active_period

The main goal of this stage is to limit the period of data collection:
- for a specific period
- starting from a specific date
- until a specific date
- permanently

Parameter name | Possible values | Required? | Comment
-- | -- | -- | --
`type` | `DateRange`, `FromDate`, `ToDate`, `Permanent` | Yes | Choose how to limit the time
`start` | Datetime in format `2023-11-15T12:43:56Z` | Required for types: `DateRange` and `FromDate` | Start time of the `DateRange` period or the start time of the `FromDate` mode
`end` | Datetime in format `2023-11-15T12:43:56Z` | Required for types: `DateRange` and `ToDate` | End time of the `DateRange` period or the end time of the `ToDate` mode

## filtres

Parameter name | Possible values | Required? | Comment
-- | -- | -- | --
`type_input_value` | `Text` or `Number` | Yes | Type of the processed data. `Number` is `float64` from [Golang](/en/definitions#golang)
`type_value_filtering` | `WhiteList` and `BlackList` | No | Type of value filtering
`filtering_values` | List of only numeric or only text values | Required if `type_value_filtering` is set | Validation is tied to the type from `type_input_value`
`type_value_threshold` | `Min`, `Max` or `Range` | No | Type of filtering for numeric value ranges
`threshold_min` | `float64` from [Golang](/en/definitions#golang) | Required if `type_value_threshold` is `Min` or `Range` | Works only when `type_input_value` = `Number`
`threshold_max` | `float64` from [Golang](/en/definitions#golang) | Required if `type_value_threshold` is `Max` or `Range` | Works only when `type_input_value` = `Number`
`max_rate` | `0 <= max_rate <= 86400` integers only | Yes | Defines after how many seconds the next message will be processed. `0` means no limit
`last_unique_check` | `true`, `false` | Yes | If `true`, only passes a new value if it differs from the previous one. Default is `false`
`max_size` | `0 <= max_size <= MQTT_MAX_PAYLOAD_SIZE * 1024` | Yes | Maximum message size; if exceeded, the message will be dropped

## transformations

This stage is not mandatory, but if you use it, you need to know the `type_input_value` type from the previous stage:

For `type_input_value` = `Number`:

Parameter name | Possible values | Required? | Comment
-- | -- | -- | --
`multiplication_ratio` | `float64` from [Golang](/en/definitions#golang) | No | Value to multiply the incoming value by — a linear transformation
`round_decimal_point` | `0 <= round_decimal_point <= 7` | No | How many digits after the decimal point should remain

For `type_input_value` = `Text`:

Parameter name | Possible values | Required? | Comment
-- | -- | -- | --
`slice_start` | Integer | No | Works like the first index in a Python 3 slice: `any_list[slice_start:]`
`slice_end` | Integer | No | Works like the second index in a Python 3 slice: `any_list[:slice_end]`

## processing_policy

Parameter name | Possible values | Required? | Comment
-- | -- | -- | --
`policy_type` | `LastValue`, `NRecords`, `TimeWindow`, `Aggregation` | Yes | One of the 4 processing policies
`n_records_count` | Number of stored records `0 < n_records_count =< 1024` | Required only for `policy_type` = `NRecords` | Defines how many records will be stored
`time_window_size` | One of: `[60, 300, 600, 900, 1200, 1800, 3600, 7200, 10800, 14400, 21600, 28800, 43200, 86400]` | Required for `policy_type` = `TimeWindow` or `Aggregation` | Window size in seconds; it must evenly divide `86400`
`aggregation_functions` | `Avg`, `Min`, `Max`, `Sum` | Required for `policy_type` = `Aggregation` | Function used to calculate the resulting value based on `time_window_size`


