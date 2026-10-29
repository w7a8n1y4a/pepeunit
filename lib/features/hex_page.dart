import 'package:flutter/material.dart';

import '../hive/hex_order.dart';
import '../hive/hex_scene.dart';
import 'account/error_reader.dart';

/// Scene background and the shared hex renderer.
class HexPage extends StatelessWidget {
  const HexPage({
    required this.slots,
    required this.onTap,
    this.wrap,
    this.frame,
    super.key,
  });

  final List<HexSlot> slots;
  final ValueChanged<String> onTap;
  final HexSlotWrap? wrap;

  /// Wraps the scene after the background, for example with a zoom frame.
  final Widget Function(Widget scene)? frame;

  @override
  Widget build(BuildContext context) {
    final scene = HexScene(slots: slots, onTap: onTap, wrap: wrap);
    return ColoredBox(
      color: sceneBackground,
      child: frame == null ? scene : frame!(scene),
    );
  }
}

/// Back cell. Every screen that has Back uses this slot.
HexSlot backSlot({required String title, required int q, required int r}) {
  return HexSlot(
    id: 'back',
    title: title,
    color: hexMuted,
    q: q,
    r: r,
    icon: 'assets/icons/back.svg',
  );
}

/// White while a file is dragged over the cell, otherwise [color].
Color dropColor(bool hot, Color color) => hot ? const Color(0xFFFFFFFF) : color;

/// Error cell in the next free slot. Nothing is added when [message] is null.
///
/// The slot stays inside the current scale tick. A full tick may grow by one
/// so the error still appears. The query tick does not change.
void appendError(
  List<HexSlot> slots, {
  required String? message,
  required bool open,
  required String language,
  required String Function(String language, String ru, String en) text,
  required bool wide,
}) {
  if (message == null) return;
  final taken = [for (final slot in slots) (slot.q, slot.r)];
  final spot = _errorSpot(taken, wide: wide);
  slots.add(
    HexSlot(
      id: 'error',
      title: text(language, 'Ошибка', 'Error'),
      color: errorColor,
      titleColor: errorColor,
      q: spot.$1,
      r: spot.$2,
      icon: 'assets/icons/error.svg',
      body: open
          ? ErrorCell(
              message: message,
              copyLabel: text(language, 'Скопировать', 'Copy'),
            )
          : null,
    ),
  );
}

(int, int) _errorSpot(List<(int, int)> taken, {required bool wide}) {
  final used = taken.toSet();
  for (final cell in hexBudget(errorBudget(taken.length), wide: wide)) {
    if (!used.contains(cell)) return cell;
  }
  return nextHex(taken, wide: wide);
}
