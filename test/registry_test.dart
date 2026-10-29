import 'dart:convert';
import 'dart:ui' show PointerDeviceKind, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pepeunit_client/account/vault_store.dart';
import 'package:pepeunit_client/api/pepeunit_api.dart';
import 'package:pepeunit_client/app_model.dart';
import 'package:pepeunit_client/app_scope.dart';
import 'package:pepeunit_client/features/registry/registry_chrome.dart';
import 'package:pepeunit_client/features/registry/registry_page.dart';
import 'package:pepeunit_client/features/registry/repo_page.dart';
import 'package:pepeunit_client/hive/hex_scene.dart';
import 'package:pepeunit_client/instances/instance.dart';
import 'package:pepeunit_client/instances/network_view.dart';
import 'package:pepeunit_client/registry/registry_view.dart';
import 'package:pepeunit_client/registry/repo.dart';

void main() {
  test('repository caption keeps the end of the link', () {
    expect(
      repoCaption('https://github.com/pepe/unit.git'),
      'github.com/pepe/unit',
    );
    expect(repoCaption('HTTP://gitlab.com/a/b.git'), 'gitlab.com/a/b');
    expect(repoCaption('github.com/a/b'), 'github.com/a/b');
    const exact = '123456789012345678901234';
    expect(exact.length, 24);
    expect(repoCaption('https://$exact.git'), exact);
    expect(
      repoCaption(
        'https://github.com/pepe/pepeunit/units/universal_test_unit.git',
      ),
      'nits/universal_test_unit',
    );
    expect(repoCaption('https://x.git').length, lessThanOrEqualTo(24));
  });

  test('size is a bare number of bytes, kilobytes or larger', () {
    expect(repoSizeLabel(0, 'ru'), '0 Б');
    expect(repoSizeLabel(512, 'en'), '512 B');
    expect(repoSizeLabel(1024, 'ru'), '1 КБ');
    expect(repoSizeLabel(1024, 'en'), '1 KB');
    expect(repoSizeLabel(1536, 'ru'), '1.5 КБ');
    expect(repoSizeLabel(10 * 1024 * 1024, 'ru'), '10 МБ');
    expect(repoSizeLabel(1536 * 1024 * 1024, 'en'), '1.5 GB');
    expect(repoPlatformLabel('ru', 'Github'), 'Гитхаб');
    expect(repoPlatformLabel('en', 'Gitlab'), 'GitLab');
  });

  test('registry search uses url order and a public or private flag', () {
    final query = RepoQuery();
    expect(query.order, 'asc');
    expect(query.publicOnly, isNull);
    expect(query.toggleKind('public'), isTrue);
    expect(query.publicOnly, isFalse);
    expect(query.toggleKind('private'), isFalse);
    expect(query.kinds, {'private'});
    expect(query.setOrder('desc'), isTrue);
    expect(query.setOrder('desc'), isFalse);
    expect(query.setOrder('sideways'), isFalse);
    expect(repoPageLimit(1), 4);
    expect(repoPageLimit(searchScaleTick), 10);
    expect(repoPageLimit(scaleTickMax), 16);
    expect(
      repoWindowText(offset: 0, limit: 16, count: 40, ofWord: 'из'),
      '1-16 из 40',
    );
    expect(repoCanPageBack(offset: 0, count: 40), isFalse);
    expect(repoCanPageForward(offset: 0, limit: 16, count: 40), isTrue);
    final board = reposBoard(
      tick: scaleTickMax,
      uuids: [for (var i = 0; i < 16; i++) 'r$i'],
    );
    expect(board.slots.firstWhere((slot) => slot.id == 'back').q, 0);
    expect(board.slots.firstWhere((slot) => slot.id == 'back').r, 0);
    expect(board.slots.firstWhere((slot) => slot.id == 'query').r, -1);
    expect(board.slots.where((slot) => slot.id.startsWith('repo:')).length, 16);
    expect(
      repoMenuIds(private: false, owned: false),
      isNot(contains('credentials')),
    );
    expect(repoMenuIds(private: true, owned: false), contains('credentials'));
    expect(repoMenuIds(private: false, owned: true), contains('delete'));
    expect(
      repoMenuIds(private: true, owned: true),
      containsAll(['credentials', 'delete']),
    );
    expect(cardBoard(repoMenuIds(private: false, owned: false)).length, 6);
  });

  test('branches stay on one ring until the list outgrows it', () {
    final few = branchesBoard(tick: 1, page: 0, names: const ['main', 'dev']);
    expect(few.slots.where((slot) => slot.id.startsWith('branch:')).length, 2);
    expect(few.canZoomIn, isFalse);
    expect(few.slots.where((slot) => slot.id == 'prev'), isEmpty);
    final many = branchesBoard(
      tick: 1,
      page: 0,
      names: [for (var i = 0; i < 8; i++) 'b$i'],
    );
    expect(many.slots.where((slot) => slot.id.startsWith('branch:')).length, 6);
    expect(many.canZoomIn, isTrue);
    final paged = branchesBoard(
      tick: scaleTickMax,
      page: 0,
      names: [for (var i = 0; i < 40; i++) 'feature/$i'],
    );
    expect(paged.pages, greaterThan(1));
    expect(paged.slots.where((slot) => slot.id == 'next'), isNotEmpty);
    expect(paged.canZoomIn, isFalse);
  });

  test('a repo card reads the link, the size and who can see it', () {
    final repo = RegistryRepo.fromJson({
      'uuid': 'repo-1',
      'icon_uuid': '',
      'platform': 'Github',
      'repository_url': 'https://github.com/pepe/unit.git',
      'is_public_repository': false,
      'local_repository_size': 2048,
      'sync_status': 'Updated',
      'sync_last_datetime': '2026-03-04T05:06:07Z',
      'create_datetime': '2026-01-02T03:04:05Z',
      'last_update_datetime': '2026-02-03T04:05:06Z',
      'creator_uuid': 'user-should-stay-out',
      'branches': ['main', 'dev'],
      'releases_data': '{"1.0.0": []}',
    });
    expect(repo.platform, 'Github');
    expect(repo.public, isFalse);
    expect(repo.branches, ['main', 'dev']);
    final lines = [for (final page in repoSummaries(repo, 'ru')) ...page.lines]
        .join('\n');
    expect(repo.creatorUuid, 'user-should-stay-out');
    expect(repoOwnedBy(repo, 'user-should-stay-out'), isTrue);
    expect(repoOwnedBy(repo, 'other'), isFalse);
    expect(lines.contains('user-should-stay-out'), isFalse);
    expect(lines.contains('Приватный · Гитхаб'), isTrue);
    expect(lines.contains('Обновлён · 2026.03.04 05:06'), isTrue);
    expect(lines.contains('2 КБ · Ветки 2'), isTrue);
    expect(lines.contains('Создан 2026.01.02 03:04'), isTrue);
    expect(lines.contains('Изменён 2026.02.03 04:05'), isTrue);
    expect(lines.contains('Github'), isFalse);
    final english = [
      for (final page in repoSummaries(repo, 'en')) ...page.lines,
    ].join('\n');
    expect(english.contains('Private · GitHub'), isTrue);
    expect(english.contains('2 KB · Branches 2'), isTrue);
    expect(shortStamp(repo.created), '2026.01.02 03:04');
    final slot = repoMark(id: 'card', repo: repo, language: 'ru', q: 0, r: 0);
    expect(slot.footerLeft, 'Приватный');
    expect(slot.sideRight, '2 КБ');
    expect(slot.sideLeft, isNull);
    expect(slot.footer, 'Гитхаб');
    expect(slotLabel(slot), 'github.com/pepe/unit, 2 КБ');
  });

  test('repo list sends only the url sort and skips creator', () async {
    final capture = _Capture();
    final api = PepeunitApi('https://devunit.pepeunit.com', client: capture);
    await api.repos(
      token: 't',
      offset: 16,
      limit: 16,
      search: ' pepe ',
      order: 'asc',
      public: false,
    );
    final query = capture.uri!.queryParameters;
    expect(query['order_by_repository_url'], 'asc');
    expect(query['search_string'], 'pepe');
    expect(query['is_public_repository'], 'false');
    expect(query['offset'], '16');
    expect(query.containsKey('creator_uuid'), isFalse);
    expect(query.containsKey('order_by_create_date'), isFalse);
    expect(query.containsKey('order_by_last_update'), isFalse);
    expect(capture.uri!.path, '/pepeunit/api/v1/repo');
  });

  testWidgets('registry opens on search and a repo card lists its actions', (
    tester,
  ) async {
    final model = AppModel(store: MemoryVaultStore(), api: (_) => _RepoApi());
    await model.load();
    model.vault.instances.add(
      InstanceRecord(
        url: defaultInstanceUrl,
        token: 't',
        role: 'User',
        active: true,
      ),
    );
    await tester.pumpWidget(
      AppScope(
        model: model,
        child: const MaterialApp(home: RegistryPage(scope: 1)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Фильтр'), findsOneWidget);
    expect(find.bySemanticsLabel('Публичные'), findsOneWidget);
    expect(find.bySemanticsLabel('Приватные'), findsOneWidget);
    expect(find.bySemanticsLabel('А-Я'), findsOneWidget);
    expect(find.bySemanticsLabel('gitlab.com/pepe/unit, 1 КБ'), findsOneWidget);
    final prompt = find.byKey(const ValueKey('line-prompt'));
    expect(tester.widget<Text>(prompt).data, 'Поиск');
    final promptBox = tester.getRect(prompt);
    final promptDy = promptBox.center.dy;
    final search = find.byKey(const ValueKey('registry-search'));
    final searchBox = tester.getRect(search);
    final mark = tester.getRect(_searchMark);
    final row = tester.getRect(_searchRow(search));
    expect((promptBox.center.dx - row.center.dx).abs(), lessThan(4));
    expect(
      (mark.center.dx - (row.left + row.width / 5)).abs(),
      lessThan(row.width * 0.04),
    );
    expect(promptBox.center.dy - row.center.dy, greaterThan(row.height * 0.09));
    expect((searchBox.center.dy - promptBox.center.dy).abs(), lessThan(4));
    expect(
      find.ancestor(of: prompt, matching: find.byType(HoverPop)),
      findsOneWidget,
    );
    final hover = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await hover.addPointer();
    await hover.moveTo(promptBox.center);
    await tester.pump();
    final scale = tester.widget<Transform>(
      find
          .descendant(
            of: find.ancestor(of: prompt, matching: find.byType(HoverPop)),
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(scale.transform.getMaxScaleOnAxis(), closeTo(1.06, 0.001));
    await hover.removePointer();
    await tester.tap(search);
    await tester.pump();
    expect(find.byKey(const ValueKey('line-prompt')), findsNothing);
    expect(tester.widget<TextField>(search).focusNode!.hasFocus, isTrue);
    await tester.enterText(search, 'p');
    await tester.pump();
    expect(tester.widget<TextField>(search).focusNode!.hasFocus, isTrue);
    expect((tester.getRect(search).center.dy - promptDy).abs(), lessThan(4));
    await tester.enterText(search, 'pepeunit-registry-search-query');
    await tester.pump();
    await tester.pump();
    expect(tester.widget<TextField>(search).focusNode!.hasFocus, isTrue);
    final parked = tester.getRect(_searchMark);
    final typedRow = tester.getRect(_searchRow(search));
    expect(
      (parked.center.dx - (typedRow.left + typedRow.width / 5)).abs(),
      lessThan(typedRow.width * 0.04),
    );
    expect(
      (tester.getRect(search).center.dx - typedRow.center.dx).abs(),
      lessThan(4),
    );
    final clip = tester.renderObject<RenderClipRect>(
      find.byKey(const ValueKey('search-text-clip')),
    );
    final clipRect = clip.clipper!.getClip(clip.size);
    final clipLeft = clip.localToGlobal(Offset(clipRect.left, 0)).dx;
    expect(clipLeft, greaterThan(parked.left + parked.width * 0.55));
    expect(clipLeft, lessThan(parked.right + 8));
    final query = 'pepeunit-registry-search-query';
    final middle = _editable(
      tester.element(
        find.descendant(of: search, matching: find.byType(EditableText)),
      ),
    )!;
    final midCaret = middle.localToGlobal(
      middle
          .getLocalRectForCaret(TextPosition(offset: query.length ~/ 2))
          .center,
    );
    expect(
      (midCaret.dx - typedRow.center.dx).abs(),
      lessThan(typedRow.width * 0.08),
    );
    expect(find.byType(ShaderMask), findsNothing);
    tester.widget<TextField>(search).controller!.selection =
        const TextSelection.collapsed(offset: 0);
    await tester.pump();
    await tester.pump();
    final editable = _editable(
      tester.element(
        find.descendant(of: search, matching: find.byType(EditableText)),
      ),
    )!;
    final caret = editable.localToGlobal(
      editable.getLocalRectForCaret(const TextPosition(offset: 0)).center,
    );
    expect(caret.dx, lessThan(typedRow.center.dx));

    await tester.pumpWidget(
      AppScope(
        model: model,
        child: const MaterialApp(home: RepoPage(uuid: 'r1')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Сводка'), findsOneWidget);
    expect(find.bySemanticsLabel('Креды'), findsNothing);
    expect(find.bySemanticsLabel('Удалить'), findsNothing);
    expect(find.bySemanticsLabel('Ветки'), findsOneWidget);
    expect(tester.getSemantics(find.bySemanticsLabel('Ветки')).value, '1 шт.');
    expect(find.bySemanticsLabel('Синхронизировать репо'), findsOneWidget);
    final unit = tester.getSemantics(find.bySemanticsLabel('Создать аппарат'));
    expect(unit.flagsCollection.isEnabled, Tristate.isFalse);
    expect(find.bySemanticsLabel('gitlab.com/pepe/unit, 1 КБ'), findsOneWidget);
  });

  testWidgets('update copy watches the repo until it leaves updating', (
    tester,
  ) async {
    final api = _WatchApi();
    final model = AppModel(store: MemoryVaultStore(), api: (_) => api);
    await model.load();
    model.vault.instances.add(
      InstanceRecord(
        url: defaultInstanceUrl,
        token: 't',
        role: 'User',
        active: true,
      ),
    );
    await tester.pumpWidget(
      AppScope(
        model: model,
        child: const MaterialApp(home: RepoPage(uuid: 'r1')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Синхронизировать репо'));
    await tester.pump();
    expect(api.watches, 1);
    final cooling = tester.getSemantics(
      find.bySemanticsLabel('Синхронизировать репо'),
    );
    expect(cooling.value, '1:00');
    expect(cooling.flagsCollection.isEnabled, Tristate.isFalse);

    await tester.pump(const Duration(seconds: 10));
    expect(api.watches, 2);
    final done = tester.getSemantics(
      find.bySemanticsLabel('Синхронизировать репо'),
    );
    expect(done.value, 'Обновлён');
    expect(done.flagsCollection.isEnabled, Tristate.isTrue);
  });
}

RenderEditable? _editable(Element element) {
  final object = element.renderObject;
  if (object is RenderEditable) return object;
  RenderEditable? found;
  element.visitChildElements((child) {
    found ??= _editable(child);
  });
  return found;
}

Finder _searchRow(Finder field) {
  return find
      .ancestor(
        of: field,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is SizedBox &&
              widget.width != null &&
              widget.height != null,
        ),
      )
      .first;
}

final _searchMark = find.byWidgetPredicate((widget) {
  if (widget is! SvgPicture) return false;
  final loader = widget.bytesLoader;
  return loader is SvgAssetLoader &&
      loader.assetName == 'assets/icons/search.svg';
});

class _RepoApi extends PepeunitApi {
  _RepoApi() : super('https://devunit.pepeunit.com');

  RegistryRepo get _sample => const RegistryRepo(
    uuid: 'r1',
    iconUuid: '',
    platform: 'Gitlab',
    repositoryUrl: 'https://gitlab.com/pepe/unit.git',
    public: true,
    localSize: 1024,
    branches: ['main'],
  );

  @override
  Future<({int count, List<RegistryRepo> repos})> repos({
    required String token,
    required int offset,
    required int limit,
    required String search,
    required String order,
    bool? public,
  }) async {
    return (count: 1, repos: [_sample]);
  }

  @override
  Future<RegistryRepo> readRepo(String token, String uuid) async => _sample;
}

class _WatchApi extends _RepoApi {
  var watches = 0;
  var _armed = false;

  RegistryRepo _copy(String status) => RegistryRepo(
    uuid: 'r1',
    iconUuid: '',
    platform: 'Gitlab',
    repositoryUrl: 'https://gitlab.com/pepe/unit.git',
    public: true,
    localSize: 1024,
    branches: const ['main'],
    syncStatus: status,
  );

  @override
  Future<void> updateLocalRepository(String token, String uuid) async {
    _armed = true;
  }

  @override
  Future<RegistryRepo> readRepo(String token, String uuid) async {
    if (!_armed) return _copy('Updated');
    watches++;
    return _copy(watches < 2 ? 'Processing' : 'Updated');
  }
}

class _Capture extends http.BaseClient {
  Uri? uri;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    uri = request.url;
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode('{"count":0,"repos":[]}')),
      200,
    );
  }
}
