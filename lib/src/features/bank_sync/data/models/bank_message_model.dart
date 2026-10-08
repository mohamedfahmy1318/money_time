import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/shared/enums/transaction_type.dart';

/// Data-layer representation of [BankMessage] with JSON mapping.
///
/// The API sends UTC instants (`…Z`); they are kept as local [DateTime]s so
/// "today / yesterday" labels match the user's clock.
class BankMessageModel extends BankMessage {
  const BankMessageModel({
    required super.id,
    required super.sender,
    required super.receivedAt,
    required super.status,
    super.bankId,
    super.body,
    super.channel,
    super.parsed,
    super.transactionId,
    super.createdAt,
  });

  factory BankMessageModel.fromJson(Map<String, dynamic> json) {
    final parsed = json['parsed'];
    return BankMessageModel(
      id: json['id'].toString(),
      bankId: json['bank_id'] as String?,
      sender: (json['sender'] ?? '') as String,
      body: json['body'] as String?,
      receivedAt: parseInstant(json['received_at']) ?? DateTime.now(),
      channel: channelFrom(json['channel']),
      status: statusFrom(json['status']),
      parsed: parsed is Map<String, dynamic> ? parsedFromJson(parsed) : null,
      transactionId: json['transaction_id'] as String?,
      createdAt: parseInstant(json['created_at']),
    );
  }

  static ParsedBankSms parsedFromJson(Map<String, dynamic> json) {
    return ParsedBankSms(
      amount: (json['amount'] as num).toDouble(),
      type: typeFrom(json['type']),
      categoryId: json['category_id'] as String?,
      categoryEmoji: json['category_emoji'] as String?,
      categoryLabel: json['category_label'] as String?,
      categoryKey: json['category_key'] as String?,
      merchant: json['merchant'] as String?,
      cardLast4: json['card_last4'] as String?,
      balance: (json['balance'] as num?)?.toDouble(),
      occurredAt: parseInstant(json['occurred_at']),
      typeDetected: (json['type_detected'] ?? true) as bool,
      currencyDetected: (json['currency_detected'] ?? true) as bool,
      isConfident: json['is_confident'] as bool?,
    );
  }

  static BankMessageStatus statusFrom(Object? value) => switch (value) {
        'imported' => BankMessageStatus.imported,
        'ignored' => BankMessageStatus.ignored,
        _ => BankMessageStatus.pending,
      };

  static String statusToWire(BankMessageStatus status) => status.name;

  static BankMessageChannel channelFrom(Object? value) => switch (value) {
        'android_sms' => BankMessageChannel.androidSms,
        'history_scan' => BankMessageChannel.historyScan,
        'shortcut' => BankMessageChannel.shortcut,
        _ => BankMessageChannel.paste,
      };

  static TransactionType typeFrom(Object? value) =>
      value == 'income' ? TransactionType.income : TransactionType.expense;

  static String typeToWire(TransactionType type) =>
      type == TransactionType.income ? 'income' : 'expense';

  static DateTime? parseInstant(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;

  /// Requests need an explicit offset; UTC with `Z` always qualifies.
  static String instantToWire(DateTime value) =>
      value.toUtc().toIso8601String();
}
