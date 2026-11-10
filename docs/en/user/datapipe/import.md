# Importing data into DataPipe

`UnitIO` → `DataPipe` → `Upload data`: choose a `CSV` file with records. `Download data` takes the data back: the client saves a `zip` with `CSV`. The `LastValue` policy has neither upload nor download: only one last record is stored.

Every row goes through the checks from the [YML configuration](/user/datapipe/datapipe), and at the first error the upload stops, the message gives the row number. The rules:

- Rows are sorted by `create_datetime` from oldest to newest
- `create_datetime` falls into `active_period`, the value passes `filters`. `max_rate` and `last_unique_check` are checked for `NRecords` and `TimeWindow`
- `NRecords`: no more rows than `n_records_count`
- `TimeWindow`: `create_datetime` is not from the future and not older than `time_window_size` from the current moment
- `Aggregation`: window fields have no seconds, `end_window_datetime` - `start_window_datetime` equals `time_window_size`, the distance between the ends of neighboring windows is a multiple of `time_window_size`, and `create_datetime` differs from `end_window_datetime` by less than `60` seconds

Date and time are in ISO 8601 format. Without a time zone, `UTC` is assumed. Below are files with the minimum set of fields for each `policy_type`. The dates in them are examples: replace them with your own, especially for `TimeWindow`.

## NRecords

```csv
state,create_datetime
9.95,2025-09-10 08:27:00
4.21,2025-09-10 09:27:00
5.69,2025-09-10 10:27:00
1.43,2025-09-10 11:27:00
7.84,2025-09-10 12:27:00
6.47,2025-09-10 13:27:00
8.93,2025-09-10 14:27:00
1.85,2025-09-10 15:27:00
7.26,2025-09-10 16:27:00
2.96,2025-09-10 17:27:00
6.58,2025-09-10 18:27:00
```

## TimeWindow

```csv
state,create_datetime
"{""level"": ""info"", ""TitleMessage"": ""Test Info One""}",2025-09-14 11:23:42
"{""level"": ""info"", ""TitleMessage"": ""Test Info One""}",2025-09-14 11:23:44
"{""level"": ""info"", ""TitleMessage"": ""Test Info One""}",2025-09-14 11:23:46
"{""level"": ""warning"", ""TitleMessage"": ""Test Info Two""}",2025-09-14 11:23:48
"{""level"": ""info"", ""TitleMessage"": ""Test Info Two""}",2025-09-14 11:23:50
"{""level"": ""error"", ""TitleMessage"": ""Test Info Two""}",2025-09-14 11:23:52
"{""level"": ""error"", ""TitleMessage"": ""Test Info One""}",2025-09-14 11:23:54
"{""level"": ""info"", ""TitleMessage"": ""Test Info Two""}",2025-09-14 11:23:56
"{""level"": ""warning"", ""TitleMessage"": ""Test Info One""}",2025-09-14 11:23:58
"{""level"": ""warning"", ""TitleMessage"": ""Test Info One""}",2025-09-14 11:24:00
"{""level"": ""warning"", ""TitleMessage"": ""Test Info Two""}",2025-09-14 11:24:02
"{""level"": ""error"", ""TitleMessage"": ""Test Info Two""}",2025-09-14 11:24:04
"{""level"": ""info"", ""TitleMessage"": ""Test Info One""}",2025-09-14 11:24:06
```

## Aggregation

Windows of `1` minute, that is `time_window_size: 60`.

```csv
state,create_datetime,start_window_datetime,end_window_datetime
-15.13,2025-09-13 02:08:00,2025-09-13 02:07:00,2025-09-13 02:08:00
-5.91,2025-09-13 02:09:00,2025-09-13 02:08:00,2025-09-13 02:09:00
8.3,2025-09-13 02:10:00,2025-09-13 02:09:00,2025-09-13 02:10:00
-8.72,2025-09-13 02:11:00,2025-09-13 02:10:00,2025-09-13 02:11:00
7.56,2025-09-13 02:12:00,2025-09-13 02:11:00,2025-09-13 02:12:00
-15.75,2025-09-13 02:13:00,2025-09-13 02:12:00,2025-09-13 02:13:00
-0.94,2025-09-13 02:14:00,2025-09-13 02:13:00,2025-09-13 02:14:00
-1.45,2025-09-13 02:15:00,2025-09-13 02:14:00,2025-09-13 02:15:00
1.49,2025-09-13 02:16:00,2025-09-13 02:15:00,2025-09-13 02:16:00
-12.69,2025-09-13 02:17:00,2025-09-13 02:16:00,2025-09-13 02:17:00
-6.51,2025-09-13 02:18:00,2025-09-13 02:17:00,2025-09-13 02:18:00
```
