import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:noel_ui_components/noel_ui_components.dart';

class InstrumentSchedulingDialog extends StatefulWidget {
  final String projectInstrumentId;
  final String instrumentName;
  final int expectedQuantity;
  final String serviceName;

  const InstrumentSchedulingDialog({
    super.key,
    required this.projectInstrumentId,
    required this.instrumentName,
    required this.expectedQuantity,
    this.serviceName = '',
  });

  @override
  State<InstrumentSchedulingDialog> createState() => _InstrumentSchedulingDialogState();
}

class _InstrumentSchedulingDialogState extends State<InstrumentSchedulingDialog> {
  bool _isLoading = true;
  double? _stipulatedDays;
  String? _quoteServiceId;
  Map<String, double> _nonWorkingDays = {};
  
  final Map<int, Map<String, dynamic>> _unitPlans = {};
  final Set<int> _selectedUnits = {};
  
  DateTime? _batchStartDate;
  DateTime? _batchEndDate;

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

      final mRes = await supabase
          .from('project_instruments')
          .select('project_id, quote_service_id, quote_service_instruments(quote_services(quote_service_estimations(total_working_days, start_date, end_date)))')
          .eq('id', widget.projectInstrumentId)
          .single();
      
      _quoteServiceId = mRes['quote_service_id'];
      final projectId = mRes['project_id'];
      
      dynamic duration;
      String? _estStartDate, _estEndDate;
      try {
        final qsi = mRes['quote_service_instruments'];
        if (qsi != null) {
          final qs = qsi['quote_services'];
          if (qs != null) {
            final est = qs['quote_service_estimations'];
            dynamic firstEst;
            if (est is List && est.isNotEmpty) {
              firstEst = est[0];
            } else if (est is Map) {
              firstEst = est;
            }
            if (firstEst != null) {
              duration = firstEst['total_working_days'];
              _estStartDate = firstEst['start_date']?.toString();
              _estEndDate = firstEst['end_date']?.toString();
            }
          }
        }
      } catch (e) {
        debugPrint('Error parsing duration: $e');
      }
      _stipulatedDays = duration != null ? (duration as num).toDouble() : null;

      final assignments = await supabase
          .from('project_instrument_assignments')
          .select()
          .eq('project_instrument_id', widget.projectInstrumentId)
          .order('created_at');

      // Default dates: estimation dates first, then other resources
      if (assignments.isEmpty && _quoteServiceId != null) {
        if (_estStartDate != null) {
          _batchStartDate = DateTime.tryParse(_estStartDate!);
          if (_batchStartDate != null && _estEndDate != null) {
            _batchEndDate = DateTime.tryParse(_estEndDate!);
          }
        }
        if (_batchStartDate == null) {
        final laborAssign = await supabase
            .from('project_labor_assignments')
            .select('start_date, end_date')
            .eq('project_labor.quote_service_id', _quoteServiceId)
            .limit(1)
            .maybeSingle();
        
        if (laborAssign != null) {
          _batchStartDate = DateTime.parse(laborAssign['start_date']);
          _batchEndDate = DateTime.parse(laborAssign['end_date']);
        }
        }
      }

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
          int currentUnitIdx = 1;
          for (var a in assignments) {
            final qty = (a['quantity'] as num?)?.toInt() ?? 1;
            for (int i = 0; i < qty; i++) {
              if (currentUnitIdx <= widget.expectedQuantity) {
                _unitPlans[currentUnitIdx] = {
                  'id': a['id'],
                  'start': a['start_date'] != null ? DateTime.parse(a['start_date']) : null,
                  'end': a['end_date'] != null ? DateTime.parse(a['end_date']) : null,
                };
                currentUnitIdx++;
              }
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading instrument data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSchedule() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('project_instrument_assignments').delete().eq('project_instrument_id', widget.projectInstrumentId);

      final Map<String, List<int>> groups = {};
      for (int i = 1; i <= widget.expectedQuantity; i++) {
        final plan = _unitPlans[i];
        final start = plan?['start']?.toString().split(' ')[0] ?? _batchStartDate?.toString().split(' ')[0];
        final end = plan?['end']?.toString().split(' ')[0] ?? _batchEndDate?.toString().split(' ')[0];
        
        if (start != null && end != null) {
          final key = '$start|$end';
          groups[key] ??= [];
          groups[key]!.add(i);
        }
      }

      for (var entry in groups.entries) {
        final dates = entry.key.split('|');
        await supabase.from('project_instrument_assignments').insert({
          'project_instrument_id': widget.projectInstrumentId,
          'start_date': dates[0],
          'end_date': dates[1],
          'quantity': entry.value.length,
        });
      }

      if (groups.isNotEmpty) {
        final first = groups.keys.first.split('|');
        await supabase.from('project_instruments').update({
          'start_date': first[0],
          'end_date': first[1],
        }).eq('id', widget.projectInstrumentId);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving schedule: $e')));
      }
    }
  }

  void _applyBatchDates() {
    if (_batchStartDate == null || _batchEndDate == null) return;
    if (_selectedUnits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one unit first')));
      return;
    }

    setState(() {
      for (var idx in _selectedUnits) {
        _unitPlans[idx] = {
          'start': _batchStartDate,
          'end': _batchEndDate,
        };
      }
      _selectedUnits.clear();
    });
  }

  Future<void> _selectBatchStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _batchStartDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        _batchStartDate = picked;
        if (_stipulatedDays != null) {
          _batchEndDate = _calculateEndDate(picked, _stipulatedDays!);
        }
      });
    }
  }

  Future<void> _selectBatchEndDate() async {
    if (_batchStartDate == null) return;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _batchEndDate ?? _batchStartDate!,
      firstDate: _batchStartDate!,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() => _batchEndDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveDialogShell(
      title: 'Instrument Planning',
      subtitle: '${widget.instrumentName} (${widget.expectedQuantity} Units)',
      icon: Icons.handyman_outlined,
      maxWidth: 700,
      bodyPadding: const EdgeInsets.all(24),
      onClose: () => Navigator.of(context).pop(),
      body: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
            )
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppTheme.slate50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.slate200)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('1. SELECT UNITS AND PROGRAM DATES', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate500, letterSpacing: 1)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: _selectBatchStartDate,
                                    child: _buildDateBox('Start Date', _batchStartDate),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: _selectBatchEndDate,
                                    child: _buildDateBox('End Date', _batchEndDate),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: _applyBatchDates,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text('Apply to Selected', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Text('2. SELECT UNITS (${_selectedUnits.length} SELECTED)', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate500, letterSpacing: 1)),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: widget.expectedQuantity,
                        itemBuilder: (context, index) {
                          final uIdx = index + 1;
                          final isSelected = _selectedUnits.contains(uIdx);
                          final plan = _unitPlans[uIdx];
                          final hasPlan = plan != null && plan['start'] != null;
                          
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) _selectedUnits.remove(uIdx);
                                else _selectedUnits.add(uIdx);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.purple.withOpacity(0.05) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isSelected ? Colors.purple : AppTheme.slate200),
                              ),
                              child: Row(
                                children: [
                                  Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, size: 18, color: isSelected ? Colors.purple : AppTheme.slate400),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Unit $uIdx', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                                        Text(
                                          hasPlan 
                                            ? '${plan['start'].toString().split(' ')[0]} to ${plan['end'].toString().split(' ')[0]}'
                                            : 'Not Scheduled',
                                          style: GoogleFonts.manrope(fontSize: 10, color: hasPlan ? Colors.purple : AppTheme.slate400),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ],
              ),
      footer: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_selectedUnits.length == widget.expectedQuantity) _selectedUnits.clear();
                  else _selectedUnits.addAll(List.generate(widget.expectedQuantity, (i) => i + 1));
                });
              },
              child: Text(
                _selectedUnits.length == widget.expectedQuantity ? 'Deselect All' : 'Select All Units',
                style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                  onTap: _saveSchedule,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'Save All Plans',
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateBox(String label, DateTime? date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.slate200)),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 16, color: Colors.purple),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.slate400, letterSpacing: 0.5)),
              Text(date != null ? date.toString().split(' ')[0] : 'Choose...', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate900)),
            ],
          ),
        ],
      ),
    );
  }
}
