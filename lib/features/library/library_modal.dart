import 'dart:math';

import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/link.dart';
import '../../library/library.dart';
import '../../library/markdown.dart';
import '../../locale/languages.dart';
import '../code/code_highlight.dart';
import '../code/code_modal.dart';
import '../code/code_view.dart';
import 'md_view.dart';

/// Every Library text in one frame: a [CodeModal] whose body is a rendered
/// markdown ([MdView]) or its source with line numbers ([CodeView]).
///
/// - A switch on the bar picks Render or Source. The pick is stored with the
///   person's parameters, so the next text opens the same way.
/// - Links inside the text open in place. Back on the bar goes to the text
///   before, and the close mark leaves the Library.
/// - With three or more headings a Contents word opens the list of them.
class LibraryModal extends StatefulWidget {
  const LibraryModal({
    required this.title,
    required this.color,
    required this.source,
    required this.onClose,
    this.path,
    this.docs,
    this.anchor,
    this.actions,
    super.key,
  });

  /// Title of the first text. A text opened by a link brings its own.
  final String title;
  final Color color;
  final String source;
  final VoidCallback onClose;

  /// Path of the first text in the documentation tree, when it has one. A
  /// relative link is read from it.
  final String? path;

  /// Where links to articles lead. Without it only outside links work.
  final DocsTree? docs;

  /// Heading the first text opens at.
  final String? anchor;

  /// Words before the switch, such as the presentation pager.
  final List<Widget> Function(double font)? actions;

  @override
  State<LibraryModal> createState() => _LibraryModalState();
}

class _Page {
  _Page({required this.title, required this.source, this.path, this.anchor})
    : doc = parseMarkdown(source);

  final String title;
  final String source;
  final String? path;
  final String? anchor;
  final MdDoc doc;
}

class _LibraryModalState extends State<LibraryModal> {
  final _controller = MdController();
  late List<_Page> _trail = [_first()];
  var _contents = false;

  _Page _first() => _Page(
    title: widget.title,
    source: widget.source,
    path: widget.path,
    anchor: widget.anchor,
  );

  @override
  void didUpdateWidget(LibraryModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.title != widget.title ||
        oldWidget.path != widget.path) {
      _trail = [_first()];
      _contents = false;
    }
  }

  _Page get _page => _trail.last;

  /// The article a link points at and the heading in it. Null for a link the
  /// client cannot follow.
  ({DocArticle? article, String? anchor, Uri? outside})? _resolve(String url) {
    if (url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('mailto:')) {
      return (article: null, anchor: null, outside: Uri.tryParse(url));
    }
    final hash = url.indexOf('#');
    String? anchor;
    if (hash >= 0) {
      var raw = url.substring(hash + 1);
      try {
        raw = Uri.decodeComponent(raw);
      } catch (_) {}
      anchor = raw.toLowerCase();
    }
    var target = hash < 0 ? url : url.substring(0, hash);
    if (target.isEmpty) {
      return anchor == null || anchor.isEmpty
          ? null
          : (article: null, anchor: anchor, outside: null);
    }
    final docs = widget.docs;
    if (docs == null) return null;
    if (target.endsWith('.md')) target = target.substring(0, target.length - 3);
    if (target.endsWith('.html')) {
      target = target.substring(0, target.length - 5);
    }
    if (target.endsWith('/') && target.length > 1) {
      target = target.substring(0, target.length - 1);
    }
    String path;
    if (target.startsWith('/')) {
      path = target.substring(1);
    } else {
      final base = _page.path ?? '';
      final slash = base.lastIndexOf('/');
      final parts = [if (slash > 0) ...base.substring(0, slash).split('/')];
      for (final part in target.split('/')) {
        if (part == '..') {
          if (parts.isNotEmpty) parts.removeLast();
        } else if (part != '.' && part.isNotEmpty) {
          parts.add(part);
        }
      }
      path = parts.join('/');
    }
    final article = docs.article(path);
    if (article == null) return null;
    return (article: article, anchor: anchor, outside: null);
  }

  bool _canOpen(String url) => _resolve(url) != null;

  void _open(String url) {
    final link = _resolve(url);
    if (link == null) return;
    final outside = link.outside;
    if (outside != null) {
      launchExternal(outside);
      return;
    }
    final article = link.article;
    if (article == null) {
      _controller.jump(link.anchor!);
      return;
    }
    setState(() {
      _contents = false;
      _trail = [
        ..._trail,
        _Page(
          title: article.title,
          source: article.source,
          path: article.path,
          anchor: link.anchor,
        ),
      ];
    });
  }

  void _back() {
    if (_trail.length < 2) return;
    setState(() {
      _contents = false;
      _trail = _trail.sublist(0, _trail.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final raw = model.vault.libraryRaw;
    final page = _page;
    final headings = page.doc.headings
        .where((heading) => heading.level <= 4)
        .toList();
    String word(String ru) => phrase(language, {'ru': ru});
    return CodeModal(
      title: page.title,
      color: widget.color,
      onClose: widget.onClose,
      copy: () => page.source,
      rows: 100000,
      actions: (font) => [
        if (_trail.length > 1)
          CodeWordButton(label: word('Назад'), font: font, onTap: _back),
        if (!raw && headings.length >= 3)
          CodeWordButton(
            label: word('Оглавление'),
            font: font,
            color: _contents ? widget.color : const Color(0xFFFFFFFF),
            onTap: () => setState(() => _contents = !_contents),
          ),
        ...?widget.actions?.call(font),
        CodeChip(
          label: word('Рендер'),
          on: !raw,
          font: font,
          color: widget.color,
          onTap: () => model.setLibraryRaw(false),
        ),
        CodeChip(
          label: word('Исходник'),
          on: raw,
          font: font,
          color: widget.color,
          onTap: () => model.setLibraryRaw(true),
        ),
      ],
      body: (codeFont, _) {
        if (raw) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final layout = CodeLayout.of(
                context,
                text: page.source,
                fontSize: codeFont,
                width: constraints.maxWidth - codeBarRoom,
              );
              return CodeView(layout: layout, language: CodeLanguage.markdown);
            },
          );
        }
        return Stack(
          children: [
            Positioned.fill(
              child: MdView(
                // A new text starts at its top with its own scroll state.
                key: ValueKey(page),
                doc: page.doc,
                font: max(13.0, codeFont * 1.2),
                accent: widget.color,
                canOpen: _canOpen,
                onOpen: _open,
                controller: _controller,
                anchor: page.anchor,
              ),
            ),
            if (_contents)
              Positioned.fill(
                child: _Contents(
                  headings: headings,
                  font: max(13.0, codeFont * 1.2),
                  color: widget.color,
                  onPick: (slug) {
                    setState(() => _contents = false);
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _controller.jump(slug),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Contents extends StatelessWidget {
  const _Contents({
    required this.headings,
    required this.font,
    required this.color,
    required this.onPick,
  });

  final List<MdHeading> headings;
  final double font;
  final Color color;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final top = headings.isEmpty
        ? 1
        : headings.map((heading) => heading.level).reduce(min);
    return ColoredBox(
      color: const Color(0xFF14161B),
      child: ListView(
        padding: EdgeInsets.only(right: codeBarRoom, bottom: font),
        children: [
          for (final heading in headings)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onPick(heading.slug),
              child: HoverPop(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: (heading.level - top) * font * 1.1,
                    top: font * 0.3,
                    bottom: font * 0.3,
                  ),
                  child: Text(
                    heading.text,
                    style: TextStyle(
                      color: heading.level == top
                          ? const Color(0xFFFFFFFF)
                          : hexMuted,
                      fontFamily: 'OpenGost Type B',
                      fontSize: font,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
