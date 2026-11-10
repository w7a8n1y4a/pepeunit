import 'dart:convert';

import 'package:yaml/yaml.dart';

import '../locale/languages.dart';
import 'unit.dart';

/// What a new DataPipe config starts from: keep the last value of a text
/// topic, with no time limit. Only the fields the backend requires.
const pipeConfigTemplate = '''active_period:
  type: Permanent
filters:
  type_input_value: Text
  max_rate: 5
  last_unique_check: false
  max_size: 100
processing_policy:
  policy_type: LastValue
''';

/// Example configs the editor hands to the clipboard: one per policy and one
/// with the `alerts` block. They are the ones of the DataPipe examples article
/// (`docs/<lang>/user/datapipe/example.md`); keep both in step.
const pipeExamples = <String, String>{
  'LastValue': '''active_period:
  type: Permanent
filters:
  type_input_value: Text
  max_rate: 5
  last_unique_check: false
  max_size: 100
processing_policy:
  policy_type: LastValue
''',
  'NRecords': '''active_period:
  type: FromDate
  start: '2023-11-15T00:00:00+00:00'
filters:
  type_input_value: Text
  type_value_filtering: WhiteList
  filtering_values:
  - Alarm
  - Error
  - Warning
  max_rate: 0
  last_unique_check: true
  max_size: 100
processing_policy:
  policy_type: NRecords
  n_records_count: 512
''',
  'TimeWindow': '''active_period:
  type: ToDate
  end: '2030-11-15T00:00:00+00:00'
filters:
  type_input_value: Number
  type_value_threshold: Range
  threshold_min: 0
  threshold_max: 100
  max_rate: 60
  last_unique_check: false
  max_size: 50
transformations:
  round_decimal_point: 2
processing_policy:
  policy_type: TimeWindow
  time_window_size: 86400
''',
  'Aggregation': '''active_period:
  type: DateRange
  start: '2023-11-15T00:00:00+00:00'
  end: '2200-11-15T00:00:00+00:00'
filters:
  type_input_value: Number
  type_value_filtering: BlackList
  filtering_values:
  - -127.00
  - 85.00
  type_value_threshold: Range
  threshold_min: -50
  threshold_max: 120
  max_rate: 0
  last_unique_check: true
  max_size: 100
transformations:
  round_decimal_point: 2
processing_policy:
  policy_type: Aggregation
  time_window_size: 900
  aggregation_functions: Avg
''',
  'Alerts': '''active_period:
  type: Permanent
filters:
  type_input_value: Number
  max_rate: 0
  last_unique_check: false
  max_size: 50
processing_policy:
  policy_type: LastValue
alerts:
  is_enabled: true
  type_value_threshold: Range
  threshold_min: 18
  threshold_max: 26
  consecutive_count: 3
  max_frequency: 60
''',
};

/// `processing_policy.policy_type` of the config the backend stores. The
/// backend keeps it as JSON. Null when there is no config or it has no known
/// policy.
String? pipePolicyOfStored(String? json) {
  if (json == null || json.trim().isEmpty) return null;
  try {
    return _policyOf(jsonDecode(json));
  } catch (_) {
    return null;
  }
}

/// The same field in YAML text. Null when the text is not a config.
String? pipePolicyOfYaml(String text) {
  try {
    return _policyOf(loadYaml(text));
  } catch (_) {
    return null;
  }
}

String? _policyOf(Object? config) {
  if (config is! Map) return null;
  final policy = config['processing_policy'];
  if (policy is! Map) return null;
  final type = policy['policy_type'];
  if (type is String && pipePolicies.contains(type)) return type;
  return null;
}

/// Policy name for the lower edge of a cell.
String pipePolicyLabel(String language, String type) {
  switch (type) {
    case 'LastValue':
      return phrase(language, {'ru': 'Последнее значение', 'en': 'Last value'});
    case 'NRecords':
      return phrase(language, {'ru': 'N записей', 'en': 'N records'});
    case 'TimeWindow':
      return phrase(language, {'ru': 'Временное окно', 'en': 'Time window'});
    case 'Aggregation':
      return phrase(language, {'ru': 'Агрегация', 'en': 'Aggregation'});
    default:
      return type;
  }
}

enum PipeSyntaxKind { yaml, empty, notMap }

/// What is wrong with the text before the backend is asked.
class PipeSyntax {
  const PipeSyntax(this.line, this.message, [this.kind = PipeSyntaxKind.yaml]);

  /// One-based line the problem is on.
  final int line;
  final String message;
  final PipeSyntaxKind kind;
}

/// Null when [text] is a YAML mapping. The backend checks the rest.
PipeSyntax? pipeSyntaxIssue(String text) {
  try {
    final data = loadYaml(text);
    if (data == null) return const PipeSyntax(1, '', PipeSyntaxKind.empty);
    if (data is! Map) return const PipeSyntax(1, '', PipeSyntaxKind.notMap);
    return null;
  } on YamlException catch (error) {
    final line = error.span?.start.line;
    return PipeSyntax(line == null ? 1 : line + 1, error.message);
  } catch (error) {
    return PipeSyntax(1, '$error');
  }
}

String pipeSyntaxText(String language, PipeSyntax issue) {
  switch (issue.kind) {
    case PipeSyntaxKind.empty:
      return phrase(language, {
        'ru': 'YAML: конфиг пуст',
        'en': 'YAML: the config is empty',
      });
    case PipeSyntaxKind.notMap:
      return phrase(language, {
        'ru': 'YAML: ожидается словарь ключей',
        'en': 'YAML: a mapping of keys is expected',
      });
    case PipeSyntaxKind.yaml:
      return phrase(language, {
        'ru': 'YAML, строка ${issue.line}: ${issue.message}',
        'en': 'YAML, line ${issue.line}: ${issue.message}',
      });
  }
}

/// One line of the backend's verdict: the stage, then what it found.
String pipeIssueText(PipeIssue issue) =>
    '${issue.stage.toLowerCase()}: ${issue.message}';

/// A file name made of a topic, which holds slashes.
String pipeFileStem(String topic, String fallback) {
  final stem = topic.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
  final trimmed = stem.replaceAll(RegExp(r'^_+|_+$'), '');
  return trimmed.isEmpty ? fallback : trimmed;
}
