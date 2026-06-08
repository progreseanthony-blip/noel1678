import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlertBanner extends StatelessWidget {
  final String message;
  final String severity;

  const AlertBanner({
    super.key,
    required this.message,
    required this.severity,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = severity == 'critical';
    final bgColor = isCritical
        ? Colors.red.withOpacity(0.1)
        : Colors.orange.withOpacity(0.1);
    final borderColor = isCritical
        ? Colors.red.withOpacity(0.3)
        : Colors.orange.withOpacity(0.3);
    final icon = isCritical ? Icons.error_outline : Icons.warning_amber_rounded;
    final iconColor = isCritical ? Colors.redAccent : Colors.orange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.manrope(
                color: iconColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
