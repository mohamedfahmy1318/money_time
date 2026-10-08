import 'package:equatable/equatable.dart';

/// Inbox counters from `GET /bank-sync/summary` — cheap enough for the home
/// banner, the profile badge and the tab labels without loading messages.
class BankSyncSummary extends Equatable {
  const BankSyncSummary({
    this.isConnected = false,
    this.pendingCount = 0,
    this.pendingNeedsCheckCount = 0,
    this.importedCount = 0,
    this.ignoredCount = 0,
    this.lastMessageAt,
  });

  static const empty = BankSyncSummary();

  final bool isConnected;
  final int pendingCount;

  /// Pending messages the parser wasn't sure about (the "Check" badge).
  final int pendingNeedsCheckCount;
  final int importedCount;
  final int ignoredCount;

  /// Newest `received_at`; `null` when there are no messages.
  final DateTime? lastMessageAt;

  /// Pending messages safe to add in bulk.
  int get pendingClearCount {
    final clear = pendingCount - pendingNeedsCheckCount;
    return clear < 0 ? 0 : clear;
  }

  @override
  List<Object?> get props => [
        isConnected,
        pendingCount,
        pendingNeedsCheckCount,
        importedCount,
        ignoredCount,
        lastMessageAt,
      ];
}
