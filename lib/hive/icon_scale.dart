/// One painted size for each icon, on every screen.
///
/// The icon square is `0.72` of the cell radius: the size of `back.svg`
/// and the home menu. [menuInk] is the longer side of the ink in the
/// smallest of those pictures, `instances.svg`. An asset that stops short
/// of that is grown until its ink matches. An asset that already reaches
/// it stays at 1, so Back, the home menu, and the avatar circle do not move.
/// The avatar circle is separate: `1.15 * 0.85` of the radius in `HexScene`.
///
/// Ink fractions are the longer side of the opaque pixels over the icon
/// square, measured on a raster of the file. Re-measure when the file changes.
///
/// Four glyphs stay off that fit. A hollow or sparse mark was still the
/// wrong size once its empty margin was gone:
/// - `settings.svg` is 1.6. The gear fit is about 1.33, and that was still small.
/// - `power.svg` is 1.5. Half again the file, which is also the menu fit.
/// - `telegram.svg` is 1.2. A fifth larger than the instance card.
/// - `sight.svg` is 1.2. The size of Make favorite.
const menuInk = 0.88;

const _boost = <String, double>{
  'assets/icons/settings.svg': 1.6,
  'assets/icons/power.svg': 1.5,
  'assets/icons/telegram.svg': 1.2,
  'assets/icons/sight.svg': 1.2,
};

const _inkFill = <String, double>{
  'assets/icons/demote.svg': 0.81,
  'assets/icons/terminal.svg': 0.80,
  'assets/icons/key_load.svg': 0.80,
  'assets/icons/icon_load.svg': 0.78,
  'assets/icons/key_gen.svg': 0.77,
  'assets/icons/key.svg': 0.77,
  'assets/icons/exclaim.svg': 0.77,
  'assets/icons/send.svg': 0.75,
  'assets/icons/rocket.svg': 0.70,
  'assets/icons/plus.svg': 0.69,
  'assets/icons/search.svg': 0.66,
  'assets/icons/check.svg': 0.62,
  'assets/icons/ban.svg': 0.62,
  'assets/icons/repo.svg': 0.86,
};

/// How far to grow [asset] inside the icon square. The same file always
/// returns the same number. 1.6 is the ceiling: past it the picture meets
/// the edge labels.
double iconScaleOf(String asset) {
  final boost = _boost[asset];
  if (boost != null) return boost;
  final fill = _inkFill[asset];
  if (fill == null || fill >= menuInk) return 1;
  final scale = menuInk / fill;
  return scale > 1.6 ? 1.6 : scale;
}
