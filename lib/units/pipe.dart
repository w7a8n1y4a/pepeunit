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
