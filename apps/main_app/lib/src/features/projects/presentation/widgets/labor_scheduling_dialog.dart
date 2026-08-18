import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:noel_core/noel_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:noel_ui_components/noel_ui_components.dart';

class LaborSchedulingDialog extends StatefulWidget {
  final String projectLaborId;
  final String roleName;
  final String serviceName;

  const LaborSchedulingDialog({
    super.key,
    required this.projectLaborId,
    required this.roleName,
    this.serviceName = '',
  });

  @override
  State<LaborSchedulingDialog> createState() => _LaborSchedulingDialogState();
}

class _LaborSchedulingDialogState extends State<LaborSchedulingDialog> {
  bool _isLoading = true;
  bool _isSaving = false;
  DateTime? _startDate;
  DateTime? _endDate;
  double? _stipulatedDays;
  Map<String, double> _nonWorkingDays = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  DateTime _calculateEndDate(DateTime start, double duration) {
    DateTime current = start;
    double remaining = duration;
    
    while (remaining > 0) {
      double contribution = getWorkingDayContribution(current, _nonWorkingDays);
      
      if (contribution <= 0) {
        current = current.add(const Duration(days: 1));
        continue;
      }
      
      if (remaining <= contribution) {
        remaining = 0;
      } else {
        remaining -= contribution;
        current = current.add(const Duration(days: 1));
      }
    }
    return current;
  }

  Future<void> _loadData() async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('project_labor')
          .select('project_id, start_date, end_date, quote_service_labors(quote_services(quote_service_estimations(total_working_days, start_date, end_date)))')
          .eq('id', widget.projectLaborId)
          .maybeSingle();

      if (data == null) return;

      final projectId = data['project_id'];

      DateTime? projectStart;
      try {
        final pRes = await supabase
            .from('projects')
            .select('start_date')
            .eq('id', projectId)
            .maybeSingle();
        projectStart = pRes?['start_date'] != null
            ? DateTime.tryParse(pRes['start_date'].toString())
            : null;
      } catch (_) {}

      // Load non-working days
      try {
        final nwDays = await supabase
            .from('project_non_working_days')
            .select('date, partial_ratio')
            .eq('project_id', projectId);
        _nonWorkingDays.clear();
        for (final nw in nwDays ?? []) {
          final dateStr = nw['date'] as String?;
          final ratio = (nw['partial_ratio'] as num?)?.toDouble() ?? 0;
          if (dateStr != null) _nonWorkingDays[dateStr.split('T')[0]] = ratio;
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _startDate = data['start_date'] != null ? DateTime.tryParse(data['start_date']) : null;
          _endDate = data['end_date'] != null ? DateTime.tryParse(data['end_date']) : null;

          final qsl = data['quote_service_labors'];
          dynamic qs;
          if (qsl is List && qsl.isNotEmpty) {
            qs = qsl[0]['quote_services'];
          } else if (qsl is Map) {
            qs = qsl['quote_services'];
          }
          if (qs != null) {
            final est = qs is List && qs.isNotEmpty ? qs[0] : (qs is Map ? qs : null);
            if (est != null) {
              final days = est['quote_service_estimations'];
              dynamic d;
              dynamic estStart, estEnd;
              if (days is List && days.isNotEmpty) {
                d = days[0]['total_working_days'];
                estStart = days[0]['start_date'];
                estEnd = days[0]['end_date'];
              } else if (days is Map) {
                d = days['total_working_days'];
                estStart = days['start_date'];
                estEnd = days['end_date'];
              }
              if (d != null) {
                _stipulatedDays = (d as num).toDouble();
              }
              if (_startDate == null && estStart != null) {
                _startDate = DateTime.tryParse(estStart.toString());
              }
              if (_endDate == null && estEnd != null) {
                _endDate = DateTime.tryParse(estEnd.toString());
              }
            }
          }
          if (_startDate == null) {
            _startDate = projectStart ?? DateTime.now();
          }
          if (_endDate == null && _stipulatedDays != null && _stipulatedDays! > 0) {
            _endDate = _calculateEndDate(_startDate!, _stipulatedDays!);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start date.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('project_labor').update({
        'start_date': _startDate!.toIso8601String().split('T')[0],
        'end_date': _endDate?.toIso8601String().split('T')[0],
      }).eq('id', widget.projectLaborId);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving dates: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_stipulatedDays != null && _stipulatedDays! > 0) {
          _endDate = _calculateEndDate(picked, _stipulatedDays!);
        }
      } else {
        _endDate = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat fmt = DateFormat('MMM dd, yyyy');

    return ResponsiveDialogShell(
      title: 'Modify Dates',
      subtitle: widget.roleName,
      icon: Icons.calendar_month,
      maxWidth: 480,
      bodyPadding: const EdgeInsets.all(24),
      onClose: () => Navigator.of(context).pop(),
      body: _isLoading
          ? const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.serviceName.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Service: ${widget.serviceName}',
                      style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen),
                    ),
                  ),
                ],
                          if (_stipulatedDays != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                'Stipulated duration: ${_stipulatedDays!.toStringAsFixed(1)} working days',
                                style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500, fontStyle: FontStyle.italic),
                              ),
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateField('Start Date', _startDate, () => _pickDate(true), fmt),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDateField('End Date', _endDate, () => _pickDate(false), fmt),
                              ),
                            ],
                          ),
                ],
              ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Spacer(),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate700),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _isSaving ? null : _save,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: _isSaving ? AppTheme.slate400 : AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSaving)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    else
                      const Icon(Icons.save, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _isSaving ? 'Saving...' : 'Save Dates',
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap, DateFormat fmt) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.slate50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: date != null ? AppTheme.primaryGreen : AppTheme.slate200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate400, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(
              date != null ? fmt.format(date) : 'Tap to select',
              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: date != null ? AppTheme.slate900 : AppTheme.slate400),
            ),
          ],
        ),
      ),
    );
  }
}
