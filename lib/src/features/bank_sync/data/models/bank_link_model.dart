import 'package:mony_time/src/features/bank_sync/domain/entities/bank_link.dart';

/// Data-layer representation of [BankLink] with JSON mapping.
class BankLinkModel extends BankLink {
  const BankLinkModel({
    super.isConnected,
    super.method,
    super.bankIds,
    super.mode,
    super.connectedAt,
  });

  factory BankLinkModel.fromEntity(BankLink link) => BankLinkModel(
        isConnected: link.isConnected,
        method: link.method,
        bankIds: link.bankIds,
        mode: link.mode,
        connectedAt: link.connectedAt,
      );

  factory BankLinkModel.fromJson(Map<String, dynamic> json) {
    final data = (json['link'] ?? json) as Map<String, dynamic>;
    return BankLinkModel(
      isConnected: (data['is_connected'] ?? false) as bool,
      method: switch (data['method']) {
        'shortcuts' => BankLinkMethod.shortcuts,
        'sms' => BankLinkMethod.sms,
        _ => null,
      },
      bankIds: [
        for (final id in (data['bank_ids'] as List<dynamic>? ?? const []))
          id.toString(),
      ],
      mode: data['mode'] == 'automatic'
          ? ImportMode.automatic
          : ImportMode.review,
      connectedAt: DateTime.tryParse((data['connected_at'] ?? '') as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'is_connected': isConnected,
        'method': method?.name,
        'bank_ids': bankIds,
        'mode': mode.name,
        'connected_at': connectedAt?.toIso8601String(),
      };
}
