import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../hive/bevel.dart';
import '../../hive/grain.dart';
import '../../hive/hex_scene.dart';
import '../../hive/marks.dart';
import '../../navigation/sections.dart';
import '../code/code_modal.dart';

/// Use the same section colors as the main menu and the screens being shown.
Color presentationColor(int slide) => sectionById(
  const [
    'library',
    'units',
    'registry',
    'units',
    'units',
    'dashboards',
    'people',
    'peers',
    'library',
  ][slide],
)!.color;

/// Let the content size a panel while the shared grain fills its background.
class PresentationSurface extends StatelessWidget {
  const PresentationSurface({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: GrainBox(tile: cellGrain, opacity: modalFillOpacity),
      ),
      child,
    ],
  );
}

/// The project's word button, with keyboard activation and a full touch target.
class PresentationWord extends StatefulWidget {
  const PresentationWord({
    required this.label,
    required this.onTap,
    this.tooltip,
    this.color = Colors.white,
    this.font = 14,
    this.selected = false,
    super.key,
  });

  final String label;
  final String? tooltip;
  final VoidCallback onTap;
  final Color color;
  final double font;
  final bool selected;

  @override
  State<PresentationWord> createState() => _PresentationWordState();
}

class _PresentationWordState extends State<PresentationWord> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: widget.tooltip ?? widget.label,
    child: FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: Semantics(
        selected: widget.selected,
        child: BevelFrame(
          color: _focused ? Colors.white : Colors.transparent,
          radius: 6,
          width: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 44),
            child: Align(
              widthFactor: 1,
              heightFactor: 1,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: CodeWordButton(
                  label: widget.label,
                  font: widget.font,
                  color: widget.color,
                  onTap: widget.onTap,
                  hint: 'presentation-action',
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The shared pager chevron; no Material button surface or icon substitution.
class PresentationChevron extends StatelessWidget {
  const PresentationChevron({
    required this.left,
    required this.label,
    required this.onTap,
    super.key,
  });

  final bool left;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Semantics(
      label: label,
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: HoverPop(
          enabled: onTap != null,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: SizedBox.square(
                dimension: 28,
                child: CustomPaint(
                  painter: ChevronMarkPainter(
                    left: left,
                    color: onTap == null ? hexMuted : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
