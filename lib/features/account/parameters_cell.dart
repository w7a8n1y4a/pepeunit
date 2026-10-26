import 'dart:math';

import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../hive/marks.dart';
import '../../locale/languages.dart';
import '../../locale/time_zones.dart';

/// Language and UTC offset. Both apply only inside the client and are stored
/// as soon as they change.
class ParametersCell extends StatelessWidget {
  const ParametersCell({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final timeZone = model.vault.timeZone;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        final style = TextStyle(
          fontFamily: 'OpenGost Type B',
          fontSize: max(11, side * 0.068),
          decoration: TextDecoration.none,
          height: 1.05,
        );
        final languages = [
          for (final item in appLanguages)
            _LanguageChoice(
              name: item.nativeName,
              selected: item.code == language,
              style: style,
              onTap: () => model.setLanguage(item.code),
            ),
        ];
        return Padding(
          padding: EdgeInsets.fromLTRB(
            side * 0.14,
            side * 0.30,
            side * 0.14,
            side * 0.12,
          ),
          child: Column(
            children: [
              Expanded(
                child: appLanguages.length <= 4
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: languages,
                      )
                    : ListView(padding: EdgeInsets.zero, children: languages),
              ),
              Container(
                height: max(1, side * 0.006),
                margin: EdgeInsets.symmetric(horizontal: side * 0.06),
                color: const Color(0xFFA1A1AA),
              ),
              SizedBox(
                height: side * 0.24,
                child: Row(
                  children: [
                    _ZoneStep(
                      left: true,
                      extent: side * 0.18,
                      label: phrase(language, {
                        'ru': 'Предыдущий пояс',
                        'en': 'Previous zone',
                      }),
                      onTap: () => model.setTimeZone(stepZone(timeZone, -1)),
                    ),
                    Expanded(
                      child: Semantics(
                        label: zoneLabel(timeZone, language),
                        excludeSemantics: true,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            zoneLabel(timeZone, language),
                            style: style.copyWith(
                              color: const Color(0xFFFFFFFF),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _ZoneStep(
                      left: false,
                      extent: side * 0.18,
                      label: phrase(language, {
                        'ru': 'Следующий пояс',
                        'en': 'Next zone',
                      }),
                      onTap: () => model.setTimeZone(stepZone(timeZone, 1)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LanguageChoice extends StatelessWidget {
  const _LanguageChoice({
    required this.name,
    required this.selected,
    required this.style,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected ? true : null,
      label: name,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: style.copyWith(
              color: selected
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFFA1A1AA),
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoneStep extends StatelessWidget {
  const _ZoneStep({
    required this.left,
    required this.extent,
    required this.label,
    required this.onTap,
  });

  final bool left;
  final double extent;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: extent,
          height: extent,
          child: CustomPaint(
            painter: ChevronMarkPainter(
              left: left,
              color: const Color(0xFFFFFFFF),
            ),
          ),
        ),
      ),
    );
  }
}
