import 'package:flutter_test/flutter_test.dart';

import 'package:mony_time/src/features/bank_sync/data/models/bank_link_model.dart';
import 'package:mony_time/src/features/bank_sync/data/models/bank_message_model.dart';
import 'package:mony_time/src/features/bank_sync/data/models/bank_model.dart';
import 'package:mony_time/src/features/bank_sync/data/models/bank_sync_result_models.dart';
import 'package:mony_time/src/features/bank_sync/data/models/bank_sync_summary_model.dart';
import 'package:mony_time/src/features/bank_sync/data/models/raw_sms.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_link.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_sync_results.dart';
import 'package:mony_time/src/shared/enums/transaction_type.dart';

// Shapes captured from https://moneytime.findosystem.com/v1 on 2026-10-07.
Map<String, dynamic> _message({
  String status = 'pending',
  Map<String, dynamic>? parsed,
}) =>
    {
      'id': '01a11616-0d0c-71b7-ae75-b7016252965c',
      'bank_id': 'cib',
      'sender': 'CIB',
      'body': 'Your CIB card ending 4821 was charged EGP 245.50 at CARREFOUR '
          'MAADI on 24/09/2026 14:32. Available limit EGP 12,450.00',
      'received_at': '2026-10-07T11:18:23Z',
      'channel': 'paste',
      'status': status,
      'parsed': parsed ??
          {
            'amount': 245.5,
            'type': 'expense',
            'category_id': '01a11615-729c-7337-96fd-80d7b2de20c1',
            'category_emoji': '🛒',
            'category_label': 'Groceries',
            'category_key': 'groceries',
            'merchant': 'Carrefour Maadi',
            'card_last4': '4821',
            'balance': 12450,
            'occurred_at': '2026-09-24T11:32:00Z',
            'type_detected': true,
            'currency_detected': true,
            'is_confident': true,
            'parser_version': '2026.10.1',
          },
      'transaction_id': null,
      'created_at': '2026-10-07T11:18:26Z',
    };

Map<String, dynamic> _transaction() => {
      'id': '01a11616-45fc-730c-bbbb-66a9778b32aa',
      'type': 'expense',
      'amount': 240,
      'currency_code': 'EGP',
      'date': '2026-09-24T11:32:00Z',
      'note': 'Carrefour Maadi',
      'merchant': 'Carrefour Maadi',
      'origin': 'bank_sms',
      'category_id': '01a11615-729c-7337-96fd-80d7b2740eb7',
      'category': {'id': 'x', 'type': 'expense', 'name': 'Food', 'emoji': '🍜'},
      'account': {'id': 'a', 'name': 'CIB •• 4821', 'type': 'card'},
      'bank_message_id': '01a11616-0d0c-71b7-ae75-b7016252965c',
      'category_emoji': '🍜',
      'category_label': 'Food',
      'source': 'CIB •• 4821',
      'is_auto': true,
    };

void main() {
  test('message: every field, instants converted to local time', () {
    final m = BankMessageModel.fromJson(_message());
    expect(m.bankId, 'cib');
    expect(m.channel, BankMessageChannel.paste);
    expect(m.status, BankMessageStatus.pending);
    expect(m.receivedAt, DateTime.utc(2026, 10, 7, 11, 18, 23).toLocal());
    expect(m.receivedAt.isUtc, isFalse);
    final p = m.parsed!;
    expect(p.amount, 245.5);
    expect(p.type, TransactionType.expense);
    expect(p.categoryId, '01a11615-729c-7337-96fd-80d7b2de20c1');
    expect(p.categoryKey, 'groceries');
    expect(p.balance, 12450);
    expect(p.isConfident, isTrue);
    expect(m.occurredAt, DateTime.utc(2026, 9, 24, 11, 32).toLocal());
    expect(m.needsAttention, isFalse);
  });

  test('message: not-a-transaction and needs-check variants', () {
    final otp = BankMessageModel.fromJson(
      _message(status: 'ignored')..['parsed'] = null,
    );
    expect(otp.isTransaction, isFalse);
    expect(otp.status, BankMessageStatus.ignored);

    final unsure = BankMessageModel.fromJson(_message(parsed: {
      'amount': 1250,
      'type': 'expense',
      'category_id': null,
      'category_emoji': null,
      'category_label': null,
      'category_key': 'other_expense',
      'merchant': null,
      'card_last4': '4821',
      'balance': null,
      'occurred_at': '2026-09-25T13:00:00Z',
      'type_detected': false,
      'currency_detected': false,
      'is_confident': false,
    }));
    expect(unsure.needsAttention, isTrue);
    expect(unsure.parsed!.categoryEmoji, isNull);
  });

  test('page, summary, link and bank catalog', () {
    final page = BankSyncResultModels.page({
      'data': [_message()],
      'meta': {'next_cursor': 'eyJyZWNl', 'has_more': true},
    });
    expect(page.items, hasLength(1));
    expect(page.nextCursor, 'eyJyZWNl');
    expect(page.hasMore, isTrue);

    final summary = BankSyncSummaryModel.fromJson(const {
      'is_connected': true,
      'pending_count': 12,
      'pending_needs_check_count': 3,
      'imported_count': 41,
      'ignored_count': 7,
      'last_message_at': '2026-10-06T08:55:10Z',
    });
    expect(summary.pendingClearCount, 9);
    expect(summary.lastMessageAt, isNotNull);

    final link = BankLinkModel.fromJson(const {
      'is_connected': true,
      'method': 'sms',
      'bank_ids': ['cib', 'nbe'],
      'mode': 'automatic',
      'connected_at': '2026-10-07T11:18:16Z',
    });
    expect(link.method, BankLinkMethod.sms);
    expect(link.mode, ImportMode.automatic);

    final bank = BankModel.fromJson(const {
      'id': 'nbe',
      'name': 'National Bank of Egypt',
      'name_ar': 'البنك الأهلي المصري',
      'short_name': 'NBE',
      'sender_ids': ['NBE', 'AlAhlyBank'],
      'brand_color': 4278218826,
    });
    expect(bank.matchesSender(' alahlybank '), isTrue);
  });

  test('import, bulk import and paste responses', () {
    final single = BankSyncResultModels.importResult({
      'message': _message(status: 'imported')
        ..['transaction_id'] = '01a11616-45fc-730c-bbbb-66a9778b32aa',
      'transaction': _transaction(),
    });
    expect(single.message.status, BankMessageStatus.imported);
    expect(single.transaction.amount, 240);
    expect(single.transaction.categoryLabel, 'Food');
    expect(single.transaction.source, 'CIB •• 4821');

    final bulk = BankSyncResultModels.bulkImport({
      'data': [
        {
          'message': _message(status: 'imported'),
          'transaction': _transaction()
        },
      ],
      'skipped': [
        {'id': '00000000-0000-0000-0000-000000000000', 'reason': 'not_found'},
        {'id': 'b', 'reason': 'not_pending'},
      ],
    });
    expect(bulk.imported, hasLength(1));
    expect(bulk.skipped, {
      '00000000-0000-0000-0000-000000000000': ImportSkipReason.notFound,
      'b': ImportSkipReason.notPending,
    });

    final pasted = BankSyncResultModels.submitted(
      _message()..addAll({'transaction': null, 'duplicate': true}),
    );
    expect(pasted.duplicate, isTrue);
    expect(pasted.transaction, isNull);
  });

  test('requests carry explicit offsets', () {
    expect(
      BankMessageModel.instantToWire(DateTime(2026, 9, 24, 14, 32)),
      endsWith('Z'),
    );
    final wire =
        const RawSms(sender: 'QNB', body: 'x', timestampMs: 0).toWire();
    expect(wire['received_at'], '1970-01-01T00:00:00.000Z');
  });
}
