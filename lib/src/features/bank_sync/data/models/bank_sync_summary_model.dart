import 'package:mony_time/src/features/bank_sync/data/models/bank_message_model.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_sync_summary.dart';

/// Data-layer representation of [BankSyncSummary] with JSON mapping.
class BankSyncSummaryModel extends BankSyncSummary {
  const BankSyncSummaryModel({
    super.isConnected,
    super.pendingCount,
    super.pendingNeedsCheckCount,
    super.importedCount,
    super.ignoredCount,
    super.lastMessageAt,
  });

  factory BankSyncSummaryModel.fromJson(Map<String, dynamic> json) {
    int count(String key) => (json[key] as num?)?.toInt() ?? 0;
    return BankSyncSummaryModel(
      isConnected: (json['is_connected'] ?? false) as bool,
      pendingCount: count('pending_count'),
      pendingNeedsCheckCount: count('pending_needs_check_count'),
      importedCount: count('imported_count'),
      ignoredCount: count('ignored_count'),
      lastMessageAt: BankMessageModel.parseInstant(json['last_message_at']),
    );
  }
}
