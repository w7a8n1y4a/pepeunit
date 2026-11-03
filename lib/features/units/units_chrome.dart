import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../hive/hex_scene.dart';
import '../../locale/languages.dart';
import '../../navigation/sections.dart';
import '../../instances/network_view.dart';
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
    required this.capacity,
    required this.onStep,
    this.order,
    this.onOrder,
    super.key,
  });

  final String language;
  final int offset;
  final int limit;
  final int count;

  /// Cards that fit at the last scale tick. Arrows stay still until the
  /// list is larger than this.
  final int capacity;
  final ValueChanged<int> onStep;
  final String? order;
  final ValueChanged<String>? onOrder;

  @override
  Widget build(BuildContext context) {
    final range = pageWindowText(
      offset: offset,
      limit: limit,
      count: count,
      ofWord: unitText(language, 'из', 'of'),
    );
    final back = pageCanBack(offset: offset, count: count, capacity: capacity);
    final forward = pageCanForward(
      offset: offset,
      limit: limit,
      count: count,
      capacity: capacity,
    );
    final previous = unitText(language, 'Предыдущие', 'Previous');
    final next = unitText(language, 'Следующие', 'Next');
    if (order != null && onOrder != null) {
      return OrderWindow(
        orders: [
          for (final value in const ['asc', 'desc'])
            (value: value, label: unitOrderLabel(language, value)),
        ],
        selected: order!,
        onOrder: onOrder!,
        range: range,
        canBack: back,
        canForward: forward,
        previousLabel: previous,
        nextLabel: next,
        onStep: onStep,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        final style = TextStyle(
          fontFamily: 'OpenGost Type B',
          fontSize: cellFont(side),
          decoration: TextDecoration.none,
          height: 1.05,
        );
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: side * 0.12,
            vertical: side * 0.28,
          ),
          child: PageWindow(
            range: range,
            canBack: back,
            canForward: forward,
            previousLabel: previous,
            nextLabel: next,
            onStep: onStep,
            style: style,
            chevronExtent: side * 0.18,
          ),
        );
      },
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
