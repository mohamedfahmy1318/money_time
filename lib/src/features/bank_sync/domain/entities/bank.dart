import 'package:equatable/equatable.dart';

/// A bank (or payment network) whose SMS alerts Money Time can read.
class Bank extends Equatable {
  const Bank({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.shortName,
    required this.senderIds,
    required this.brandColor,
  });

  final String id;
  final String name;
  final String nameAr;

  /// Monogram shown on the bank tile (`CIB`, `NBE` …).
  final String shortName;

  /// SMS sender IDs the bank sends alerts from.
  final List<String> senderIds;

  /// ARGB brand colour — tints the monogram tile.
  final int brandColor;

  /// Sender ids vary in case, spacing and punctuation between phones and
  /// message types (`BanqueMisr` / `Banque Misr`, `BanK-AlAhly`): compare
  /// the canonical form — lower-case letters and digits only. The server,
  /// Android and iOS apply the same rule.
  static String canonicalSender(String sender) => sender
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');

  bool matchesSender(String sender) {
    final s = canonicalSender(sender);
    return s.isNotEmpty && senderIds.any((id) => canonicalSender(id) == s);
  }

  @override
  List<Object?> get props =>
      [id, name, nameAr, shortName, senderIds, brandColor];
}
