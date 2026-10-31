import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../hive/hex_scene.dart';
import '../../locale/languages.dart';
import '../../navigation/sections.dart';
import '../../registry/registry_view.dart';
import '../../units/unit.dart';
import '../page_window.dart';
import '../slanted_choices.dart';

Color get unitsColor => sectionById('units')!.color;

String unitText(String language, String ru, String en) =>
    phrase(language, {'ru': ru, 'en': en});

String unitOrderLabel(String language, String order) {
  if (order == 'desc') return unitText(language, 'Я-А', 'Z-A');
  return unitText(language, 'А-Я', 'A-Z');
}

String unitOwnerLabel(String language, String owner) {
  if (owner == 'all') return unitText(language, 'Все', 'All');
  return unitText(language, 'Свои', 'Mine');
}

String unitAutoLabel(String language, String auto) {
  if (auto == 'off') return unitText(language, 'Вручную', 'Manual');
  return unitText(language, 'Авто', 'Auto');
}

/// Search card and the identity cell of one unit.
HexSlot unitMark({
  required String id,
  required Unit unit,
  required String language,
  required int q,
  required int r,
  Uint8List? image,
  bool tappable = true,
  bool busy = false,
}) {
  final commit = shortCommit(unit.currentCommit ?? unit.commit);
  final corner = commit.isEmpty ? unit.branch : commit;
  return HexSlot(
    id: id,
    title: unit.name,
    footer: unitVisibilityLabel(language, unit.visibility),
    footerLeft: corner.isEmpty ? null : corner,
    color: unitsColor,
    q: q,
    r: r,
    icon: image == null ? 'assets/icons/micro.svg' : null,
    image: image,
    tappable: tappable,
    busy: busy,
  );
}

/// Page range, and an optional А-Я / Я-А pair above the stroke.
class UnitWindow extends StatelessWidget {
  const UnitWindow({
    required this.language,
    required this.offset,
    required this.limit,
    required this.count,
    required this.onStep,
    this.order,
    this.onOrder,
    super.key,
  });

  final String language;
  final int offset;
  final int limit;
  final int count;
  final ValueChanged<int> onStep;
  final String? order;
  final ValueChanged<String>? onOrder;

  @override
  Widget build(BuildContext context) {
    final range = repoWindowText(
      offset: offset,
      limit: limit,
      count: count,
      ofWord: unitText(language, 'из', 'of'),
    );
    final back = repoCanPageBack(offset: offset, count: count);
    final forward = repoCanPageForward(
      offset: offset,
      limit: limit,
      count: count,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        final style = TextStyle(
          fontFamily: 'OpenGost Type B',
          fontSize: cellFont(side),
          decoration: TextDecoration.none,
          height: 1.05,
        );
        final window = PageWindow(
          range: range,
          canBack: back,
          canForward: forward,
          previousLabel: unitText(language, 'Предыдущие', 'Previous'),
          nextLabel: unitText(language, 'Следующие', 'Next'),
          onStep: onStep,
          style: style,
          chevronExtent: side * 0.18,
        );
        if (order == null || onOrder == null) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: side * 0.12,
              vertical: side * 0.28,
            ),
            child: window,
          );
        }
        return Padding(
          padding: EdgeInsets.fromLTRB(
            side * 0.12,
            side * 0.22,
            side * 0.12,
            side * 0.16,
          ),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    for (final value in const ['asc', 'desc'])
                      Expanded(child: _order(value, style)),
                  ],
                ),
              ),
              Container(
                height: 1,
                margin: EdgeInsets.symmetric(horizontal: side * 0.06),
                color: const Color(0xFFA1A1AA),
              ),
              Expanded(child: window),
            ],
          ),
        );
      },
    );
  }

  Widget _order(String value, TextStyle style) {
    final on = order == value;
    final label = unitOrderLabel(language, value);
    return Semantics(
      button: true,
      selected: on,
      label: label,
      excludeSemantics: true,
      onTap: () => onOrder!(value),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onOrder!(value),
        child: HoverPop(
          child: Center(
            child: Text(
              label,
              style: style.copyWith(
                color: on ? const Color(0xFFFFFFFF) : hexMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One horizontal filter row. The row scales down until it fits the cell.
class FilterLine extends StatelessWidget {
  const FilterLine({
    required this.choices,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final List<({String id, String label})> choices;
  final bool Function(String id) selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final font = cellFont(constraints.maxWidth);
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final choice in choices)
                  Semantics(
                    button: true,
                    selected: selected(choice.id),
                    label: choice.label,
                    excludeSemantics: true,
                    onTap: () => onTap(choice.id),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(choice.id),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: font * 0.28),
                        child: Text(
                          choice.label,
                          style: TextStyle(
                            fontFamily: 'OpenGost Type B',
                            fontSize: font,
                            height: 1,
                            decoration: TextDecoration.none,
                            color: selected(choice.id)
                                ? const Color(0xFFFFFFFF)
                                : hexMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ChoiceWords extends StatelessWidget {
  const ChoiceWords({
    required this.choices,
    required this.selected,
    required this.onTap,
    this.fontScale = 1.2,
    super.key,
  });

  final List<({String id, String label})> choices;
  final bool Function(String id) selected;
  final ValueChanged<String> onTap;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SlantedChoices(
          fontSize: cellFont(constraints.maxWidth) * fontScale,
          maxWidth: constraints.maxWidth,
          lineGapShare: 0.2,
          choices: [
            for (final choice in choices)
              SlantedChoice(
                label: choice.label,
                selected: selected(choice.id),
                onTap: () => onTap(choice.id),
              ),
          ],
        );
      },
    );
  }
}
