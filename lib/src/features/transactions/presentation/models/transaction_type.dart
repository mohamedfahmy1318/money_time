import 'package:mony_time/src/imports/core_imports.dart';

/// Whether a transaction adds money (income) or removes it (expense).
enum TransactionType {
  income,
  expense;

  /// Localised label shown on the segmented toggle.
  String get label => switch (this) {
        TransactionType.income => 'transactions.income'.tr(),
        TransactionType.expense => 'transactions.expense'.tr(),
      };
}
