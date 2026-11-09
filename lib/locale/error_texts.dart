/// What the user reads for a backend error code. Keys are the code names the
/// backend lists at `/error_codes` (`ErrorCode` there); the number comes from
/// that route, so a renumbered code keeps its text.
///
/// A line is short and says why it happened. To add a language, append one
/// more outer key. A missing line falls back to Russian, then to the generic
/// text of the status (see `describeFailure`).
const errorTexts = <String, Map<String, String>>{'ru': _ru};

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
