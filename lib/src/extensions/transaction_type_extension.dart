import 'package:easy_localization/easy_localization.dart';

import '../shared/enums/transaction_type.dart';

/// Presentation-layer sugar for [TransactionType] — kept out of the enum file
/// so the enum itself stays pure Dart for the domain layer.
extension TransactionTypeX on TransactionType {
  /// Localised label shown on segmented toggles and tabs.
  String get label => switch (this) {
        TransactionType.income => 'transactions.income'.tr(),
        TransactionType.expense => 'transactions.expense'.tr(),
      };

  bool get isIncome => this == TransactionType.income;
}
