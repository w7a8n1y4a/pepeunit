import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../instances/link.dart';
import '../../library/library.dart';
import '../../library/markdown.dart';
import '../code/code_highlight.dart';
import '../code/code_view.dart';
import 'md_view.dart';

class _Read {
  const _Read(this.title, this.doc);

  final String title;
  final MdDoc doc;
}

final _reads = Expando<_Read>();

/// Size of the running text, from the size of code on the same screen.
double docFontOf(double codeFont) => max(13.0, codeFont * 1.2);

/// One text the reader has shown.
class DocPage {
  DocPage._(this.title, this.source, this.path, this.anchor, this.doc);

  /// The first `# ` heading of [source] is the title of the panel and is not
  /// drawn again in the text. [title] is for a text that has none.
  factory DocPage({
    required String title,
    required String source,
    String? path,
    String? anchor,
  }) {
    final doc = parseMarkdown(source);
    return DocPage._(
      doc.title ?? title,
      source,
      path,
      anchor,
      doc.withoutTitle(),
    );
  }

  /// An article of the tree. The text is parsed once, the first time it is
  /// shown; every later visit reuses it.
  factory DocPage.of(DocArticle article, {String? anchor}) {
    var read = _reads[article];
    if (read == null) {
      final doc = parseMarkdown(article.source);
      read = _Read(doc.title ?? article.title, doc.withoutTitle());
      _reads[article] = read;
    }
    return DocPage._(
      read.title,
      article.source,
      article.path,
      anchor,
      read.doc,
    );
  }

  final String title;
  final String source;

  /// Path of the text in the documentation tree. A relative link is read from
  /// it.
  final String? path;
  final String? anchor;

  /// The text as drawn: without its title.
  final MdDoc doc;
}

/// What a Library text keeps while the person reads: the trail of texts
/// opened by links, and the way a link is followed. A link to an article
/// opens it as the next text; Back goes to the one before. A link to a
/// heading of the open text only scrolls.
class DocReader {
  DocReader({required DocPage first, required this.onChange, this.docs})
    : trail = [first];

  /// Called after the trail changed.
  final VoidCallback onChange;

  /// Where links to articles lead. Without it only outside links work. The
  /// tree may arrive after the first text is shown.
  DocsTree? docs;

  final controller = MdController();
  List<DocPage> trail;

  DocPage get page => trail.last;
  bool get canBack => trail.length > 1;

  /// Starts over from [first].
  void reset(DocPage first) => trail = [first];

  bool canOpen(String url) =>
      resolveDocLink(url, tree: docs, from: page.path) != null;

  void open(String url) {
    final link = resolveDocLink(url, tree: docs, from: page.path);
    if (link == null) return;
    final outside = link.outside;
    if (outside != null) {
      launchExternal(outside);
      return;
    }
    final article = link.article;
    final anchor = link.anchor;
    // A heading of the text that is open: scroll to it, no new page.
    if (anchor != null &&
        anchor.isNotEmpty &&
        (article == null || article.path == page.path)) {
      controller.jump(anchor);
      return;
    }
    if (article == null) return;
    show(article, anchor: anchor);
  }

  /// Opens [article] as the next text. The one that is open stays as it is.
  void show(DocArticle article, {String? anchor}) {
    if (article.path == page.path && (anchor == null || anchor.isEmpty)) {
      return;
    }
    trail = [...trail, DocPage.of(article, anchor: anchor)];
    onChange();
  }

  void back() {
    if (!canBack) return;
    trail = trail.sublist(0, trail.length - 1);
    onChange();
  }
}

/// The text of a [DocReader]: rendered markdown, or its source with line
/// numbers.
class DocBody extends StatelessWidget {
  const DocBody({
    required this.reader,
    required this.raw,
    required this.codeFont,
    required this.accent,
    this.linkOf,
    this.sides = 0,
    this.lead = 0,
    this.trail = 0,
    super.key,
  });

  final DocReader reader;
  final bool raw;
  final double codeFont;
  final Color accent;

  /// See [MdView.linkOf].
  final String Function(String slug)? linkOf;

  /// See [MdView.sides].
  final double sides;

  /// See [MdView.lead].
  final double lead;

  /// See [MdView.trail].
  final double trail;

  @override
  Widget build(BuildContext context) {
    final page = reader.page;
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
      font: docFontOf(codeFont),
      accent: accent,
      canOpen: reader.canOpen,
      onOpen: reader.open,
      controller: reader.controller,
      anchor: page.anchor,
      linkOf: linkOf,
      sides: sides,
      lead: lead,
      trail: trail,
    );
  }
}
