import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../library/library.dart';
import '../code/code_modal.dart';
import 'doc_reader.dart';
import '../../locale/languages.dart';

/// A short Library text in one frame: a [CodeModal] whose body is a rendered
/// markdown or its source with line numbers ([DocBody]). The support
/// rules use it. The documentation has a screen
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
    this.footer,
    this.note,
    this.noteColor = errorColor,
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

  /// Additional actions before the render/source switch.
  final List<Widget> Function(double font)? actions;

  /// One action under the text, such as Update.
  final List<Widget> Function(double font)? footer;

  /// A line under the text, like the outcome of the footer action.
  final String? note;
  final Color noteColor;

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
    return CodeModal(
      title: page.title,
      color: widget.color,
      onClose: widget.onClose,
      copy: () => page.source,
      footer: widget.footer,
      note: widget.note,
      noteColor: widget.noteColor,
      rows: 100000,
      actions: (font) => [
        if (_reader.canBack)
          CodeWordButton(
            label: localized(language, 'Назад', 'Back'),
            font: font,
            onTap: _reader.back,
            hint: 'button-doc-back',
          ),
        ...?widget.actions?.call(font),
        CodeChip(
          label: localized(language, 'Рендер', 'Render'),
          on: !raw,
          font: font,
          color: widget.color,
          onTap: () => model.setLibraryRaw(false),
          hint: 'button-render',
        ),
        CodeChip(
          label: localized(language, 'Исходник', 'Source'),
          on: raw,
          font: font,
          color: widget.color,
          onTap: () => model.setLibraryRaw(true),
          hint: 'button-source',
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
