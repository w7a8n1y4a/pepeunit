import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../units/unit.dart';
import '../../units/unit_read.dart';
import '../hex_page.dart';
import '../network/line_cell.dart';
import 'units_chrome.dart';

/// Commits, network, memory, clock and the crystal of one unit.
class UnitInfoPage extends StatefulWidget {
  const UnitInfoPage({required this.uuid, super.key});

  final String uuid;

  @override
  State<UnitInfoPage> createState() => _UnitInfoPageState();
}

class _UnitInfoPageState extends State<UnitInfoPage> {
  Unit? _unit;
  String? _failure;
  var _open = false;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    const ids = ['updates', 'network', 'ram', 'flash', 'time', 'freq'];
    final placed = cardBoard(ids, wide: wide);
    final slots = <HexSlot>[for (final slot in placed) _slot(slot, language)];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: unitText,
      wide: wide,
    );
    return HexPage(
      slots: slots,
      onTap: (id) {
        if (id == 'back') popOrHome(context);
        if (id == 'error') setState(() => _open = true);
      },
    );
  }

  HexSlot _slot(BoardSlot slot, String language) {
    final unit = _unit;
    final color = unitsColor;
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: unitText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'updates':
        return _facts(
          slot,
          language,
          'Обновления',
          'Updates',
          unit == null ? const ['—'] : updateLines(unit, language),
          copy: unit == null ? '' : updateCopy(unit),
        );
      case 'network':
        final lines = unit == null ? const ['—'] : networkLines(unit, language);
        return _facts(
          slot,
          language,
          'Сеть',
          'Network',
          lines,
          copy: lines.join('\n'),
        );
      case 'ram':
        return _facts(
          slot,
          language,
          'RAM',
          'RAM',
          unit == null ? const ['—'] : ramLines(unit, language),
        );
      case 'flash':
        return _facts(
          slot,
          language,
          'Flash',
          'Flash',
          unit == null ? const ['—'] : flashLines(unit, language),
        );
      case 'time':
        return _facts(
          slot,
          language,
          'Время',
          'Time',
          unit == null
              ? const ['—']
              : deviceTimeLines(unit.state?.millis, language),
        );
      case 'freq':
        return _facts(slot, language, 'Частота', 'Frequency', [
          freqText(unit?.state?.freq, language),
        ]);
      default:
        return HexSlot(
          id: slot.id,
          title: slot.id,
          color: color,
          q: slot.q,
          r: slot.r,
        );
    }
  }

  HexSlot _facts(
    BoardSlot slot,
    String language,
    String ru,
    String en,
    List<String> lines, {
    String copy = '',
  }) {
    return HexSlot(
      id: slot.id,
      title: unitText(language, ru, en),
      color: unitsColor,
      busy: _loading && slot.id == 'updates',
      q: slot.q,
      r: slot.r,
      tappable: false,
      body: MetricsCell(
        lines: lines,
        copyText: copy.isEmpty ? null : copy,
        copyLabel: unitText(language, 'Скопировать', 'Copy'),
      ),
    );
  }

  Future<void> _load() async {
    final model = AppScope.of(context);
    if (!model.signedIn) {
      setState(() {
        _loading = false;
        _failure = model.notSignedIn;
      });
      return;
    }
    try {
      final unit = await model.readUnit(widget.uuid);
      if (!mounted) return;
      setState(() {
        _unit = unit;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failure = '$error';
      });
    }
  }
}
