import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Where releases of the client live and how their files are named.
///
/// The first source is the default, the next ones answer when it fails.
/// Packages include the release tag, platform and architecture in their names.
enum ReleaseHost { github, gitlab }

class ReleaseSource {
  const ReleaseSource({
    required this.host,
    required this.repository,
    required this.releases,
    required this.downloads,
  });

  final ReleaseHost host;

  /// The page of the repository.
  final String repository;

  /// The API list of releases.
  final String releases;

  /// Static start of a file link: `<downloads>/<version>/<file>`.
  final String downloads;
}

const githubSource = ReleaseSource(
  host: ReleaseHost.github,
  repository: 'https://github.com/w7a8n1y4a/pepeunit',
  releases:
      'https://api.github.com/repos/w7a8n1y4a/pepeunit/releases?per_page=100',
  downloads: 'https://github.com/w7a8n1y4a/pepeunit/releases/download',
);

const gitlabSource = ReleaseSource(
  host: ReleaseHost.gitlab,
  repository: 'https://git.pepemoss.com/pepe/pepeunit/pepeunit',
  releases:
      'https://git.pepemoss.com/api/v4/projects/212/releases?per_page=100',
  downloads: 'https://git.pepemoss.com/api/v4/projects/212/packages/generic/pepeunit-client',
);

const releaseSources = [githubSource, gitlabSource];

const upgradeNotesName = 'UPGRADE.md';

/// The file extension of every native platform.
const platformExtensions = <String, String>{
  'android': 'apk',
  'ios': 'ipa',
  'linux': 'tar.gz',
  'macos': 'dmg',
  'windows': 'exe',
};

const nativePackageSuffixes = <String, String>{
  'linux': 'linux-amd64.tar.gz',
  'android': 'android-arm64-v8a.apk',
  'windows': 'windows-amd64.zip',
};

String assetName(String version, String platform) =>
    'pepeunit-$version-${nativePackageSuffixes[platform] ?? '$platform.${platformExtensions[platform]}'}';

/// The link of a file, made from the version alone. No request is made.
Uri assetUri(ReleaseSource source, String version, String platform) =>
    Uri.parse('${source.downloads}/$version/${assetName(version, platform)}');

/// The platform of this build, or null on the web and on a platform that has
/// no file in a release.
String? nativePlatform() {
  if (kIsWeb) return null;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    TargetPlatform.linux => 'linux',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.windows => 'windows',
    TargetPlatform.fuchsia => null,
  };
}

/// `1.5.0` and `v1.5.0` as numbers. Null for any other tag, such as a
/// pre-release.
List<int>? parseVersion(String tag) {
  final match = RegExp(r'^[vV]?(\d+)\.(\d+)\.(\d+)$').firstMatch(tag.trim());
  if (match == null) return null;
  return [for (var i = 1; i <= 3; i++) int.parse(match.group(i)!)];
}

/// Negative when [a] is older. Null when either is not a version.
int? compareVersions(String a, String b) {
  final left = parseVersion(a);
  final right = parseVersion(b);
  if (left == null || right == null) return null;
  for (var i = 0; i < 3; i++) {
    if (left[i] != right[i]) return left[i].compareTo(right[i]);
  }
  return 0;
}

class ReleaseAsset {
  const ReleaseAsset({required this.name, required this.url, this.apiUrl});

  final String name;

  /// The link a person follows.
  final String url;

  /// A link the API serves the same bytes from, when the host has one.
  final String? apiUrl;

  /// The `<platform>` block of `pepeunit-<version>-<platform>.<extension>`.
  String? get platform {
    for (final entry in nativePackageSuffixes.entries) {
      if (name.startsWith('pepeunit-') && name.endsWith('-${entry.value}')) {
        return entry.key;
      }
    }
    final blocks = name.split('-');
    if (blocks.length < 3 || blocks.first != 'pepeunit') return null;
    return blocks.last.split('.').first;
  }
}

class Release {
  const Release({required this.tag, required this.assets});

  final String tag;
  final List<ReleaseAsset> assets;

  ReleaseAsset? get notes {
    for (final asset in assets) {
      if (asset.name == upgradeNotesName) return asset;
    }
    return null;
  }

  /// The ready link for a platform: the asset that has it as its block.
  ReleaseAsset? assetFor(String platform) {
    for (final asset in assets) {
      if (asset.name == assetName(tag, platform)) return asset;
    }
    for (final asset in assets) {
      if (asset.platform == platform) return asset;
    }
    return null;
  }
}

/// Releases of one host's answer. A draft, a pre-release and a tag that is
/// not a version are left out.
List<Release> parseReleases(ReleaseHost host, Object? json) {
  if (json is! List) throw const FormatException('releases are not a list');
  final found = <Release>[];
  for (final item in json) {
    if (item is! Map) continue;
    final tag = item['tag_name'];
    if (tag is! String || parseVersion(tag) == null) continue;
    if (item['draft'] == true ||
        item['prerelease'] == true ||
        item['upcoming_release'] == true) {
      continue;
    }
    found.add(Release(tag: tag, assets: _assetsOf(host, item)));
  }
  return found;
}

List<ReleaseAsset> _assetsOf(ReleaseHost host, Map<dynamic, dynamic> item) {
  final assets = item['assets'];
  final found = <ReleaseAsset>[];
  switch (host) {
    case ReleaseHost.github:
      if (assets is! List) return found;
      for (final asset in assets) {
        if (asset is! Map) continue;
        final name = asset['name'];
        final url = asset['browser_download_url'];
        if (name is! String || url is! String) continue;
        final api = asset['url'];
        found.add(
          ReleaseAsset(
            name: name,
            url: url,
            apiUrl: api is String ? api : null,
          ),
        );
      }
    case ReleaseHost.gitlab:
      final links = assets is Map ? assets['links'] : null;
      if (links is! List) return found;
      for (final link in links) {
        if (link is! Map) continue;
        final name = link['name'];
        final url = link['direct_asset_url'] ?? link['url'];
        if (name is! String || url is! String) continue;
        found.add(ReleaseAsset(name: name, url: url));
      }
  }
  return found;
}

/// The release with the greatest version.
Release? newestRelease(Iterable<Release> releases) {
  Release? best;
  for (final release in releases) {
    if (best == null || compareVersions(release.tag, best.tag)! > 0) {
      best = release;
    }
  }
  return best;
}

enum UpdateState {
  /// The newest release is the installed one or older.
  current,

  /// A newer release has no files.
  noAssets,

  /// A newer release with files.
  available,
}

class UpdateCheck {
  const UpdateCheck({
    required this.state,
    required this.latest,
    required this.source,
    this.notes,
    this.binary,
  });

  final UpdateState state;
  final String latest;
  final ReleaseSource source;

  /// `UPGRADE.md` of the newer release, when it was read.
  final String? notes;

  /// The file of this platform, null on the web and when the release has none.
  final ReleaseAsset? binary;
}

/// All the sources failed.
class UpdateSourcesFailed implements Exception {
  const UpdateSourcesFailed(this.reasons);

  final List<Object> reasons;

  @override
  String toString() => 'UpdateSourcesFailed($reasons)';
}

/// The newest release of the first source that answers.
Future<(ReleaseSource, Release)> fetchNewestRelease(
  http.Client client, {
  List<ReleaseSource> sources = releaseSources,
}) async {
  final reasons = <Object>[];
  for (final source in sources) {
    try {
      final response = await client.get(
        Uri.parse(source.releases),
        headers: const {'Accept': 'application/json'},
      );
      if (response.statusCode != 200) {
        throw http.ClientException(
          'Releases failed: ${response.statusCode}',
          Uri.parse(source.releases),
        );
      }
      final release = newestRelease(
        parseReleases(source.host, jsonDecode(utf8.decode(response.bodyBytes))),
      );
      if (release == null) throw const FormatException('no releases');
      return (source, release);
    } catch (error) {
      reasons.add(error);
    }
  }
  throw UpdateSourcesFailed(reasons);
}

/// The text of a file of a release. Null when no link of it answers.
Future<String?> fetchAssetText(http.Client client, ReleaseAsset asset) async {
  final tries = <(String, Map<String, String>)>[
    (asset.url, const {}),
    if (asset.apiUrl != null)
      (asset.apiUrl!, const {'Accept': 'application/octet-stream'}),
  ];
  for (final (url, headers) in tries) {
    try {
      final response = await client.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return utf8.decode(response.bodyBytes);
      }
    } catch (_) {
      continue;
    }
  }
  return null;
}

/// The check behind Check updates. [platform] is null on the web, where no
/// file is picked. The whole check stops after [timeout].
Future<UpdateCheck> checkForUpdate({
  required http.Client client,
  required String current,
  String? platform,
  Duration timeout = const Duration(minutes: 1),
  List<ReleaseSource> sources = releaseSources,
}) {
  Future<UpdateCheck> run() async {
    final (source, release) = await fetchNewestRelease(
      client,
      sources: sources,
    );
    final newer = (compareVersions(release.tag, current) ?? 0) > 0;
    if (!newer) {
      return UpdateCheck(
        state: UpdateState.current,
        latest: release.tag,
        source: source,
      );
    }
    if (release.assets.isEmpty) {
      return UpdateCheck(
        state: UpdateState.noAssets,
        latest: release.tag,
        source: source,
      );
    }
    final notes = release.notes;
    return UpdateCheck(
      state: UpdateState.available,
      latest: release.tag,
      source: source,
      notes: notes == null ? null : await fetchAssetText(client, notes),
      binary: platform == null ? null : release.assetFor(platform),
    );
  }

  return run().timeout(timeout);
}
