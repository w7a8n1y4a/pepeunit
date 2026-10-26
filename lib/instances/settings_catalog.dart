import '../locale/languages.dart';

class SettingField {
  const SettingField(
    this.key, {
    required this.kind,
    this.titles = const {},
    this.min,
    this.max,
    this.options = const [],
    this.nullable = false,
    this.hint,
  });

  final String key;

  /// `bool`, `int`, `number`, `text`, or `enum`.
  final String kind;
  final Map<String, String> titles;
  final num? min;
  final num? max;
  final List<String> options;
  final bool nullable;
  final String? hint;

  String label([String language = 'en']) {
    if (titles.isNotEmpty) return phrase(language, titles);
    return key.replaceFirst(RegExp(r'^pu_'), '').replaceAll('_', ' ');
  }

  String? rangeHint() {
    if (hint != null && hint!.isNotEmpty) return hint;
    if (min != null && max != null) return '$min..$max';
    return null;
  }
}

class SettingCategory {
  const SettingCategory({
    required this.id,
    required this.titles,
    required this.fields,
    this.icon = 'assets/icons/settings.svg',
  });

  final String id;
  final Map<String, String> titles;
  final List<SettingField> fields;
  final String icon;
}

class SettingGroup {
  const SettingGroup({
    required this.id,
    required this.titles,
    required this.icon,
    required this.categoryIds,
  });

  final String id;
  final Map<String, String> titles;
  final String icon;
  final List<String> categoryIds;
}

const _bool = 'bool';
const _int = 'int';
const _num = 'number';
const _text = 'text';

SettingField _flag(String key, String ru, String en) =>
    SettingField(key, kind: _bool, titles: {'ru': ru, 'en': en});

SettingField _whole(
  String key,
  num min,
  num max, {
  required String ru,
  required String en,
}) => SettingField(
  key,
  kind: _int,
  min: min,
  max: max,
  titles: {'ru': ru, 'en': en},
);

SettingField _real(
  String key,
  num min,
  num max, {
  required String ru,
  required String en,
  bool nullable = false,
}) => SettingField(
  key,
  kind: _num,
  min: min,
  max: max,
  nullable: nullable,
  titles: {'ru': ru, 'en': en},
);

SettingField _line(
  String key, {
  required String ru,
  required String en,
  String? hint,
}) => SettingField(
  key,
  kind: _text,
  titles: {'ru': ru, 'en': en},
  hint: hint,
);

/// One cell per category. Every category has at most six fields so its fields
/// fit on a single first-ring hex cluster around Back.
final settingCategories = <SettingCategory>[
  SettingCategory(
    id: 'flags',
    titles: {'ru': 'Флаги', 'en': 'Flags'},
    icon: 'assets/icons/check.svg',
    fields: [
      _flag('pu_ff_datapipe_enable', 'DataPipe', 'DataPipe'),
      _flag('pu_ff_federation_enable', 'Федерация', 'Federation'),
      _flag('pu_ff_grafana_integration_enable', 'Grafana', 'Grafana'),
      _flag('pu_ff_notification_enable', 'Уведомления', 'Alerts'),
      _flag('pu_ff_prometheus_enable', 'Prometheus', 'Prometheus'),
      _flag('pu_ff_telegram_bot_enable', 'Telegram бот', 'Telegram bot'),
    ],
  ),
  SettingCategory(
    id: 'contacts',
    titles: {'ru': 'Контакты', 'en': 'Contacts'},
    icon: 'assets/icons/send.svg',
    fields: [
      _line(
        'pu_instance_owner_email',
        ru: 'Email владельца',
        en: 'Owner email',
        hint: 'mail@host',
      ),
      _line(
        'pu_instance_owner_tg',
        ru: 'Telegram контакт',
        en: 'Owner Telegram',
        hint: '@username',
      ),
      _real(
        'pu_instance_lat',
        -90,
        90,
        ru: 'Широта',
        en: 'Latitude',
        nullable: true,
      ),
      _real(
        'pu_instance_lon',
        -180,
        180,
        ru: 'Долгота',
        en: 'Longitude',
        nullable: true,
      ),
    ],
  ),
  SettingCategory(
    id: 'users',
    titles: {'ru': 'Пользователи', 'en': 'Users'},
    icon: 'assets/icons/account.svg',
    fields: [
      _whole(
        'pu_instance_user_max_count',
        1,
        1000000,
        ru: 'Макс. юзеров',
        en: 'Max users',
      ),
      _whole(
        'pu_instance_user_max_group',
        8,
        32,
        ru: 'Макс. групп',
        en: 'Max groups',
      ),
      _whole(
        'pu_instance_user_auth_token_expiration',
        600,
        11059200,
        ru: 'Срок токена (с)',
        en: 'Token TTL (s)',
      ),
    ],
  ),
  SettingCategory(
    id: 'federation',
    titles: {'ru': 'Федерация', 'en': 'Federation'},
    icon: 'assets/icons/instances.svg',
    fields: [
      _whole(
        'pu_instance_retention_days',
        1,
        120,
        ru: 'Хранение пиров (дн)',
        en: 'Retention (days)',
      ),
      _whole(
        'pu_instance_max_state_size',
        4096,
        65536,
        ru: 'Макс. стейт (Б)',
        en: 'Max state (B)',
      ),
      _whole(
        'pu_instance_max_pagination_size',
        1,
        500,
        ru: 'Пагинация',
        en: 'Pagination size',
      ),
      _real(
        'pu_instance_http_timeout',
        1,
        120,
        ru: 'HTTP таймаут (с)',
        en: 'HTTP timeout (s)',
      ),
      _real(
        'pu_instance_http_connect_timeout',
        1,
        60,
        ru: 'Таймаут соед. (с)',
        en: 'Connect timeout',
      ),
      _whole(
        'pu_instance_cipher_max_length',
        0,
        5000000,
        ru: 'Лимит шифра (Б)',
        en: 'Cipher max (B)',
      ),
    ],
  ),
  SettingCategory(
    id: 'repos',
    titles: {'ru': 'Репозитории', 'en': 'Repositories'},
    icon: 'assets/icons/copy.svg',
    fields: [
      _whole(
        'pu_instance_repo_max_size',
        0,
        1024,
        ru: 'Макс. репо (МБ)',
        en: 'Max repo (MB)',
      ),
      _whole(
        'pu_instance_repo_min_interval_sync',
        1,
        1800,
        ru: 'Интервал синка (с)',
        en: 'Sync interval (s)',
      ),
      _whole(
        'pu_instance_unit_state_send_interval',
        1,
        600,
        ru: 'Отправка стейта (с)',
        en: 'State interval (s)',
      ),
      _whole(
        'pu_instance_unit_log_expiration',
        60,
        604800,
        ru: 'Срок логов (с)',
        en: 'Log TTL (s)',
      ),
    ],
  ),
  SettingCategory(
    id: 'datapipe',
    titles: {'ru': 'DataPipe', 'en': 'DataPipe'},
    icon: 'assets/icons/panel.svg',
    fields: [
      _flag(
        'pu_datapipe_default_last_value_enable',
        'Посл. значение',
        'Default last value',
      ),
      _whole(
        'pu_datapipe_limit_unit_io_per_one_panel',
        1,
        32,
        ru: 'UnitIO на панель',
        en: 'UnitIO per panel',
      ),
      _whole(
        'pu_datapipe_buffer_max_size',
        1,
        1000000,
        ru: 'Буфер Pipe',
        en: 'Buffer max size',
      ),
      _whole(
        'pu_datapipe_mqtt_keepalive',
        0,
        600,
        ru: 'Keepalive (с)',
        en: 'Keepalive (s)',
      ),
    ],
  ),
  SettingCategory(
    id: 'datapipe-time',
    titles: {'ru': 'DataPipe время', 'en': 'DataPipe time'},
    icon: 'assets/icons/reload.svg',
    fields: [
      _whole(
        'pu_datapipe_buffer_flush_interval',
        1,
        3600,
        ru: 'Сброс буфера (с)',
        en: 'Buffer flush (s)',
      ),
      _whole(
        'pu_datapipe_config_sync_interval',
        1,
        86400,
        ru: 'Синк конфига (с)',
        en: 'Config sync (s)',
      ),
      _whole(
        'pu_datapipe_nrecords_cleanup_interval',
        1,
        604800,
        ru: 'Очистка записей (с)',
        en: 'Cleanup (s)',
      ),
    ],
  ),
  SettingCategory(
    id: 'mqtt',
    titles: {'ru': 'MQTT', 'en': 'MQTT'},
    icon: 'assets/icons/micro.svg',
    fields: [
      _whole(
        'pu_mqtt_keepalive',
        0,
        600,
        ru: 'Keepalive (с)',
        en: 'Keepalive (s)',
      ),
      _whole(
        'pu_mqtt_max_clients',
        1,
        1024,
        ru: 'Макс. клиентов',
        en: 'Max clients',
      ),
      _whole('pu_mqtt_max_qos', 0, 2, ru: 'Макс. QoS', en: 'Max QoS'),
      _line(
        'pu_mqtt_client_max_messages_rate',
        ru: 'Лимит сообщ.',
        en: 'Messages rate',
        hint: '30/s',
      ),
      _line(
        'pu_mqtt_client_max_bytes_rate',
        ru: 'Лимит трафика',
        en: 'Bytes rate',
        hint: '1MB/s',
      ),
      _line(
        'pu_mqtt_max_client_connection_rate',
        ru: 'Лимит подключ.',
        en: 'Connect rate',
        hint: '20/s',
      ),
    ],
  ),
  SettingCategory(
    id: 'mqtt-size',
    titles: {'ru': 'MQTT размеры', 'en': 'MQTT sizes'},
    icon: 'assets/icons/settings.svg',
    fields: [
      _whole(
        'pu_mqtt_max_client_id_len',
        1,
        1024,
        ru: 'Длина Client ID',
        en: 'Client ID len',
      ),
      _whole(
        'pu_mqtt_max_len_message_queue',
        1,
        1024,
        ru: 'Очередь сообщ.',
        en: 'Queue length',
      ),
      _whole(
        'pu_mqtt_max_payload_size',
        1,
        4096,
        ru: 'Payload (Б)',
        en: 'Payload size (B)',
      ),
      _whole(
        'pu_mqtt_max_topic_alias',
        0,
        256,
        ru: 'Topic alias',
        en: 'Topic aliases',
      ),
      _whole(
        'pu_mqtt_max_topic_levels',
        5,
        32,
        ru: 'Уровни топика',
        en: 'Topic levels',
      ),
    ],
  ),
  SettingCategory(
    id: 'notifications',
    titles: {'ru': 'Уведомления', 'en': 'Notifications'},
    icon: 'assets/icons/notifications.svg',
    fields: [
      _whole(
        'pu_notification_data_pipe_alert_batch',
        1,
        1000,
        ru: 'Пачка алертов',
        en: 'Alert batch',
      ),
      _whole(
        'pu_notification_small_text_limit',
        1,
        96,
        ru: 'Короткий текст',
        en: 'Short text len',
      ),
      _whole(
        'pu_notification_stream_maxlen',
        1,
        10000,
        ru: 'Буфер стрима',
        en: 'Stream maxlen',
      ),
      _whole(
        'pu_notification_telegram_alert_text_limit',
        1,
        4096,
        ru: 'Лимит текста TG',
        en: 'TG alert len',
      ),
      _whole(
        'pu_notification_telegram_instance_rate',
        1,
        30,
        ru: 'Частота TG инст.',
        en: 'TG instance rate',
      ),
      _real(
        'pu_notification_telegram_user_interval_seconds',
        1,
        60,
        ru: 'Интервал TG (с)',
        en: 'TG user interval',
      ),
    ],
  ),
  SettingCategory(
    id: 'telegram',
    titles: {'ru': 'Telegram', 'en': 'Telegram'},
    icon: 'assets/icons/send.svg',
    fields: [
      _line(
        'pu_telegram_bot_link',
        ru: 'Ссылка на бота',
        en: 'Bot link',
        hint: 'https://t.me/bot',
      ),
      const SettingField(
        'pu_telegram_bot_mode',
        kind: 'enum',
        titles: {'ru': 'Режим бота', 'en': 'Bot mode'},
        options: ['webhook', 'pooling'],
      ),
      _line(
        'pu_telegram_token',
        ru: 'Токен бота',
        en: 'Bot token',
        hint: '123456:ABC-def',
      ),
      _line(
        'pu_telegram_proxy_url',
        ru: 'Прокси URL',
        en: 'Proxy URL',
        hint: 'socks5://...',
      ),
    ],
  ),
  SettingCategory(
    id: 'telegram-size',
    titles: {'ru': 'Telegram размеры', 'en': 'Telegram sizes'},
    icon: 'assets/icons/library.svg',
    fields: [
      _whole(
        'pu_telegram_items_per_page',
        1,
        20,
        ru: 'Записей на стр.',
        en: 'Items per page',
      ),
      _whole(
        'pu_telegram_header_entity_length',
        1,
        64,
        ru: 'Длина заголовка',
        en: 'Header length',
      ),
      _whole(
        'pu_telegram_git_hash_length',
        1,
        16,
        ru: 'Длина git-хеша',
        en: 'Git hash len',
      ),
    ],
  ),
  SettingCategory(
    id: 'logs',
    titles: {'ru': 'Журнал', 'en': 'Log'},
    icon: 'assets/icons/library.svg',
    fields: [
      const SettingField(
        'pu_instance_log_format',
        kind: 'enum',
        titles: {'ru': 'Формат лога', 'en': 'Log format'},
        options: ['json', 'plain'],
      ),
      const SettingField(
        'pu_instance_log_min_level',
        kind: 'enum',
        titles: {'ru': 'Уровень лога', 'en': 'Log level'},
        options: ['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'],
      ),
    ],
  ),
  SettingCategory(
    id: 'github',
    titles: {'ru': 'GitHub', 'en': 'GitHub'},
    icon: 'assets/icons/key.svg',
    fields: [
      _line(
        'pu_instance_github_token_name',
        ru: 'Имя токена',
        en: 'Token name',
        hint: 'username',
      ),
      _line(
        'pu_instance_github_token_pat',
        ru: 'Токен PAT',
        en: 'Token PAT',
        hint: 'ghp_...',
      ),
    ],
  ),
];

/// Top-level groups so the owner settings menu stays on a single ring.
const settingGroups = <SettingGroup>[
  SettingGroup(
    id: 'core',
    titles: {'ru': 'Система', 'en': 'System'},
    icon: 'assets/icons/instances.svg',
    categoryIds: ['contacts', 'users', 'federation', 'logs'],
  ),
  SettingGroup(
    id: 'services',
    titles: {'ru': 'Сервисы', 'en': 'Services'},
    icon: 'assets/icons/panel.svg',
    categoryIds: [
      'repos',
      'github',
      'datapipe',
      'datapipe-time',
      'notifications',
    ],
  ),
  SettingGroup(
    id: 'transport',
    titles: {'ru': 'Транспорт', 'en': 'Transport'},
    icon: 'assets/icons/micro.svg',
    categoryIds: ['mqtt', 'mqtt-size', 'telegram', 'telegram-size'],
  ),
];

SettingCategory? settingCategory(String id) {
  for (final category in settingCategories) {
    if (category.id == id) return category;
  }
  return null;
}

SettingGroup? settingGroup(String id) {
  for (final group in settingGroups) {
    if (group.id == id) return group;
  }
  return null;
}

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _telegramTokenRe = RegExp(r'^\d+:[A-Za-z0-9_-]+$');
final _countRateRe = RegExp(r'^[1-9]\d*(/[smh])?$');
final _bytesRateRe = RegExp(
  r'^[1-9]\d*(?:\.\d+)?(?:KB|MB|GB|B)/[smh]$',
  caseSensitive: false,
);

/// Why [raw] cannot be saved, or null when it can.
///
/// Shown under the field. A range on the cell edge is the hint; this is the check.
String? settingIssue(SettingField field, String raw, String language) {
  final text = raw.trim();
  if (field.nullable && text.isEmpty) return null;
  if (parseSetting(field, raw) != null) return null;
  if (text.isEmpty) {
    return phrase(language, {'ru': 'Пустое значение', 'en': 'Empty value'});
  }
  if (field.kind == 'int' || field.kind == 'number') {
    final number = field.kind == 'int' ? int.tryParse(text) : num.tryParse(text);
    if (number == null) {
      return phrase(language, {'ru': 'Нужно число', 'en': 'Need a number'});
    }
    final range = field.rangeHint();
    if (range != null) {
      return phrase(language, {
        'ru': 'Вне диапазона $range',
        'en': 'Outside $range',
      });
    }
  }
  final hint = field.rangeHint();
  if (hint != null) {
    return phrase(language, {
      'ru': 'Не подходит: $hint',
      'en': 'Does not match: $hint',
    });
  }
  return phrase(language, {
    'ru': 'Некорректное значение',
    'en': 'Invalid value',
  });
}

/// A value the settings patch will accept, or null when [raw] is not valid.
Object? parseSetting(SettingField field, String raw) {
  final text = raw.trim();
  if (field.nullable && text.isEmpty) return null;
  switch (field.kind) {
    case 'bool':
      if (text == 'true') return true;
      if (text == 'false') return false;
      return null;
    case 'int':
      final value = int.tryParse(text);
      if (value == null) return null;
      if (field.min != null && value < field.min!) return null;
      if (field.max != null && value > field.max!) return null;
      return value;
    case 'number':
      final value = num.tryParse(text);
      if (value == null) return null;
      if (field.min != null && value < field.min!) return null;
      if (field.max != null && value > field.max!) return null;
      return value;
    case 'enum':
      return field.options.contains(text) ? text : null;
    default:
      if (text.isNotEmpty) {
        if (field.key == 'pu_instance_owner_email' &&
            !_emailRe.hasMatch(text)) {
          return null;
        }
        if (field.key == 'pu_telegram_token' &&
            !_telegramTokenRe.hasMatch(text)) {
          return null;
        }
        if ((field.key == 'pu_mqtt_max_client_connection_rate' ||
                field.key == 'pu_mqtt_client_max_messages_rate') &&
            !_countRateRe.hasMatch(text)) {
          return null;
        }
        if (field.key == 'pu_mqtt_client_max_bytes_rate' &&
            !_bytesRateRe.hasMatch(text)) {
          return null;
        }
      } else if (field.key == 'pu_mqtt_max_client_connection_rate' ||
          field.key == 'pu_mqtt_client_max_messages_rate' ||
          field.key == 'pu_mqtt_client_max_bytes_rate') {
        return null;
      }
      return text;
  }
}
