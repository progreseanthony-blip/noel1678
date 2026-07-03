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
  String? _quoteServiceId;
  Map<String, double> _nonWorkingDays = {};
  
  // Virtual units: index -> {startDate, endDate, assignmentId}
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

      // 1. Get machinery details and stipulated duration
      final mRes = await supabase
          .from('project_machinery')
          .select('project_id, quote_service_id, calculation_metadata, quote_service_machineries(quote_services(quote_service_estimations(total_working_days)))')
          .eq('id', widget.projectMachineryId)
          .single();
      
      _quoteServiceId = mRes['quote_service_id'];
      final projectId = mRes['project_id'];
      
      dynamic duration;
      try {
        final meta = mRes['calculation_metadata'] as Map<String, dynamic>?;
        if (meta != null && meta['days'] != null) {
          duration = meta['days'];
        } else {
          final qsm = mRes['quote_service_machineries'];
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
        }
      } catch (e) {
        debugPrint('Error parsing duration: $e');
      }
      _stipulatedDays = duration != null ? (duration as num).toDouble() : null;

      // 2. Load existing assignments
      final assignments = await supabase
          .from('project_machinery_assignments')
          .select()
          .eq('project_machinery_id', widget.projectMachineryId)
          .order('created_at');

      // 3. Try to find DEFAULT dates from OTHER resources in the same service (Request 5)
      if (assignments.isEmpty && _quoteServiceId != null) {
        // Try Labor first
        final laborAssign = await supabase
            .from('project_labor_assignments')
            .select('start_date, end_date')
            .eq('project_labor.quote_service_id', _quoteServiceId)
            .limit(1)
            .maybeSingle();
        
        if (laborAssign != null) {
          _batchStartDate = DateTime.parse(laborAssign['start_date']);
          if (_stipulatedDays != null) {
            _batchEndDate = _calculateEndDate(_batchStartDate!, _stipulatedDays!);
          } else {
            _batchEndDate = DateTime.parse(laborAssign['end_date']);
          }
        } else {
          // Try other machinery in same service
          final otherMachAssign = await supabase
              .from('project_machinery_assignments')
              .select('start_date, end_date')
              .eq('project_machinery.quote_service_id', _quoteServiceId)
              .neq('project_machinery_id', widget.projectMachineryId)
              .limit(1)
              .maybeSingle();
          
          if (otherMachAssign != null) {
            _batchStartDate = DateTime.parse(otherMachAssign['start_date']);
            if (_stipulatedDays != null) {
              _batchEndDate = _calculateEndDate(_batchStartDate!, _stipulatedDays!);
            } else {
              _batchEndDate = DateTime.parse(otherMachAssign['end_date']);
            }
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
          // Map existing assignments to virtual units
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
      debugPrint('Error loading machinery data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSchedule() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // Group units by their plans (dates) to minimize records
      // Or just save one record per unit for maximum granularity?
      // User wants "Joint or Independent".
      
      // 1. Delete all current assignments for this project_machinery
      await supabase.from('project_machinery_assignments').delete().eq('project_machinery_id', widget.projectMachineryId);

      // 2. Insert new ones grouped by identical dates
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
        await supabase.from('project_machinery_assignments').insert({
          'project_machinery_id': widget.projectMachineryId,
          'start_date': dates[0],
          'end_date': dates[1],
          'quantity': entry.value.length,
        });
      }

      // 3. Update main record with first available dates for summary
      if (groups.isNotEmpty) {
        final first = groups.keys.first.split('|');
        await supabase.from('project_machinery').update({
          'start_date': first[0],
          'end_date': first[1],
        }).eq('id', widget.projectMachineryId);
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        height: 650,
        padding: const EdgeInsets.all(24),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.precision_manufacturing, color: Colors.orange),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Machinery Planning', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
                      Text('${widget.machineryName} (${widget.expectedQuantity} Units)', style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate500)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppTheme.slate400)),
              ],
            ),
            const Divider(height: 32),
            
            // Batch Selection & Date Picker
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
                          backgroundColor: AppTheme.primaryGreen,
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
            
            // Units Grid
            Text('2. SELECT UNITS (${_selectedUnits.length} SELECTED)', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate500, letterSpacing: 1)),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
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
                        color: isSelected ? AppTheme.primaryGreen.withOpacity(0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? AppTheme.primaryGreen : AppTheme.slate200),
                      ),
                      child: Row(
                        children: [
                          Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, size: 18, color: isSelected ? AppTheme.primaryGreen : AppTheme.slate400),
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
                                  style: GoogleFonts.manrope(fontSize: 10, color: hasPlan ? AppTheme.primaryGreen : AppTheme.slate400),
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
            ),
            
            // Footer
            const Divider(height: 32),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedUnits.length == widget.expectedQuantity) _selectedUnits.clear();
                      else _selectedUnits.addAll(List.generate(widget.expectedQuantity, (i) => i + 1));
                    });
                  },
                  child: Text(_selectedUnits.length == widget.expectedQuantity ? 'Deselect All' : 'Select All Units'),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: Text('Cancel', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppTheme.slate600)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveSchedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.slate900,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Save All Plans', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateBox(String label, DateTime? date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.slate200)),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 16, color: Colors.orange),
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
