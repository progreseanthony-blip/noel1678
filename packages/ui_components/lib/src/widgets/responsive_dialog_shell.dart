import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:noel_core/noel_core.dart';

import 'scroll_indicator.dart';

const double kMobileBreakpoint = 768;

bool isMobileContext(BuildContext context) {
  final size = MediaQuery.of(context).size;
  return size.width < kMobileBreakpoint;
}

/// Full-screen mobile presentation used by [showSafeDialog] when a dialog is
/// not built with [ResponsiveDialogShell]. Wraps the (nested) [Dialog] in a
/// full-screen frame and forces the inner dialog to expand so it fills the
/// screen, while keeping the content above the virtual keyboard.
class MobileDialogFrame extends StatelessWidget {
  final Widget child;

  const MobileDialogFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQueryData.fromView(View.of(context));
    final keyboard = media.viewInsets.bottom;
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboard),
          child: Theme(
            data: Theme.of(context).copyWith(
              dialogTheme: const DialogThemeData(
                insetPadding: EdgeInsets.zero,
              ),
            ),
            child: SizedBox.expand(child: child),
          ),
        ),
      ),
    );
  }
}

/// Shared responsive shell for form dialogs.
///
/// - **Desktop**: renders the classic centered card (`BackdropFilter` + [Dialog],
///   rounded corners, max width) so the current desktop look is preserved.
/// - **Mobile**: renders a full-screen page with a fixed header (title + close),
///   a scrollable body and a fixed footer. The whole frame is lifted above the
///   virtual keyboard via [AnimatedPadding], so the field being edited is never
///   covered while typing.
class ResponsiveDialogShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget body;
  final Widget? footer;
  final VoidCallback? onClose;
  final bool isEditMode;
  final Color? headerColor;
  final Color? footerColor;
  final EdgeInsets? bodyPadding;
  final double maxWidth;

  const ResponsiveDialogShell({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.icon,
    this.footer,
    this.onClose,
    this.isEditMode = false,
    this.headerColor,
    this.footerColor,
    this.bodyPadding,
    this.maxWidth = 550,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobileContext(context)) return _buildMobile(context);
    return _buildDesktop(context);
  }

  Widget _buildHeader(BuildContext context, {required bool isMobile}) {
    final bg = headerColor ?? const Color(0xFFF8FAFC);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 32,
        vertical: isMobile ? 16 : 24,
      ),
      decoration: BoxDecoration(
        color: bg,
        border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        borderRadius: isMobile
            ? null
            : const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
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
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.slate900,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppTheme.slate500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose ?? () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppTheme.slate400),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, {required bool isMobile}) {
    final bg = footerColor ?? const Color(0xFFF8FAFC);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 32,
        vertical: isMobile ? 14 : 24,
      ),
      decoration: BoxDecoration(
        color: bg,
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        borderRadius: isMobile
            ? null
            : const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: footer,
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxWidth: maxWidth),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context, isMobile: false),
              Flexible(
                child: ScrollIndicator(
                  padding: bodyPadding ?? const EdgeInsets.all(32),
                  child: body,
                ),
              ),
              if (footer != null) _buildFooter(context, isMobile: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    final media = MediaQueryData.fromView(View.of(context));
    final keyboard = media.viewInsets.bottom;
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboard),
          child: Column(
            children: [
              _buildHeader(context, isMobile: true),
              Expanded(
                child: ScrollIndicator(
                  padding: bodyPadding ?? const EdgeInsets.all(20),
                  child: body,
                ),
              ),
              if (footer != null) _buildFooter(context, isMobile: true),
            ],
          ),
        ),
      ),
    );
  }
}