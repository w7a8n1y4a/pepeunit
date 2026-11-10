/// What the user reads for a backend error code. Keys are the code names the
/// backend lists at `/error_codes` (`ErrorCode` there); the number comes from
/// that route, so a renumbered code keeps its text.
///
/// A line is short and says why it happened. To add a language, append one
/// more outer key. A missing line falls back to Russian, then to the generic
/// text of the status (see `describeFailure`).
const errorTexts = <String, Map<String, String>>{'ru': _ru, 'en': _en};

const _ru = <String, String>{
  // Access
  'ACCESS_TOKEN_EXPIRED': 'Сессия истекла. Войдите в инстанс заново.',
  'ACCESS_TOKEN_INVALID':
      'Сервер не принял токен входа. Войдите в инстанс заново.',
  'ACCESS_AGENT_BLOCKED_OR_NOT_FOUND':
      'Аккаунт заблокирован или удалён на этом инстансе.',
  'ACCESS_USER_BLOCKED': 'Пользователь заблокирован владельцем инстанса.',
  'ACCESS_USER_NOT_FOUND': 'Пользователь не найден.',
  'ACCESS_UNIT_NOT_FOUND': 'Юнит не найден.',
  'ACCESS_INVALID_AGENT_TYPE': 'Сервер не распознал, кто выполняет запрос.',
  'ACCESS_UNKNOWN_AGENT_TYPE': 'Сервер не распознал, кто выполняет запрос.',
  'ACCESS_AGENT_TYPE_NOT_ALLOWED':
      'Это действие недоступно для такого типа доступа: оно только для '
      'пользователей или только для юнитов.',
  'ACCESS_ROLE_NOT_ALLOWED':
      'Для этого действия нужна другая роль. Обратитесь к владельцу инстанса.',
  'ACCESS_NOT_CREATOR': 'Менять объект может только его создатель.',
  'ACCESS_UNIT_REQUEST_DENIED':
      'У юнита нет доступа к этим данным. Откройте доступ в настройках юнита.',
  'ACCESS_UNIT_INPUT_DENIED':
      'Юнит не может писать в этот вход: он не перезаписываемый.',
  'ACCESS_VISIBILITY_LEVEL_NOT_ALLOWED':
      'Такой уровень видимости здесь не разрешён.',
  'ACCESS_PRIVATE_REPO': 'Приватный репозиторий здесь не разрешён.',
  'ACCESS_PRIVATE_VISIBILITY': 'Приватный уровень видимости здесь не разрешён.',
  'ACCESS_REPO_ONLY': 'Действие применимо только к репозиторию.',
  'ACCESS_REPO_USERS_ONLY':
      'Операции с репозиториями доступны только пользователям, не юнитам.',
  'ACCESS_REPO_NO_CREDENTIALS':
      'У репозитория нет учётных данных. Добавьте токен доступа к нему.',
  'ACCESS_NO_PLATFORM_CREDENTIALS':
      'У вас нет токена Git-платформы. Добавьте его в учётных данных.',
  'ACCESS_PLATFORM_CREDENTIALS_STATUS':
      'Токен Git-платформы не подходит: он не проверен или с ошибкой.',
  'ACCESS_NOTIFICATION_NOT_ALLOWED':
      'Нет доступа к этому уведомлению: оно принадлежит другому пользователю.',
  'ACCESS_ICON_OWNER_ONLY': 'Менять эту иконку может только её владелец.',
  'ACCESS_DOCKED_UNIT_ONLY':
      'Доступно только самому юниту, к которому относится топик.',
  'ACCESS_TOPIC_DESTINATION_INVALID': 'Такого типа топика не существует.',
  'ACCESS_CHALLENGE_INVALID': 'Вход не удался: проверка ключа повреждена.',
  'ACCESS_CHALLENGE_DOMAIN_MISMATCH':
      'Вход не удался: проверка выдана для другого адреса инстанса.',
  'ACCESS_CHALLENGE_USED_OR_EXPIRED':
      'Вход не удался: проверка ключа уже использована или устарела. '
      'Повторите вход.',
  'ACCESS_CHALLENGE_EXPIRED': 'Проверка ключа устарела. Повторите вход.',
  'ACCESS_SIGNATURE_MISMATCH':
      'Подпись не подошла: ключ в клиенте не совпадает с ключом аккаунта.',

  // Cipher
  'CIPHER_CONTENT_TOO_LONG': 'Текст для шифрования длиннее допустимого.',
  'CIPHER_ENV_JSON_INVALID': 'Переменные окружения не читаются как JSON.',

  // Dashboard
  'DASHBOARD_NOT_FOUND': 'Дашборд не найден.',
  'DASHBOARD_PANEL_NOT_FOUND': 'Панель не найдена.',
  'PANELS_UNIT_IOS_NOT_FOUND': 'Узел не подключён к этой панели.',
  'DASHBOARD_UUID_INVALID': 'Идентификатор дашборда записан неверно.',

  // DataPipe
  'DATAPIPE_BULK_CREATE_LAST_VALUE_UNAVAILABLE':
      'Для типа «последнее значение» нельзя загрузить много записей сразу.',
  'DATAPIPE_NO_DATA': 'Данных за этот период нет.',
  'DATAPIPE_TOPIC_SUFFIX':
      'DataPipe включается только для топика, который оканчивается на '
      '/pepeunit.',
  'DATAPIPE_NOT_ACTIVE': 'DataPipe выключен. Сначала включите его.',
  'DATAPIPE_NOT_FILLED': 'Конфиг DataPipe пуст. Сначала заполните его.',
  'DATAPIPE_LAST_VALUE_UNSUPPORTED':
      'Тип «последнее значение» не подходит для этого действия.',
  'DATAPIPE_IS_NONE': 'У этого узла нет DataPipe.',
  'DATAPIPE_CONFIG_INVALID': 'Конфиг DataPipe не прошёл проверку.',
  'DATAPIPE_CONFIG_JSON_INVALID': 'Конфиг DataPipe не читается как YAML.',
  'DATAPIPE_ACTIVE_FROM_DATE_START':
      'Для периода «с даты» нужно указать начало.',
  'DATAPIPE_ACTIVE_TO_DATE_END': 'Для периода «до даты» нужно указать конец.',
  'DATAPIPE_ACTIVE_RANGE_BOUNDS':
      'Для периода «диапазон дат» нужны и начало, и конец.',
  'DATAPIPE_ACTIVE_RANGE_ORDER': 'Начало периода должно быть раньше конца.',
  'DATAPIPE_FILTER_VALUES_NUMBER':
      'Для числового входа значения фильтра должны быть числами.',
  'DATAPIPE_FILTER_VALUES_TEXT':
      'Для текстового входа значения фильтра должны быть строками.',
  'DATAPIPE_THRESHOLD_MIN_REQUIRED':
      'Для порога «минимум» нужно задать нижнюю границу.',
  'DATAPIPE_THRESHOLD_MAX_REQUIRED':
      'Для порога «максимум» нужно задать верхнюю границу.',
  'DATAPIPE_THRESHOLD_RANGE_REQUIRED':
      'Для порога «диапазон» нужны обе границы: нижняя и верхняя.',
  'DATAPIPE_THRESHOLD_RANGE_ORDER':
      'Нижняя граница порога должна быть меньше верхней.',
  'DATAPIPE_MAX_SIZE': 'Максимальный размер записи больше допустимого.',
  'DATAPIPE_N_RECORDS_REQUIRED':
      'Для политики «N записей» нужно указать их количество.',
  'DATAPIPE_N_RECORDS_RANGE': 'Количество записей должно быть от 1 до 1024.',
  'DATAPIPE_TIME_WINDOW_REQUIRED': 'Нужно указать размер временного окна.',
  'DATAPIPE_TIME_WINDOW_INVALID':
      'Такого размера окна нет. Выберите из списка допустимых.',
  'DATAPIPE_AGGREGATION_FUNCTIONS_REQUIRED':
      'Для агрегации нужно выбрать хотя бы одну функцию.',
  'DATAPIPE_FILTERING_VALUES_REQUIRED':
      'Для выбранной фильтрации нужно задать значения.',
  'DATAPIPE_THRESHOLD_NOT_FOR_TEXT':
      'Порог не применяется к текстовому входу, он только для чисел.',
  'DATAPIPE_CSV_WINDOW_DATETIME':
      'В CSV время записи не попадает в допустимое окно.',
  'DATAPIPE_CSV_N_RECORDS_LIMIT': 'В CSV записей больше, чем разрешает конфиг.',
  'DATAPIPE_CSV_WINDOW_SECONDS': 'В CSV границы окна должны быть без секунд.',
  'DATAPIPE_CSV_WINDOW_ORDER': 'В CSV конец окна раньше его начала.',
  'DATAPIPE_CSV_WINDOW_MIN_DELTA':
      'В CSV время записи слишком далеко от конца окна.',
  'DATAPIPE_CSV_WINDOW_SIZE_MISMATCH':
      'В CSV длина окна не совпадает с размером окна в конфиге.',
  'DATAPIPE_CSV_PREVIOUS_WINDOW_SIZE':
      'В CSV окна идут не подряд: между ними разрыв или перекрытие.',
  'DATAPIPE_CSV_MAX_RATE': 'В CSV записи идут чаще, чем разрешает конфиг.',
  'DATAPIPE_CSV_LAST_UNIQUE':
      'В CSV значение повторяет предыдущее, а конфиг пропускает повторы.',
  'DATAPIPE_CSV_MAX_SIZE': 'В CSV значение длиннее допустимого.',
  'DATAPIPE_CSV_NOT_MONOTONIC': 'В CSV время записей идёт не по возрастанию.',
  'DATAPIPE_CSV_BEFORE_ACTIVE_START':
      'В CSV запись раньше начала периода работы DataPipe.',
  'DATAPIPE_CSV_AFTER_ACTIVE_END':
      'В CSV запись позже конца периода работы DataPipe.',
  'DATAPIPE_CSV_OUTSIDE_ACTIVE_RANGE':
      'В CSV запись вне периода работы DataPipe.',
  'DATAPIPE_CSV_NOT_IN_WHITELIST':
      'В CSV значение отсутствует в белом списке конфига.',
  'DATAPIPE_CSV_IN_BLACKLIST': 'В CSV значение есть в чёрном списке конфига.',
  'DATAPIPE_CSV_BELOW_THRESHOLD': 'В CSV значение ниже нижнего порога.',
  'DATAPIPE_CSV_ABOVE_THRESHOLD': 'В CSV значение выше верхнего порога.',
  'DATAPIPE_CSV_OUTSIDE_THRESHOLD': 'В CSV значение вне порогов конфига.',
  'DATAPIPE_CSV_STATE_NOT_TEXT': 'В CSV значение должно быть текстом.',
  'DATAPIPE_CSV_STATE_NOT_NUMBER': 'В CSV значение должно быть числом.',
  'DATAPIPE_CSV_DATETIME_INVALID':
      'В CSV дата записана неверно. Нужен формат ISO, например '
      '2026-01-31T12:00:00.',
  'DATAPIPE_RELATIVE_TIME_INVALID':
      'Такого относительного интервала нет. Выберите из списка допустимых.',

  // Feature flag
  'FEATURE_DISABLED': 'Эту функцию отключил владелец инстанса.',

  // Git platform
  'GIT_PLATFORM_TIMEOUT': 'Git-платформа не ответила вовремя. Повторите позже.',
  'GIT_PLATFORM_REQUEST_FAILED':
      'Запрос к Git-платформе не удался. Проверьте адрес репозитория и '
      'повторите позже.',
  'GIT_PLATFORM_INVALID_CREDENTIALS':
      'Git-платформа не приняла токен. Он неверный или истёк.',
  'GIT_PLATFORM_RATE_LIMIT':
      'Git-платформа ограничила число запросов. Подождите и повторите.',

  // Git repository
  'GIT_REPO_VERSION_MISSING':
      'В репозитории нет тегов с версиями, поэтому выбрать версию нельзя.',
  'GIT_REPO_COMMIT_WITHOUT_TAG':
      'У этого коммита нет тега. Выберите коммит с тегом.',
  'GIT_REPO_COMMIT_NOT_FOUND': 'Такого коммита в репозитории нет.',
  'GIT_REPO_SCHEMA_UNRESOLVED_KEYS':
      'В schema.json остались ключи, для которых нет описания входов или '
      'выходов.',
  'GIT_REPO_SCHEMA_VALUE_TYPE':
      'В schema.json значения топиков должны быть только списками.',
  'GIT_REPO_TOPIC_CHARS':
      'В schema.json в топике есть недопустимые символы. Разрешены латинские '
      'буквы, цифры и / _ -',
  'GIT_REPO_TOPIC_TOO_LONG': 'В schema.json название топика слишком длинное.',
  'GIT_REPO_ENV_UNRESOLVED':
      'В env.json остались переменные без значения. Заполните их.',
  'GIT_REPO_BRANCH_NOT_FOUND': 'Такой ветки в репозитории нет.',
  'GIT_REPO_COMMIT_NOT_IN_BRANCH': 'Этого коммита нет в выбранной ветке.',
  'GIT_REPO_TAG_NO_PLATFORMS':
      'У выбранного тега нет собранных платформ. Выберите другой тег.',
  'GIT_REPO_PLATFORM_NOT_FOUND':
      'Для этого тега такой платформы нет. Выберите из доступных.',
  'GIT_REPO_NOT_EXIST':
      'Репозиторий не скачан на сервер. Запустите синхронизацию.',
  'GIT_REPO_INVALID_URL_OR_CREDENTIALS':
      'Адрес репозитория или токен неверны, либо у токена нет доступа.',
  'GIT_REPO_FILE_NOT_FOUND': 'В этом коммите нет нужного файла.',
  'GIT_REPO_TOO_LARGE': 'Репозиторий больше разрешённого размера.',
  'GIT_REPO_SCHEMA_JSON_INVALID': 'schema.json в репозитории не читается.',
  'GIT_REPO_ENV_EXAMPLE_JSON_INVALID':
      'env_example.json в репозитории не читается.',
  'GIT_REPO_ENV_JSON_INVALID': 'env.json не читается как JSON.',
  'GIT_REPO_COMMIT_MISSING': 'Коммит не найден в репозитории.',

  // Grafana
  'GRAFANA_NAME_INVALID':
      'Имя должно быть от 4 до 20 символов: латинские буквы, цифры и _ - .',
  'GRAFANA_TITLE_INVALID':
      'Заголовок должен быть от 4 до 20 символов: латинские буквы, цифры '
      'и _ - .',
  'GRAFANA_UNIT_IO_NOT_UNIQUE': 'Этот узел уже есть на панели.',
  'GRAFANA_PANEL_UNIT_IO_LIMIT': 'На одной панели узлов не может быть больше.',
  'GRAFANA_RETRIES_EXHAUSTED':
      'Grafana не отвечает. Попытки закончились, повторите позже.',
  'GRAFANA_VALUE_NOT_SUPPORTED': 'Grafana не умеет показывать это значение.',
  'GRAFANA_DATA_TYPE_NOT_SUPPORTED':
      'Этот тип данных нельзя показать на панели.',
  'GRAFANA_DASHBOARD_HAS_NO_PANELS':
      'На дашборде нет панелей. Сначала добавьте хотя бы одну.',
  'GRAFANA_NO_ACTIVE_DATAPIPE':
      'У узла нет включённого DataPipe, а панели он нужен.',
  'GRAFANA_INVALID_DATAPIPE_YML':
      'У узла неверный конфиг DataPipe, панель его не прочитает.',
  'GRAFANA_NAME_NOT_UNIQUE': 'Дашборд с таким именем уже есть.',
  'GRAFANA_TITLE_NOT_UNIQUE': 'Дашборд с таким заголовком уже есть.',

  // Icon
  'ICON_TOO_LARGE': 'Картинка больше 128 КБ.',
  'ICON_NOT_PNG': 'Нужен файл PNG.',
  'ICON_WRONG_SIZE': 'Размер картинки должен быть 192×192 пикселя.',
  'ICON_TARGET_UNSUPPORTED': 'Для этого объекта иконку задать нельзя.',
  'ICON_NOT_FOUND': 'Иконка не найдена.',

  // Instance
  'INSTANCE_CACHE_NOT_INITIALIZED':
      'Инстанс ещё запускается. Подождите немного и повторите.',
  'INSTANCE_INTEGRATION_TESTS_FAILED':
      'Проверка инстанса не прошла. Подробности в логах сервера.',
  'INSTANCE_SETTINGS_NOT_FOUND': 'Настройка не найдена.',
  'INSTANCE_SETTINGS_INVALID': 'Значение настройки не прошло проверку.',
  'INSTANCE_SETTINGS_EMAIL_INVALID':
      'Почта владельца записана неверно. Укажите адрес или оставьте пустым.',
  'INSTANCE_SETTINGS_TELEGRAM_TOKEN_INVALID':
      'Токен Telegram-бота должен выглядеть как 123456:ABC-def или быть '
      'пустым.',
  'INSTANCE_SETTINGS_COUNT_RATE_INVALID':
      'Лимит записывается как 20/s или 20/m: число в секунду или в минуту.',
  'INSTANCE_SETTINGS_BYTES_RATE_INVALID':
      'Лимит записывается как 1MB/s: объём в секунду.',
  'INSTANCE_SETTINGS_GRAFANA_CREDENTIALS':
      'Grafana не включить: на сервере не заданы логин и пароль её '
      'администратора.',
  'INSTANCE_SETTINGS_GITHUB_TOKEN_PAIR':
      'Имя и токен GitHub задаются вместе: заполните оба поля или оба '
      'очистите.',

  // Link
  'LINK_NOT_FOUND': 'Связь не найдена.',
  'LINK_EXISTS': 'Эти узлы уже связаны.',

  // MQTT
  'MQTT_RATE_LIMIT': 'Значения шлют слишком часто. Увеличьте интервал.',
  'MQTT_PAYLOAD_TOO_LARGE': 'Сообщение больше допустимого размера.',
  'MQTT_TOPIC_DOMAIN': 'Топик относится к другому домену, не к этому инстансу.',
  'MQTT_STATE_NO_COMMIT': 'В состоянии юнита нет версии прошивки.',
  'MQTT_PUBLISH_LOOP_NOT_INITIALIZED':
      'MQTT на сервере ещё не запущен. Повторите позже.',
  'MQTT_PUBLISH_DISCONNECTED':
      'Сервер потерял связь с MQTT-брокером. Повторите позже.',
  'MQTT_PUBLISH_TIMEOUT':
      'MQTT-брокер не ответил вовремя: он занят или остановлен.',
  'MQTT_PUBLISH_FAILED': 'Сообщение в MQTT отправить не удалось.',
  'MQTT_SESSION_INVALID':
      'MQTT-сессия сервера повреждена. Сообщите владельцу инстанса.',
  'MQTT_UNIT_TOPIC_ONLY': 'Обмен по топикам доступен только юнитам.',
  'MQTT_TOPIC_STRUCT': 'Топик составлен неверно: ожидается 2 или 3 части.',
  'MQTT_HARDWARE_STATE_INVALID': 'Состояние устройства не читается как JSON.',
  'MQTT_UNIT_LOG_INVALID': 'Лог устройства не читается как JSON.',

  // Notification
  'NOTIFICATION_NOT_FOUND': 'Уведомление не найдено.',
  'NOTIFICATION_TIME_INVALID': 'Время рассылки записывается как ЧЧ:ММ по UTC.',

  // Operation task
  'OPERATION_TASK_COOLDOWN':
      'Это действие недавно уже выполнялось. Подождите и повторите.',
  'OPERATION_TASK_NOT_FOUND': 'Задача не найдена.',

  // Pagination
  'PAGINATION_OFFSET': 'Смещение списка не может быть отрицательным.',
  'PAGINATION_LIMIT_NEGATIVE': 'Размер страницы не может быть отрицательным.',
  'PAGINATION_LIMIT_TOO_LARGE':
      'Размер страницы больше, чем разрешает инстанс.',

  // Peer
  'PEER_NOT_FOUND': 'Пир не найден.',
  'PEER_URL_EXISTS': 'Такой пир уже добавлен.',
  'PEER_URL_SCHEME': 'Адрес пира должен начинаться с http или https.',
  'PEER_URL_HOST': 'В адресе пира нет хоста.',
  'PEER_URL_QUERY': 'В адресе пира не должно быть параметров после «?» и «#».',
  'PEER_URL_CREDENTIALS': 'В адресе пира не должно быть логина и пароля.',
  'PEER_URL_ENDPOINT':
      'Адрес пира должен вести на /instances/current его сервера.',
  'PEER_TRUST_STATUS_INVALID': 'Пира можно только доверить или заблокировать.',
  'PEER_COLLECTION_TRUST':
      'Данные собираются только с доверенных пиров. Сначала доверьте этот.',
  'PEER_COLLECTION_FAILED': 'Не удалось собрать данные с пира.',
  'PEER_RESPONSE_TOO_LARGE': 'Ответ пира больше допустимого размера.',

  // Permission
  'PERMISSION_AGENT_TYPE_INVALID': 'Такого типа доступа не существует.',
  'PERMISSION_RESOURCE_TYPE_INVALID': 'Такого типа ресурса не существует.',
  'PERMISSION_EXISTS': 'Этот доступ уже выдан.',
  'PERMISSION_SELF_ACCESS': 'Доступ ресурса к самому себе убрать нельзя.',
  'PERMISSION_CREATOR_ACCESS':
      'Доступ создателя к своему ресурсу убрать нельзя.',
  'PERMISSION_UNIT_CHILD_IO':
      'Доступ юнита к его собственным узлам убрать нельзя.',
  'PERMISSION_NOT_FOUND': 'Доступ не найден.',
  'PERMISSION_AGENT_UUID_INVALID': 'Идентификатор получателя доступа неверен.',
  'PERMISSION_RESOURCE_UUID_INVALID': 'Идентификатор ресурса неверен.',

  // Readme
  'README_FIELD_TOO_LONG': 'Поле в описании репозитория слишком длинное.',
  'README_FIELD_TOO_MANY_ITEMS':
      'В поле описания репозитория слишком много пунктов.',
  'README_TOML_TOO_LARGE': 'Описание репозитория больше 10 000 символов.',
  'README_TOML_INVALID': 'Описание репозитория записано с ошибкой в TOML.',

  // Repo
  'REPO_URL_EXISTS': 'Репозиторий с таким адресом уже добавлен.',
  'REPO_IS_PUBLIC': 'Репозиторий публичный: токен для него не нужен.',
  'REPO_PLATFORM_UNSUPPORTED':
      'Эта Git-платформа не поддерживается. Выберите из списка.',
  'REPO_SYNC_FAILED':
      'Синхронизация не удалась. Проверьте адрес и токен репозитория.',
  'REPO_URL_INVALID':
      'Адрес репозитория неверен. Он должен оканчиваться на .git и '
      'начинаться с http или https.',
  'REPO_CREDENTIALS_INVALID': 'Токен репозитория не подошёл.',
  'REPO_PUBLIC': 'Репозиторий публичный: токен для него не нужен.',
  'REPO_CREDENTIALS_MISSING': 'Токена для репозитория нет. Добавьте его.',
  'REPO_NO_VALID_CREDENTIALS':
      'Ни один токен не подошёл репозиторию. Проверьте их срок и права.',
  'REPO_SYNC_TOO_SOON':
      'Синхронизация недавно уже была. Подождите и повторите.',
  'REPO_USER_NO_CREDENTIALS': 'У вас нет токена для этого репозитория.',
  'REPO_CREDENTIALS_ERROR':
      'Токен не работает: проверка завершилась ошибкой. Проверьте его права.',
  'REPO_CREDENTIALS_NOT_VERIFIED':
      'Токен ещё не проверен. Проверьте его и повторите.',
  'REPO_NOT_FOUND': 'Репозиторий не найден.',
  'REPO_HAS_UNITS': 'К репозиторию привязаны юниты. Сначала удалите их.',
  'REPO_RELEASES_MISSING':
      'У репозитория нет релизов. Создайте релиз с тегом и повторите.',
  'REPO_RELEASES_JSON_INVALID': 'Список релизов не читается как JSON.',
  'REPO_CREDENTIALS_JSON_INVALID': 'Учётные данные не читаются как JSON.',
  'REPO_PRIVATE_REPO_JSON_INVALID':
      'Данные приватного репозитория не читаются как JSON.',
  'REPO_UUID_INVALID': 'Идентификатор репозитория записан неверно.',

  // Unit
  'UNIT_NOT_FOUND': 'Юнит не найден.',
  'UNIT_NAME_INVALID':
      'Имя должно быть от 4 до 20 символов: латинские буквы, цифры и _ - .',
  'UNIT_AUTOUPDATE_TAGS_ONLY':
      'Скомпилированный юнит автоматически обновляется только до тегов.',
  'UNIT_MANUAL_UPDATE_BRANCH_COMMIT':
      'Для ручного обновления нужно выбрать ветку и коммит.',
  'UNIT_WBITS_INVALID': 'Такого значения сжатия (wbits) нет.',
  'UNIT_LEVEL_INVALID': 'Такого уровня сжатия нет.',
  'UNIT_VISIBILITY_PARENT_BELOW_CHILD':
      'Родитель не может быть закрытее вложенных объектов. Сначала откройте '
      'вложенные или закройте родителя меньше.',
  'UNIT_NAME_NOT_UNIQUE': 'Юнит с таким именем уже есть.',
  'UNIT_UUID_INVALID': 'Идентификатор юнита записан неверно.',

  // Unit group
  'UNIT_GROUP_NOT_FOUND': 'Группа не найдена.',
  'UNIT_GROUP_NAME_INVALID':
      'Имя должно быть от 4 до 20 символов: латинские буквы, цифры и _ - .',
  'UNIT_GROUP_UNIT_ALREADY_IN_GROUP': 'Юнит уже есть в этой группе.',
  'UNIT_GROUP_COUNT_LIMIT': 'Достигнут предел числа групп на инстансе.',
  'UNIT_GROUP_LINK_NOT_FOUND': 'Юнита нет в этой группе.',
  'UNIT_GROUP_NAME_NOT_UNIQUE': 'Группа с таким именем уже есть.',
  'UNIT_GROUP_UUID_INVALID': 'Идентификатор группы записан неверно.',

  // Unit IO
  'UNIT_IO_NOT_FOUND': 'Узел не найден.',
  'UNIT_IO_MAX_CONNECTIONS': 'Допустимое число связей должно быть не меньше 1.',
  'UNIT_IO_INPUT_CONNECTION_LIMIT':
      'У входа уже максимум связей. Увеличьте лимит или уберите лишнюю.',
  'UNIT_IO_OUTPUT_CONNECTION_LIMIT':
      'У выхода уже максимум связей. Увеличьте лимит или уберите лишнюю.',
  'UNIT_IO_NOT_INPUT': 'Этот узел не вход.',
  'UNIT_IO_NOT_OUTPUT': 'Этот узел не выход.',
  'UNIT_IO_STATE_JSON_INVALID': 'Значение узла не читается как JSON.',
  'UNIT_IO_UUID_INVALID': 'Идентификатор узла записан неверно.',
  'UNIT_IO_INPUT_UUID_INVALID': 'Идентификатор входа записан неверно.',
  'UNIT_IO_OUTPUT_UUID_INVALID': 'Идентификатор выхода записан неверно.',

  // User
  'USER_NOT_FOUND': 'Пользователь не найден.',
  'USER_LOGIN_INVALID':
      'Логин должен быть от 4 до 20 символов: латинские буквы, цифры и _ - .',
  'USER_TELEGRAM_ALREADY_LINKED': 'Этот Telegram уже привязан к аккаунту.',
  'USER_PUBLIC_KEY_NOT_UNIQUE':
      'Пользователь с таким ключом уже есть. Войдите вместо регистрации.',
  'USER_COUNT_LIMIT': 'На инстансе достигнут предел числа пользователей.',
  'USER_PUBLIC_KEY_INVALID': 'Открытый ключ записан неверно.',
  'USER_PUBLIC_KEY_HASH_INVALID': 'Хеш открытого ключа записан неверно.',
  'USER_VERIFICATION_CODE_NOT_FOUND':
      'Код подтверждения не найден: он устарел или уже использован.',
  'USER_UUID_INVALID': 'Идентификатор пользователя записан неверно.',
};

const _en = <String, String>{
  // Access
  'ACCESS_TOKEN_EXPIRED':
      'The session has expired. Sign in to the instance again.',
  'ACCESS_TOKEN_INVALID':
      'The server did not accept the sign-in token. Sign in to the instance '
      'again.',
  'ACCESS_AGENT_BLOCKED_OR_NOT_FOUND':
      'The account is blocked or deleted on this instance.',
  'ACCESS_USER_BLOCKED': 'The user is blocked by the instance owner.',
  'ACCESS_USER_NOT_FOUND': 'User not found.',
  'ACCESS_UNIT_NOT_FOUND': 'Unit not found.',
  'ACCESS_INVALID_AGENT_TYPE':
      'The server could not tell who sent the request.',
  'ACCESS_UNKNOWN_AGENT_TYPE':
      'The server could not tell who sent the request.',
  'ACCESS_AGENT_TYPE_NOT_ALLOWED':
      'This action is not available for this type of access: it is for '
      'users only or for units only.',
  'ACCESS_ROLE_NOT_ALLOWED':
      'This action needs a different role. Contact the instance owner.',
  'ACCESS_NOT_CREATOR': 'Only the creator of an object can change it.',
  'ACCESS_UNIT_REQUEST_DENIED':
      'The unit has no access to this data. Grant access in the unit '
      'settings.',
  'ACCESS_UNIT_INPUT_DENIED':
      'The unit cannot write to this input: it is not rewritable.',
  'ACCESS_VISIBILITY_LEVEL_NOT_ALLOWED':
      'This visibility level is not allowed here.',
  'ACCESS_PRIVATE_REPO': 'A private repository is not allowed here.',
  'ACCESS_PRIVATE_VISIBILITY':
      'The private visibility level is not allowed here.',
  'ACCESS_REPO_ONLY': 'The action applies to a repository only.',
  'ACCESS_REPO_USERS_ONLY':
      'Repository operations are available to users only, not to units.',
  'ACCESS_REPO_NO_CREDENTIALS':
      'The repository has no credentials. Add an access token for it.',
  'ACCESS_NO_PLATFORM_CREDENTIALS':
      'You have no Git platform token. Add one in your credentials.',
  'ACCESS_PLATFORM_CREDENTIALS_STATUS':
      'The Git platform token does not fit: it is not verified or has an '
      'error.',
  'ACCESS_NOTIFICATION_NOT_ALLOWED':
      'No access to this notification: it belongs to another user.',
  'ACCESS_ICON_OWNER_ONLY': 'Only its owner can change this icon.',
  'ACCESS_DOCKED_UNIT_ONLY':
      'Available only to the unit that the topic belongs to.',
  'ACCESS_TOPIC_DESTINATION_INVALID': 'This topic type does not exist.',
  'ACCESS_CHALLENGE_INVALID': 'Sign-in failed: the key check is corrupted.',
  'ACCESS_CHALLENGE_DOMAIN_MISMATCH':
      'Sign-in failed: the check was issued for another instance address.',
  'ACCESS_CHALLENGE_USED_OR_EXPIRED':
      'Sign-in failed: the key check was already used or has expired. Sign '
      'in again.',
  'ACCESS_CHALLENGE_EXPIRED': 'The key check has expired. Sign in again.',
  'ACCESS_SIGNATURE_MISMATCH':
      'The signature does not match: the key in the client differs from the '
      'key of the account.',

  // Cipher
  'CIPHER_CONTENT_TOO_LONG': 'The text to encrypt is longer than allowed.',
  'CIPHER_ENV_JSON_INVALID':
      'The environment variables cannot be read as JSON.',

  // Dashboard
  'DASHBOARD_NOT_FOUND': 'Dashboard not found.',
  'DASHBOARD_PANEL_NOT_FOUND': 'Panel not found.',
  'PANELS_UNIT_IOS_NOT_FOUND': 'The node is not connected to this panel.',
  'DASHBOARD_UUID_INVALID': 'The dashboard identifier is written incorrectly.',

  // DataPipe
  'DATAPIPE_BULK_CREATE_LAST_VALUE_UNAVAILABLE':
      'Many records cannot be uploaded at once for the "last value" type.',
  'DATAPIPE_NO_DATA': 'There is no data for this period.',
  'DATAPIPE_TOPIC_SUFFIX':
      'DataPipe can be enabled only for a topic that ends with /pepeunit.',
  'DATAPIPE_NOT_ACTIVE': 'DataPipe is off. Turn it on first.',
  'DATAPIPE_NOT_FILLED': 'The DataPipe config is empty. Fill it in first.',
  'DATAPIPE_LAST_VALUE_UNSUPPORTED':
      'The "last value" type does not fit this action.',
  'DATAPIPE_IS_NONE': 'This node has no DataPipe.',
  'DATAPIPE_CONFIG_INVALID': 'The DataPipe config did not pass validation.',
  'DATAPIPE_CONFIG_JSON_INVALID': 'The DataPipe config cannot be read as YAML.',
  'DATAPIPE_ACTIVE_FROM_DATE_START': 'The "from date" period needs a start.',
  'DATAPIPE_ACTIVE_TO_DATE_END': 'The "to date" period needs an end.',
  'DATAPIPE_ACTIVE_RANGE_BOUNDS':
      'The "date range" period needs both a start and an end.',
  'DATAPIPE_ACTIVE_RANGE_ORDER': 'The period must start before it ends.',
  'DATAPIPE_FILTER_VALUES_NUMBER':
      'For a numeric input the filter values must be numbers.',
  'DATAPIPE_FILTER_VALUES_TEXT':
      'For a text input the filter values must be strings.',
  'DATAPIPE_THRESHOLD_MIN_REQUIRED':
      'The "minimum" threshold needs a lower bound.',
  'DATAPIPE_THRESHOLD_MAX_REQUIRED':
      'The "maximum" threshold needs an upper bound.',
  'DATAPIPE_THRESHOLD_RANGE_REQUIRED':
      'The "range" threshold needs both bounds: lower and upper.',
  'DATAPIPE_THRESHOLD_RANGE_ORDER':
      'The lower bound of the threshold must be less than the upper one.',
  'DATAPIPE_MAX_SIZE': 'The maximum record size is larger than allowed.',
  'DATAPIPE_N_RECORDS_REQUIRED':
      'The "N records" policy needs the number of records.',
  'DATAPIPE_N_RECORDS_RANGE': 'The number of records must be from 1 to 1024.',
  'DATAPIPE_TIME_WINDOW_REQUIRED': 'The size of the time window is required.',
  'DATAPIPE_TIME_WINDOW_INVALID':
      'There is no such window size. Pick one from the list.',
  'DATAPIPE_AGGREGATION_FUNCTIONS_REQUIRED':
      'Aggregation needs at least one function.',
  'DATAPIPE_FILTERING_VALUES_REQUIRED': 'The chosen filtering needs values.',
  'DATAPIPE_THRESHOLD_NOT_FOR_TEXT':
      'A threshold does not apply to a text input, only to numbers.',
  'DATAPIPE_CSV_WINDOW_DATETIME':
      'In the CSV the record time is outside the allowed window.',
  'DATAPIPE_CSV_N_RECORDS_LIMIT':
      'The CSV has more records than the config allows.',
  'DATAPIPE_CSV_WINDOW_SECONDS':
      'In the CSV the window bounds must have no seconds.',
  'DATAPIPE_CSV_WINDOW_ORDER': 'In the CSV the window ends before it starts.',
  'DATAPIPE_CSV_WINDOW_MIN_DELTA':
      'In the CSV the record time is too far from the end of the window.',
  'DATAPIPE_CSV_WINDOW_SIZE_MISMATCH':
      'In the CSV the window length differs from the window size in the '
      'config.',
  'DATAPIPE_CSV_PREVIOUS_WINDOW_SIZE':
      'In the CSV the windows are not consecutive: there is a gap or an '
      'overlap.',
  'DATAPIPE_CSV_MAX_RATE':
      'In the CSV the records come more often than the config allows.',
  'DATAPIPE_CSV_LAST_UNIQUE':
      'In the CSV a value repeats the previous one, and the config skips '
      'repeats.',
  'DATAPIPE_CSV_MAX_SIZE': 'In the CSV a value is longer than allowed.',
  'DATAPIPE_CSV_NOT_MONOTONIC': 'In the CSV the record times do not increase.',
  'DATAPIPE_CSV_BEFORE_ACTIVE_START':
      'In the CSV a record is before the start of the DataPipe period.',
  'DATAPIPE_CSV_AFTER_ACTIVE_END':
      'In the CSV a record is after the end of the DataPipe period.',
  'DATAPIPE_CSV_OUTSIDE_ACTIVE_RANGE':
      'In the CSV a record is outside the DataPipe period.',
  'DATAPIPE_CSV_NOT_IN_WHITELIST':
      'In the CSV a value is not in the whitelist of the config.',
  'DATAPIPE_CSV_IN_BLACKLIST':
      'In the CSV a value is in the blacklist of the config.',
  'DATAPIPE_CSV_BELOW_THRESHOLD':
      'In the CSV a value is below the lower threshold.',
  'DATAPIPE_CSV_ABOVE_THRESHOLD':
      'In the CSV a value is above the upper threshold.',
  'DATAPIPE_CSV_OUTSIDE_THRESHOLD':
      'In the CSV a value is outside the thresholds of the config.',
  'DATAPIPE_CSV_STATE_NOT_TEXT': 'In the CSV the value must be text.',
  'DATAPIPE_CSV_STATE_NOT_NUMBER': 'In the CSV the value must be a number.',
  'DATAPIPE_CSV_DATETIME_INVALID':
      'In the CSV a date is written incorrectly. The ISO format is needed, '
      'for example 2026-01-31T12:00:00.',
  'DATAPIPE_RELATIVE_TIME_INVALID':
      'There is no such relative interval. Pick one from the list.',

  // Feature flag
  'FEATURE_DISABLED': 'The instance owner turned this feature off.',

  // Git platform
  'GIT_PLATFORM_TIMEOUT':
      'The Git platform did not answer in time. Try again later.',
  'GIT_PLATFORM_REQUEST_FAILED':
      'The request to the Git platform failed. Check the repository address '
      'and try again later.',
  'GIT_PLATFORM_INVALID_CREDENTIALS':
      'The Git platform did not accept the token. It is wrong or has '
      'expired.',
  'GIT_PLATFORM_RATE_LIMIT':
      'The Git platform limited the number of requests. Wait and try again.',

  // Git repository
  'GIT_REPO_VERSION_MISSING':
      'The repository has no version tags, so a version cannot be chosen.',
  'GIT_REPO_COMMIT_WITHOUT_TAG':
      'This commit has no tag. Choose a commit with a tag.',
  'GIT_REPO_COMMIT_NOT_FOUND': 'There is no such commit in the repository.',
  'GIT_REPO_SCHEMA_UNRESOLVED_KEYS':
      'schema.json still has keys with no description of inputs or outputs.',
  'GIT_REPO_SCHEMA_VALUE_TYPE':
      'In schema.json the topic values must be lists only.',
  'GIT_REPO_TOPIC_CHARS':
      'In schema.json a topic has forbidden characters. Latin letters, '
      'digits and / _ - are allowed.',
  'GIT_REPO_TOPIC_TOO_LONG': 'In schema.json a topic name is too long.',
  'GIT_REPO_ENV_UNRESOLVED':
      'env.json still has variables without a value. Fill them in.',
  'GIT_REPO_BRANCH_NOT_FOUND': 'There is no such branch in the repository.',
  'GIT_REPO_COMMIT_NOT_IN_BRANCH': 'This commit is not in the chosen branch.',
  'GIT_REPO_TAG_NO_PLATFORMS':
      'The chosen tag has no built platforms. Choose another tag.',
  'GIT_REPO_PLATFORM_NOT_FOUND':
      'This tag has no such platform. Choose from the available ones.',
  'GIT_REPO_NOT_EXIST':
      'The repository is not downloaded to the server. Start a sync.',
  'GIT_REPO_INVALID_URL_OR_CREDENTIALS':
      'The repository address or the token is wrong, or the token has no '
      'access.',
  'GIT_REPO_FILE_NOT_FOUND': 'This commit does not have the needed file.',
  'GIT_REPO_TOO_LARGE': 'The repository is larger than the allowed size.',
  'GIT_REPO_SCHEMA_JSON_INVALID':
      'schema.json in the repository cannot be read.',
  'GIT_REPO_ENV_EXAMPLE_JSON_INVALID':
      'env_example.json in the repository cannot be read.',
  'GIT_REPO_ENV_JSON_INVALID': 'env.json cannot be read as JSON.',
  'GIT_REPO_COMMIT_MISSING': 'The commit is not found in the repository.',

  // Grafana
  'GRAFANA_NAME_INVALID':
      'The name must be 4 to 20 characters: Latin letters, digits and _ - .',
  'GRAFANA_TITLE_INVALID':
      'The title must be 4 to 20 characters: Latin letters, digits and '
      '_ - .',
  'GRAFANA_UNIT_IO_NOT_UNIQUE': 'This node is already on the panel.',
  'GRAFANA_PANEL_UNIT_IO_LIMIT': 'A panel cannot hold more nodes.',
  'GRAFANA_RETRIES_EXHAUSTED':
      'Grafana does not answer. The attempts ran out, try again later.',
  'GRAFANA_VALUE_NOT_SUPPORTED': 'Grafana cannot show this value.',
  'GRAFANA_DATA_TYPE_NOT_SUPPORTED':
      'This data type cannot be shown on a panel.',
  'GRAFANA_DASHBOARD_HAS_NO_PANELS':
      'The dashboard has no panels. Add at least one first.',
  'GRAFANA_NO_ACTIVE_DATAPIPE':
      'The node has no active DataPipe, and the panel needs it.',
  'GRAFANA_INVALID_DATAPIPE_YML':
      'The node has an invalid DataPipe config, the panel cannot read it.',
  'GRAFANA_NAME_NOT_UNIQUE': 'A dashboard with this name already exists.',
  'GRAFANA_TITLE_NOT_UNIQUE': 'A dashboard with this title already exists.',

  // Icon
  'ICON_TOO_LARGE': 'The picture is larger than 128 KB.',
  'ICON_NOT_PNG': 'A PNG file is needed.',
  'ICON_WRONG_SIZE': 'The picture must be 192×192 pixels.',
  'ICON_TARGET_UNSUPPORTED': 'An icon cannot be set for this object.',
  'ICON_NOT_FOUND': 'Icon not found.',

  // Instance
  'INSTANCE_CACHE_NOT_INITIALIZED':
      'The instance is still starting. Wait a little and try again.',
  'INSTANCE_INTEGRATION_TESTS_FAILED':
      'The instance check failed. See the server logs for details.',
  'INSTANCE_SETTINGS_NOT_FOUND': 'Setting not found.',
  'INSTANCE_SETTINGS_INVALID': 'The setting value did not pass validation.',
  'INSTANCE_SETTINGS_EMAIL_INVALID':
      'The owner email is written incorrectly. Enter an address or leave it '
      'empty.',
  'INSTANCE_SETTINGS_TELEGRAM_TOKEN_INVALID':
      'The Telegram bot token must look like 123456:ABC-def or be empty.',
  'INSTANCE_SETTINGS_COUNT_RATE_INVALID':
      'The limit is written as 20/s or 20/m: a number per second or per '
      'minute.',
  'INSTANCE_SETTINGS_BYTES_RATE_INVALID':
      'The limit is written as 1MB/s: a size per second.',
  'INSTANCE_SETTINGS_GRAFANA_CREDENTIALS':
      'Grafana cannot be turned on: the server has no login and password of '
      'its administrator.',
  'INSTANCE_SETTINGS_GITHUB_TOKEN_PAIR':
      'The GitHub name and token go together: fill in both fields or clear '
      'both.',

  // Link
  'LINK_NOT_FOUND': 'Link not found.',
  'LINK_EXISTS': 'These nodes are already linked.',

  // MQTT
  'MQTT_RATE_LIMIT': 'Values are sent too often. Increase the interval.',
  'MQTT_PAYLOAD_TOO_LARGE': 'The message is larger than allowed.',
  'MQTT_TOPIC_DOMAIN':
      'The topic belongs to another domain, not to this instance.',
  'MQTT_STATE_NO_COMMIT': 'The unit state has no firmware version.',
  'MQTT_PUBLISH_LOOP_NOT_INITIALIZED':
      'MQTT on the server is not running yet. Try again later.',
  'MQTT_PUBLISH_DISCONNECTED':
      'The server lost the connection to the MQTT broker. Try again later.',
  'MQTT_PUBLISH_TIMEOUT':
      'The MQTT broker did not answer in time: it is busy or stopped.',
  'MQTT_PUBLISH_FAILED': 'The message could not be sent to MQTT.',
  'MQTT_SESSION_INVALID':
      'The MQTT session of the server is corrupted. Tell the instance owner.',
  'MQTT_UNIT_TOPIC_ONLY': 'Topic exchange is available to units only.',
  'MQTT_TOPIC_STRUCT': 'The topic is built incorrectly: 2 or 3 parts expected.',
  'MQTT_HARDWARE_STATE_INVALID': 'The device state cannot be read as JSON.',
  'MQTT_UNIT_LOG_INVALID': 'The device log cannot be read as JSON.',

  // Notification
  'NOTIFICATION_NOT_FOUND': 'Notification not found.',
  'NOTIFICATION_TIME_INVALID': 'The delivery time is written as HH:MM in UTC.',

  // Operation task
  'OPERATION_TASK_COOLDOWN':
      'This action was done recently. Wait and try again.',
  'OPERATION_TASK_NOT_FOUND': 'Task not found.',

  // Pagination
  'PAGINATION_OFFSET': 'The list offset cannot be negative.',
  'PAGINATION_LIMIT_NEGATIVE': 'The page size cannot be negative.',
  'PAGINATION_LIMIT_TOO_LARGE':
      'The page size is larger than the instance allows.',

  // Peer
  'PEER_NOT_FOUND': 'Peer not found.',
  'PEER_URL_EXISTS': 'This peer is already added.',
  'PEER_URL_SCHEME': 'The peer address must start with http or https.',
  'PEER_URL_HOST': 'The peer address has no host.',
  'PEER_URL_QUERY': 'The peer address must have no parameters after ? and #.',
  'PEER_URL_CREDENTIALS': 'The peer address must have no login and password.',
  'PEER_URL_ENDPOINT':
      'The peer address must lead to /instances/current of its server.',
  'PEER_TRUST_STATUS_INVALID': 'A peer can only be trusted or blocked.',
  'PEER_COLLECTION_TRUST':
      'Data is collected from trusted peers only. Trust this one first.',
  'PEER_COLLECTION_FAILED': 'Data could not be collected from the peer.',
  'PEER_RESPONSE_TOO_LARGE': 'The peer answer is larger than allowed.',

  // Permission
  'PERMISSION_AGENT_TYPE_INVALID': 'This access type does not exist.',
  'PERMISSION_RESOURCE_TYPE_INVALID': 'This resource type does not exist.',
  'PERMISSION_EXISTS': 'This access is already granted.',
  'PERMISSION_SELF_ACCESS':
      'The access of a resource to itself cannot be removed.',
  'PERMISSION_CREATOR_ACCESS':
      'The access of the creator to their resource cannot be removed.',
  'PERMISSION_UNIT_CHILD_IO':
      'The access of a unit to its own nodes cannot be removed.',
  'PERMISSION_NOT_FOUND': 'Access not found.',
  'PERMISSION_AGENT_UUID_INVALID':
      'The identifier of the access recipient is wrong.',
  'PERMISSION_RESOURCE_UUID_INVALID': 'The resource identifier is wrong.',

  // Readme
  'README_FIELD_TOO_LONG': 'A field in the repository description is too long.',
  'README_FIELD_TOO_MANY_ITEMS':
      'A field in the repository description has too many items.',
  'README_TOML_TOO_LARGE':
      'The repository description is larger than 10,000 characters.',
  'README_TOML_INVALID': 'The repository description has a TOML syntax error.',

  // Repo
  'REPO_URL_EXISTS': 'A repository with this address is already added.',
  'REPO_IS_PUBLIC': 'The repository is public: it needs no token.',
  'REPO_PLATFORM_UNSUPPORTED':
      'This Git platform is not supported. Choose from the list.',
  'REPO_SYNC_FAILED':
      'The sync failed. Check the repository address and token.',
  'REPO_URL_INVALID':
      'The repository address is wrong. It must end with .git and start '
      'with http or https.',
  'REPO_CREDENTIALS_INVALID': 'The repository token did not fit.',
  'REPO_PUBLIC': 'The repository is public: it needs no token.',
  'REPO_CREDENTIALS_MISSING': 'The repository has no token. Add one.',
  'REPO_NO_VALID_CREDENTIALS':
      'No token fit the repository. Check their expiry and permissions.',
  'REPO_SYNC_TOO_SOON': 'A sync was done recently. Wait and try again.',
  'REPO_USER_NO_CREDENTIALS': 'You have no token for this repository.',
  'REPO_CREDENTIALS_ERROR':
      'The token does not work: the check ended with an error. Check its '
      'permissions.',
  'REPO_CREDENTIALS_NOT_VERIFIED':
      'The token is not verified yet. Verify it and try again.',
  'REPO_NOT_FOUND': 'Repository not found.',
  'REPO_HAS_UNITS': 'The repository has linked units. Delete them first.',
  'REPO_RELEASES_MISSING':
      'The repository has no releases. Create a release with a tag and try '
      'again.',
  'REPO_RELEASES_JSON_INVALID': 'The list of releases cannot be read as JSON.',
  'REPO_CREDENTIALS_JSON_INVALID': 'The credentials cannot be read as JSON.',
  'REPO_PRIVATE_REPO_JSON_INVALID':
      'The private repository data cannot be read as JSON.',
  'REPO_UUID_INVALID': 'The repository identifier is written incorrectly.',

  // Unit
  'UNIT_NOT_FOUND': 'Unit not found.',
  'UNIT_NAME_INVALID':
      'The name must be 4 to 20 characters: Latin letters, digits and _ - .',
  'UNIT_AUTOUPDATE_TAGS_ONLY':
      'A compiled unit updates automatically only to tags.',
  'UNIT_MANUAL_UPDATE_BRANCH_COMMIT':
      'A manual update needs a branch and a commit.',
  'UNIT_WBITS_INVALID': 'There is no such compression value (wbits).',
  'UNIT_LEVEL_INVALID': 'There is no such compression level.',
  'UNIT_VISIBILITY_PARENT_BELOW_CHILD':
      'A parent cannot be more closed than its nested objects. Open the '
      'nested ones first or make the parent less closed.',
  'UNIT_NAME_NOT_UNIQUE': 'A unit with this name already exists.',
  'UNIT_UUID_INVALID': 'The unit identifier is written incorrectly.',

  // Unit group
  'UNIT_GROUP_NOT_FOUND': 'Group not found.',
  'UNIT_GROUP_NAME_INVALID':
      'The name must be 4 to 20 characters: Latin letters, digits and _ - .',
  'UNIT_GROUP_UNIT_ALREADY_IN_GROUP': 'The unit is already in this group.',
  'UNIT_GROUP_COUNT_LIMIT': 'The limit of groups on the instance is reached.',
  'UNIT_GROUP_LINK_NOT_FOUND': 'The unit is not in this group.',
  'UNIT_GROUP_NAME_NOT_UNIQUE': 'A group with this name already exists.',
  'UNIT_GROUP_UUID_INVALID': 'The group identifier is written incorrectly.',

  // Unit IO
  'UNIT_IO_NOT_FOUND': 'Node not found.',
  'UNIT_IO_MAX_CONNECTIONS': 'The allowed number of links must be at least 1.',
  'UNIT_IO_INPUT_CONNECTION_LIMIT':
      'The input already has the maximum of links. Raise the limit or '
      'remove one.',
  'UNIT_IO_OUTPUT_CONNECTION_LIMIT':
      'The output already has the maximum of links. Raise the limit or '
      'remove one.',
  'UNIT_IO_NOT_INPUT': 'This node is not an input.',
  'UNIT_IO_NOT_OUTPUT': 'This node is not an output.',
  'UNIT_IO_STATE_JSON_INVALID': 'The node value cannot be read as JSON.',
  'UNIT_IO_UUID_INVALID': 'The node identifier is written incorrectly.',
  'UNIT_IO_INPUT_UUID_INVALID': 'The input identifier is written incorrectly.',
  'UNIT_IO_OUTPUT_UUID_INVALID':
      'The output identifier is written incorrectly.',

  // User
  'USER_NOT_FOUND': 'User not found.',
  'USER_LOGIN_INVALID':
      'The login must be 4 to 20 characters: Latin letters, digits and _ - .',
  'USER_TELEGRAM_ALREADY_LINKED':
      'This Telegram is already linked to an account.',
  'USER_PUBLIC_KEY_NOT_UNIQUE':
      'A user with this key already exists. Sign in instead of registering.',
  'USER_COUNT_LIMIT': 'The limit of users on the instance is reached.',
  'USER_PUBLIC_KEY_INVALID': 'The public key is written incorrectly.',
  'USER_PUBLIC_KEY_HASH_INVALID':
      'The hash of the public key is written incorrectly.',
  'USER_VERIFICATION_CODE_NOT_FOUND':
      'The verification code is not found: it has expired or was already '
      'used.',
  'USER_UUID_INVALID': 'The user identifier is written incorrectly.',
};
