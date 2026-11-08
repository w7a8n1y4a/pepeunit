import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../library/library.dart';
import '../../locale/languages.dart';
import '../code/code_modal.dart';
import 'doc_reader.dart';

/// A short Library text in one frame: a [CodeModal] whose body is a rendered
/// markdown or its source with line numbers ([DocBody]). Tips, the
/// presentation and the support rules use it. The documentation has a screen
/// of its own (`DocsPage`).
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

class _LibraryModalState extends State<LibraryModal> {
  late final DocReader _reader = DocReader(
    first: _first(),
    docs: widget.docs,
    onChange: () => setState(() {}),
  );

  DocPage _first() => DocPage(
    title: widget.title,
    source: widget.source,
    path: widget.path,
    anchor: widget.anchor,
  );

  @override
  void didUpdateWidget(LibraryModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reader.docs = widget.docs;
    if (oldWidget.source != widget.source ||
        oldWidget.title != widget.title ||
        oldWidget.path != widget.path) {
      _reader.reset(_first());
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final raw = model.vault.libraryRaw;
    final page = _reader.page;
    String word(String ru) => phrase(language, {'ru': ru});
    return CodeModal(
      title: page.title,
      color: widget.color,
      onClose: widget.onClose,
      copy: () => page.source,
      rows: 100000,
      actions: (font) => [
        if (_reader.canBack)
          CodeWordButton(label: word('Назад'), font: font, onTap: _reader.back),
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
      body: (codeFont, _) => DocBody(
        reader: _reader,
        raw: raw,
        codeFont: codeFont,
        accent: widget.color,
      ),
    );
  }
}
