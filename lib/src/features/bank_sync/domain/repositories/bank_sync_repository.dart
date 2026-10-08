import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_link.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_sync_results.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_sync_summary.dart';
import 'package:mony_time/src/shared/enums/transaction_type.dart';

/// Contract implemented by the data layer: the bank-SMS link, its review
/// inbox, and this device's background capture.
abstract class BankSyncRepository {
  /// Signed in — every endpoint but the bank catalog needs the session.
  bool get hasSession;

  /// Fires when this device's background capture delivered new messages.
  Stream<void> get capturedMessages;

  /// The method this device captures with: SMS on Android, Shortcuts on
  /// iPhone.
  BankLinkMethod get deviceMethod;

  /// Banks whose alerts can be read (public catalog).
  FutureEither<List<Bank>> getSupportedBanks();

  FutureEither<BankLink> getLink();

  /// Links [bankIds] once, at the end of the wizard, and arms this device's
  /// capture with the fresh ingest token (which revokes any previous one).
  FutureEither<BankLink> connect({
    required List<String> bankIds,
    required ImportMode mode,
  });

  /// Changes banks / import mode without issuing a new token.
  FutureEither<BankLink> updateLink({
    required List<String> bankIds,
    required ImportMode mode,
  });

  /// Stops capture everywhere; received messages stay in the inbox.
  FutureEither<void> disconnect();

  /// Makes sure this device is capturing for [link]: issues the ingest
  /// token when none is stored (fresh install), refreshes the sender filter,
  /// flushes anything queued and catches up on SMS the receiver missed.
  /// Stands down when the link captures on the other platform, and reports
  /// [CaptureOutcome.revoked] — without re-issuing — when this device's
  /// token was revoked, so two phones never keep revoking each other.
  FutureEither<CaptureReport> ensureCapture(BankLink link);

  /// "Capture on this phone": re-issues the token (revoking the other
  /// phone's) and arms capture here.
  FutureEither<void> reissueCapture();

  /// Disarms capture on this device (sign-out).
  FutureEither<void> stopCapture();

  /// Reads the last 30 days of bank SMS on this device (Android) and
  /// uploads them for review.
  FutureEither<HistoryScanResult> importRecentHistory({
    required List<String> bankIds,
  });

  FutureEither<BankSyncSummary> getSummary();

  /// One page of a tab, newest first.
  FutureEither<BankMessagePage> getMessages({
    required BankMessageStatus status,
    String? cursor,
    int limit = 100,
  });

  FutureEither<BankMessage> getMessage(String id);

  /// Stores a pasted SMS (parsed server-side).
  FutureEither<SubmittedBankMessage> submitMessage({
    required String sender,
    required String body,
  });

  /// Ignore (pending → ignored) or restore (ignored → pending). Returns only
  /// the messages that actually moved.
  FutureEither<List<BankMessage>> setStatus(
    List<String> ids,
    BankMessageStatus status,
  );

  /// Adds one message as a transaction, with the user's edits.
  FutureEither<BankImportResult> importMessage(
    String id,
    ImportOverrides overrides,
  );

  /// Adds several messages with their parsed values.
  FutureEither<BulkImportResult> importMessages(List<String> ids);

  /// Active categories of [type] for the review screen's picker.
  FutureEither<List<BankCategory>> getCategories(TransactionType type);
}
