import 'package:flutter/material.dart';
import 'package:noel_core/noel_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class InspectionCard extends StatelessWidget {
  final Map<String, dynamic> inspection;
  final String projectId;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  const InspectionCard({
    super.key,
    required this.inspection,
    required this.projectId,
    required this.dateFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = inspection['inspection_date'] as String? ?? '';
    final status = inspection['status'] as String? ?? 'draft';
    final method = inspection['method'] as String? ?? 'drone';
    final inspectorName =
        (inspection['profiles'] as Map?)?['name'] as String? ?? 'Unknown';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: status == 'reconciled'
                  ? AppTheme.primaryGreen.withOpacity(0.3)
                  : const Color(0xFF334155),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    method == 'drone'
                        ? Icons.flight
                        : method == 'gps'
                            ? Icons.satellite_alt
                            : method == 'total_station'
                                ? Icons.camera
                                : Icons.science,
                    color: _statusColor(status),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(DateTime.tryParse(date) ?? DateTime.now()),
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$method · $inspectorName',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: AppTheme.slate400,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(status),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppTheme.slate500, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'reconciled':
        return AppTheme.primaryGreen;
      case 'approved':
        return Colors.blue;
      case 'submitted':
        return Colors.orange;
      default:
        return AppTheme.slate400;
    }
  }

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);
    final label = status.replaceAll('_', ' ').toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
