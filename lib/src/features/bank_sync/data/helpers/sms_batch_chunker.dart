import 'dart:convert';

/// Splits SMS for `POST /bank-sync/messages/batch`: at most [maxItems] per
/// call **and** an encoded body under [maxBytes] — the server caps bodies at
/// 1 MB, and 500 long Arabic messages can pass that.
abstract final class SmsBatchChunker {
  SmsBatchChunker._();

  static const int defaultMaxItems = 500;
  static const int defaultMaxBytes = 900 * 1024;

  /// Room for `{"channel":"history_scan","messages":[…]}` around the items.
  static const int _envelopeBytes = 64;

  static List<List<Map<String, dynamic>>> chunk(
    List<Map<String, dynamic>> items, {
    int maxItems = defaultMaxItems,
    int maxBytes = defaultMaxBytes,
  }) {
    final chunks = <List<Map<String, dynamic>>>[];
    var current = <Map<String, dynamic>>[];
    var bytes = _envelopeBytes;

    for (final item in items) {
      final size = utf8.encode(jsonEncode(item)).length + 1; // + comma
      final full = current.length == maxItems || bytes + size > maxBytes;
      if (current.isNotEmpty && full) {
        chunks.add(current);
        current = [];
        bytes = _envelopeBytes;
      }
      current.add(item);
      bytes += size;
    }
    if (current.isNotEmpty) chunks.add(current);
    return chunks;
  }
}
