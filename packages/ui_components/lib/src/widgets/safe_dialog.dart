import 'package:flutter/material.dart';
import 'package:noel_core/noel_core.dart';

import 'scroll_indicator.dart';

Future<T?> showSafeDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = false,
  Color? barrierColor,
  bool useSafeArea = true,
  RouteSettings? routeSettings,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.5),
    useSafeArea: useSafeArea,
    routeSettings: routeSettings,
    builder: builder,
  );
}

class SafeDialogBody extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget body;
  final String? cancelLabel;
  final String? confirmLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final bool isLoading;
  final bool isEditMode;
  final Color? headerColor;
  final Color? footerColor;
  final EdgeInsets? bodyPadding;

  const SafeDialogBody({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.icon,
    this.cancelLabel,
    this.confirmLabel,
    this.onCancel,
    this.onConfirm,
    this.isLoading = false,
    this.isEditMode = false,
    this.headerColor,
    this.footerColor,
    this.bodyPadding,
  });

  static const double defaultMaxWidth = 550;
  static const EdgeInsets defaultInsetPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 24);
  static const double defaultBorderRadius = 16;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: defaultInsetPadding,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: defaultMaxWidth),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(defaultBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Builder(
          builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(ctx),
              Flexible(
                child: ScrollIndicator(
                  padding: bodyPadding ?? const EdgeInsets.all(32),
                  child: body,
                ),
              ),
              if (onCancel != null || onConfirm != null) _buildFooter(ctx),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext ctx) {
    final bg = headerColor ?? const Color(0xFFF8FAFC);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: bg,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9)),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isEditMode ? Icons.edit_outlined : icon!,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.slate900,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppTheme.slate500,
                      ),
                    ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: onCancel ?? () => Navigator.pop(ctx),
            icon: const Icon(Icons.close, color: AppTheme.slate400),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext ctx) {
    final bg = footerColor ?? const Color(0xFFF8FAFC);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: bg,
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (cancelLabel != null)
            TextButton(
              onPressed: isLoading ? null : (onCancel ?? () => Navigator.pop(ctx)),
              child: Text(
                cancelLabel!,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate700,
                ),
              ),
            ),
          if (confirmLabel != null) ...[
            if (cancelLabel != null) const SizedBox(width: 16),
            ElevatedButton(
              onPressed: isLoading ? null : onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      confirmLabel!,
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class RequiredLabel extends StatelessWidget {
  final String label;
  final TextStyle? style;

  const RequiredLabel({super.key, required this.label, this.style});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: style ??
            GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate700,
            ),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(color: AppTheme.errorRed, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
