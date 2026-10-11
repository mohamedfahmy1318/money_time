import 'package:flutter_test/flutter_test.dart';

import 'package:mony_time/src/features/bank_sync/domain/entities/bank.dart';

void main() {
  const bm = Bank(
    id: 'bm',
    name: 'Banque Misr',
    nameAr: 'بنك مصر',
    shortName: 'BM',
    senderIds: ['BanqueMisr', 'BM'],
    brandColor: 0xFF000000,
  );

  group('Bank.matchesSender', () {
    test('ignores case, spaces and punctuation — the rule all platforms share',
        () {
      // Banque Misr's instant transfers arrive from "Banque Misr".
      expect(bm.matchesSender('Banque Misr'), isTrue);
      expect(bm.matchesSender(' banque-misr '), isTrue);
      expect(bm.matchesSender('bm'), isTrue);
      expect(Bank.canonicalSender('BanK-AlAhly'), 'bankalahly');
      expect(Bank.canonicalSender('بنك مصر'), 'بنكمصر');
    });

    test('never matches a prefix, a phone number or an empty sender', () {
      expect(bm.matchesSender('Banque'), isFalse);
      expect(bm.matchesSender('+201001234567'), isFalse);
      expect(bm.matchesSender(' - '), isFalse);
    });
  });
}
