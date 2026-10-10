# DataPipe

:::info Как найти DataPipe?
1. Найдите интересующий вас [Unit](/definitions#unit) визуально или через вкладку поиска
1. Нажмите `ПКМ` по [Unit](/definitions#unit), если [UnitNode](/definitions#unitnode) ещё не отобразились
1. Выберите `ЛКМ` `Input` или `Output` [UnitNode](/definitions#unitnode)
1. Кликните жёлткую кнопку [DataPipe](/deployment/dependencies/datapipe)
:::

Имя кнопки | Назначение
-- | --
`Import YML Config` | Позволяет загрузить конвейер с вашего локального устройства в редактор
`Export YML Config` | Позволяет скачать конвейер, который на данный момент актуален на сервере
`Import CSV Data` | Позволяет загрузить данные с вашего локальной устройства в [DataPipe](/deployment/dependencies/datapipe)
`Export CSV Data` | Позволяет скачать все накопленные данные в формате `CSV`, если данных нет - выдаст ошибку
`Set Config` | Позволяет отправить на сервер новый конвейер
`Del Saved Pipe Data` | Позволяет удалить все данные, которые получились в результате работы конвейера, для данного [UnitNode](/definitions#unitnode)

Особенности редактора:
1. Редактор выводит базовые ошибки синтаксиса [YML](/definitions#yml)
1. Редактор умеет выводить `бизнес-ошибки`, если формат не соответствует структуре ожидаемой сервером
1. При попытке отправки неверного [YML](/definitions#yml) конфига, так же будет выведена ошибка

## Значение параметров

Конвейер состоит из этапов `active_period`, `filters`, `transformations`, `processing_policy` и необязательного `alerts`

## active_period

Основная цель данного этапа ограничить время сбора данных:
- за определённый период
- начиная с определённой даты
- до определённой даты
- постоянно

Название параметра | Возможные значения | Обязательный? | Комментарий
-- | -- | -- | --
`type` | `DateRange`, `FromDate`, `ToDate`, `Permanent` | Да | Выбор ограничения времени
`start` | Дата в формате `2023-11-15T12:43:56Z` | Обязателен для типов: `DateRange` и `FromDate` | Время начала периода `DateRange` или время начала работы `FromDate`
`end` | Дата в формате `2023-11-15T12:43:56Z` | Обязателен для типов: `DateRange` и `ToDate` | Время конца периода `DateRange` или время конца работы `ToDate`

## filters

Название параметра | Возможные значения | Обязательный? | Комментарий
-- | -- | -- | --
`type_input_value` | `Text` или `Number` | Да | Тип обрабатываемых данных. `Number` это `float64` из [Golang](/definitions#golang)
`type_value_filtering` | `WhiteList` и `BlackList` | Нет | Тип фильтрации значений 
`filtering_values` | Список только числовых или только текстовых значений | Обязателен в случае, если есть `type_value_filtering` | Проверка завязана на тип из `type_input_value`
`type_value_threshold` | `Min`, `Max` или `Range` | Нет | Тип фильтрации диапазонов числовых значений
`threshold_min` | `float64` из [Golang](/definitions#golang) | Обязателен, если есть `type_value_threshold` с типами `Min` и `Range` | Работает только с `type_input_value` = `Number`
`threshold_max` | `float64` из [Golang](/definitions#golang) | Обязателен, если есть `type_value_threshold` с типами `Max` и `Range` | Работает только с `type_input_value` = `Number`
`max_rate` | `0 <= max_rate <= 86400` только целые | Да | Определят, через сколько секунд будет обработано следующее сообщение. `0` без ограничения
`last_unique_check` | `true`, `false` | Да | Если `true`, то пропустит только если новое значение отличается от предыдущего. По умолчанию `false`
`max_size` | `0 <= max_size <= MQTT_MAX_PAYLOAD_SIZE * 1024` | Да | Максимальный размер сообщения, если размер превысит - сообщение будет пропущено

## transformations

Данный этап не является обязательным, но, если вы его используете, он требует знания о типе `type_input_value` из предыдущего этапа:

Для `type_input_value` = `Number`:
Название параметра | Возможные значения | Обязательный? | Комментарий
-- | -- | -- | --
`multiplication_ratio` | `float64` из [Golang](/definitions#golang) | Нет | На это число можно умножить заданное значение - линейное преобразование
`round_decimal_point` | `0 <= round_decimal_point <= 7` | Нет | Сколько чисел после запятой останется?

Для `type_input_value` = `Text`:
Название параметра | Возможные значения | Обязательный? | Комментарий
-- | -- | -- | --
`slice_start` | Целое число | Нет | Работает как первый элемент среза в `python3` - `any_list[slice_start:]`
`slice_end` | Целое число | Нет | Работает как второй элемент среза в `python3` - `any_list[:slice_end]`

## processing_policy

Название параметра | Возможные значения | Обязательный? | Комментарий
-- | -- | -- | --
`policy_type` | `LastValue`, `NRecords`, `TimeWindow`, `Aggregation` | Да | Одна из `4` политик обработки
`n_records_count` | Число хранимых записей `0 < n_records_count =< 1024` | Обязателен только для `policy_type` = `NRecords` | Определяет, сколько записей будет храниться
`time_window_size` | Одно из значений: `[60, 300, 600, 900, 1200, 1800, 3600, 7200, 10800, 14400, 21600, 28800, 43200, 86400]` | Обязателен для `policy_type` = `TimeWindow` или `Aggregation` | Размер окна в секундах, оно должно нацело делить `86400`
`aggregation_functions` | `Avg`, `Min`, `Max`, `Sum` | Обязателен для `policy_type` = `Aggregation` | Функция, на основе которой будет рассычитано итоговое значение, на основе `time_window_size`

## alerts

Необязательный этап. [DataPipe](/deployment/dependencies/datapipe) проверяет значение, которое уже прошло `filters` и `transformations`, и пишет [уведомление](/user/notification/notifications#datapipe-alert) создателю [Unit](/definitions#unit). Правила похожи на `filters`, но смысл обратный: `WhiteList` срабатывает на значение вне списка, `BlackList` на значение внутри списка. `Min` срабатывает ниже `threshold_min`, `Max` выше `threshold_max`, `Range` вне обоих границ.

`max_rate` и `last_unique_check` из `filters` решают, какие значения вообще дойдут до этой проверки. Первое уведомление уходит после `consecutive_count` нарушений подряд. Пока значение остаётся нарушением, следующее уведомление того же [UnitNode](/definitions#unitnode) приходит не чаще чем раз в `max_frequency` секунд. Обычное значение сбрасывает счётчик `consecutive_count`.

Этап работает при включённом `PU_FF_NOTIFICATION_ENABLE` у [Backend](/deployment/dependencies/backend) и [DataPipe](/deployment/dependencies/datapipe). Выключенный `Data pipe alerts` в [настройках уведомлений](/user/notification/notifications#настройки) оставляет запись в списке и правило в конвейере, живое обновление страницы и [Telegram](/definitions#telegram) для этого типа прекращаются.

Название параметра | Возможные значения | Обязательный? | Комментарий
-- | -- | -- | --
`is_enabled` | `true`, `false` | Нет, по умолчанию `true` | `false` выключает проверку
`type_value_filtering` | `WhiteList`, `BlackList` | Нужен он или `type_value_threshold` | Тип списка
`filtering_values` | Список чисел или строк | Обязателен, если задан `type_value_filtering` | Тип значений берётся из `filters.type_input_value`
`type_value_threshold` | `Min`, `Max`, `Range` | Нужен он или `type_value_filtering` | Только при `filters.type_input_value` = `Number`
`threshold_min` | Целое | Обязателен для `Min` и `Range` | Для `Range` меньше `threshold_max`
`threshold_max` | Целое | Обязателен для `Max` и `Range` | Для `Range` больше `threshold_min`
`consecutive_count` | Целое `1`–`1024`, по умолчанию `1` | Нет | Сколько нарушений подряд нужно до первого уведомления
`max_frequency` | Целое `10`–`86400`, по умолчанию `10` | Нет | Минимум секунд между двумя уведомлениями одного [UnitNode](/definitions#unitnode)