import 'package:mony_time/src/features/bank_sync/domain/entities/bank.dart';

/// Data-layer representation of [Bank] with JSON mapping.
class BankModel extends Bank {
  const BankModel({
    required super.id,
    required super.name,
    required super.nameAr,
    required super.shortName,
    required super.senderIds,
    required super.brandColor,
  });

  factory BankModel.fromJson(Map<String, dynamic> json) {
    return BankModel(
      id: json['id'].toString(),
      name: (json['name'] ?? '') as String,
      nameAr: (json['name_ar'] ?? json['name'] ?? '') as String,
      shortName: (json['short_name'] ?? '') as String,
      senderIds: [
        for (final s in (json['sender_ids'] as List<dynamic>? ?? const []))
          s.toString(),
      ],
      brandColor: (json['brand_color'] as num?)?.toInt() ?? 0xFF64748B,
    );
  }
}
