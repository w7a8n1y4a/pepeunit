# DataPipe

:::info Как найти DataPipe?
1. Найдите интересующий вас [Unit](/definitions#unit) визуально или через вкладку поиска. 
1. Нажмите `ПКМ` по [Unit](/definitions#unit) если [UnitNode](/definitions#unitnode) ещё не отобразились
1. Выберите `ЛКМ` `Input` или `Output` [UnitNode](/definitions#unitnode)
1. Кликните жёлткую кнопку [DataPipe](/deployment/dependencies/datapipe)
:::

Имя кнопки | Назначение
-- | --
`Import YML Config` | Позволяет загрузить конвейер с вашего локального устройства в редактор
`Export YML Config` | Позволяет скачать конвейер, который на данный момент актуален на сервере
`Import CSV Data` | Позволяет загрузить данные с вашего локлаьной устройства в [DataPipe](/deployment/dependencies/datapipe)
`Export CSV Data` | Позволяет скачать все накопленные данные в формате `CSV`, если данных нет выдаст ошибку
`Set Config` | Позволяет отправить на сервер новый конвейер
`Del Saved Pipe Data` | Позволяет удалить все данные которые получились в результате работы конвейера, для данного [UnitNode](/definitions#unitnode)

Особенности редактора:
1. Редактор выводит базовые ошибки синтаксиса [YML](/definitions#yml)
1. Редактор умеет выводить `бизнес-ошибки`, если формат не соответствует структуре ожидаемой сервером
1. При попытке отправки неверного [YML](/definitions#yml) конфига, так же будет выведена ошибка

## Значение параметров

Всего есть 4 основных этапа конвейера: `active_period`, `filtres`, `transformations`, `processing_policy`

## active_period

Основная цель данного этапа ограничить время сбора данных:
- определённый период
- начиная с определённой даты
- до определённой даты
- постоянно

Название параметра | Возможные значения | Обязательный? | Комментарий
-- | -- | -- | --
`type` | `DateRange`, `FromDate`, `ToDate`, `Permanent` | Да | Выбор ограничения времени
`start` | Дата в формате `2023-11-15T12:43:56Z` | Обязателен для типов: `DateRange` и `FromDate` | Время начала периода `DateRange` или время начала работы `FromDate`
`end` | Дата в формате `2023-11-15T12:43:56Z` | Обязателен для типов: `DateRange` и `ToDate` | Время конца периода `DateRange` или время конца работы `ToDate`

## filtres

Название параметра | Возможные значения | Обязательный? | Комментарий
-- | -- | -- | --
`type_input_value` | `Text` или `Number` | Да | Тип обрабатываемых данных. `Number` это `float64` из [Golang](/definitions#golang)
`type_value_filtering` | `WhiteList` и `BlackList` | Нет | Тип фильтрации значений 
`filtering_values` | Список только числовых или только текстовых значений | Обязателен в случае если есть `type_value_filtering` | Проверка завязана на тип из `type_input_value`
`type_value_threshold` | `Min`, `Max` или `Range` | Нет | Тип фильтрации диапазонов числовых значений
`threshold_min` | `float64` из [Golang](/definitions#golang) | Обязателен если есть `type_value_threshold` с типами: `Min` и `Range` | Работает только с `type_input_value` = `Number`
`threshold_max` | `float64` из [Golang](/definitions#golang) | Обязателен если есть `type_value_threshold` с типами: `Max` и `Range` | Работает только с `type_input_value` = `Number`
`max_rate` | `0 <= max_rate <= 86400` только целые | Да | Определят через сколько секунд будет обработано следующее сообщение. `0` без ограничения
`last_unique_check` | `true`, `false` | Да | Если `true` пропустит только если новое значение отличается от предыдущего, по умолчанию `false`
`max_size` | `0 <= max_size <= MQTT_MAX_PAYLOAD_SIZE * 1024` | Да | Максимальный размер сообщения, если рамер привысит, сообщение будет пропущено

## transformations

Данный этап не является обязательным, но если вы его используете, он требует знания о типе `type_input_value` из предыдущего этапа:

Для `type_input_value` = `Number`:
Название параметра | Возможные значения | Обязательный? | Комментарий
-- | -- | -- | --
`multiplication_ratio` | `float64` из [Golang](/definitions#golang) | Нет | На это число можно умножить заданное значение - линейное преобразование
`round_decimal_point` | `0 <= round_decimal_point <= 7` | Нет | Сколько чисел после запятой останется ?

Для `type_input_value` = `Text`:
Название параметра | Возможные значения | Обязательный? | Комментарий
-- | -- | -- | --
`slice_start` | Целое число | Нет | Работает как первый элемент среза в `python3` - `any_list[slice_start:]`
`slice_end` | Целое число | Нет | Работает как второй элемент среза в `python3` - `any_list[:slice_end]`

## processing_policy

Название параметра | Возможные значения | Обязательный? | Комментарий
-- | -- | -- | --
`policy_type` | `LastValue`, `NRecords`, `TimeWindow`, `Aggregation` | Да | Одна из `4` политик обработки
`n_records_count` | Число хранимых записей `0 < n_records_count =< 1024` | Обязателен только для `policy_type` = `NRecords` | Определяет сколько записей будет храниться
`time_window_size` | Одно из значений: `[60, 300, 600, 900, 1200, 1800, 3600, 7200, 10800, 14400, 21600, 28800, 43200, 86400]` | Обязателен для `policy_type` = `TimeWindow` или `Aggregation` | Размер окна в секундах, оно должно нацело делить `86400`
`aggregation_functions` | `Avg`, `Min`, `Max`, `Sum` | Обязателен для `policy_type` = `Aggregation` | Фунация на основе которой будет расчитано итоговое значение, на основе `time_window_size`