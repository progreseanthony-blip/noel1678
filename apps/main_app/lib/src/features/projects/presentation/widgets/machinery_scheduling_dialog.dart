import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MachinerySchedulingDialog extends StatefulWidget {
  final String projectMachineryId;
  final String machineryName;
  final int expectedQuantity;

  const MachinerySchedulingDialog({
    super.key,
    required this.projectMachineryId,
    required this.machineryName,
    required this.expectedQuantity,
  });

  @override
  State<MachinerySchedulingDialog> createState() => _MachinerySchedulingDialogState();
}

class _MachinerySchedulingDialogState extends State<MachinerySchedulingDialog> {
  bool _isLoading = true;
  double? _stipulatedDays;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  DateTime _calculateEndDate(DateTime start, double duration) {
    DateTime current = start;
    double remaining = duration;
    
    while (remaining > 0) {
      double contribution = 0;
      if (current.weekday >= 1 && current.weekday <= 5) {
        contribution = 1.0;
      } else if (current.weekday == 6) {
        contribution = 0.5;
      }
      
      if (remaining <= contribution) {
        remaining = 0;
      } else {
        remaining -= contribution;
        current = current.add(const Duration(days: 1));
        if (current.weekday == 7) {
          current = current.add(const Duration(days: 1));
        }
      }
    }
    return current;
  }

  Future<void> _loadData() async {
    try {
      final supabase = Supabase.instance.client;

      // 1. Get stipulated duration and current dates
      final machineryData = await supabase
          .from('project_machinery')
          .select('start_date, end_date, quote_service_machineries(quote_services(quote_service_estimations(total_working_days)))')
          .eq('id', widget.projectMachineryId)
          .maybeSingle();
      
      if (machineryData == null) return;

      dynamic duration;
      try {
        final qsm = machineryData['quote_service_machineries'];
        if (qsm != null) {
          final qs = qsm['quote_services'];
          if (qs != null) {
            final est = qs['quote_service_estimations'];
            if (est is List && est.isNotEmpty) {
              duration = est[0]['total_working_days'];
            } else if (est is Map) {
              duration = est['total_working_days'];
            }
          }
        }
      } catch (e) {
        debugPrint('Error parsing duration path: $e');
      }

      final double? durationValue = duration != null ? (duration as num).toDouble() : null;

      if (mounted) {
        setState(() {
          _stipulatedDays = durationValue;
          if (machineryData['start_date'] != null) {
            _startDate = DateTime.parse(machineryData['start_date']);
          }
          if (machineryData['end_date'] != null) {
            _endDate = DateTime.parse(machineryData['end_date']);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading machinery data: $e')),
        );
      }
    }
  }

  Future<void> _saveSchedule() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end dates')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('project_machinery')
          .update({
            'start_date': _startDate!.toIso8601String().split('T')[0],
            'end_date': _endDate!.toIso8601String().split('T')[0],
          })
          .eq('id', widget.projectMachineryId);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving schedule: $e')),
        );
      }
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_stipulatedDays != null) {
          _endDate = _calculateEndDate(picked, _stipulatedDays!);
        } else {
          _endDate = picked.add(const Duration(days: 7));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) return;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!,
      firstDate: _startDate!,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: _isLoading 
          ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
          : Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.precision_manufacturing, color: Colors.orange),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Machinery Planning',
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.slate900,
                        ),
                      ),
                      Text(
                        'Scheduling ${widget.machineryName}',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: AppTheme.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppTheme.slate400),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Info Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: AppTheme.slate500),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REQUIRED DURATION',
                          style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate500, letterSpacing: 1),
                        ),
                        Text(
                          _stipulatedDays != null ? '${_stipulatedDays} Working Days' : 'Not defined',
                          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.slate900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Date Selection
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start Date', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate600)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectStartDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.slate200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text(
                                _startDate != null ? _startDate!.toString().split(' ')[0] : 'Choose...',
                                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.slate900),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('End Date', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate600)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectEndDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.slate200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_available, size: 16, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text(
                                _endDate != null ? _endDate!.toString().split(' ')[0] : 'Choose...',
                                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.slate900),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Cancel', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppTheme.slate600)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _saveSchedule,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.slate900,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Save Plan', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
