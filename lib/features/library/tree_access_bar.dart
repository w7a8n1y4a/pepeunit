import 'package:flutter/material.dart';

import '../../hive/bevel.dart';
import '../../hive/hex_scene.dart';
import '../../hive/hint.dart';
import '../../locale/languages.dart';
import '../../locale/roles.dart';
import 'library_menu_page.dart';

/// Current role and the share of the map this session can access.
class TreeAccessBar extends StatelessWidget {
  const TreeAccessBar({
    required this.language,
    required this.role,
    required this.available,
    required this.total,
    required this.font,
    super.key,
  }) : assert(available >= 0 && available <= total);

  final String language;
  final String role;
  final int available;
  final int total;
  final double font;

  @override
  Widget build(BuildContext context) {
    final label = roleLabel(language, role);
    final title = localized(language, 'Доступность', 'Availability');
    final value = localized(
      language,
      'Роль: $label. Доступно $available из $total. Недоступно ${total - available}.',
      'Role: $label. Available: $available of $total. Unavailable: ${total - available}.',
    );
    final style = TextStyle(
      color: Colors.white,
      fontFamily: 'OpenGost Type B',
      fontSize: font * 1.2,
      decoration: TextDecoration.none,
    );
    return HintTarget(
      id: 'tree-access',
      title: title,
      color: libraryColor,
      child: Semantics(
        label: title,
        value: value,
        excludeSemantics: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: font * 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                flex: 2,
                child: Text(
                  label,
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: BevelFrame(
                  color: libraryColor.withValues(alpha: 0.7),
                  radius: font * 0.4,
                  width: 1.2,
                  child: SizedBox(
                    height: font * 2.4,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: LinearProgressIndicator(
                            value: total == 0 ? 0 : available / total,
                            color: libraryColor.withValues(alpha: 0.5),
                            backgroundColor: hexMuted.withValues(alpha: 0.16),
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('$available / $total', style: style),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
