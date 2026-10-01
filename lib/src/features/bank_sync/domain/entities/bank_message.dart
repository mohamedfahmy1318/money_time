import 'package:equatable/equatable.dart';

import 'package:mony_time/src/shared/enums/transaction_type.dart';

/// Where a message sits in the review flow.
enum BankMessageStatus { pending, imported, ignored }

/// The transaction details read out of a bank SMS.
class ParsedBankSms extends Equatable {
  const ParsedBankSms({
    required this.amount,
    required this.type,
    required this.categoryEmoji,
    required this.categoryLabel,
    this.merchant,
    this.cardLast4,
    this.balance,
    this.occurredAt,
    this.typeDetected = true,
    this.currencyDetected = true,
  });

  final double amount;
  final TransactionType type;
  final String categoryEmoji;
  final String categoryLabel;
  final String? merchant;
  final String? cardLast4;

  /// Balance / available limit reported after the transaction.
  final double? balance;

  /// Date written in the message, when it has one.
  final DateTime? occurredAt;

  /// False when the text gave no money-in / money-out cue and the type is a
  /// guess.
  final bool typeDetected;

  /// False when the amount was found without a currency next to it.
  final bool currencyDetected;

  /// Every field was read with certainty — safe to import without review.
  bool get isConfident => typeDetected && currencyDetected;

  @override
  List<Object?> get props => [
        amount,
        type,
        categoryEmoji,
        categoryLabel,
        merchant,
        cardLast4,
        balance,
        occurredAt,
        typeDetected,
        currencyDetected,
      ];
}

/// One SMS received from a linked bank.
class BankMessage extends Equatable {
  const BankMessage({
    required this.id,
    required this.bankId,
    required this.sender,
    required this.body,
    required this.receivedAt,
    required this.status,
    this.parsed,
  });

  final String id;
  final String bankId;
  final String sender;
  final String body;
  final DateTime receivedAt;
  final BankMessageStatus status;

  /// `null` when the message is not a transaction (OTP, promo …).
  final ParsedBankSms? parsed;

  bool get isTransaction => parsed != null;
  bool get needsAttention => parsed != null && !parsed!.isConfident;

  BankMessage copyWith({BankMessageStatus? status}) => BankMessage(
        id: id,
        bankId: bankId,
        sender: sender,
        body: body,
        receivedAt: receivedAt,
        status: status ?? this.status,
        parsed: parsed,
      );

  @override
  List<Object?> get props =>
      [id, bankId, sender, body, receivedAt, status, parsed];
}
