import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../account/key_mark.dart';
import '../../hive/hex_scene.dart';
import '../../hive/marks.dart';
import '../../instances/directory_user.dart';
import '../../instances/instance.dart';
import '../../locale/languages.dart';
import '../../navigation/sections.dart';

Color get networkColor => sectionById('peers')!.color;

String netText(String language, String ru, String en) =>
    phrase(language, {'ru': ru, 'en': en});

String trustLabel(String language, String trust) {
  switch (trust) {
    case 'Trust':
      return netText(language, 'Доверенный', 'Trusted');
    case 'Pending':
      return netText(language, 'Ожидает', 'Waiting');
    case 'Blocking':
      return netText(language, 'Заблокирован', 'Blocked');
    default:
      return trust;
  }
}

String roleLabel(String language, String role) {
  switch (role) {
    case 'Admin':
      return netText(language, 'Админ', 'Admin');
    case 'Owner':
      return netText(language, 'Владелец', 'Owner');
    default:
      return netText(language, 'Пользователь', 'User');
  }
}

String memberStatusLabel(String language, String status) {
  switch (status) {
    case 'Blocked':
      return netText(language, 'Заблокирован', 'Blocked');
    default:
      return netText(language, 'Активный', 'Active');
  }
}

String memberOrderLabel(String language, String order) {
  if (order == 'asc') return netText(language, 'Старые', 'Old');
  return netText(language, 'Новые', 'New');
}

Color trustColor(String? trust, Color accent) {
  switch (trust) {
    case 'Blocking':
      return errorColor;
    case 'Pending':
      return hexMuted;
    default:
      return accent;
  }
}

/// The current-instance cell, the same shape on the home menu, the network
/// menu and the instance card.
HexSlot instanceMark({
  required String id,
  required String url,
  required String language,
  required int q,
  required int r,
  required Color color,
  required bool current,
  String? version,
  Color footerColor = const Color(0xFFFFFFFF),
  String? footerLeft,
  Color footerLeftColor = const Color(0xFFFFFFFF),
  Uint8List? image,
  String icon = 'assets/icons/instance.svg',
  bool tappable = true,
  bool enabled = true,
  bool busy = false,
}) {
  return HexSlot(
    id: id,
    title: instanceHost(url),
    footerLeft:
        footerLeft ??
        (current ? netText(language, 'Избранный', 'Favorite') : null),
    footerLeftColor: footerLeftColor,
    footer: version,
    footerColor: footerColor,
    color: color,
    q: q,
    r: r,
    icon: image == null ? icon : null,
    image: image,
    tappable: tappable,
    enabled: enabled,
    busy: busy,
  );
}

/// Account-shaped card: login on the upper left, key mark across the bottom,
/// role on the right edge. Blocked accounts use the error border.
HexSlot userMark({
  required String id,
  required DirectoryUser user,
  required String language,
  required int q,
  required int r,
  required Color accent,
  Uint8List? image,
  bool tappable = true,
  bool busy = false,
}) {
  final login = user.login ?? '';
  return HexSlot(
    id: id,
    title: login,
    footer: keyMarkFromBase64(user.publicKey),
    sideRight: roleLabel(language, user.role),
    color: user.status == 'Blocked' ? errorColor : accent,
    q: q,
    r: r,
    icon: image == null ? 'assets/icons/account.svg' : null,
    image: image,
    tappable: tappable,
    busy: busy,
  );
}

HexSlot pageStepSlot({
  required String id,
  required bool left,
  required String language,
  required Color color,
  required int q,
  required int r,
  required int page,
  required int pages,
  required bool enabled,
  VoidCallback? onTap,
}) {
  return HexSlot(
    id: id,
    title: left
        ? netText(language, 'Предыдущие', 'Previous')
        : netText(language, 'Следующие', 'Next'),
    footer: pages > 1 ? '${page + 1}/$pages' : null,
    color: color,
    q: q,
    r: r,
    enabled: enabled,
    body: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Center(
        child: HoverPop(
          enabled: enabled,
          child: FractionallySizedBox(
            widthFactor: 0.34,
            heightFactor: 0.34,
            child: CustomPaint(
              painter: ChevronMarkPainter(
                left: left,
                color: enabled ? const Color(0xFFFFFFFF) : hexMuted,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class ScopeFrame extends StatefulWidget {
  const ScopeFrame({
    required this.scope,
    required this.canZoomIn,
    required this.path,
    required this.child,
    this.minScope = 0,
    this.maxScope = 2,
    super.key,
  });

  final int scope;
  final bool canZoomIn;
  final String path;
  final Widget child;
  final int minScope;
  final int maxScope;

  @override
  State<ScopeFrame> createState() => _ScopeFrameState();
}

class _ScopeFrameState extends State<ScopeFrame> {
  var _pinched = false;

  void _step(int delta) {
    if (delta > 0 && !widget.canZoomIn) return;
    final next = (widget.scope + delta).clamp(widget.minScope, widget.maxScope);
    if (next == widget.scope) return;
    final uri = Uri.parse(widget.path)
        .replace(queryParameters: {'scope': '$next'});
    context.replace(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if (event is! PointerScrollEvent) return;
        if (event.scrollDelta.dy < 0) {
          _step(1);
        } else if (event.scrollDelta.dy > 0) {
          _step(-1);
        }
      },
      child: GestureDetector(
        onScaleStart: (_) => _pinched = false,
        onScaleUpdate: (details) {
          if (details.pointerCount < 2 || _pinched) return;
          if (details.scale > 1.08) {
            _pinched = true;
            _step(1);
          } else if (details.scale < 0.92) {
            _pinched = true;
            _step(-1);
          }
        },
        child: widget.child,
      ),
    );
  }
}

int scopeOf(Uri uri) {
  final raw = int.tryParse(uri.queryParameters['scope'] ?? '') ?? 0;
  return raw.clamp(0, 2);
}

/// Users open on two rings. Scope 2 adds the third.
int userScopeOf(Uri uri) {
  final raw = int.tryParse(uri.queryParameters['scope'] ?? '') ?? 1;
  return raw.clamp(1, 2);
}
