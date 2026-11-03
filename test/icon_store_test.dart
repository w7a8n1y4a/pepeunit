import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pepeunit_client/account/vault_store.dart';
import 'package:pepeunit_client/api/icon_disk.dart';
import 'package:pepeunit_client/api/icon_disk_io.dart' hide openIconDisk;
import 'package:pepeunit_client/api/icon_disk_open.dart';
import 'package:pepeunit_client/api/icon_store.dart';
import 'package:pepeunit_client/api/pepeunit_api.dart';
import 'package:pepeunit_client/app_model.dart';
import 'package:pepeunit_client/instances/instance.dart';

void main() {
  test('one icon load is shared, then served from memory', () async {
    final store = IconStore();
    var calls = 0;
    final gate = Future<void>.delayed(Duration.zero);
    Future<Uint8List> fetch() async {
      calls++;
      await gate;
      return Uint8List.fromList(const [9, 8, 7]);
    }

    final first = store.load(
      origin: 'https://unit.test',
      uuid: 'pic',
      fetch: fetch,
    );
    final second = store.load(
      origin: 'https://unit.test',
      uuid: 'pic',
      fetch: fetch,
    );
    expect(await first, await second);
    expect(calls, 1);
    await store.load(origin: 'https://unit.test', uuid: 'pic', fetch: fetch);
    expect(calls, 1);
    expect(store.peek(IconStore.keyOf('https://unit.test', 'pic'))?.length, 3);
  });

  test('a failed load is not cached', () async {
    final store = IconStore();
    var calls = 0;
    Future<Uint8List> fetch() async {
      calls++;
      throw StateError('down');
    }

    await expectLater(
      store.load(origin: 'https://unit.test', uuid: 'pic', fetch: fetch),
      throwsStateError,
    );
    await expectLater(
      store.load(origin: 'https://unit.test', uuid: 'pic', fetch: fetch),
      throwsStateError,
    );
    expect(calls, 2);
    expect(store.peek(IconStore.keyOf('https://unit.test', 'pic')), isNull);
  });

  test('disk satisfies the next load without a fetch', () async {
    final disk = _MemoryDisk();
    final store = IconStore(disk: disk);
    await store.remember(
      IconStore.keyOf('https://unit.test', 'pic'),
      Uint8List.fromList(const [4, 5]),
    );
    var calls = 0;
    final bytes = await IconStore(disk: disk).load(
      origin: 'https://unit.test',
      uuid: 'pic',
      fetch: () async {
        calls++;
        return Uint8List(0);
      },
    );
    expect(calls, 0);
    expect(bytes, Uint8List.fromList(const [4, 5]));
  });

  test('the test runner does not open the application directory', () async {
    expect(await openIconDisk(), isNull);
  });

  test('files round-trip and the oldest drop off past the cap', () async {
    final root = await Directory.systemTemp.createTemp('pepeunit-icons');
    try {
      final disk = FileIconDisk(root, cap: 2);
      await disk.write('https://unit.test/a', Uint8List.fromList(const [1]));
      final aged = File(
        '${root.path}${Platform.pathSeparator}${sha256.convert(utf8.encode('https://unit.test/a'))}',
      );
      await aged.setLastModified(DateTime.utc(2020));
      await disk.write('https://unit.test/b', Uint8List.fromList(const [2]));
      await disk.write('https://unit.test/c', Uint8List.fromList(const [3]));
      expect(await disk.read('https://unit.test/a'), isNull);
      expect(
        await disk.read('https://unit.test/b'),
        Uint8List.fromList(const [2]),
      );
      expect(
        await disk.read('https://unit.test/c'),
        Uint8List.fromList(const [3]),
      );
    } finally {
      await root.delete(recursive: true);
    }
  });

  test('a restarted model reads the icon from disk', () async {
    final disk = _MemoryDisk();
    final api = _IconApi();
    const url = 'https://unit.pepeunit.com$instanceCurrentPath';

    Future<AppModel> open() async {
      final model = AppModel(
        store: MemoryVaultStore(),
        api: (_) => api,
        hostedUrl: () async => null,
        iconDisk: () async => disk,
      );
      await model.load();
      model.vault.instances.add(InstanceRecord(url: url, active: true));
      return model;
    }

    final first = await open();
    await first.ensureIcon('pic');
    expect(api.calls, 1);
    expect(first.cachedIcon('pic'), Uint8List.fromList(const [1, 2, 3]));

    final second = await open();
    await second.ensureIcon('pic');
    expect(api.calls, 1);
    expect(second.cachedIcon('pic'), Uint8List.fromList(const [1, 2, 3]));
  });
}

class _MemoryDisk implements IconDisk {
  final files = <String, Uint8List>{};

  @override
  Future<Uint8List?> read(String key) async {
    final bytes = files[key];
    if (bytes == null) return null;
    return Uint8List.fromList(bytes);
  }

  @override
  Future<void> write(String key, Uint8List bytes) async {
    files[key] = Uint8List.fromList(bytes);
  }
}

class _IconApi extends PepeunitApi {
  _IconApi() : super('https://unit.pepeunit.com');

  var calls = 0;

  @override
  Future<Uint8List> icon(String uuid) async {
    calls++;
    return Uint8List.fromList(const [1, 2, 3]);
  }
}
