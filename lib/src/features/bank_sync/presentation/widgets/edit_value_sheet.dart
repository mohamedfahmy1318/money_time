import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// A floating one-field editor (amount, merchant …). Resolves to the trimmed
/// text, or `null` when dismissed.
Future<String?> showEditValueSheet(
  BuildContext context, {
  required String title,
  String? initial,
  String? hint,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _EditValueSheet(
      title: title,
      initial: initial,
      hint: hint,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
    ),
  );
}

class _EditValueSheet extends StatefulWidget {
  const _EditValueSheet({
    required this.title,
    this.initial,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
  });

  final String title;
  final String? initial;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<_EditValueSheet> createState() => _EditValueSheetState();
}

class _EditValueSheetState extends State<_EditValueSheet> {
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
              widget.title,
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 17.sp,
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              style: context.textTheme.bodyLarge
                  ?.copyWith(color: context.colors.onSurface),
              decoration: InputDecoration(hintText: widget.hint),
            ),
            SizedBox(height: 14.h),
            AppGradientButton(label: 'bank_sync.done'.tr(), onPressed: _save),
          ],
        ),
      ),
    );
  }
}
