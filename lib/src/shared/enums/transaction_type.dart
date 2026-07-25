/// Whether a transaction (or a category) adds money (income) or removes it
/// (expense). Shared across the transactions and categories features.
///
/// Pure Dart on purpose — domain entities reference this enum, so it must not
/// drag Flutter/easy_localization in. The localised `label` getter lives in
/// `extensions/transaction_type_extension.dart`.
enum TransactionType { income, expense }
