import 'package:easy_localization/easy_localization.dart';

/// Whether a transaction (or a category) adds money (income) or removes it
/// (expense). Shared across the transactions and categories features.
enum TransactionType {
  income,
  expense;

  /// Localised label shown on the segmented toggle.
  String get label => switch (this) {
        TransactionType.income => 'transactions.income'.tr(),
        TransactionType.expense => 'transactions.expense'.tr(),
      };
}
