import 'dart:convert';

import '../instances/network_view.dart';

/// Wire names of `NotificationType`, in the settings menu order.
const noticeTypes = <String>[
  'InstanceDailyState',
  'UnitDailySummary',
  'DataPipeAlert',
  'IntegrationTests',
  'ScanAllPeers',
  'ScanPeer',
  'UpdateAllRepos',
  'UpdateRepo',
  'UpdateUnitsFirmware',
  'UpdateAllUnitsFirmware',
  'RebootInstance',
];

/// Commands an Admin starts. Owner passes the same check on the backend.
const _staffTypes = <String>{
  'InstanceDailyState',
  'IntegrationTests',
  'ScanAllPeers',
  'ScanPeer',
  'UpdateAllRepos',
  'UpdateAllUnitsFirmware',
};

/// Reboot is owner-only. The alert is written for the user who started it.
const _ownerTypes = <String>{'RebootInstance'};

/// Types this role can receive.
///
/// A plain user gets summaries, data-pipe alerts, and the repo or firmware
/// tasks they themselves start. Admin adds the instance commands. Owner adds
/// reboot. The backend does not send a type to a role that cannot receive it.
List<String> noticeTypesForRole(String? role) {
  final staff = role == 'Admin' || role == 'Owner';
  final owner = role == 'Owner';
  return [
    for (final type in noticeTypes)
      if ((!_staffTypes.contains(type) && !_ownerTypes.contains(type)) ||
          (staff && _staffTypes.contains(type)) ||
          (owner && _ownerTypes.contains(type)))
        type,
  ];
}

/// Read filter of the list. The backend sorts by creation time, newest first.
const noticeReads = ['all', 'read', 'unread'];

class NoticeQuery {
  String read = 'unread';

  /// Selected wire names. Empty until the role is known, then every type
  /// that role can receive.
  final Set<String> types = {};
  var tuned = false;

  bool showsAll(String? role) {
    final available = noticeTypesForRole(role);
    if (available.isEmpty) return types.isEmpty;
    return available.every(types.contains);
  }

  bool accepts(Notice notice) {
    if (!types.contains(notice.type)) return false;
    return switch (read) {
      'read' => notice.isRead,
      'unread' => !notice.isRead,
      _ => true,
    };
  }
}

/// One row of `GET /notifications`.
class Notice {
  const Notice({
    required this.uuid,
    required this.created,
    required this.type,
    required this.smallText,
    required this.tableText,
    required this.isRead,
    this.bigText = '',
  });

  final String uuid;
  final String created;
  final String type;
  final String smallText;
  final String tableText;
  final bool isRead;

  /// Pytest log. Only integration-test notices carry it, and those may have
  /// no table.
  final String bigText;

  bool get hasLog => bigText.trim().isNotEmpty;

  Notice copyWith({bool? isRead}) {
    return Notice(
      uuid: uuid,
      created: created,
      type: type,
      smallText: smallText,
      tableText: tableText,
      bigText: bigText,
      isRead: isRead ?? this.isRead,
    );
  }

  factory Notice.fromJson(Map<String, Object?> json) {
    return Notice(
      uuid: json['uuid'] as String? ?? '',
      created: json['create_datetime'] as String? ?? '',
      type: json['type'] as String? ?? '',
      smallText: json['small_text'] as String? ?? '',
      tableText: json['table_text'] as String? ?? '',
      bigText: json['big_text'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
    );
  }
}

/// `MM.DD HH:MM` in the client zone. [zoneMinutes] is the stored UTC offset.
/// A timestamp without a zone is UTC, which is how the backend writes it.
String noticeWhen(String raw, String zoneMinutes) {
  final instant = _utc(raw);
  if (instant == null) return '';
  final shift = int.tryParse(zoneMinutes) ?? 0;
  final local = instant.add(Duration(minutes: shift));
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$month.$day $hour:$minute';
}

DateTime? _utc(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) return null;
  if (parsed.isUtc) return parsed;
  final zoned =
      trimmed.endsWith('Z') ||
      trimmed.contains('+') ||
      RegExp(r'-\d\d:\d\d$').hasMatch(trimmed);
  if (zoned) return parsed.toUtc();
  return DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  );
}

/// Cards beside Back, the filter, and the type menu at this tick.
int noticePageLimit(int tick) =>
    scaleTickCells(tick.clamp(scaleTickMin, scaleTickMax)) - 3;

bool noticeCanPageBack({required int offset, required int count}) =>
    count > noticePageLimit(scaleTickMax) && offset > 0;

bool noticeCanPageForward({
  required int offset,
  required int limit,
  required int count,
}) => count > noticePageLimit(scaleTickMax) && offset + limit < count;

/// Back, filter, type menu, then notice cards. The tick caps the disk.
NetworkBoard noticesBoard({
  required int tick,
  required List<String> uuids,
  bool wide = false,
}) {
  final step = tick.clamp(scaleTickMin, scaleTickMax);
  final ids = <String>[
    'filter',
    'types',
    for (final uuid in uuids) 'notice:$uuid',
  ];
  final frame = hexFrame(
    count: ids.length,
    back: HexBack.center,
    wide: wide,
    cells: scaleTickCells(step),
  );
  final back = frame.back!;
  return NetworkBoard(
    slots: [
      BoardSlot('back', back.$1, back.$2),
      for (var i = 0; i < ids.length && i < frame.cells.length; i++)
        BoardSlot(ids[i], frame.cells[i].$1, frame.cells[i].$2),
    ],
    canZoomIn: step < scaleTickMax,
    page: 0,
    pages: 1,
  );
}

/// Pulls complete SSE frames out of a byte stream and reads `data:` lines.
class SseBuffer {
  String _pending = '';

  List<Notice> add(String chunk) {
    _pending += chunk;
    final frames = _pending.split('\n\n');
    _pending = frames.removeLast();
    final found = <Notice>[];
    for (final frame in frames) {
      for (final line in frame.split('\n')) {
        if (!line.startsWith('data:')) continue;
        final raw = line.substring(5).trim();
        if (raw.isEmpty) continue;
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        found.add(Notice.fromJson(decoded.cast<String, Object?>()));
      }
    }
    return found;
  }
}
