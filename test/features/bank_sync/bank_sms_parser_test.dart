import 'package:flutter_test/flutter_test.dart';

import 'package:mony_time/src/features/bank_sync/domain/parsing/bank_sms_parser.dart';
import 'package:mony_time/src/shared/enums/transaction_type.dart';

void main() {
  final received = DateTime(2026, 9, 27, 18);

  group('BankSmsParser', () {
    test('CIB card purchase (English)', () {
      final p = BankSmsParser.parse(
        'Your CIB card ending 4821 was charged EGP 245.50 at CARREFOUR MAADI '
        'on 24/09/2026 14:32. Available limit EGP 12,450.00',
        receivedAt: received,
      )!;
      expect(p.amount, 245.50);
      expect(p.type, TransactionType.expense);
      expect(p.merchant, 'Carrefour Maadi');
      expect(p.cardLast4, '4821');
      expect(p.balance, 12450);
      expect(p.occurredAt, DateTime(2026, 9, 24, 14, 32));
      expect(p.categoryLabel, 'Groceries');
      expect(p.isConfident, isTrue);
    });

    test('NBE debit (Arabic)', () {
      final p = BankSmsParser.parse(
        'تم خصم مبلغ 350.00 جنيه من حسابكم رقم ****7812 لدى TALABAT بتاريخ '
        '22/09/2026. الرصيد المتاح 8,240.15 جنيه',
        receivedAt: received,
      )!;
      expect(p.amount, 350);
      expect(p.type, TransactionType.expense);
      expect(p.merchant, 'Talabat');
      expect(p.cardLast4, '7812');
      expect(p.balance, 8240.15);
      expect(p.categoryLabel, 'Food');
    });

    test('Banque Misr salary deposit with Arabic-Indic digits', () {
      final p = BankSmsParser.parse(
        'تم إيداع مبلغ ١٢٬٠٠٠٫٠٠ ج.م في حسابكم رقم ***5521 - تحويل راتب. '
        'الرصيد 20,340.00 ج.م',
        receivedAt: received,
      )!;
      expect(p.amount, 12000);
      expect(p.type, TransactionType.income);
      expect(p.merchant, isNull);
      expect(p.balance, 20340);
      expect(p.categoryLabel, 'Salary');
    });

    test('QNB purchase with a named-month date and no year', () {
      final p = BankSmsParser.parse(
        'QNB: Purchase of EGP 89.00 from UBER *TRIP with card ending 3390 on '
        '21SEP. Avl bal EGP 5,210.00',
        receivedAt: received,
      )!;
      expect(p.amount, 89);
      expect(p.merchant, 'Uber Trip');
      expect(p.balance, 5210);
      expect(p.occurredAt, DateTime(2026, 9, 21));
      expect(p.categoryLabel, 'Transport');
    });

    test('InstaPay transfer out is an expense to the recipient', () {
      final p = BankSmsParser.parse(
        'InstaPay: تم تحويل 500 جنيه إلى AHMED M. رقم مرجعي 88213',
        receivedAt: received,
      )!;
      expect(p.amount, 500);
      expect(p.type, TransactionType.expense);
      expect(p.merchant, 'Ahmed M');
      expect(p.cardLast4, isNull);
      expect(p.categoryLabel, 'Transfer');
    });

    test('an alert without currency or direction needs review', () {
      final p = BankSmsParser.parse(
        'CIB: A transaction of 1,250.00 was made on your card ending 4821 on '
        '21/09.',
        receivedAt: received,
      )!;
      expect(p.amount, 1250);
      expect(p.typeDetected, isFalse);
      expect(p.currencyDetected, isFalse);
      expect(p.isConfident, isFalse);
    });

    test('a missing year never lands in the future', () {
      final p = BankSmsParser.parse(
        'Your card ending 1111 was charged EGP 10 at KIOSK on 30/12',
        receivedAt: DateTime(2026, 1, 2),
      )!;
      expect(p.occurredAt, DateTime(2025, 12, 30));
    });

    test('OTP and promotional messages are not transactions', () {
      expect(
        BankSmsParser.parse('Your CIB OTP for EGP 500.00 at AMAZON is 482913'),
        isNull,
      );
      expect(
        BankSmsParser.parse('Get 20% cashback up to EGP 200 with your card!'),
        isNull,
      );
      expect(BankSmsParser.parse('رمز التحقق الخاص بك هو 5521'), isNull);
    });
  });
}
