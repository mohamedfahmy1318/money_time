import 'package:mony_time/src/imports/core_imports.dart';

/// A spending or earning category: an emoji glyph and a display name.
///
/// Named `AppCategory` (not `Category`) to avoid clashing with Flutter's
/// `foundation` `Category` annotation.
class AppCategory {
  const AppCategory({required this.emoji, required this.label});

  final String emoji;
  final String label;
}

/// Placeholder category content for the UI phase. Replace with real data once
/// the backend exists. Names are plain strings (like [HomeSampleData]) — they
/// become user data later, not translation keys.
abstract final class CategorySampleData {
  /// Income categories shown on the income management screen (Figma order).
  static const incomeCategories = <AppCategory>[
    AppCategory(emoji: '🤑', label: 'Allowance'),
    AppCategory(emoji: '💰', label: 'Salary'),
    AppCategory(emoji: '💵', label: 'Petty cash'),
    AppCategory(emoji: '🥇', label: 'Bonus'),
  ];

  /// Categories shown in the picker grid (Figma order).
  static const categories = <AppCategory>[
    AppCategory(emoji: '🍜', label: 'Food'),
    AppCategory(emoji: '🚕', label: 'Transport'),
    AppCategory(emoji: '🛍️', label: 'Shopping'),
    AppCategory(emoji: '🏠', label: 'Household'),
    AppCategory(emoji: '💊', label: 'Health'),
    AppCategory(emoji: '🎬', label: 'Culture'),
    AppCategory(emoji: '👕', label: 'Apparel'),
    AppCategory(emoji: '🎁', label: 'Gift'),
    AppCategory(emoji: '🐶', label: 'Pets'),
    AppCategory(emoji: '📚', label: 'Education'),
    AppCategory(emoji: '💄', label: 'Beauty'),
  ];

  /// Selectable accent colours on the add-category screen.
  static const palette = <Color>[
    Color(0xFF10B981), // emerald
    Color(0xFF2E7DEF), // blue
    Color(0xFFFBBF24), // amber
    Color(0xFFEF4444), // red
    Color(0xFF8B5CF6), // purple
    Color(0xFFEC4899), // pink
  ];

  /// Emoji options in the icon picker (Figma set first, then common extras).
  /// Twelve fills a clean 4×3 grid.
  static const icons = <String>[
    '🍜', '🍔', '☕', '🛒',
    '🎬', '🚕', '🏠', '💊',
    '👕', '🎁', '🐶', '📚',
  ];
}
