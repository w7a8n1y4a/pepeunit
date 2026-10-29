import 'dart:convert';

import '../locale/languages.dart';

/// One row of `GET /repo`. `creator_uuid` is not a search filter.
class RegistryRepo {
  const RegistryRepo({
    required this.uuid,
    required this.iconUuid,
    required this.platform,
    required this.repositoryUrl,
    required this.public,
    required this.localSize,
    required this.branches,
    this.creatorUuid = '',
    this.releasesData,
    this.syncStatus,
    this.syncError,
    this.syncLast,
    this.created = '',
    this.updated = '',
  });

  final String uuid;
  final String iconUuid;
  final String platform;
  final String repositoryUrl;
  final bool public;

  /// Set only so the creator can delete this repo. Not sent as a filter.
  final String creatorUuid;

  /// Bytes on disk.
  final int localSize;
  final String? releasesData;
  final String? syncStatus;
  final String? syncError;
  final String? syncLast;
  final String created;
  final String updated;
  final List<String> branches;

  factory RegistryRepo.fromJson(Map<String, Object?> json) {
    final size = json['local_repository_size'];
    final icon = json['icon_uuid'];
    final releases = json['releases_data'];
    final creator = json['creator_uuid'];
    return RegistryRepo(
      uuid: json['uuid'] as String? ?? '',
      iconUuid: icon is String ? icon : '',
      platform: json['platform'] as String? ?? '',
      repositoryUrl: json['repository_url'] as String? ?? '',
      public: json['is_public_repository'] == true,
      creatorUuid: creator is String ? creator : '',
      localSize: size is num ? size.round() : 0,
      releasesData: releases is String && releases.isNotEmpty ? releases : null,
      syncStatus: json['sync_status'] as String?,
      syncError: json['sync_error'] as String?,
      syncLast: json['sync_last_datetime'] as String?,
      created: json['create_datetime'] as String? ?? '',
      updated: json['last_update_datetime'] as String? ?? '',
      branches: [
        for (final item in json['branches'] as List<Object?>? ?? const [])
          if (item is String && item.isNotEmpty) item,
      ],
    );
  }
}

class RepoCredentials {
  const RepoCredentials({
    required this.username,
    required this.token,
    required this.status,
  });

  final String username;
  final String token;
  final String status;

  factory RepoCredentials.fromJson(Map<String, Object?> json) {
    final raw = json['credentials'];
    final credentials = raw is Map
        ? raw.cast<String, Object?>()
        : const <String, Object?>{};
    return RepoCredentials(
      username: credentials['username'] as String? ?? '',
      token: credentials['pat_token'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}

class RepoSummary {
  const RepoSummary({required this.title, required this.lines});

  final String title;
  final List<String> lines;
}

/// Host and path of a repository link. `https://`, `http://` and a trailing
/// `.git` are dropped. Past 24 characters the start is cut, so the end stays.
String repoCaption(String url) {
  var text = url.trim();
  final lower = text.toLowerCase();
  if (lower.startsWith('https://')) {
    text = text.substring('https://'.length);
  } else if (lower.startsWith('http://')) {
    text = text.substring('http://'.length);
  }
  if (text.toLowerCase().endsWith('.git')) {
    text = text.substring(0, text.length - '.git'.length);
  }
  return tailText(text, 24);
}

/// Keeps the last [limit] characters. The end of a link or a branch matters more.
String tailText(String text, int limit) {
  final runes = text.runes.toList();
  if (runes.length <= limit) return text;
  return String.fromCharCodes(runes.sublist(runes.length - limit));
}

/// Bare size: `512 Б` / `512 B`, `1.5 КБ` / `1.5 KB`. Powers of 1024.
String repoSizeLabel(int bytes, String language) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  const unitsRu = ['Б', 'КБ', 'МБ', 'ГБ', 'ТБ'];
  final names = language == 'ru' ? unitsRu : units;
  var value = (bytes < 0 ? 0 : bytes).toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  if (unit == 0) return '${value.round()} ${names[unit]}';
  final whole = (value - value.roundToDouble()).abs() < 0.05;
  final shown = whole || value >= 10
      ? value.round().toString()
      : value.toStringAsFixed(1);
  return '$shown ${names[unit]}';
}

/// `Github` and `Gitlab` stay the wire values. The cell shows the name.
String repoPlatformLabel(String language, String platform) {
  switch (platform) {
    case 'Github':
      return phrase(language, {'ru': 'Гитхаб', 'en': 'GitHub'});
    case 'Gitlab':
      return phrase(language, {'ru': 'Гитлаб', 'en': 'GitLab'});
    default:
      return platform.trim();
  }
}

String repoAccessLabel(String language, bool public) {
  return phrase(
    language,
    public
        ? {'ru': 'Публичный', 'en': 'Public'}
        : {'ru': 'Приватный', 'en': 'Private'},
  );
}

/// Delete is offered only when the signed-in user created the repo.
bool repoOwnedBy(RegistryRepo? repo, String? userUuid) {
  final creator = repo?.creatorUuid.trim() ?? '';
  final user = userUuid?.trim() ?? '';
  if (creator.isEmpty || user.isEmpty) return false;
  return creator.toLowerCase() == user.toLowerCase();
}

String repoSyncLabel(String language, String? status) {
  switch (status) {
    case 'Updated':
      return phrase(language, {'ru': 'Обновлён', 'en': 'Updated'});
    case 'Processing':
      return phrase(language, {'ru': 'Обновляется', 'en': 'Updating'});
    case 'Error':
      return phrase(language, {'ru': 'Ошибка', 'en': 'Error'});
    default:
      return '—';
  }
}

String credentialStatusLabel(String language, String status) {
  switch (status) {
    case 'Valid':
      return phrase(language, {'ru': 'Действителен', 'en': 'Valid'});
    case 'NotVerified':
      return phrase(language, {'ru': 'Не проверен', 'en': 'Unchecked'});
    case 'Error':
      return phrase(language, {'ru': 'Ошибка', 'en': 'Error'});
    default:
      return '';
  }
}

/// `2025-12-06T11:51:30Z` becomes `2025.12.06 11:51`.
String shortStamp(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '—';
  final text = raw.trim().replaceFirst('T', ' ');
  final head = text.length >= 16 ? text.substring(0, 16) : text;
  return head.replaceAll('-', '.');
}

List<String> releaseTags(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return [for (final key in decoded.keys) '$key'];
    }
  } catch (_) {}
  return const [];
}

String _joined(List<String> parts) =>
    parts.where((part) => part.isNotEmpty).join(' · ');

List<RepoSummary> repoSummaries(RegistryRepo repo, String language) {
  final tags = releaseTags(repo.releasesData);
  final access = repoAccessLabel(language, repo.public);
  final platform = repoPlatformLabel(language, repo.platform);
  final status = repoSyncLabel(language, repo.syncStatus);
  final stamp = repo.syncLast == null || repo.syncLast!.trim().isEmpty
      ? ''
      : shortStamp(repo.syncLast);
  final pages = <RepoSummary>[
    RepoSummary(
      title: phrase(language, {'ru': 'Сводка', 'en': 'Summary'}),
      lines: [
        _joined([access, platform]),
        _joined([status, stamp]),
        _joined([
          repoSizeLabel(repo.localSize, language),
          '${phrase(language, {'ru': 'Ветки', 'en': 'Branches'})} ${repo.branches.length}',
        ]),
        if (tags.isNotEmpty)
          '${phrase(language, {'ru': 'Релизы', 'en': 'Releases'})} ${tags.length}',
      ],
    ),
  ];
  final error = repo.syncError?.trim() ?? '';
  final syncLines = <String>[if (error.isNotEmpty) tailText(error, 48)];
  if (syncLines.isNotEmpty) {
    pages.add(
      RepoSummary(
        title: phrase(language, {'ru': 'Синхронизация', 'en': 'Sync'}),
        lines: syncLines,
      ),
    );
  }
  final when = <String>[
    if (repo.created.isNotEmpty)
      '${phrase(language, {'ru': 'Создан', 'en': 'Created'})} ${shortStamp(repo.created)}',
    if (repo.updated.isNotEmpty)
      '${phrase(language, {'ru': 'Изменён', 'en': 'Updated'})} ${shortStamp(repo.updated)}',
  ];
  if (when.isNotEmpty) {
    pages.add(
      RepoSummary(
        title: phrase(language, {'ru': 'Время', 'en': 'Time'}),
        lines: when,
      ),
    );
  }
  if (tags.isNotEmpty) {
    pages.add(
      RepoSummary(
        title: phrase(language, {'ru': 'Релизы', 'en': 'Releases'}),
        lines: [for (final tag in tags.take(5)) tag],
      ),
    );
  }
  return pages;
}
