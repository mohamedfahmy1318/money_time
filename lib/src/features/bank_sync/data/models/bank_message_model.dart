import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/shared/enums/transaction_type.dart';

/// Data-layer representation of [BankMessage] with JSON mapping.
class BankMessageModel extends BankMessage {
  const BankMessageModel({
    required super.id,
    required super.bankId,
    required super.sender,
    required super.body,
    required super.receivedAt,
    required super.status,
    super.parsed,
  });

  factory BankMessageModel.fromEntity(BankMessage message) => BankMessageModel(
        id: message.id,
        bankId: message.bankId,
        sender: message.sender,
        body: message.body,
        receivedAt: message.receivedAt,
        status: message.status,
        parsed: message.parsed,
      );

  factory BankMessageModel.fromJson(Map<String, dynamic> json) {
    final data = (json['message'] ?? json) as Map<String, dynamic>;
    final parsed = data['parsed'] as Map<String, dynamic>?;
    return BankMessageModel(
      id: data['id'].toString(),
      bankId: (data['bank_id'] ?? '') as String,
      sender: (data['sender'] ?? '') as String,
      body: (data['body'] ?? '') as String,
      receivedAt: DateTime.parse(data['received_at'] as String),
      status: BankMessageStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => BankMessageStatus.pending,
      ),
      parsed: parsed == null ? null : _parsedFromJson(parsed),
    );
  }

  BankMessageModel withStatus(BankMessageStatus status) =>
      BankMessageModel.fromEntity(copyWith(status: status));

  Map<String, dynamic> toJson() => {
        'id': id,
        'bank_id': bankId,
        'sender': sender,
        'body': body,
        'received_at': receivedAt.toIso8601String(),
        'status': status.name,
        'parsed': parsed == null ? null : _parsedToJson(parsed!),
      };

  static ParsedBankSms _parsedFromJson(Map<String, dynamic> json) {
    return ParsedBankSms(
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      categoryEmoji: (json['category_emoji'] ?? '') as String,
      categoryLabel: (json['category_label'] ?? '') as String,
      merchant: json['merchant'] as String?,
      cardLast4: json['card_last4'] as String?,
      balance: (json['balance'] as num?)?.toDouble(),
      occurredAt: DateTime.tryParse((json['occurred_at'] ?? '') as String),
      typeDetected: (json['type_detected'] ?? true) as bool,
      currencyDetected: (json['currency_detected'] ?? true) as bool,
    );
  }

  static Map<String, dynamic> _parsedToJson(ParsedBankSms p) => {
        'amount': p.amount,
        'type': p.type == TransactionType.income ? 'income' : 'expense',
        'category_emoji': p.categoryEmoji,
        'category_label': p.categoryLabel,
        'merchant': p.merchant,
        'card_last4': p.cardLast4,
        'balance': p.balance,
        'occurred_at': p.occurredAt?.toIso8601String(),
        'type_detected': p.typeDetected,
        'currency_detected': p.currencyDetected,
      };
}
