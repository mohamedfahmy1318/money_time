import 'package:mony_time/src/features/bank_sync/data/models/bank_message_model.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_sync_results.dart';

/// JSON mapping for the bank-sync response shapes that aren't a single
/// message: list pages, categories, import results, pastes and batches.
abstract final class BankSyncResultModels {
  BankSyncResultModels._();

  /// `{data: [...], meta: {next_cursor, has_more}}`.
  static BankMessagePage page(Map<String, dynamic> json) {
    final meta = (json['meta'] as Map<String, dynamic>?) ?? const {};
    return BankMessagePage(
      items: [
        for (final item in (json['data'] as List<dynamic>? ?? const []))
          BankMessageModel.fromJson(item as Map<String, dynamic>),
      ],
      nextCursor: meta['next_cursor'] as String?,
      hasMore: (meta['has_more'] ?? false) as bool,
    );
  }

  static BankCategory category(Map<String, dynamic> json) => BankCategory(
        id: json['id'].toString(),
        type: BankMessageModel.typeFrom(json['type']),
        name: (json['name'] ?? '') as String,
        emoji: (json['emoji'] ?? '🧾') as String,
        systemKey: json['system_key'] as String?,
      );

  static ImportedTransaction transaction(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final account = json['account'] as Map<String, dynamic>?;
    return ImportedTransaction(
      id: json['id'].toString(),
      type: BankMessageModel.typeFrom(json['type']),
      amount: (json['amount'] as num).toDouble(),
      date: BankMessageModel.parseInstant(json['date']) ?? DateTime.now(),
      categoryEmoji:
          (json['category_emoji'] ?? category?['emoji'] ?? '🧾') as String,
      categoryLabel:
          (json['category_label'] ?? category?['name'] ?? '') as String,
      source: (json['source'] ?? account?['name'] ?? '') as String,
      note: (json['note'] ?? '') as String,
      bankMessageId: json['bank_message_id'] as String?,
    );
  }

  /// `{message, transaction}` from a single or bulk import.
  static BankImportResult importResult(Map<String, dynamic> json) =>
      BankImportResult(
        message: BankMessageModel.fromJson(
          json['message'] as Map<String, dynamic>,
        ),
        transaction: transaction(json['transaction'] as Map<String, dynamic>),
      );

  /// `{data: [{message, transaction}], skipped: [{id, reason}]}`.
  static BulkImportResult bulkImport(Map<String, dynamic> json) =>
      BulkImportResult(
        imported: [
          for (final item in (json['data'] as List<dynamic>? ?? const []))
            importResult(item as Map<String, dynamic>),
        ],
        skipped: {
          for (final item in (json['skipped'] as List<dynamic>? ?? const []))
            (item as Map<String, dynamic>)['id'].toString():
                skipReason(item['reason']),
        },
      );

  static ImportSkipReason skipReason(Object? value) => switch (value) {
        'not_found' => ImportSkipReason.notFound,
        'no_parsed' => ImportSkipReason.noParsed,
        'not_pending' => ImportSkipReason.notPending,
        _ => ImportSkipReason.invalid,
      };

  /// `POST /bank-sync/messages`: the stored message (bare) plus
  /// `transaction` and `duplicate`.
  static SubmittedBankMessage submitted(Map<String, dynamic> json) {
    final tx = json['transaction'];
    return SubmittedBankMessage(
      message: BankMessageModel.fromJson(json),
      transaction: tx is Map<String, dynamic> ? transaction(tx) : null,
      duplicate: (json['duplicate'] ?? false) as bool,
    );
  }
}
