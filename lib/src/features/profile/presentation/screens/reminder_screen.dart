import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/setup/presentation/widgets/pill_toggle.dart';

/// Reminder: the daily-reminder toggle, a reminder time, and the weekdays it
/// fires on. Local state for the UI phase — no scheduling is wired yet.
class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  static const _days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  bool _enabled = true;
  final Set<int> _selectedDays = {0, 1, 2, 3, 4};

  void _comingSoon() =>
      showToast(context, message: 'profile.coming_soon'.tr(), status: 'info');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'reminder.title'.tr()),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 2.h, 20.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoCard(),
              SizedBox(height: 18.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'reminder.daily'.tr(),
                        style: context.textTheme.titleSmall?.copyWith(
                          color: context.colors.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                        ),
                      ),
                    ),
                    PillToggle(
                      value: _enabled,
                      onChanged: (v) => setState(() => _enabled = v),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              _TimeCard(onTap: _comingSoon),
              SizedBox(height: 14.h),
              Row(
                children: [
                  for (var i = 0; i < _days.length; i++) ...[
                    if (i > 0) SizedBox(width: 6.w),
                    Expanded(
                      child: _DayChip(
                        letter: _days[i],
                        selected: _selectedDays.contains(i),
                        onTap: () => setState(() {
                          _selectedDays.contains(i)
                              ? _selectedDays.remove(i)
                              : _selectedDays.add(i);
                        }),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppSoftCard(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.colors.primary, width: 2),
            ),
            child: Icon(
              Icons.notifications_outlined,
              size: 18.sp,
              color: context.colors.primary,
            ),
          ),
          SizedBox(width: 13.w),
          Expanded(
            child: Text(
              'reminder.info'.tr(),
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontSize: 12.3.sp,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppSoftCard(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '09:00',
              style: context.textTheme.displaySmall?.copyWith(
                color: context.colors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 36.sp,
                letterSpacing: -0.72,
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              'PM',
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: 17.4.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.letter,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? context.colors.primaryContainer
              : context.colors.surface,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
          letter,
          style: context.textTheme.labelSmall?.copyWith(
            color: selected
                ? context.colors.primary
                : context.colors.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 11.sp,
          ),
        ),
      ),
    );
  }
}
