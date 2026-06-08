import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';

class ServiceProgressTable extends StatelessWidget {
  final List<Map<String, dynamic>> services;

  const ServiceProgressTable({super.key, required this.services});

  String _fmt(dynamic val, {int decimals = 1}) {
    if (val == null) return '-';
    final d = (val as num).toDouble();
    if (d == 0 && decimals > 0) return '0';
    return d.toStringAsFixed(decimals);
  }

  String _fmtCurrency(dynamic val) {
    if (val == null) return '-';
    final d = (val as num).toDouble();
    return '\$${d.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  Color _progressColor(double pct) {
    if (pct >= 80) return AppTheme.primaryGreen;
    if (pct >= 40) return Colors.orange;
    return Colors.redAccent;
  }

  Color _cpiColor(double cpi) {
    if (cpi >= 0.95) return AppTheme.primaryGreen;
    if (cpi >= 0.85) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Center(
          child: Text(
            'No service data available. Start by creating daily reports with production data.',
            style: GoogleFonts.manrope(color: AppTheme.slate500, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFF0F172A)),
            dataRowColor: WidgetStateProperty.resolveWith((_) => Colors.transparent),
            columnSpacing: 24,
            columns: [
              _col('Service'),
              _col('Unit'),
              _col('Plan'),
              _col('Real'),
              _col('%'),
              _col('Perf'),
              _col('CPI'),
              _col('Budget'),
              _col('Actual'),
            ],
            rows: services.map((s) {
              final progress = (s['progress'] as num?)?.toDouble() ?? 0;
              final perf = (s['performance'] as num?)?.toDouble() ?? 0;
              final pc = (s['planned_cost'] as num?)?.toDouble() ?? 0;
              final ac = (s['actual_cost'] as num?)?.toDouble() ?? 0;
              final ev = (s['earned_value'] as num?)?.toDouble() ?? 0;
              final cpi = ac > 0 ? ev / ac : 1.0;

              return DataRow(cells: [
                DataCell(Text(
                  s['name'] ?? '',
                  style: GoogleFonts.manrope(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                )),
                DataCell(Text(
                  s['unit'] ?? '',
                  style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 12),
                )),
                DataCell(Text(
                  _fmt(s['planned_quantity']),
                  style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 12),
                )),
                DataCell(Text(
                  _fmt(s['actual_quantity']),
                  style: GoogleFonts.manrope(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                )),
                DataCell(
                  _buildProgressCell(progress, _progressColor(progress)),
                ),
                DataCell(Text(
                  '$perf ${s['performance_unit'] ?? ''}',
                  style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 11),
                )),
                DataCell(Text(
                  cpi.toStringAsFixed(2),
                  style: GoogleFonts.manrope(
                    color: _cpiColor(cpi),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                )),
                DataCell(Text(
                  _fmtCurrency(pc),
                  style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 12),
                )),
                DataCell(Text(
                  _fmtCurrency(ac),
                  style: GoogleFonts.manrope(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  DataColumn _col(String label) {
    return DataColumn(
      label: Text(
        label,
        style: GoogleFonts.manrope(
          color: AppTheme.slate500,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProgressCell(double pct, Color color) {
    return SizedBox(
      width: 100,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0.0, 1.0),
                backgroundColor: const Color(0xFF0F172A),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${pct.toStringAsFixed(0)}%',
            style: GoogleFonts.manrope(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
