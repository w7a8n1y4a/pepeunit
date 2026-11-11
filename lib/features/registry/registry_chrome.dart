import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../hive/hex_scene.dart';
import '../../locale/languages.dart';
import '../../navigation/sections.dart';
import '../../registry/repo.dart';

Color get registryColor => sectionById('registry')!.color;

String repoKindLabel(String language, String kind) {
  switch (kind) {
    case 'private':
      return localized(language, 'Приватные', 'Private');
    default:
      return localized(language, 'Публичные', 'Public');
  }
}

String repoOrderLabel(String language, String order) {
  if (order == 'desc') return localized(language, 'Я-А', 'Z-A');
  return localized(language, 'А-Я', 'A-Z');
}

/// Search card and the identity cell inside a repository.
///
/// The link sits on the upper left. Public or private sits on the lower
/// right. The linked unit count sits on the lower left.
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
  return HexSlot(
    id: id,
    title: repoCaption(repo.repositoryUrl),
    footer: repoAccessLabel(language, repo.public),
    footerLeft: pieceCount(language, repo.childUnitCount),
    color: registryColor,
    q: q,
    r: r,
    icon: image == null ? 'assets/icons/objects/repo.svg' : null,
    image: image,
    tappable: tappable,
    busy: busy,
  );
}
