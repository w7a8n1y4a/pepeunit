import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pepeunit_client/library/updates.dart';

String _github(List<Map<String, Object?>> releases) => jsonEncode(releases);

Map<String, Object?> _release(
  String tag,
  List<String> names, {
  bool draft = false,
  bool prerelease = false,
}) => {
  'tag_name': tag,
  'draft': draft,
  'prerelease': prerelease,
  'assets': [
    for (final name in names)
      {
        'name': name,
        'browser_download_url': 'https://dl.test/$tag/$name',
        'url': 'https://api.test/assets/$name',
      },
  ],
};

void main() {
  test('names and links of the files follow the rule', () {
    expect(assetName('1.5.0', 'android'), 'pepeunit-1.5.0-android.apk');
    expect(assetName('1.5.0', 'linux'), 'pepeunit-1.5.0-linux.AppImage');
    expect(
      assetUri(githubSource, '1.5.0', 'linux').toString(),
      'https://github.com/w7a8n1y4a/pepeunit/releases/download/1.5.0/'
      'pepeunit-1.5.0-linux.AppImage',
    );
    expect(
      assetUri(gitlabSource, '1.5.0', 'android').toString(),
      'https://git.pepemoss.com/api/v4/projects/212/packages/generic/'
      'release/1.5.0/pepeunit-1.5.0-android.apk',
    );
  });

  test('versions compare by number, other tags are not versions', () {
    expect(compareVersions('1.10.0', '1.9.9'), greaterThan(0));
    expect(compareVersions('v1.5.0', '1.5.0'), 0);
    expect(compareVersions('1.4.9', '1.5.0'), lessThan(0));
    expect(compareVersions('1.5.0-rc1', '1.5.0'), isNull);
    expect(parseVersion('latest'), isNull);
  });

  test('a platform is the block of the file name', () {
    const asset = ReleaseAsset(name: 'pepeunit-1.5.0-ios.ipa', url: 'u');
    expect(asset.platform, 'ios');
    expect(const ReleaseAsset(name: 'UPGRADE.md', url: 'u').platform, isNull);
    final release = Release(
      tag: '1.5.0',
      assets: const [
        ReleaseAsset(name: 'UPGRADE.md', url: 'n'),
        ReleaseAsset(name: 'pepeunit-1.5.0-linux.AppImage', url: 'l'),
      ],
    );
    expect(release.assetFor('linux')?.url, 'l');
    expect(release.assetFor('windows'), isNull);
    expect(release.notes?.url, 'n');
  });

  test('the newest release skips drafts, pre-releases and odd tags', () {
    final releases = parseReleases(
      ReleaseHost.github,
      jsonDecode(
        _github([
          _release('1.5.0', []),
          _release('1.10.0', []),
          _release('2.0.0', [], draft: true),
          _release('2.1.0', [], prerelease: true),
          _release('nightly', []),
        ]),
      ),
    );
    expect(newestRelease(releases)?.tag, '1.10.0');
  });

  test('the GitLab answer reads links as files', () {
    final releases = parseReleases(ReleaseHost.gitlab, [
      {
        'tag_name': '1.6.0',
        'assets': {
          'sources': [
            {'format': 'zip', 'url': 'https://gl.test/src.zip'},
          ],
          'links': [
            {'name': 'UPGRADE.md', 'url': 'https://gl.test/UPGRADE.md'},
            {
              'name': 'pepeunit-1.6.0-android.apk',
              'url': 'https://gl.test/a',
              'direct_asset_url': 'https://gl.test/direct/a',
            },
          ],
        },
      },
    ]);
    expect(releases.single.assets.map((asset) => asset.name), [
      'UPGRADE.md',
      'pepeunit-1.6.0-android.apk',
    ]);
    expect(
      releases.single.assetFor('android')?.url,
      'https://gl.test/direct/a',
    );
  });

  group('check for an update', () {
    Future<UpdateCheck> check(
      MockClient client, {
      String? platform = 'linux',
    }) => checkForUpdate(client: client, current: '1.5.0', platform: platform);

    test('a newer release with files gives its notes and the file', () async {
      final client = MockClient((request) async {
        if (request.url.toString() == githubSource.releases) {
          return http.Response(
            _github([
              _release('1.5.0', ['UPGRADE.md']),
              _release('1.6.0', [
                'UPGRADE.md',
                'pepeunit-1.6.0-linux.AppImage',
                'pepeunit-1.6.0-android.apk',
              ]),
            ]),
            200,
          );
        }
        return http.Response.bytes(utf8.encode('Что нового'), 200);
      });
      final result = await check(client);
      expect(result.state, UpdateState.available);
      expect(result.latest, '1.6.0');
      expect(result.notes, 'Что нового');
      expect(
        result.binary?.url,
        'https://dl.test/1.6.0/pepeunit-1.6.0-linux.AppImage',
      );
      final web = await check(client, platform: null);
      expect(web.binary, isNull);
    });

    test('the same or an older release is current', () async {
      final client = MockClient(
        (request) async => http.Response(
          _github([
            _release('1.5.0', ['UPGRADE.md']),
          ]),
          200,
        ),
      );
      expect((await check(client)).state, UpdateState.current);
    });

    test('a newer release with no files says so', () async {
      final client = MockClient(
        (request) async => http.Response(_github([_release('1.6.0', [])]), 200),
      );
      final result = await check(client);
      expect(result.state, UpdateState.noAssets);
      expect(result.latest, '1.6.0');
    });

    test('GitLab answers when GitHub is down', () async {
      final seen = <String>[];
      final client = MockClient((request) async {
        seen.add(request.url.host);
        if (request.url.host == 'api.github.com') {
          return http.Response('down', 502);
        }
        return http.Response(
          jsonEncode([
            {
              'tag_name': '1.7.0',
              'assets': {
                'links': [
                  {'name': 'pepeunit-1.7.0-linux.AppImage', 'url': 'u'},
                ],
              },
            },
          ]),
          200,
        );
      });
      final result = await check(client);
      expect(seen.take(2), ['api.github.com', 'git.pepemoss.com']);
      expect(result.source.host, ReleaseHost.gitlab);
      expect(result.latest, '1.7.0');
    });

    test('every host down fails', () async {
      final client = MockClient((request) async => http.Response('', 500));
      await expectLater(check(client), throwsA(isA<UpdateSourcesFailed>()));
    });

    test('a slow host stops at the timeout', () async {
      final client = MockClient((request) async {
        await Future<void>.delayed(const Duration(seconds: 2));
        return http.Response('[]', 200);
      });
      await expectLater(
        checkForUpdate(
          client: client,
          current: '1.5.0',
          timeout: const Duration(milliseconds: 50),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('the notes fall back to the API link of the file', () async {
      final client = MockClient((request) async {
        if (request.url.toString() == githubSource.releases) {
          return http.Response(
            _github([
              _release('1.6.0', ['UPGRADE.md']),
            ]),
            200,
          );
        }
        if (request.url.toString() == 'https://api.test/assets/UPGRADE.md') {
          expect(request.headers['Accept'], 'application/octet-stream');
          return http.Response.bytes(utf8.encode('Через API'), 200);
        }
        return http.Response('blocked', 403);
      });
      expect((await check(client)).notes, 'Через API');
    });
  });

  test('the platform of this build is a platform with a file', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(nativePlatform(), 'macos');
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    expect(nativePlatform(), isNull);
    debugDefaultTargetPlatformOverride = null;
    expect(platformExtensions.keys, contains(nativePlatform() ?? 'android'));
  });
}
