import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../library/library.dart';
import '../../navigation/back.dart';
import '../../registry/repo.dart';
import '../hex_page.dart';
import '../network/network_chrome.dart';
import '../../units/unit_view.dart';
import 'library_menu_page.dart';
import 'library_modal.dart';

String docsAddress({String dir = '', String? doc, int? scope}) {
  return Uri(
    path: '/library/docs',
    queryParameters: {
      if (dir.isNotEmpty) 'dir': dir,
      'doc': ?doc,
      if (scope != null && scope != menuScaleTick) 'scope': '$scope',
    },
  ).toString();
}

/// One folder of the documentation tree: a cell for each folder and each
/// article in it. The tree comes from the documentation files, nothing in
/// the client lists them. An article opens in a panel over the folder.
class DocsPage extends StatefulWidget {
  const DocsPage({required this.dir, required this.scope, this.doc, super.key});

  /// Path of the folder in the tree. Empty is the root.
  final String dir;
  final int scope;

  /// Path of the article that is open.
  final String? doc;

  @override
  State<DocsPage> createState() => _DocsPageState();
}

class _DocsPageState extends State<DocsPage> {
  DocsTree? _tree;
  String? _failure;
  var _failureOpen = false;
  var _page = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(DocsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope != widget.scope || oldWidget.dir != widget.dir) {
      _page = 0;
    }
  }

  Future<void> _load() async {
    final language = AppScope.of(context).vault.language;
    try {
      final tree = await Library.instance.docs(language);
      if (!mounted) return;
      setState(() => _tree = tree);
    } catch (error) {
      if (!mounted) return;
      setState(() => _failure = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final tree = _tree;
    final folder = tree?.folder(widget.dir);
    final ids = [
      if (folder != null) ...[
        for (final child in folder.folders) 'dir:${child.path}',
        for (final article in folder.articles) 'doc:${article.path}',
      ],
    ];
    final board = ids.isEmpty
        ? null
        : tailBoard(tick: widget.scope, page: _page, ids: ids, wide: wide);
    final slots = <HexSlot>[];
    if (board == null) {
      final frame = hexFrame(count: 1, back: HexBack.center, wide: wide);
      slots.add(
        backSlot(
          title: libText(language, 'Назад'),
          q: frame.back!.$1,
          r: frame.back!.$2,
        ),
      );
      slots.add(
        HexSlot(
          id: 'empty',
          title: tree == null && _failure == null
              ? libText(language, 'Документация')
              : libText(language, 'Пусто'),
          color: libraryColor,
          busy: tree == null && _failure == null,
          tappable: false,
          q: frame.cells.first.$1,
          r: frame.cells.first.$2,
        ),
      );
    } else {
      for (final slot in board.slots) {
        slots.add(_slot(slot, board, tree!, language));
      }
    }
    appendError(
      slots,
      message: _failure,
      open: _failureOpen,
      language: language,
      text: libErrorText,
      wide: wide,
    );
    final scene = HexPage(
      slots: slots,
      onTap: (id) => _tap(id),
      frame: board == null
          ? null
          : (child) => ScopeFrame(
              scope: widget.scope,
              canZoomIn: board.canZoomIn,
              path: docsAddress(dir: widget.dir),
              child: child,
            ),
    );
    final article = tree == null || widget.doc == null
        ? null
        : tree.article(widget.doc!);
    if (article == null) return scene;
    return Stack(
      children: [
        scene,
        Material(
          type: MaterialType.transparency,
          child: LibraryModal(
            title: article.title,
            color: libraryColor,
            source: article.source,
            path: article.path,
            docs: tree,
            onClose: () => closeLibrary(
              context,
              docsAddress(dir: widget.dir, scope: widget.scope),
            ),
          ),
        ),
      ],
    );
  }

  HexSlot _slot(
    BoardSlot slot,
    NetworkBoard board,
    DocsTree tree,
    String language,
  ) {
    if (slot.id == 'back') {
      return backSlot(title: libText(language, 'Назад'), q: slot.q, r: slot.r);
    }
    if (slot.id == 'prev' || slot.id == 'next') {
      final forward = slot.id == 'next';
      return pageStepSlot(
        id: slot.id,
        left: !forward,
        language: language,
        color: libraryColor,
        q: slot.q,
        r: slot.r,
        page: board.page,
        pages: board.pages,
        enabled: forward ? board.page < board.pages - 1 : board.page > 0,
        onTap: () => setState(() => _page = board.page + (forward ? 1 : -1)),
      );
    }
    if (slot.id.startsWith('dir:')) {
      final folder = tree.folder(slot.id.substring(4));
      return HexSlot(
        id: slot.id,
        title: folder?.title ?? slot.id,
        footer: folder == null ? null : pieceCount(language, folder.count),
        color: libraryColor,
        q: slot.q,
        r: slot.r,
        icon: 'assets/icons/sections/library.svg',
      );
    }
    final article = tree.article(slot.id.substring(4));
    return HexSlot(
      id: slot.id,
      title: article?.title ?? slot.id,
      color: libraryColor,
      q: slot.q,
      r: slot.r,
      icon: 'assets/icons/objects/file.svg',
    );
  }

  void _tap(String id) {
    if (id == 'back') {
      popOrHome(context);
    } else if (id == 'error') {
      setState(() => _failureOpen = true);
    } else if (id.startsWith('dir:')) {
      context.push(docsAddress(dir: id.substring(4)));
    } else if (id.startsWith('doc:')) {
      context.push(
        docsAddress(dir: widget.dir, doc: id.substring(4), scope: widget.scope),
      );
    }
  }
}
