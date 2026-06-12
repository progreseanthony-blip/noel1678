import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:noel_core/noel_core.dart';

class StepGeneralInfo extends StatelessWidget {
  final Map<String, dynamic> reportData;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const StepGeneralInfo({
    super.key,
    required this.reportData,
    required this.onChanged,
  });

  static const List<String> weatherOptions = [
    'Sunny',
    'Partly Cloudy',
    'Cloudy',
    'Rainy',
    'Stormy',
    'Windy',
    'Foggy',
    'Snow',
  ];

  void _update(String key, dynamic value) {
    final updated = Map<String, dynamic>.from(reportData);
    updated[key] = value;
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = reportData['report_date'] as String? ?? '';
    DateTime? reportDate;
    try {
      if (dateStr.isNotEmpty) {
        reportDate = DateTime.parse(dateStr);
      }
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Report Date'),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: reportDate ?? DateTime.now(),
              firstDate: DateTime(2024),
              lastDate: DateTime.now().add(const Duration(days: 730)),
            );
            if (picked != null) {
              _update('report_date', DateFormat('yyyy-MM-dd').format(picked));
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.slate50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: AppTheme.slate500),
                const SizedBox(width: 12),
                Text(
                  dateStr.isNotEmpty
                      ? DateFormat('EEEE, MMMM d, yyyy').format(reportDate!)
                      : 'Tap to select date',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: dateStr.isNotEmpty ? AppTheme.slate900 : AppTheme.slate400,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        _sectionLabel('Weather Condition'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.slate200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: weatherOptions.contains(reportData['weather_condition'])
                  ? reportData['weather_condition']
                  : null,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Select weather...',
                    style: GoogleFonts.manrope(color: AppTheme.slate400)),
              ),
              isExpanded: true,
              borderRadius: BorderRadius.circular(8),
              items: weatherOptions.map((w) {
                return DropdownMenuItem(
                  value: w,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(_weatherIcon(w), size: 20, color: _weatherColor(w)),
                        const SizedBox(width: 10),
                        Text(w, style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) => _update('weather_condition', val),
            ),
          ),
        ),
        const SizedBox(height: 20),

        _sectionLabel('General Notes'),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: reportData['general_notes'] ?? '',
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Observations, incidents, delays...',
          ),
          onChanged: (val) => _update('general_notes', val),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.slate700,
      ),
    );
  }

  IconData _weatherIcon(String condition) {
    switch (condition) {
      case 'Sunny':
        return Icons.wb_sunny;
      case 'Partly Cloudy':
        return Icons.cloud;
      case 'Cloudy':
        return Icons.cloud_queue;
      case 'Rainy':
        return Icons.water_drop;
      case 'Stormy':
        return Icons.thunderstorm;
      case 'Windy':
        return Icons.air;
      case 'Foggy':
        return Icons.foggy;
      case 'Snow':
        return Icons.ac_unit;
      default:
        return Icons.help_outline;
    }
  }

  Color _weatherColor(String condition) {
    switch (condition) {
      case 'Sunny':
        return Colors.orange;
      case 'Partly Cloudy':
        return Colors.blueGrey;
      case 'Cloudy':
        return AppTheme.slate500;
      case 'Rainy':
        return Colors.blue;
      case 'Stormy':
        return Colors.deepPurple;
      case 'Windy':
        return Colors.teal;
      case 'Foggy':
        return AppTheme.slate400;
      case 'Snow':
        return Colors.lightBlue;
      default:
        return AppTheme.slate400;
    }
  }
}
