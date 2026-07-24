import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// Shows the "Add a note" modal over the current screen and resolves to the
/// entered text, or `null` if the user dismissed it without saving.
Future<String?> showNoteSheet(BuildContext context, {String? initial}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _NoteSheet(initial: initial),
  );
}

/// The floating white card that hosts the note text field and its save button.
class _NoteSheet extends StatefulWidget {
  const _NoteSheet({this.initial});

  final String? initial;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Float 16 from every edge; lift above the keyboard when it is open.
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        bottom: 16.h + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLowest,
          borderRadius: AppBorders.xxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'transactions.add_note'.tr(),
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 17.sp,
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              height: 90.h,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                border: Border.all(color: context.colors.outlineVariant),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                textCapitalization: TextCapitalization.sentences,
                cursorColor: context.colors.primary,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurface,
                  fontSize: 13.sp,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  // The wrapping container owns the border; kill the themed
                  // input borders (incl. the green focus ring) in every state.
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hintText: 'transactions.note_hint'.tr(),
                  hintStyle: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            AppGradientButton(
              label: 'transactions.save_note'.tr(),
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
