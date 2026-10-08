import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:mony_time/src/features/bank_sync/data/helpers/sms_batch_chunker.dart';

Map<String, dynamic> _sms(int i, {int length = 120}) => {
      'sender': 'NBE',
      'body': 'تم خصم مبلغ $i جنيه ${'٠' * length}',
      'received_at': '2026-09-22T19:05:00Z',
    };

void main() {
  test('no chunk exceeds 500 messages', () {
    final chunks = SmsBatchChunker.chunk(
        [for (var i = 0; i < 1201; i++) _sms(i, length: 1)]);
    expect(chunks.map((c) => c.length), [500, 500, 201]);
  });

  test('no chunk body reaches the 1 MB cap with long Arabic messages', () {
    final items = [for (var i = 0; i < 500; i++) _sms(i, length: 1900)];
    final chunks = SmsBatchChunker.chunk(items);
    expect(chunks.length, greaterThan(1));
    for (final chunk in chunks) {
      final bytes = utf8
          .encode(jsonEncode({'channel': 'history_scan', 'messages': chunk}))
          .length;
      expect(bytes, lessThan(SmsBatchChunker.defaultMaxBytes));
    }
    expect(chunks.expand((c) => c).length, items.length);
  });

  test('empty input makes no calls', () {
    expect(SmsBatchChunker.chunk(const []), isEmpty);
  });
}
