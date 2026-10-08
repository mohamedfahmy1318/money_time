import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:mony_time/src/features/bank_sync/bank_sync_di.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_link.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/presentation/cubits/bank_sync_cubit.dart';

import 'fake_bank_sync_repository.dart';

/// The cubit is shared app-wide, so reads and writes overlap: a resume
/// refresh while the user taps Ignore, a sign-out while a load is in flight.
/// These pin down what wins.
void main() {
  late FakeBankSyncRepository repo;
  late BankSyncCubit cubit;

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 80));

  setUp(() {
    repo = FakeBankSyncRepository()
      ..link = BankLink(
        isConnected: true,
        method: BankLinkMethod.sms,
        bankIds: const ['cib'],
        mode: ImportMode.review,
        connectedAt: DateTime.now(),
      )
      ..seedInbox();
    BankSyncDi.repository = repo;
    cubit = BankSyncDi.bankSyncCubit();
  });

  tearDown(() => cubit.close());

  test('a load still in flight at sign-out never lands on the guest state',
      () async {
    repo.holds['getSummary'] = Completer<void>();
    final load = cubit.load();
    await settle();
    expect(cubit.state.isLoading, isTrue);

    repo.signedIn = false;
    await cubit.signOut();
    repo.holds.remove('getSummary')!.complete();
    await load;
    await settle();

    expect(cubit.state.status, BankSyncStatus.ready);
    expect(cubit.state.isConnected, isFalse);
    expect(cubit.state.pending, isEmpty);
    expect(cubit.state.summary.pendingCount, 0);
    expect(cubit.state.banks, isNotEmpty,
        reason: 'the guest intro still gets the catalog');
  });

  test('a refresh that started before Ignore does not undo it', () async {
    await cubit.load();
    final target = cubit.state.pending.first;

    // The link read gates the whole refresh (the ignore below only reads
    // the summary, so it is not held).
    repo.holds['getLink'] = Completer<void>();
    final refresh = cubit.refresh();
    await settle();

    await cubit.ignore(target.id);
    expect(cubit.state.ignored.items.map((m) => m.id), contains(target.id));

    repo.holds.remove('getLink')!.complete();
    await refresh;
    await settle();

    expect(cubit.state.pending.map((m) => m.id), isNot(contains(target.id)));
    expect(cubit.state.ignored.items.map((m) => m.id), contains(target.id));
  });

  test('a failed Ignore puts only that row back and reports the failure',
      () async {
    await cubit.load();
    final first = cubit.state.pending[0];
    final second = cubit.state.pending[1];

    await cubit.ignore(second.id);
    repo.failNext['setStatus'] = 'CONFLICT';
    await cubit.ignore(first.id);
    await settle();

    expect(cubit.state.action, BankSyncAction.failure);
    expect(cubit.state.errorCode, 'CONFLICT');
    expect(cubit.state.pending.map((m) => m.id), contains(first.id),
        reason: 'the failed ignore is rolled back');
    expect(cubit.state.ignored.items.map((m) => m.id), contains(second.id),
        reason: 'the other row keeps its server-confirmed state');
    expect(cubit.state.ignored.items.map((m) => m.id),
        isNot(contains(first.id)));
  });

  test('loadMore merges into the tab as it is now, deduplicated by id',
      () async {
    repo.pageSize = 2;
    for (var i = 0; i < 5; i++) {
      final m = repo.add(
        'CIB',
        'Your CIB card ending 4821 was charged EGP ${100 + i}.00 at SHOP $i '
            'on 2$i/09/2026 10:00. Available limit EGP 1,000.00',
        DateTime.now().subtract(Duration(days: i + 1)),
      );
      repo.messages[repo.messages.indexOf(m)] =
          m.copyWith(status: BankMessageStatus.imported);
    }
    await cubit.load();
    expect(cubit.state.imported.items, hasLength(2));
    expect(cubit.state.imported.hasMore, isTrue);

    // A message is added to the tab while the next page is loading.
    repo.holds['getMessages'] = Completer<void>();
    final more = cubit.loadMore(BankMessageStatus.imported);
    await settle();
    final pendingOne = cubit.state.pending.first;
    repo.holds.remove('getMessages')!.complete();
    await cubit.importOne(pendingOne.id);
    await more;
    await settle();

    final ids = cubit.state.imported.items.map((m) => m.id).toList();
    expect(ids, contains(pendingOne.id));
    expect(ids.toSet().length, ids.length, reason: 'no duplicates');
  });

  test('a revoked token is reported, not silently re-issued', () async {
    repo.captureReport = (outcome: CaptureOutcome.revoked, caughtUp: 0);
    await cubit.load();
    await settle();
    expect(cubit.state.captureRevoked, isTrue);
    expect(repo.calls, isNot(contains('reissueCapture')));

    await cubit.useThisPhone();
    expect(cubit.state.captureRevoked, isFalse);
    expect(cubit.state.action, BankSyncAction.captureMoved);
    expect(repo.calls, contains('reissueCapture'));
  });

  test('a catch-up that delivered SMS reloads the inbox', () async {
    repo.captureReport = (outcome: CaptureOutcome.armed, caughtUp: 2);
    await cubit.load();
    await settle();
    repo.captureReport = (outcome: CaptureOutcome.armed, caughtUp: 0);
    await settle();
    expect(repo.calls.where((c) => c == 'getSummary').length, greaterThan(1));
  });
}
