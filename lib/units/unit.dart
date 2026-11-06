import '../locale/languages.dart';

/// `4..20` of letters, digits, `_`, `.` and `-`. Unique per user on the instance.
final unitNamePattern = RegExp(r'^[A-Za-z0-9_.-]{4,20}$');

bool unitNameOk(String name) => unitNamePattern.hasMatch(name.trim());

const unitVisibilities = ['Public', 'Internal', 'Private'];

const unitCommands = [
  'Update',
  'EnvUpdate',
  'SchemaUpdate',
  'LogSync',
  'Reset',
];

const pipePolicies = ['LastValue', 'NRecords', 'TimeWindow', 'Aggregation'];

const logLevels = ['Debug', 'Info', 'Warning', 'Error', 'Critical'];

/// One row of `GET /units`.
class Unit {
  const Unit({
    required this.uuid,
    required this.iconUuid,
    required this.visibility,
    required this.name,
    required this.created,
    required this.auto,
    required this.compilable,
    required this.tagsOnly,
    required this.branch,
    required this.updated,
    required this.creatorUuid,
    required this.repoUuid,
    this.platform,
    this.commit,
    this.currentCommit,
    this.firmwareStatus,
    this.firmwareError,
    this.firmwareAt,
    this.state,
    this.ios = const [],
  });

  final String uuid;
  final String iconUuid;
  final String visibility;
  final String name;
  final String created;
  final bool auto;
  final bool compilable;
  final bool tagsOnly;
  final String? platform;
  final String branch;
  final String? commit;
  final String? currentCommit;
  final String updated;
  final String creatorUuid;
  final String repoUuid;
  final String? firmwareStatus;
  final String? firmwareError;
  final String? firmwareAt;
  final UnitLive? state;
  final List<UnitIo> ios;

  factory Unit.fromJson(Map<String, Object?> json) {
    final icon = json['icon_uuid'];
    final state = json['unit_state'];
    return Unit(
      uuid: json['uuid'] as String? ?? '',
      iconUuid: icon is String ? icon : '',
      visibility: json['visibility_level'] as String? ?? '',
      name: json['name'] as String? ?? '',
      created: json['create_datetime'] as String? ?? '',
      auto: json['is_auto_update_unit'] == true,
      compilable: json['is_compilable_unit'] == true,
      tagsOnly: json['is_only_tag_update'] == true,
      platform: _text(json['target_firmware_platform']),
      branch: json['target_branch'] as String? ?? '',
      commit: _text(json['target_commit']),
      currentCommit: _text(json['current_commit_version']),
      updated: json['last_update_datetime'] as String? ?? '',
      creatorUuid: json['creator_uuid'] as String? ?? '',
      repoUuid: json['repo_uuid'] as String? ?? '',
      firmwareStatus: _text(json['firmware_update_status']),
      firmwareError: _text(json['firmware_update_error']),
      firmwareAt: _text(json['last_firmware_update_datetime']),
      state: state is Map
          ? UnitLive.fromJson(state.cast<String, Object?>())
          : null,
      ios: [
        for (final item in json['unit_ios'] as List<Object?>? ?? const [])
          if (item is Map) UnitIo.fromJson(item.cast<String, Object?>()),
      ],
    );
  }
}

class UnitLive {
  const UnitLive({
    this.millis,
    this.memFree,
    this.memAlloc,
    this.freq,
    this.commit,
    this.statvfs = const [],
    this.ifconfig = const [],
  });

  final num? millis;
  final num? memFree;
  final num? memAlloc;
  final num? freq;
  final String? commit;

  /// `statvfs` block: sizes, then block counts. See the state topic.
  final List<num> statvfs;
  final List<String> ifconfig;

  factory UnitLive.fromJson(Map<String, Object?> json) {
    return UnitLive(
      millis: _num(json['millis']),
      memFree: _num(json['mem_free']),
      memAlloc: _num(json['mem_alloc']),
      freq: _num(json['freq']),
      commit: _text(json['pu_commit_version']),
      statvfs: [
        for (final item in json['statvfs'] as List<Object?>? ?? const [])
          if (item is num) item,
      ],
      ifconfig: [
        for (final item in json['ifconfig'] as List<Object?>? ?? const [])
          if (item != null) '$item',
      ],
    );
  }
}

class UnitIo {
  const UnitIo({
    required this.uuid,
    required this.type,
    required this.visibility,
    required this.rewritable,
    required this.maxConnections,
    required this.topic,
    required this.updated,
    required this.pipeActive,
    required this.created,
    required this.unitUuid,
    required this.creatorUuid,
    this.pipeYml,
    this.pipeStatus,
    this.pipeError,
    this.state,
  });

  final String uuid;
  final String type;
  final String visibility;
  final bool rewritable;
  final int maxConnections;
  final String topic;
  final String updated;
  final bool pipeActive;
  final String? pipeYml;
  final String? pipeStatus;
  final String? pipeError;
  final String created;
  final String? state;
  final String unitUuid;
  final String creatorUuid;

  bool get input => type == 'Input';

  factory UnitIo.fromJson(Map<String, Object?> json) {
    final max = json['max_connections'];
    return UnitIo(
      uuid: json['uuid'] as String? ?? '',
      type: json['type'] as String? ?? '',
      visibility: json['visibility_level'] as String? ?? '',
      rewritable: json['is_rewritable_input'] == true,
      maxConnections: max is num ? max.round() : 0,
      topic: json['topic_name'] as String? ?? '',
      updated: json['last_update_datetime'] as String? ?? '',
      pipeActive: json['is_data_pipe_active'] == true,
      pipeYml: _text(json['data_pipe_yml']),
      pipeStatus: _text(json['data_pipe_status']),
      pipeError: _text(json['data_pipe_error']),
      created: json['create_datetime'] as String? ?? '',
      state: _text(json['state']),
      unitUuid: json['unit_uuid'] as String? ?? '',
      creatorUuid: json['creator_uuid'] as String? ?? '',
    );
  }
}

class UnitGroup {
  const UnitGroup({
    required this.uuid,
    required this.iconUuid,
    required this.name,
    required this.created,
    required this.creatorUuid,
  });

  final String uuid;
  final String iconUuid;
  final String name;
  final String created;
  final String creatorUuid;

  factory UnitGroup.fromJson(Map<String, Object?> json) {
    final icon = json['icon_uuid'];
    return UnitGroup(
      uuid: json['uuid'] as String? ?? '',
      iconUuid: icon is String ? icon : '',
      name: json['name'] as String? ?? '',
      created: json['create_datetime'] as String? ?? '',
      creatorUuid: json['creator_uuid'] as String? ?? '',
    );
  }
}

class AccessGrant {
  const AccessGrant({
    required this.uuid,
    required this.agentUuid,
    required this.agentType,
    required this.resourceUuid,
    required this.resourceType,
  });

  final String uuid;
  final String agentUuid;
  final String agentType;
  final String resourceUuid;
  final String resourceType;

  factory AccessGrant.fromJson(Map<String, Object?> json) {
    return AccessGrant(
      uuid: json['uuid'] as String? ?? '',
      agentUuid: json['agent_uuid'] as String? ?? '',
      agentType: json['agent_type'] as String? ?? '',
      resourceUuid: json['resource_uuid'] as String? ?? '',
      resourceType: json['resource_type'] as String? ?? '',
    );
  }
}

class RepoCommit {
  const RepoCommit({required this.commit, required this.summary, this.tag});

  final String commit;
  final String summary;
  final String? tag;

  factory RepoCommit.fromJson(Map<String, Object?> json) {
    return RepoCommit(
      commit: json['commit'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      tag: _text(json['tag']),
    );
  }
}

class FirmwarePlatform {
  const FirmwarePlatform({required this.name, required this.link});

  final String name;
  final String link;

  factory FirmwarePlatform.fromJson(Map<String, Object?> json) {
    return FirmwarePlatform(
      name: json['name'] as String? ?? '',
      link: json['link'] as String? ?? '',
    );
  }
}

class UnitLog {
  const UnitLog({
    required this.uuid,
    required this.level,
    required this.unitUuid,
    required this.text,
    required this.created,
  });

  final String uuid;
  final String level;
  final String unitUuid;
  final String text;
  final String created;

  factory UnitLog.fromJson(Map<String, Object?> json) {
    return UnitLog(
      uuid: json['uuid'] as String? ?? '',
      level: json['level'] as String? ?? '',
      unitUuid: json['unit_uuid'] as String? ?? '',
      text: json['text'] as String? ?? '',
      created: json['create_datetime'] as String? ?? '',
    );
  }
}

class PipeIssue {
  const PipeIssue({
    required this.stage,
    required this.message,
    required this.code,
  });

  final String stage;
  final String message;
  final int code;

  factory PipeIssue.fromJson(Map<String, Object?> json) {
    final code = json['error_code'];
    return PipeIssue(
      stage: json['stage'] as String? ?? '',
      message: json['message'] as String? ?? '',
      code: code is num ? code.round() : 0,
    );
  }
}

class PipeRow {
  const PipeRow({required this.text, required this.time});

  final String text;
  final String time;

  factory PipeRow.fromJson(Map<String, Object?> json) {
    final state = json['state'];
    final agg = json['aggregation_type'];
    final time = json['create_datetime'] ?? json['start_window_datetime'] ?? '';
    final label = agg == null ? '$state' : '$agg $state';
    return PipeRow(text: label, time: time is String ? time : '$time');
  }
}

bool unitOwnedBy(String creator, String? userUuid) {
  final user = userUuid?.trim() ?? '';
  if (creator.trim().isEmpty || user.isEmpty) return false;
  return creator.toLowerCase() == user.toLowerCase();
}

String unitVisibilityLabel(String language, String visibility) {
  switch (visibility) {
    case 'Public':
      return phrase(language, {'ru': 'Публичный', 'en': 'Public'});
    case 'Internal':
      return phrase(language, {'ru': 'Внутренний', 'en': 'Internal'});
    case 'Private':
      return phrase(language, {'ru': 'Приватный', 'en': 'Private'});
    default:
      return visibility;
  }
}

String unitCommandLabel(String language, String command) {
  switch (command) {
    case 'Update':
      return phrase(language, {
        'ru': 'Обновить прошивку',
        'en': 'Update firmware',
      });
    case 'EnvUpdate':
      return phrase(language, {
        'ru': 'Обновить окружение',
        'en': 'Update environment',
      });
    case 'SchemaUpdate':
      return phrase(language, {'ru': 'Обновить схему', 'en': 'Update schema'});
    case 'LogSync':
      return phrase(language, {
        'ru': 'Синхронизировать логи',
        'en': 'Sync logs',
      });
    case 'Reset':
      return phrase(language, {
        'ru': 'Перезапустить аппарат',
        'en': 'Restart unit',
      });
    default:
      return command;
  }
}

String firmwareStatusLabel(String language, String? status) {
  switch (status) {
    case 'RequestSent':
      return phrase(language, {'ru': 'Запрошено', 'en': 'Requested'});
    case 'Success':
      return phrase(language, {'ru': 'Готово', 'en': 'Done'});
    case 'Error':
      return phrase(language, {'ru': 'Ошибка', 'en': 'Error'});
    default:
      return '—';
  }
}

/// First seven characters of a commit.
String shortCommit(String? commit) {
  final text = commit?.trim() ?? '';
  if (text.isEmpty) return '';
  return text.length <= 7 ? text : text.substring(0, 7);
}

String? _text(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return value;
}

num? _num(Object? value) => value is num ? value : null;
