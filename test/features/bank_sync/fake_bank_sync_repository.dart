import 'dart:async';

import 'package:fpdart/fpdart.dart';

import 'package:mony_time/src/features/bank_sync/domain/entities/bank.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_link.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_sync_results.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_sync_summary.dart';
import 'package:mony_time/src/features/bank_sync/domain/parsing/bank_sms_parser.dart';
import 'package:mony_time/src/features/bank_sync/domain/repositories/bank_sync_repository.dart';
import 'package:mony_time/src/shared/enums/transaction_type.dart';
import 'package:mony_time/src/utils/failure.dart';
import 'package:mony_time/src/utils/typedefs.dart';

/// In-memory stand-in for the live API + native capture, shaped like the
/// production responses. Records what the app asked for.
class FakeBankSyncRepository implements BankSyncRepository {
  FakeBankSyncRepository({this.signedIn = true});

  bool signedIn;
  BankLink link = BankLink.disconnected;
  final List<BankMessage> messages = [];
  final List<String> calls = [];
  ImportOverrides? lastOverrides;

  /// Next call of that name fails with this code once.
  final Map<String, String> failNext = {};

  /// Calls of that name wait here until the test completes the gate — for
  /// racing an in-flight read against a mutation or a sign-out.
  final Map<String, Completer<void>> holds = {};

  /// Settled tabs page through `pageSize` items when set (the real server
  /// pages; `null` returns everything at once, as the flow tests expect).
  int? pageSize;

  final _captured = StreamController<void>.broadcast();
  void emitCaptured() => _captured.add(null);

  static const banks = <Bank>[
    Bank(
      id: 'cib',
      name: 'CIB',
      nameAr: 'البنك التجاري الدولي',
      shortName: 'CIB',
      senderIds: ['CIB'],
      brandColor: 4280045210,
    ),
    Bank(
      id: 'nbe',
      name: 'National Bank of Egypt',
      nameAr: 'البنك الأهلي المصري',
      shortName: 'NBE',
      senderIds: ['NBE', 'AlAhlyBank'],
      brandColor: 4278218826,
    ),
    Bank(
      id: 'bm',
      name: 'Banque Misr',
      nameAr: 'بنك مصر',
      shortName: 'BM',
      senderIds: ['BanqueMisr', 'BM'],
      brandColor: 4288880436,
    ),
  ];

  static const _categories = {
    'groceries': ('🛒', 'Groceries'),
    'food': ('🍜', 'Food'),
    'salary': ('💰', 'Salary'),
    'other_expense': ('🧾', 'Other'),
    'other_income': ('➕', 'Other'),
  };

  var _ids = 0;

  /// What a fresh connect finds: one clear purchase, one the parser wasn't
  /// sure about, and an OTP filed as ignored.
  void seedInbox() {
    final now = DateTime.now();
    add(
      'CIB',
      'Your CIB card ending 4821 was charged EGP 245.50 at CARREFOUR MAADI '
          'on 24/09/2026 14:32. Available limit EGP 12,450.00',
      now.subtract(const Duration(minutes: 20)),
    );
    add(
      'CIB',
      'CIB: A transaction of 1,250.00 was made on your card ending 4821 on '
          '25/09/2026.',
      now.subtract(const Duration(hours: 3)),
    );
    add(
      'CIB',
      'Your CIB OTP for EGP 500.00 at AMAZON is ••••••',
      now.subtract(const Duration(hours: 5)),
    );
  }

  BankMessage add(String sender, String body, DateTime at) {
    final parsed = BankSmsParser.parse(body, receivedAt: at);
    final key = parsed?.categoryLabel?.toLowerCase();
    final category = _categories[key] ??
        _categories[parsed?.type == TransactionType.income
            ? 'other_income'
            : 'other_expense'];
    final message = BankMessage(
      id: 'msg-${++_ids}',
      bankId: banks.firstWhere((b) => b.matchesSender(sender)).id,
      sender: sender,
      body: body,
      receivedAt: at,
      status: parsed == null
          ? BankMessageStatus.ignored
          : BankMessageStatus.pending,
      parsed: parsed == null
          ? null
          : ParsedBankSms(
              amount: parsed.amount,
              type: parsed.type,
              categoryId: 'cat-${key ?? 'other'}',
              categoryEmoji: category?.$1,
              categoryLabel: category?.$2,
              categoryKey: key,
              merchant: parsed.merchant,
              cardLast4: parsed.cardLast4,
              balance: parsed.balance,
              occurredAt: parsed.occurredAt ?? at,
              typeDetected: parsed.typeDetected,
              currencyDetected: parsed.currencyDetected,
            ),
    );
    messages.add(message);
    return message;
  }

  FutureEither<T> _run<T>(String name, T Function() body) async {
    calls.add(name);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final hold = holds[name];
    if (hold != null) await hold.future;
    final code = failNext.remove(name);
    if (code != null) return left(ServerFailure(code, code: code, status: 409));
    return right(body());
  }

  void _replace(BankMessage message) {
    final i = messages.indexWhere((m) => m.id == message.id);
    messages[i] = message;
  }

  BankImportResult _import(BankMessage m, ImportOverrides o) {
    final p = m.parsed!;
    final imported = BankMessage(
      id: m.id,
      bankId: m.bankId,
      sender: m.sender,
      body: m.body,
      receivedAt: m.receivedAt,
      channel: m.channel,
      status: BankMessageStatus.imported,
      parsed: p,
      transactionId: 'txn-${m.id}',
    );
    _replace(imported);
    return BankImportResult(
      message: imported,
      transaction: ImportedTransaction(
        id: 'txn-${m.id}',
        type: o.type ?? p.type,
        amount: o.amount ?? p.amount,
        date: o.date ?? p.occurredAt ?? m.receivedAt,
        categoryEmoji: p.categoryEmoji ?? '🧾',
        categoryLabel: p.categoryLabel ?? 'Other',
        source: 'CIB •• ${p.cardLast4}',
        note: o.note ?? p.merchant ?? '',
        bankMessageId: m.id,
      ),
    );
  }

  // ── BankSyncRepository ─────────────────────────────────────────────────────

  @override
  bool get hasSession => signedIn;

  @override
  Stream<void> get capturedMessages => _captured.stream;

  @override
  BankLinkMethod get deviceMethod => BankLinkMethod.sms;

  @override
  FutureEither<List<Bank>> getSupportedBanks() =>
      _run('getSupportedBanks', () => banks);

  @override
  FutureEither<BankLink> getLink() => _run('getLink', () => link);

  @override
  FutureEither<BankLink> connect({
    required List<String> bankIds,
    required ImportMode mode,
  }) =>
      _run('connect', () {
        link = BankLink(
          isConnected: true,
          method: BankLinkMethod.sms,
          bankIds: bankIds,
          mode: mode,
          connectedAt: DateTime.now(),
        );
        return link;
      });

  @override
  FutureEither<BankLink> updateLink({
    required List<String> bankIds,
    required ImportMode mode,
  }) =>
      _run('updateLink',
          () => link = link.copyWith(bankIds: bankIds, mode: mode));

  @override
  FutureEither<void> disconnect() =>
      _run('disconnect', () => link = BankLink.disconnected);

  /// What the next `ensureCapture` reports.
  CaptureReport captureReport = (outcome: CaptureOutcome.armed, caughtUp: 0);

  @override
  FutureEither<CaptureReport> ensureCapture(BankLink link) =>
      _run('ensureCapture', () => captureReport);

  @override
  FutureEither<void> reissueCapture() => _run('reissueCapture', () {
        captureReport = (outcome: CaptureOutcome.armed, caughtUp: 0);
      });

  @override
  FutureEither<void> stopCapture() => _run('stopCapture', () {});

  @override
  FutureEither<HistoryScanResult> importRecentHistory({
    required List<String> bankIds,
  }) =>
      _run('importRecentHistory', () {
        seedInbox();
        return const HistoryScanResult(
          found: 3,
          created: 3,
          pendingCreated: 2,
        );
      });

  @override
  FutureEither<BankSyncSummary> getSummary() => _run('getSummary', () {
        int count(BankMessageStatus s) =>
            messages.where((m) => m.status == s).length;
        return BankSyncSummary(
          isConnected: link.isConnected,
          pendingCount: count(BankMessageStatus.pending),
          pendingNeedsCheckCount: messages
              .where((m) =>
                  m.status == BankMessageStatus.pending && m.needsAttention)
              .length,
          importedCount: count(BankMessageStatus.imported),
          ignoredCount: count(BankMessageStatus.ignored),
          lastMessageAt: messages.isEmpty
              ? null
              : messages
                  .map((m) => m.receivedAt)
                  .reduce((a, b) => a.isAfter(b) ? a : b),
        );
      });

  @override
  FutureEither<BankMessagePage> getMessages({
    required BankMessageStatus status,
    String? cursor,
    int limit = 100,
  }) =>
      _run('getMessages', () {
        final items = messages.where((m) => m.status == status).toList()
          ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
        final size = pageSize;
        if (size == null) return BankMessagePage(items: items);
        // Opaque cursor = offset into the sorted list.
        final offset = int.tryParse(cursor ?? '') ?? 0;
        final end = offset + size > items.length ? items.length : offset + size;
        return BankMessagePage(
          items: items.sublist(offset, end),
          nextCursor: end < items.length ? '$end' : null,
          hasMore: end < items.length,
        );
      });

  @override
  FutureEither<BankMessage> getMessage(String id) =>
      _run('getMessage', () => messages.firstWhere((m) => m.id == id));

  @override
  FutureEither<SubmittedBankMessage> submitMessage({
    required String sender,
    required String body,
  }) =>
      _run('submitMessage', () {
        final message = add(sender, body, DateTime.now());
        return SubmittedBankMessage(message: message);
      });

  @override
  FutureEither<List<BankMessage>> setStatus(
    List<String> ids,
    BankMessageStatus status,
  ) =>
      _run('setStatus', () {
        final moved = <BankMessage>[];
        for (final id in ids) {
          final m = messages.firstWhere((m) => m.id == id);
          final next = m.copyWith(status: status);
          _replace(next);
          moved.add(next);
        }
        return moved;
      });

  @override
  FutureEither<BankImportResult> importMessage(
    String id,
    ImportOverrides overrides,
  ) =>
      _run('importMessage', () {
        lastOverrides = overrides;
        return _import(messages.firstWhere((m) => m.id == id), overrides);
      });

  @override
  FutureEither<BulkImportResult> importMessages(List<String> ids) => _run(
      'importMessages',
      () => BulkImportResult(imported: [
            for (final id in ids)
              _import(
                messages.firstWhere((m) => m.id == id),
                ImportOverrides.none,
              ),
          ]));

  @override
  FutureEither<List<BankCategory>> getCategories(TransactionType type) => _run(
      'getCategories',
      () => [
            for (final MapEntry(:key, :value) in _categories.entries)
              if ((type == TransactionType.income) ==
                  (key == 'salary' || key == 'other_income'))
                BankCategory(
                  id: 'cat-$key',
                  type: type,
                  name: value.$2,
                  emoji: value.$1,
                  systemKey: key,
                ),
          ]);
}
