import 'package:flutter/material.dart';
import 'package:noel_core/noel_core.dart';

class IncidentPriorityBadge extends StatelessWidget {
  final String priority;
  const IncidentPriorityBadge({super.key, required this.priority});

  Color _color() {
    switch (priority) {
      case 'low': return AppTheme.slate400;
      case 'medium': return const Color(0xFFEAB308);
      case 'high': return const Color(0xFFF97316);
      case 'critical': return AppTheme.errorRed;
      default: return AppTheme.slate400;
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
      child: Text(
        priority.toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 10, fontWeight: FontWeight.w800,
          color: color, letterSpacing: 0.5,
        ),
      ),
    );
  }
}
