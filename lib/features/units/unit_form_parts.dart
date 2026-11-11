import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../locale/languages.dart';
import '../../units/unit.dart';
import '../line_input.dart';
import 'units_chrome.dart';

/// Update flags collected on the updates menu and returned to the form.
class UnitUpdateDraft {
  const UnitUpdateDraft({
    required this.compilable,
    required this.auto,
    required this.tagsOnly,
    this.commit,
    this.platform,
  });

  final bool compilable;
  final bool auto;
  final bool tagsOnly;
  final String? commit;
  final String? platform;
}

/// Route of the updates menu with the flags the form holds now.
String unitUpdatesPath({
  required String repo,
  required String branch,
  required bool compilable,
  required bool auto,
  required bool tags,
  String? commit,
  String? platform,
}) {
  final query = <String, String>{
    'repo': repo,
    'branch': branch,
    'compilable': compilable ? '1' : '0',
    'auto': auto ? '1' : '0',
    'tags': tags ? '1' : '0',
    if (commit != null && commit.isNotEmpty) 'commit': commit,
    if (platform != null && platform.isNotEmpty) 'platform': platform,
  };
  return Uri(path: '/units/new/updates', queryParameters: query).toString();
}

/// What one form holds before it complains: the text of a failure, or of the
/// hint under the name field.
typedef UnitFormProblem = ({String? issue, String? failure});

/// Fields the create form and the settings form of a unit share.
class UnitFormFields {
  String visibility = 'Internal';
  bool compilable = false;
  bool auto = true;
  bool tags = true;
  String branch = '';
  String? commit;
  String? platform;

  /// Takes the stored values of [unit].
  void takeUnit(Unit unit) {
    visibility = unit.visibility.isEmpty ? 'Internal' : unit.visibility;
    compilable = unit.compilable;
    auto = unit.auto;
    tags = unit.compilable || unit.tagsOnly;
    branch = unit.branch;
    commit = unit.commit;
    platform = unit.platform;
  }

  /// A new branch drops the commit and the platform chosen for the old one.
  void takeBranch(String name) {
    branch = name;
    commit = null;
    platform = null;
  }

  void takeUpdates(UnitUpdateDraft draft) {
    compilable = draft.compilable;
    auto = draft.auto;
    tags = draft.compilable || draft.tagsOnly;
    commit = draft.commit;
    platform = draft.platform;
  }

  /// Opens the updates menu with these flags; `null` when it closes unsaved.
  Future<UnitUpdateDraft?> pickUpdates(BuildContext context, String repo) {
    return context.push<UnitUpdateDraft>(
      unitUpdatesPath(
        repo: repo,
        branch: branch,
        compilable: compilable,
        auto: auto,
        tags: compilable || tags,
        commit: commit,
        platform: platform,
      ),
    );
  }

  /// The first thing wrong with [name] and these fields, or `null`.
  UnitFormProblem? problem(String language, String name) {
    if (!unitNameOk(name)) {
      return (
        issue: localized(
          language,
          'От 4 до 20: буквы, цифры, _ . -',
          '4 to 20: letters, digits, _ . -',
        ),
        failure: null,
      );
    }
    final String? failure;
    if (branch.isEmpty) {
      failure = localized(language, 'Нужна ветка', 'A branch is required');
    } else if (!auto && (commit == null || commit!.isEmpty)) {
      failure = localized(language, 'Нужен коммит', 'A commit is required');
    } else if (compilable && (platform == null || platform!.isEmpty)) {
      failure = localized(
        language,
        'Нужна платформа',
        'A platform is required',
      );
    } else {
      return null;
    }
    return (issue: null, failure: failure);
  }

  /// Request body. With [clearUnused] a commit or a platform the flags do not
  /// need goes out as `null`, so a saved unit forgets it.
  Map<String, Object?> body(String name, {bool clearUnused = false}) => {
    'name': name,
    'visibility_level': visibility,
    'target_branch': branch,
    'is_auto_update_unit': auto,
    'is_compilable_unit': compilable,
    'is_only_tag_update': compilable || tags,
    if (!auto || clearUnused) 'target_commit': auto ? null : commit,
    if (compilable || clearUnused)
      'target_firmware_platform': compilable ? platform : null,
  };
}

HexSlot unitFormNameSlot(
  BoardSlot slot,
  String language, {
  required TextEditingController controller,
  required FocusNode focusNode,
  required String? issue,
  required bool enabled,
}) {
  final color = unitsColor;
  return HexSlot(
    id: 'name',
    title: localized(language, 'Имя', 'Name'),
    color: color,
    q: slot.q,
    r: slot.r,
    tappable: false,
    enabled: enabled,
    body: LineInput(
      color: color,
      controller: controller,
      focusNode: focusNode,
      fieldKey: const ValueKey('unit-name'),
      hint: localized(language, 'имя', 'name'),
      issue: issue ?? '',
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_.-]')),
        LengthLimitingTextInputFormatter(20),
      ],
    ),
  );
}

HexSlot unitFormVisibilitySlot(
  BoardSlot slot,
  String language, {
  required UnitFormFields fields,
  required bool enabled,
  required ValueChanged<String> onPick,
}) {
  return HexSlot(
    id: 'visibility',
    title: localized(language, 'Видимость', 'Visibility'),
    color: unitsColor,
    q: slot.q,
    r: slot.r,
    tappable: false,
    enabled: enabled,
    body: ChoiceWords(
      center: true,
      choices: [
        for (final level in unitVisibilities)
          (id: level, label: unitVisibilityLabel(language, level)),
      ],
      selected: (id) => fields.visibility == id,
      onTap: onPick,
    ),
  );
}

HexSlot unitFormBranchSlot(
  BoardSlot slot,
  String language, {
  required UnitFormFields fields,
  required bool enabled,
}) {
  return HexSlot(
    id: 'branch',
    title: localized(language, 'Ветка', 'Branch'),
    footer: fields.branch.isEmpty ? null : fields.branch,
    color: unitsColor,
    enabled: enabled,
    q: slot.q,
    r: slot.r,
    icon: 'assets/icons/objects/repo.svg',
  );
}

HexSlot unitFormUpdatesSlot(
  BoardSlot slot,
  String language, {
  required UnitFormFields fields,
  required bool enabled,
}) {
  return HexSlot(
    id: 'updates',
    title: localized(language, 'Обновления', 'Updates'),
    footer: unitRunLabel(language, fields.compilable),
    footerLeft: unitHandsLabel(language, fields.auto),
    color: unitsColor,
    enabled: enabled,
    q: slot.q,
    r: slot.r,
    icon: 'assets/icons/actions/updates.svg',
  );
}

/// A cell the form does not know: its id as the title.
HexSlot unitFormFallbackSlot(BoardSlot slot) {
  return HexSlot(
    id: slot.id,
    title: slot.id,
    color: unitsColor,
    q: slot.q,
    r: slot.r,
  );
}
