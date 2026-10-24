class SettingField {
  const SettingField(
    this.key, {
    required this.kind,
    this.min,
    this.max,
    this.options = const [],
    this.nullable = false,
  });

  final String key;

  /// `bool`, `int`, `number`, `text`, or `enum`.
  final String kind;
  final num? min;
  final num? max;
  final List<String> options;
  final bool nullable;

  String label() => key.replaceFirst(RegExp(r'^pu_'), '').replaceAll('_', ' ');
}

class SettingCategory {
  const SettingCategory({
    required this.id,
    required this.titles,
    required this.fields,
  });

  final String id;
  final Map<String, String> titles;
  final List<SettingField> fields;
}

const _bool = 'bool';
const _int = 'int';
const _num = 'number';
const _text = 'text';

SettingField _flag(String key) => SettingField(key, kind: _bool);

SettingField _whole(String key, num min, num max) =>
    SettingField(key, kind: _int, min: min, max: max);

SettingField _real(String key, num min, num max, {bool nullable = false}) =>
    SettingField(key, kind: _num, min: min, max: max, nullable: nullable);

SettingField _line(String key) => SettingField(key, kind: _text);

/// One cell per category. A category longer than six fields is split so the
/// form still fits inside a cell.
final settingCategories = <SettingCategory>[
  SettingCategory(
    id: 'flags',
    titles: {'ru': 'Флаги', 'en': 'Flags'},
    fields: [
      _flag('pu_ff_datapipe_enable'),
      _flag('pu_ff_federation_enable'),
      _flag('pu_ff_grafana_integration_enable'),
      _flag('pu_ff_notification_enable'),
      _flag('pu_ff_prometheus_enable'),
      _flag('pu_ff_telegram_bot_enable'),
    ],
  ),
  SettingCategory(
    id: 'contacts',
    titles: {'ru': 'Контакты', 'en': 'Contacts'},
    fields: [
      _line('pu_instance_owner_email'),
      _line('pu_instance_owner_tg'),
      _real('pu_instance_lat', -90, 90, nullable: true),
      _real('pu_instance_lon', -180, 180, nullable: true),
    ],
  ),
  SettingCategory(
    id: 'users',
    titles: {'ru': 'Пользователи', 'en': 'Users'},
    fields: [
      _whole('pu_instance_user_max_count', 1, 1000000),
      _whole('pu_instance_user_max_group', 8, 32),
      _whole('pu_instance_user_auth_token_expiration', 600, 11059200),
    ],
  ),
  SettingCategory(
    id: 'federation',
    titles: {'ru': 'Федерация', 'en': 'Federation'},
    fields: [
      _whole('pu_instance_retention_days', 1, 120),
      _whole('pu_instance_max_state_size', 4096, 65536),
      _whole('pu_instance_max_pagination_size', 1, 500),
      _real('pu_instance_http_timeout', 1, 120),
      _real('pu_instance_http_connect_timeout', 1, 60),
      _whole('pu_instance_cipher_max_length', 0, 5000000),
    ],
  ),
  SettingCategory(
    id: 'repos',
    titles: {'ru': 'Репозитории', 'en': 'Repositories'},
    fields: [
      _whole('pu_instance_repo_max_size', 0, 1024),
      _whole('pu_instance_repo_min_interval_sync', 1, 1800),
      _whole('pu_instance_unit_state_send_interval', 1, 600),
      _whole('pu_instance_unit_log_expiration', 60, 604800),
    ],
  ),
  SettingCategory(
    id: 'datapipe',
    titles: {'ru': 'DataPipe', 'en': 'DataPipe'},
    fields: [
      _flag('pu_datapipe_default_last_value_enable'),
      _whole('pu_datapipe_limit_unit_io_per_one_panel', 1, 32),
      _whole('pu_datapipe_buffer_max_size', 1, 1000000),
      _whole('pu_datapipe_mqtt_keepalive', 0, 600),
    ],
  ),
  SettingCategory(
    id: 'datapipe-time',
    titles: {'ru': 'DataPipe время', 'en': 'DataPipe time'},
    fields: [
      _whole('pu_datapipe_buffer_flush_interval', 1, 3600),
      _whole('pu_datapipe_config_sync_interval', 1, 86400),
      _whole('pu_datapipe_nrecords_cleanup_interval', 1, 604800),
    ],
  ),
  SettingCategory(
    id: 'mqtt',
    titles: {'ru': 'MQTT', 'en': 'MQTT'},
    fields: [
      _whole('pu_mqtt_keepalive', 0, 600),
      _whole('pu_mqtt_max_clients', 1, 1024),
      _whole('pu_mqtt_max_qos', 0, 2),
      _line('pu_mqtt_client_max_messages_rate'),
      _line('pu_mqtt_client_max_bytes_rate'),
      _line('pu_mqtt_max_client_connection_rate'),
    ],
  ),
  SettingCategory(
    id: 'mqtt-size',
    titles: {'ru': 'MQTT размеры', 'en': 'MQTT sizes'},
    fields: [
      _whole('pu_mqtt_max_client_id_len', 1, 1024),
      _whole('pu_mqtt_max_len_message_queue', 1, 1024),
      _whole('pu_mqtt_max_payload_size', 1, 4096),
      _whole('pu_mqtt_max_topic_alias', 0, 256),
      _whole('pu_mqtt_max_topic_levels', 5, 32),
    ],
  ),
  SettingCategory(
    id: 'notifications',
    titles: {'ru': 'Уведомления', 'en': 'Notifications'},
    fields: [
      _whole('pu_notification_data_pipe_alert_batch', 1, 1000),
      _whole('pu_notification_small_text_limit', 1, 96),
      _whole('pu_notification_stream_maxlen', 1, 10000),
      _whole('pu_notification_telegram_alert_text_limit', 1, 4096),
      _whole('pu_notification_telegram_instance_rate', 1, 30),
      _real('pu_notification_telegram_user_interval_seconds', 1, 60),
    ],
  ),
  SettingCategory(
    id: 'telegram',
    titles: {'ru': 'Telegram', 'en': 'Telegram'},
    fields: [
      _line('pu_telegram_bot_link'),
      SettingField(
        'pu_telegram_bot_mode',
        kind: 'enum',
        options: ['webhook', 'pooling'],
      ),
      _line('pu_telegram_token'),
      _line('pu_telegram_proxy_url'),
    ],
  ),
  SettingCategory(
    id: 'telegram-size',
    titles: {'ru': 'Telegram размеры', 'en': 'Telegram sizes'},
    fields: [
      _whole('pu_telegram_items_per_page', 1, 20),
      _whole('pu_telegram_header_entity_length', 1, 64),
      _whole('pu_telegram_git_hash_length', 1, 16),
    ],
  ),
  SettingCategory(
    id: 'logs',
    titles: {'ru': 'Журнал', 'en': 'Log'},
    fields: [
      SettingField(
        'pu_instance_log_format',
        kind: 'enum',
        options: ['json', 'plain'],
      ),
      SettingField(
        'pu_instance_log_min_level',
        kind: 'enum',
        options: ['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'],
      ),
    ],
  ),
  SettingCategory(
    id: 'github',
    titles: {'ru': 'GitHub', 'en': 'GitHub'},
    fields: [
      _line('pu_instance_github_token_name'),
      _line('pu_instance_github_token_pat'),
    ],
  ),
];

SettingCategory? settingCategory(String id) {
  for (final category in settingCategories) {
    if (category.id == id) return category;
  }
  return null;
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
      return text;
  }
}
