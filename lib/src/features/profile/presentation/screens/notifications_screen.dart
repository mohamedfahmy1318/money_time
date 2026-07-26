import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/profile/presentation/models/notification_sample.dart';

/// Notifications: the recent activity feed with a Clear action. Seeded from
/// sample data for the UI phase; Clear empties the local list.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<AppNotification> _items = List.of(NotificationSampleData.items);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'notifications.title'.tr(),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: () => setState(_items.clear),
              child: Text(
                'notifications.clear'.tr(),
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _items.isEmpty
            ? _EmptyState()
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 2.h, 20.w, 24.h),
                child: AppSoftCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < _items.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: context.colors.outlineVariant,
                          ),
                        _NotificationRow(item: _items[i]),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 38.r,
            height: 38.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: item.tint ?? context.colors.surface,
              borderRadius: BorderRadius.circular(13.r),
            ),
            child: Text(item.emoji, style: TextStyle(fontSize: 15.sp)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: context.colors.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 44.sp,
            color: context.colors.onSurfaceVariant,
          ),
          SizedBox(height: 12.h),
          Text(
            'notifications.empty'.tr(),
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }
}
