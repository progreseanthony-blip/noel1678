import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkerAssignmentDialog extends StatefulWidget {
  final String projectLaborId;
  final String roleName;
  final int expectedEmployees;

  const WorkerAssignmentDialog({
    super.key,
    required this.projectLaborId,
    required this.roleName,
    required this.expectedEmployees,
  });

  @override
  State<WorkerAssignmentDialog> createState() => _WorkerAssignmentDialogState();
}

class _WorkerAssignmentDialogState extends State<WorkerAssignmentDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allWorkers = [];
  Set<String> _assignedWorkerIds = {};
  Map<String, String> _globalBusyWorkers = {}; // workerId -> Reason/Project Name
  Map<String, Map<String, String>> _workerDates = {}; // workerId -> {start, end}
  
  double? _stipulatedDays;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _limitError;
  final Set<String> _processingWorkers = {};
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredWorkers {
    if (_searchQuery.isEmpty) return _allWorkers;
    final q = _searchQuery.toLowerCase();
    return _allWorkers.where((w) {
      final name = (w['full_name'] ?? '').toString().toLowerCase();
      final id = (w['id_number'] ?? '').toString().toLowerCase();
      return name.contains(q) || id.contains(q);
    }).toList();
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

      // 1. Get role and stipulated duration
      final laborData = await supabase
          .from('project_labor')
          .select('project_id, role_id, quote_service_labors(role_id, quote_services(quote_service_estimations(total_working_days)))')
          .eq('id', widget.projectLaborId)
          .maybeSingle();
      
      if (laborData == null) return;

      dynamic duration;
      dynamic roleId;
      try {
        final qsl = laborData['quote_service_labors'];
        roleId = qsl?['role_id'] ?? laborData['role_id'];
        if (qsl != null) {
          final qs = qsl['quote_services'];
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
        debugPrint('Error parsing labor duration path: $e');
      }

      final double? durationValue = duration != null ? (duration as num).toDouble() : null;

      // 2. Load all workers with that role
      var workersQuery = supabase
          .from('workers')
          .select(''', id, full_name, id_number,
            role:labor_roles(id, description)
          '''.replaceAll('\n', ' '))
          .eq('status', 'Active');
      
      if (roleId != null) {
        debugPrint('Filtering workers by role_id: $roleId');
        workersQuery = workersQuery.eq('role_id', roleId);
      } else {
        debugPrint('Warning: roleId is null, showing all active workers');
      }
      
      final workersResult = await workersQuery.order('full_name');

      // 3. Load current assignments with dates
      final assignmentsResult = await supabase
          .from('project_labor_assignments')
          .select('worker_id, start_date, end_date')
          .eq('project_labor_id', widget.projectLaborId);

      final Map<String, Map<String, String>> workerDatesMap = {};
      final Set<String> assignedIds = {};
      if (assignmentsResult != null && assignmentsResult is List) {
        for (final a in assignmentsResult) {
          final id = a['worker_id'].toString();
          assignedIds.add(id);
          workerDatesMap[id] = {
            'start': a['start_date'].toString(),
            'end': a['end_date'].toString(),
          };
        }
      }

      // 4. Load GLOBAL assignments to identify busy workers (Date-Aware)
      // 3. Check for Global Busy Workers (Other projects or other roles in same project)
      final Set<String> busyWorkerIds = {};
      final Map<String, String> busyReasons = {};

      final projectAssignments = await supabase
          .from('project_labor_assignments')
          .select('worker_id, project_labor!inner(project_id, role_name)')
          .eq('project_labor.project_id', laborData['project_id']);
      
      for (var row in projectAssignments as List) {
        final wId = row['worker_id'].toString();
        final roleName = row['project_labor']?['role_name'] ?? 'Other Role';
        if (wId != null && !assignedIds.contains(wId)) {
          busyWorkerIds.add(wId);
          busyReasons[wId] = 'Already assigned to this project as $roleName';
        }
      }

      if (_startDate != null && _endDate != null) {
        final busyRes = await supabase
            .from('project_labor_assignments')
            .select('worker_id, project_labor(project_id(title))')
            .neq('project_labor_id', widget.projectLaborId)
            .or('and(start_date.lte.${_endDate!.toIso8601String()},end_date.gte.${_startDate!.toIso8601String()})');
        
        if (busyRes != null) {
          for (var row in busyRes as List) {
            final wId = row['worker_id'].toString();
            final projectName = row['project_labor']?['project_id']?['title'] ?? 'Another Project';
            if (!busyWorkerIds.contains(wId)) {
              busyWorkerIds.add(wId);
              busyReasons[wId] = 'Busy in $projectName';
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _stipulatedDays = durationValue;
          _allWorkers = List<Map<String, dynamic>>.from(workersResult ?? []);
          _assignedWorkerIds = assignedIds;
          _workerDates = workerDatesMap;
          _globalBusyWorkers = Map.fromIterable(busyWorkerIds, value: (id) => busyReasons[id] ?? 'Busy');
          _isLoading = false;
          
          if (_assignedWorkerIds.length > widget.expectedEmployees) {
            _limitError = 'Exceeded Limit: ${_assignedWorkerIds.length} workers assigned, but only ${widget.expectedEmployees} required.';
          } else {
            _limitError = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
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
        _isLoading = true;
      });
      _loadData();
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
        _isLoading = true;
      });
      _loadData();
    }
  }

  Future<void> _editIndividualDates(String workerId) async {
    final current = _workerDates[workerId];
    if (current == null) return;

    final DateTime initialStart = DateTime.parse(current['start']!);
    final DateTime initialEnd = DateTime.parse(current['end']!);

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );

    if (picked != null) {
      try {
        final supabase = Supabase.instance.client;
        final startIso = picked.start.toIso8601String().split('T')[0];
        final endIso = picked.end.toIso8601String().split('T')[0];

        // Check for conflicts
        final conflict = await supabase
            .from('project_labor_assignments')
            .select('project_labor(project_id(title))')
            .eq('worker_id', workerId)
            .neq('project_labor_id', widget.projectLaborId)
            .lte('start_date', endIso)
            .gte('end_date', startIso)
            .maybeSingle();

        if (conflict != null) {
          final pName = conflict['project_labor']?['project_id']?['title'] ?? 'another project';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Conflict: Worker is busy in "$pName" during those dates.')),
            );
          }
          return;
        }

        await supabase
            .from('project_labor_assignments')
            .update({
              'start_date': startIso,
              'end_date': endIso,
            })
            .eq('project_labor_id', widget.projectLaborId)
            .eq('worker_id', workerId);

        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating individual dates: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleAssignment(String workerId, bool assign) async {
    if (_processingWorkers.contains(workerId)) return;
    
    try {
      final supabase = Supabase.instance.client;
      setState(() {
        _processingWorkers.add(workerId);
        _limitError = null;
      });

      if (assign) {
        if (_startDate == null || _endDate == null) {
          setState(() {
            _processingWorkers.remove(workerId);
            _limitError = 'Please select a starting date first';
          });
          return;
        }

        // Final safety check on limit
        if (_assignedWorkerIds.length >= widget.expectedEmployees) {
          setState(() {
            _processingWorkers.remove(workerId);
            _limitError = 'Limit reached: Only ${widget.expectedEmployees} required.';
          });
          return;
        }

        await supabase.from('project_labor_assignments').insert({
          'project_labor_id': widget.projectLaborId,
          'worker_id': workerId,
          'start_date': _startDate!.toIso8601String().split('T')[0],
          'end_date': _endDate!.toIso8601String().split('T')[0],
        });
        
        setState(() {
          _assignedWorkerIds.add(workerId);
          _workerDates[workerId] = {
            'start': _startDate!.toIso8601String().split('T')[0],
            'end': _endDate!.toIso8601String().split('T')[0],
          };
        });
      } else {
        await supabase
            .from('project_labor_assignments')
            .delete()
            .eq('project_labor_id', widget.projectLaborId)
            .eq('worker_id', workerId);
        setState(() {
          _assignedWorkerIds.remove(workerId);
          _workerDates.remove(workerId);
        });
      }
      
      // Reload to ensure everything is in sync
      await _loadData();
    } catch (e) {
      debugPrint('Error updating assignment: $e');
      if (mounted) {
        setState(() => _limitError = 'Error updating assignment: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingWorkers.remove(workerId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 550,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.group_add, color: AppTheme.primaryGreen),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Team Planning',
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.slate900,
                        ),
                      ),
                      Text(
                        'Scheduling ${widget.roleName}',
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
            
            // Resource Info & Calculation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: AppTheme.primaryGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STIPULATED DURATION',
                          style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen, letterSpacing: 1),
                        ),
                        Text(
                          _stipulatedDays != null ? '${_stipulatedDays} Working Days' : 'Not defined',
                          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.slate900),
                        ),
                      ],
                    ),
                  ),
                  if (_stipulatedDays != null)
                    Text(
                      '(Sat = 0.5d)',
                      style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate500, fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Global Scheduling Row
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.slate200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month, size: 16, color: AppTheme.primaryGreen),
                              const SizedBox(width: 8),
                              Text(
                                _startDate != null ? _startDate!.toString().split(' ')[0] : 'Choose...',
                                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.slate900),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('End Date (Estimated)', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate600)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectEndDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.slate200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_available, size: 16, color: AppTheme.primaryGreen),
                              const SizedBox(width: 8),
                              Text(
                                _endDate != null ? _endDate!.toString().split(' ')[0] : 'Choose...',
                                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.slate900),
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
            
            const SizedBox(height: 24),
            
            if (_limitError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _limitError!,
                        style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.errorRed),
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate900),
                decoration: InputDecoration(
                  hintText: 'Search by name or ID...',
                  hintStyle: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate400),
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.slate400),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16, color: AppTheme.slate400),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredWorkers.length,
                  itemBuilder: (context, index) {
                    final worker = _filteredWorkers[index];
                    final workerId = worker['id'].toString();
                    final isAssignedHere = _assignedWorkerIds.contains(workerId);
                    final busyProject = _globalBusyWorkers[workerId];
                    final isBusyElsewhere = busyProject != null;
                    final dates = _workerDates[workerId];
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isAssignedHere 
                            ? AppTheme.primaryGreen.withOpacity(0.05) 
                            : (isBusyElsewhere ? AppTheme.slate50 : Colors.transparent),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isAssignedHere 
                              ? AppTheme.primaryGreen.withOpacity(0.2) 
                              : (isBusyElsewhere ? AppTheme.slate200.withOpacity(0.5) : AppTheme.slate200),
                        ),
                      ),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            enabled: !isBusyElsewhere && (_startDate != null || isAssignedHere),
                            value: isAssignedHere,
                            onChanged: _processingWorkers.contains(workerId) ? null : (val) {
                              if (isBusyElsewhere) return;
                              if (val == true && _startDate == null) {
                                setState(() => _limitError = 'Select a start date for the team first');
                                return;
                              }
                              if (val == true && _assignedWorkerIds.length >= widget.expectedEmployees) {
                                setState(() => _limitError = 'Limit reached: Only ${widget.expectedEmployees} required.');
                                return;
                              }
                              _toggleAssignment(workerId, val ?? false);
                            },
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        worker['full_name'],
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w700,
                                          color: isBusyElsewhere ? AppTheme.slate400 : AppTheme.slate900,
                                        ),
                                      ),
                                    ),
                                    if (isBusyElsewhere) _buildBusyBadge(busyProject),
                                    if (isAssignedHere)
                                      IconButton(
                                        icon: const Icon(Icons.edit_calendar, size: 20, color: Colors.blue),
                                        onPressed: () => _editIndividualDates(workerId),
                                        tooltip: 'Edit individual dates',
                                      ),
                                  ],
                                ),
                                Text(
                                  'ID: ${worker['id_number'] ?? '-'}  \u2022  ${worker['role']?['description'] ?? 'No role'}',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.slate500,
                                  ),
                                ),
                              ],
                            ),
                            activeColor: AppTheme.primaryGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          if (isAssignedHere && dates != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 70, bottom: 12, right: 16),
                              child: Row(
                                children: [
                                  const Icon(Icons.date_range, size: 14, color: AppTheme.slate400),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Planned: ${dates['start']} to ${dates['end']}',
                                    style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.slate600),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.slate900,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Confirm Schedule', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusyBadge(String project) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: AppTheme.errorRed.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text('BUSY: $project', style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.errorRed)),
    );
  }
}
