import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../hive/hex_scene.dart';
import '../../locale/languages.dart';
import '../../navigation/sections.dart';
import '../../registry/repo.dart';

Color get registryColor => sectionById('registry')!.color;

String regText(String language, String ru, String en) =>
    phrase(language, {'ru': ru, 'en': en});

String repoKindLabel(String language, String kind) {
  switch (kind) {
    case 'private':
      return regText(language, 'Приватные', 'Private');
    default:
      return regText(language, 'Публичные', 'Public');
  }
}

String repoOrderLabel(String language, String order) {
  if (order == 'desc') return regText(language, 'Я-А', 'Z-A');
  return regText(language, 'А-Я', 'A-Z');
}

/// Search card and the identity cell inside a repository.
///
/// The link sits on the upper left. The platform sits on the lower right.
/// Public or private runs up the right edge. The size runs up the left edge.
HexSlot repoMark({
  required String id,
  required RegistryRepo repo,
  required String language,
  required int q,
  required int r,
  Uint8List? image,
  bool tappable = true,
  bool busy = false,
}) {
  final platform = repoPlatformLabel(language, repo.platform);
  return HexSlot(
    id: id,
    title: repoCaption(repo.repositoryUrl),
    footer: platform.isEmpty ? null : platform,
    sideLeft: repoSizeLabel(repo.localSize, language),
    sideRight: repoAccessLabel(language, repo.public),
    color: registryColor,
    q: q,
    r: r,
    icon: image == null ? 'assets/icons/repo.svg' : null,
    image: image,
    tappable: tappable,
    busy: busy,
  );
}
