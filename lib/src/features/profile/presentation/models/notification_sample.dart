import 'package:mony_time/src/imports/core_imports.dart';

/// A notification-center entry. [tint] is the emoji tile background; a null tint
/// falls back to the neutral surface fill.
class AppNotification {
  const AppNotification({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.tint,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color? tint;
}

/// Placeholder notification feed for the UI phase. Plain strings — these become
/// real events once the backend exists.
abstract final class NotificationSampleData {
  static const items = <AppNotification>[
    AppNotification(
      emoji: '⚡',
      title: '3 transactions auto-logged',
      subtitle: 'Shortcut · 2m ago',
      tint: AppColors.tintMint,
    ),
    AppNotification(
      emoji: '⚠️',
      title: 'Food budget 80% used',
      subtitle: 'Today · 1:20 PM',
      tint: AppColors.tintOrange,
    ),
    AppNotification(
      emoji: '💰',
      title: 'Salary received · E£6,000',
      subtitle: 'Today · 9:00 AM',
      tint: AppColors.tintBlue,
    ),
    AppNotification(
      emoji: '☁️',
      title: 'Backup completed',
      subtitle: 'Today · 8:20 AM',
      tint: AppColors.tintMint,
    ),
    AppNotification(
      emoji: '🔔',
      title: 'Time to log yesterday',
      subtitle: 'Yesterday · 9:00 PM',
    ),
  ];
}
