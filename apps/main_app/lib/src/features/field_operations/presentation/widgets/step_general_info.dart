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
    final dayType = reportData['day_type'] as String? ?? 'working';
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

        _sectionLabel('Day Type'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.slate200),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _dayTypeChip('Working', 'working', Icons.work_outline, AppTheme.primaryGreen),
              const SizedBox(width: 4),
              _dayTypeChip('Partial', 'partial', Icons.cloudy_snowing, Colors.orange),
              const SizedBox(width: 4),
              _dayTypeChip('Non-Working', 'non_working', Icons.cancel_outlined, AppTheme.errorRed),
            ],
          ),
        ),
        if (dayType == 'partial') ...[
          const SizedBox(height: 16),
          _sectionLabel('Work Stopped At'),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                _update('stopped_at', '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00');
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
              child: Row(children: [
                const Icon(Icons.access_time, size: 18, color: AppTheme.slate500),
                const SizedBox(width: 12),
                Text(
                  reportData['stopped_at'] != null && (reportData['stopped_at'] as String).isNotEmpty
                      ? (reportData['stopped_at'] as String).substring(0, 5)
                      : 'Tap to set time',
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600,
                      color: reportData['stopped_at'] != null && (reportData['stopped_at'] as String).isNotEmpty ? AppTheme.slate900 : AppTheme.slate400),
                ),
              ]),
            ),
          ),
        ],
        if (dayType == 'non_working' || dayType == 'partial') ...[
          const SizedBox(height: 16),
          _sectionLabel('Reason'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.slate200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _nonWorkingReasons.contains(reportData['non_working_reason'])
                    ? reportData['non_working_reason']
                    : null,
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Select reason...', style: GoogleFonts.manrope(color: AppTheme.slate400)),
                ),
                isExpanded: true,
                borderRadius: BorderRadius.circular(8),
                items: _nonWorkingReasons.map((r) => DropdownMenuItem(
                  value: r,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(r, style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                  ),
                )).toList(),
                onChanged: (val) => _update('non_working_reason', val),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            SizedBox(
              width: 20, height: 20,
              child: Checkbox(
                value: reportData['credit_minimum'] == true,
                onChanged: (v) => _update('credit_minimum', v),
                activeColor: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 8),
            Text('Credit minimum 1 hour to workers who showed up',
                style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate600)),
          ]),
          const SizedBox(height: 8),
          if (reportData['credit_minimum'] == true)
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text('Workers without entries will get 1h auto-credited',
                  style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate400)),
            ),
        ],
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

  static const List<String> _nonWorkingReasons = [
    'Condiciones climáticas adversas',
    'Condición de terreno imprevista',
    'Falta de materiales',
    'Urgencia solicitada por el cliente',
    'Feriado',
    'Otro',
  ];

  Widget _dayTypeChip(String label, String value, IconData icon, Color color) {
    final isSelected = (reportData['day_type'] as String? ?? 'working') == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _update('day_type', value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withAlpha(20) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(children: [
            Icon(icon, size: 20, color: isSelected ? color : AppTheme.slate400),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.manrope(fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : AppTheme.slate500)),
          ]),
        ),
      ),
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
