import 'dart:math';

import 'package:flutter/material.dart';

import '../../app_scope.dart';
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
/// - The title of the panel is the first `# ` heading of the text, drawn once.
///   A text with no such heading takes [title].
/// - Links inside the text open in place. Back on the bar goes to the text
///   before, and the close mark leaves the Library.
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

  /// Title of a text that has no `# ` heading of its own.
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
  _Page._(this.title, this.source, this.path, this.anchor, this.doc);

  /// The first `# ` heading of [source] is the title of the panel and is not
  /// drawn again in the text. [title] is for a text that has none.
  factory _Page({
    required String title,
    required String source,
    String? path,
    String? anchor,
  }) {
    final doc = parseMarkdown(source);
    return _Page._(
      doc.title ?? title,
      source,
      path,
      anchor,
      doc.withoutTitle(),
    );
  }

  final String title;
  final String source;
  final String? path;
  final String? anchor;

  /// The text as drawn: without its title.
  final MdDoc doc;
}

class _LibraryModalState extends State<LibraryModal> {
  final _controller = MdController();
  late List<_Page> _trail = [_first()];

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
    // A heading of the text that is open: scroll to it, no new page.
    final anchor = link.anchor;
    if (anchor != null &&
        anchor.isNotEmpty &&
        (article == null || article.path == _page.path)) {
      _controller.jump(anchor);
      return;
    }
    if (article == null) return;
    setState(() {
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
      _trail = _trail.sublist(0, _trail.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final raw = model.vault.libraryRaw;
    final page = _page;
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
        return MdView(
          // A new text starts at its top with its own scroll state.
          key: ValueKey(page),
          doc: page.doc,
          font: max(13.0, codeFont * 1.2),
          accent: widget.color,
          canOpen: _canOpen,
          onOpen: _open,
          controller: _controller,
          anchor: page.anchor,
        );
      },
    );
  }
}
