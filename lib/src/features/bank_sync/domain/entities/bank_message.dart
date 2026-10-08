import 'package:equatable/equatable.dart';

import 'package:mony_time/src/shared/enums/transaction_type.dart';

/// Where a message sits in the review flow — the inbox tabs.
enum BankMessageStatus { pending, imported, ignored }

/// How a message reached the server.
enum BankMessageChannel { androidSms, historyScan, shortcut, paste }

/// The transaction details read out of a bank SMS — by the server for stored
/// messages, or on-device for the paste sheet's live preview.
class ParsedBankSms extends Equatable {
  const ParsedBankSms({
    required this.amount,
    required this.type,
    this.categoryId,
    this.categoryEmoji,
    this.categoryLabel,
    this.categoryKey,
    this.merchant,
    this.cardLast4,
    this.balance,
    this.occurredAt,
    this.typeDetected = true,
    this.currencyDetected = true,
    bool? isConfident,
  }) : isConfident = isConfident ?? (typeDetected && currencyDetected);

  /// Always positive — [type] gives the direction.
  final double amount;
  final TransactionType type;

  /// The user's category the server matched (null for the local preview).
  final String? categoryId;
  final String? categoryEmoji;
  final String? categoryLabel;

  /// Parser system key (`groceries`, `salary`, `other_expense` …).
  final String? categoryKey;
  final String? merchant;
  final String? cardLast4;

  /// Balance / available limit reported after the transaction.
  final double? balance;

  /// When the money moved.
  final DateTime? occurredAt;

  /// False when the text gave no money-in / money-out cue and the type is a
  /// guess.
  final bool typeDetected;

  /// False when the amount was found without a currency next to it.
  final bool currencyDetected;

  /// Every field was read with certainty — safe to add without a second look.
  /// False drives the "Check" badge.
  final bool isConfident;

  @override
  List<Object?> get props => [
        amount,
        type,
        categoryId,
        categoryEmoji,
        categoryLabel,
        categoryKey,
        merchant,
        cardLast4,
        balance,
        occurredAt,
        typeDetected,
        currencyDetected,
        isConfident,
      ];
}

/// One SMS received from a linked bank.
class BankMessage extends Equatable {
  const BankMessage({
    required this.id,
    required this.sender,
    required this.receivedAt,
    required this.status,
    this.bankId,
    this.body,
    this.channel = BankMessageChannel.paste,
    this.parsed,
    this.transactionId,
    this.createdAt,
  });

  final String id;
  final String? bankId;
  final String sender;

  /// The SMS text; `null` once the 90-day retention purged it.
  final String? body;
  final DateTime receivedAt;
  final BankMessageChannel channel;
  final BankMessageStatus status;

  /// `null` when the message is not a transaction (OTP, promotion …).
  final ParsedBankSms? parsed;

  /// The transaction it became, once imported.
  final String? transactionId;
  final DateTime? createdAt;

  bool get isTransaction => parsed != null;
  bool get needsAttention => parsed != null && !parsed!.isConfident;

  /// When the money moved: the date in the SMS, else when it arrived.
  DateTime get occurredAt => parsed?.occurredAt ?? receivedAt;

  BankMessage copyWith({BankMessageStatus? status}) => BankMessage(
        id: id,
        bankId: bankId,
        sender: sender,
        body: body,
        receivedAt: receivedAt,
        channel: channel,
        status: status ?? this.status,
        parsed: parsed,
        transactionId: transactionId,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [
        id,
        bankId,
        sender,
        body,
        receivedAt,
        channel,
        status,
        parsed,
        transactionId,
        createdAt,
      ];
}
