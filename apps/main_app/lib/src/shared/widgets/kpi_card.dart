import 'package:flutter/material.dart';
import 'package:noel_core/noel_core.dart';

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double? progress;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? valueColor;
  final Color? titleColor;
  final Color? subtitleColor;
  final EdgeInsetsGeometry? padding;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.progress,
    this.backgroundColor,
    this.borderColor,
    this.valueColor,
    this.titleColor,
    this.subtitleColor,
    this.padding,
  });

  factory KpiCard.dark({
    Key? key,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    double? progress,
  }) {
    return KpiCard(
      key: key,
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      color: color,
      progress: progress,
      backgroundColor: const Color(0xFF1E293B),
      borderColor: color.withOpacity(0.3),
      valueColor: Colors.white,
      titleColor: AppTheme.slate400,
      subtitleColor: AppTheme.slate500,
    );
  }

  factory KpiCard.light({
    Key? key,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    double? progress,
    EdgeInsetsGeometry? padding,
  }) {
    return KpiCard(
      key: key,
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      color: color,
      progress: progress,
      padding: padding,
      backgroundColor: Colors.white,
      borderColor: AppTheme.slate200,
      valueColor: AppTheme.slate900,
      titleColor: AppTheme.slate500,
      subtitleColor: AppTheme.slate400,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? const Color(0xFF1E293B);
    final border = borderColor ?? color.withOpacity(0.3);
    final valColor = valueColor ?? Colors.white;
    final tColor = titleColor ?? AppTheme.slate400;
    final subColor = subtitleColor ?? AppTheme.slate500;
    final pad = padding ?? const EdgeInsets.all(20);

    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.manrope(
                    color: tColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.manrope(
              color: valColor,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.manrope(
              color: subColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                backgroundColor: bg == Colors.white
                    ? AppTheme.slate200
                    : const Color(0xFF0F172A),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
