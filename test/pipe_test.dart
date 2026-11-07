import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pepeunit_client/account/key_file_port.dart';
import 'package:pepeunit_client/account/vault_store.dart';
import 'package:pepeunit_client/api/pepeunit_api.dart';
import 'package:pepeunit_client/app_model.dart';
import 'package:pepeunit_client/app_scope.dart';
import 'package:pepeunit_client/features/code/code_highlight.dart';
import 'package:pepeunit_client/features/units/unit_pipe_pages.dart';
import 'package:pepeunit_client/features/units/units_chrome.dart';
import 'package:pepeunit_client/hive/hex_scene.dart';
import 'package:pepeunit_client/instances/instance.dart';
import 'package:pepeunit_client/units/pipe.dart';
import 'package:pepeunit_client/units/unit.dart';

void main() {
  group('highlight', () {
    String joined(List<CodeToken> line) => line.map((t) => t.text).join();

    List<CodeKind> kinds(List<CodeToken> line) =>
        [for (final token in line) token.kind];

    test('json keeps every character and colors the parts', () {
      const text = '{\n    "a": [1, -2.5e3, true, null, "x"],\n    "b": {}\n}';
      final lines = codeTokens(text, CodeLanguage.json);
      expect([for (final line in lines) joined(line)].join('\n'), text);
      final second = lines[1];
      expect(second.firstWhere((t) => t.text == '"a"').kind, CodeKind.key);
      expect(second.firstWhere((t) => t.text == '"x"').kind, CodeKind.string);
      expect(second.firstWhere((t) => t.text == '1').kind, CodeKind.number);
      expect(second.firstWhere((t) => t.text == '-2.5e3').kind, CodeKind.number);
      expect(second.firstWhere((t) => t.text == 'true').kind, CodeKind.keyword);
      expect(second.firstWhere((t) => t.text == 'null').kind, CodeKind.keyword);
    });

    test('auto colors json only', () {
      expect(codeSniff('  {"a": 1}'), CodeLanguage.json);
      expect(codeSniff('[1]'), CodeLanguage.json);
      expect(codeSniff('23.5'), CodeLanguage.plain);
      final plain = codeTokens('hello: world', CodeLanguage.auto);
      expect(kinds(plain.single), [CodeKind.plain]);
    });

    test('yaml keeps every character and colors the parts', () {
      const text = '''# pipe
active_period:
  type: Permanent
filters:
  max_rate: 5
  last_unique_check: false
  filtering_values: [1, "two", 3.5]
  note: "a: b" # tail
processing_policy:
  policy_type: NRecords
list:
  - one
  - key: |
      free: text
      more
  - end
''';
      final lines = codeTokens(text, CodeLanguage.yaml);
      expect([for (final line in lines) joined(line)].join('\n'), text);
      expect(kinds(lines[0]), [CodeKind.comment]);
      expect(lines[1].first.kind, CodeKind.key);
      expect(lines[2].firstWhere((t) => t.text == 'type').kind, CodeKind.key);
      expect(
        lines[2].firstWhere((t) => t.text == 'Permanent').kind,
        CodeKind.string,
      );
      expect(lines[4].firstWhere((t) => t.text == '5').kind, CodeKind.number);
      expect(
        lines[5].firstWhere((t) => t.text == 'false').kind,
        CodeKind.keyword,
      );
      expect(lines[6].firstWhere((t) => t.text == '"two"').kind, CodeKind.string);
      expect(lines[7].firstWhere((t) => t.text == '"a: b"').kind, CodeKind.string);
      expect(lines[7].last.kind, CodeKind.comment);
      expect(lines[11].first.kind, CodeKind.plain);
      expect(lines[11].firstWhere((t) => t.text == '-').kind, CodeKind.punct);
      // Lines inside a block scalar are text, even with a colon in them.
      expect(kinds(lines[13]), [CodeKind.string]);
      expect(kinds(lines[14]), [CodeKind.string]);
      expect(lines[15].firstWhere((t) => t.text == 'end').kind, CodeKind.string);
      expect(lines[15].firstWhere((t) => t.text == '-').kind, CodeKind.punct);
    });

    test('a field controller keeps the text it shows', () {
      final controller = CodeController(language: CodeLanguage.yaml)
        ..text = 'a: 1\nb: "x"';
      addTearDown(controller.dispose);
      final span = codeSpans(
        controller.text,
        CodeLanguage.yaml,
        const TextStyle(),
      );
      expect(TextSpan(children: span).toPlainText(), controller.text);
    });
  });

  group('pipe config', () {
    test('the stored policy and its label', () {
      expect(pipePolicyOfStored(null), isNull);
      expect(pipePolicyOfStored(''), isNull);
      expect(pipePolicyOfStored('not json'), isNull);
      expect(
        pipePolicyOfStored('{"processing_policy": {"policy_type": "NRecords"}}'),
        'NRecords',
      );
      expect(
        pipePolicyOfStored('{"processing_policy": {"policy_type": "Other"}}'),
        isNull,
      );
      expect(pipePolicyOfYaml(pipeConfigTemplate), 'LastValue');
      expect(pipePolicyOfYaml('a: ['), isNull);
      expect(pipePolicyLabel('ru', 'TimeWindow'), 'Временное окно');
      expect(pipePolicyLabel('en', 'TimeWindow'), 'Time window');
      expect(pipePolicyLabel('ru', 'Aggregation'), 'Агрегация');
    });

    test('syntax is told before the backend is asked', () {
      expect(pipeSyntaxIssue(pipeConfigTemplate), isNull);
      expect(pipeSyntaxIssue('')!.kind, PipeSyntaxKind.empty);
      expect(pipeSyntaxIssue('- a\n- b')!.kind, PipeSyntaxKind.notMap);
      final broken = pipeSyntaxIssue('a: 1\nb: [1, 2\nc: 3');
      expect(broken!.kind, PipeSyntaxKind.yaml);
      expect(broken.line, greaterThan(1));
      expect(pipeSyntaxText('ru', broken), startsWith('YAML, строка'));
    });

    test('a topic makes a file name', () {
      expect(pipeFileStem('abc/pepeunit', 'x'), 'abc_pepeunit');
      expect(pipeFileStem('///', 'x'), 'x');
    });
  });

  group('screen', () {
    Future<(AppModel, _PipeApi, MemoryKeyFilePort)> open(
      WidgetTester tester,
      _PipeApi api,
    ) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final files = MemoryKeyFilePort();
      final model = AppModel(
        store: MemoryVaultStore(),
        api: (_) => api,
        files: files,
      );
      await model.load();
      model.vault.instances.add(
        InstanceRecord(
          url: defaultInstanceUrl,
          token: 't',
          role: 'User',
          userUuid: 'me',
          active: true,
        ),
      );
      await tester.pumpWidget(
        AppScope(
          model: model,
          child: const MaterialApp(home: UnitPipePage(uuid: 'io1')),
        ),
      );
      await tester.pumpAndSettle();
      return (model, api, files);
    }

    Iterable<HexSlot> cells(WidgetTester tester) =>
        tester.widget<HexScene>(find.byType(HexScene)).slots;

    HexSlot cell(WidgetTester tester, String id) =>
        cells(tester).firstWhere((slot) => slot.id == id);

    testWidgets('the flag is off, so the other cells do nothing', (
      tester,
    ) async {
      final (_, api, _) = await open(tester, _PipeApi());
      expect(cell(tester, 'flag').enabled, isTrue);
      expect(cell(tester, 'flag').footer, 'выкл');
      for (final id in ['editor', 'import', 'export', 'clear']) {
        expect(cell(tester, id).enabled, isFalse, reason: id);
      }
      final colors = {for (final slot in cells(tester)) slot.id: slot.color};
      expect(colors['clear'], errorColor);
      expect(colors['flag'], unitPipeColor);
      expect(colors['editor'], unitPipeColor);
      expect(api.calls, isEmpty);
    });

    testWidgets('the flag switches the pipe and wakes the cells', (
      tester,
    ) async {
      final (_, api, _) = await open(tester, _PipeApi());
      await tester.tap(find.bySemanticsLabel('DataPipe'));
      await tester.pumpAndSettle();
      expect(api.patch, {'is_data_pipe_active': true});
      expect(cell(tester, 'flag').footer, 'вкл');
      for (final id in ['editor', 'import', 'export', 'clear']) {
        expect(cell(tester, id).enabled, isTrue, reason: id);
      }
      expect(cell(tester, 'editor').center, '.yml');
      expect(cell(tester, 'editor').footer, isNull);
    });

    testWidgets('a valid config names its policy on the editor cell', (
      tester,
    ) async {
      final (_, _, _) = await open(
        tester,
        _PipeApi(
          active: true,
          yml: '{"processing_policy": {"policy_type": "TimeWindow"}}',
        ),
      );
      expect(cell(tester, 'editor').footer, 'Временное окно');
      expect(cells(tester).map((slot) => slot.id), contains('import'));
      expect(cells(tester).map((slot) => slot.id), contains('export'));
    });

    testWidgets('LastValue has no upload and no download', (tester) async {
      await open(
        tester,
        _PipeApi(
          active: true,
          yml: '{"processing_policy": {"policy_type": "LastValue"}}',
        ),
      );
      expect(
        [for (final slot in cells(tester)) slot.id],
        unorderedEquals(['flag', 'editor', 'clear', 'back']),
      );
      expect(cell(tester, 'editor').footer, 'Последнее значение');
    });

    testWidgets('the editor opens with the stored config and checks it', (
      tester,
    ) async {
      final (_, api, _) = await open(
        tester,
        _PipeApi(
          active: true,
          yml: '{"processing_policy": {"policy_type": "LastValue"}}',
          config: 'processing_policy:\n  policy_type: LastValue\n',
        ),
      );
      await tester.tap(find.bySemanticsLabel('Редактор'));
      await tester.pumpAndSettle();
      expect(find.text('Редактор DataPipe'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, contains('policy_type: LastValue'));
      expect(api.calls, contains('check'));
      expect(find.text('Сохранить'), findsOneWidget);
      expect(find.text('Проверить'), findsOneWidget);
      expect(find.text('Загрузить'), findsOneWidget);
      expect(find.text('Выгрузить'), findsOneWidget);
    });

    testWidgets('a broken text shows its error under the editor', (
      tester,
    ) async {
      final (_, api, _) = await open(
        tester,
        _PipeApi(active: true, config: 'a: 1\n'),
      );
      await tester.tap(find.bySemanticsLabel('Редактор'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'a: [1\nb: 2');
      await tester.pump();
      expect(find.textContaining('YAML, строка'), findsOneWidget);
      final before = api.calls.where((call) => call == 'check').length;
      await tester.pump(const Duration(seconds: 1));
      expect(
        api.calls.where((call) => call == 'check').length,
        before,
        reason: 'broken yaml never reaches the backend',
      );
    });

    testWidgets('the backend verdict stands under the editor and blocks save', (
      tester,
    ) async {
      final (_, api, _) = await open(
        tester,
        _PipeApi(
          active: true,
          config: 'a: 1\n',
          issues: const [
            PipeIssue(stage: 'Filters', message: 'max_rate is required', code: 1),
          ],
        ),
      );
      await tester.tap(find.bySemanticsLabel('Редактор'));
      await tester.pumpAndSettle();
      expect(find.text('filters: max_rate is required'), findsOneWidget);
      await tester.tap(find.text('Сохранить'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(api.calls, isNot(contains('set')));
    });

    testWidgets('save sends the text typed', (tester) async {
      final (_, api, _) = await open(
        tester,
        _PipeApi(active: true, config: 'a: 1\n'),
      );
      await tester.tap(find.bySemanticsLabel('Редактор'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'a: 2\n');
      await tester.pump();
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(api.set, 'a: 2\n');
      expect(find.text('Сохранено'), findsOneWidget);
    });

    testWidgets('a pipe with no config starts from the template', (
      tester,
    ) async {
      final (_, api, _) = await open(tester, _PipeApi(active: true));
      await tester.tap(find.bySemanticsLabel('Редактор'));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, pipeConfigTemplate);
      expect(api.calls, isNot(contains('config')));
    });

    testWidgets('deleting the data asks once more', (tester) async {
      final (_, api, _) = await open(tester, _PipeApi(active: true));
      await tester.tap(find.bySemanticsLabel('Удалить все данные'));
      await tester.pumpAndSettle();
      expect(api.calls, isNot(contains('delete')));
      expect([for (final slot in cells(tester)) slot.id], ['confirm', 'back']);
      await tester.tap(find.bySemanticsLabel('Удалить все данные'));
      await tester.pumpAndSettle();
      expect(api.calls, contains('delete'));
      expect(cell(tester, 'clear').footer, 'готово');
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('back from the confirmation returns to the menu', (
      tester,
    ) async {
      final (_, api, _) = await open(tester, _PipeApi(active: true));
      await tester.tap(find.bySemanticsLabel('Удалить все данные'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Назад'));
      await tester.pumpAndSettle();
      expect(cell(tester, 'flag').title, 'DataPipe');
      expect(api.calls, isNot(contains('delete')));
    });

    testWidgets('upload sends the file, download saves the zip', (
      tester,
    ) async {
      final (_, api, files) = await open(tester, _PipeApi(active: true));
      files.nextPick = Uint8List.fromList(utf8.encode('state,create_datetime\n'));
      await tester.tap(find.bySemanticsLabel('Загрузить данные'));
      await tester.pumpAndSettle();
      expect(api.csv, 'state,create_datetime\n');
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.bySemanticsLabel('Выгрузить данные'));
      await tester.pumpAndSettle();
      expect(files.savedName, 'u_pepeunit.zip');
      await tester.pump(const Duration(seconds: 3));
    });
  });
}

class _PipeApi extends PepeunitApi {
  _PipeApi({this.active = false, this.yml, this.config, this.issues = const []})
    : super('https://devunit.pepeunit.com');

  bool active;
  final String? yml;
  final String? config;
  final List<PipeIssue> issues;
  final calls = <String>[];
  Map<String, Object?>? patch;
  String? set;
  String? csv;

  UnitIo _io() => UnitIo(
    uuid: 'io1',
    type: 'Input',
    visibility: 'Private',
    rewritable: false,
    maxConnections: 10,
    topic: 'u/pepeunit',
    updated: '',
    pipeActive: active,
    created: '',
    unitUuid: 'u1',
    creatorUuid: 'me',
    pipeYml: yml,
  );

  @override
  Future<UnitIo> readUnitIo(String token, String uuid) async => _io();

  @override
  Future<UnitIo> updateUnitIo(
    String token,
    String uuid,
    Map<String, Object?> patch,
  ) async {
    this.patch = patch;
    active = patch['is_data_pipe_active'] == true;
    return _io();
  }

  @override
  Future<List<PipeIssue>> checkPipe(String token, Uint8List yml) async {
    calls.add('check');
    return issues;
  }

  @override
  Future<void> setPipe(String token, String uuid, Uint8List yml) async {
    calls.add('set');
    set = utf8.decode(yml);
  }

  @override
  Future<Uint8List> pipeConfig(String token, String uuid) async {
    calls.add('config');
    return Uint8List.fromList(utf8.encode(config ?? ''));
  }

  @override
  Future<Uint8List> pipeCsv(String token, String uuid) async {
    calls.add('csv');
    return Uint8List.fromList([80, 75]);
  }

  @override
  Future<void> uploadPipeCsv(String token, String uuid, Uint8List csv) async {
    calls.add('upload');
    this.csv = utf8.decode(csv);
  }

  @override
  Future<void> deletePipeData(String token, String uuid) async {
    calls.add('delete');
  }
}
