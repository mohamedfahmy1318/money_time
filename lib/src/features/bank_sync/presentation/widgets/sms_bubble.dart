import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/bank_sync/presentation/helpers/bank_display.dart';

/// A bank SMS drawn as a received chat bubble. Arabic messages lay out
/// right-to-left whatever the app language; [maxLines] collapses it to a
/// preview. A `null` [body] (purged after 90 days) shows a muted note.
class SmsBubble extends StatelessWidget {
  const SmsBubble({super.key, required this.body, this.maxLines});

  final String? body;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final text = body;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: context.colors.outlineVariant),
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(4.r),
          topEnd: Radius.circular(16.r),
          bottomStart: Radius.circular(16.r),
          bottomEnd: Radius.circular(16.r),
        ),
      ),
      child: text == null
          ? Text(
              'bank_sync.body_expired'.tr(),
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
                fontSize: 12.sp,
              ),
            )
          : Text(
              text,
              maxLines: maxLines,
              overflow: maxLines == null ? null : TextOverflow.ellipsis,
              textDirection: smsDirection(text),
              textAlign: TextAlign.start,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.onSurface,
                fontSize: 12.sp,
                height: 1.45,
              ),
            ),
    );
  }
}
