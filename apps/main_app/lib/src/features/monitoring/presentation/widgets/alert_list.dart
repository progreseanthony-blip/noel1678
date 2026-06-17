import 'package:flutter/material.dart';
import 'package:noel_core/noel_core.dart';

class AlertList extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;
  const AlertList({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final a in alerts) ...[
          _buildAlert(a),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildAlert(Map<String, dynamic> alert) {
    final severity = alert['severity']?.toString() ?? 'warning';
    final isCritical = severity == 'critical';
    final bgColor = isCritical ? Colors.red.withOpacity(0.12) : Colors.orange.withOpacity(0.10);
    final borderColor = isCritical ? Colors.red.withOpacity(0.3) : Colors.orange.withOpacity(0.2);
    final iconColor = isCritical ? Colors.redAccent : Colors.orange;
    final icon = isCritical ? Icons.error_outline : Icons.warning_amber_rounded;

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
              alert['message']?.toString() ?? '',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isCritical ? Colors.red.shade200 : Colors.orange.shade200,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isCritical ? Colors.red.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isCritical ? 'CRITICAL' : 'WARNING',
              style: GoogleFonts.manrope(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: iconColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
