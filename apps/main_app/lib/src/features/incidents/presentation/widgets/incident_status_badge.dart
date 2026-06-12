import 'package:flutter/material.dart';
import 'package:noel_core/noel_core.dart';

class IncidentStatusBadge extends StatelessWidget {
  final String status;
  const IncidentStatusBadge({super.key, required this.status});

  Color _color() {
    switch (status) {
      case 'open': return AppTheme.errorRed;
      case 'in_progress': return const Color(0xFF3B82F6);
      case 'resolved': return AppTheme.accentCyan;
      case 'closed': return AppTheme.primaryGreen;
      default: return AppTheme.slate400;
    }
  }

  String _label() {
    switch (status) {
      case 'open': return 'Open';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      case 'closed': return 'Closed';
      default: return status;
    }
  }

  IconData _icon() {
    switch (status) {
      case 'open': return Icons.error_outline;
      case 'in_progress': return Icons.engineering;
      case 'resolved': return Icons.check_circle_outline;
      case 'closed': return Icons.check_circle;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            _label(),
            style: GoogleFonts.manrope(
              fontSize: 11, fontWeight: FontWeight.w700, color: color,
            ),
          ),
        ],
      ),
    );
  }
}
