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

/// Create-unit cells. Green reads as «add».
const unitAddColor = addColor;

/// Unit groups. No home section uses this hue.
const unitGroupsColor = Color(0xFF00E5FF);

/// Inputs and outputs. The child screens of a node use this teal.
const unitIoColor = Color(0xFF2BD9C3);

/// Output cells. Inputs keep [unitIoColor].
const unitOutputColor = Color(0xFFFF7A59);

Color unitIoTone(bool input) => input ? unitIoColor : unitOutputColor;

String unitIoIcon(bool input) =>
    input ? 'assets/icons/input.svg' : 'assets/icons/output.svg';

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

/// Auto or by hand, on the updates cell of the unit form.
String unitHandsLabel(String language, bool auto) {
  if (auto) return unitText(language, 'Авто', 'Auto');
  return unitText(language, 'Руками', 'Manual');
}

/// Compilable or interpreted, short enough for one edge of that cell.
String unitRunLabel(String language, bool compilable) {
  if (compilable) return unitText(language, 'Компил', 'Comp');
  return unitText(language, 'Интерп', 'Interp');
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
  Color? color,
}) {
  final commit = shortCommit(unit.currentCommit ?? unit.commit);
  final corner = commit.isEmpty ? unit.branch : commit;
  return HexSlot(
    id: id,
    title: unit.name,
    footer: unitVisibilityLabel(language, unit.visibility),
    footerLeft: corner.isEmpty ? null : corner,
    color: color ?? unitsColor,
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

class ChoiceWords extends StatelessWidget {
  const ChoiceWords({
    required this.choices,
    required this.selected,
    required this.onTap,
    this.fontScale = 1.2,
    this.center = false,
    super.key,
  });

  final List<({String id, String label})> choices;
  final bool Function(String id) selected;
  final ValueChanged<String> onTap;
  final double fontScale;

  /// Keeps the slanted row in the middle of the cell, inside the hex.
  final bool center;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        final line = center ? side * _centeredLine : side;
        final labels = [for (final choice in choices) choice.label];
        final font = center
            ? _centeredEnumFont(
                ceiling: cellFont(side) * fontScale,
                line: line,
                band: side * _centeredBand,
                scaler: MediaQuery.textScalerOf(context),
                labels: labels,
              )
            : cellFont(side) * fontScale;
        return SlantedChoices(
          fontSize: font,
          maxWidth: line,
          lineGapShare: 0.2,
          alignment: center ? Alignment.center : Alignment.topCenter,
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

/// Width of a centered enum, as a share of the cell. The pointy hex is
/// narrower than the square, and the edge captions need the rim.
const _centeredLine = 0.64;

/// Height a centered enum may use, as a share of the cell.
const _centeredBand = 0.52;

double _centeredEnumFont({
  required double ceiling,
  required double line,
  required double band,
  required TextScaler scaler,
  required List<String> labels,
}) {
  if (!line.isFinite || line <= 0 || !band.isFinite || band <= 0) {
    return ceiling;
  }
  bool fits(double font) {
    final height = slantedEnumHeight(
      labels: labels,
      fontSize: font,
      maxWidth: line,
      scaler: scaler,
      lineGapShare: 0.2,
    );
    return height != null && height > 0 && height <= band;
  }

  if (fits(ceiling)) return ceiling;
  var low = 1.0;
  var high = ceiling;
  if (high <= low || !fits(low)) return low;
  for (var step = 0; step < 14; step++) {
    final mid = (low + high) / 2;
    if (fits(mid)) {
      low = mid;
    } else {
      high = mid;
    }
  }
  return low;
}
