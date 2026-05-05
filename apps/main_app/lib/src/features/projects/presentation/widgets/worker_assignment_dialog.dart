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
  Map<String, String> _globalBusyWorkers = {}; // workerId -> Project Name

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final supabase = Supabase.instance.client;

      // 1. Get the required role_id
      final laborData = await supabase
          .from('project_labor')
          .select('quote_service_labor_id(role_id)')
          .eq('id', widget.projectLaborId)
          .single();
      
      final roleId = laborData['quote_service_labor_id']?['role_id'];

      // 2. Load all workers with that role
      var workersQuery = supabase
          .from('workers')
          .select('id, full_name, id_number')
          .eq('status', 'Active');
      
      if (roleId != null) {
        workersQuery = workersQuery.eq('role_id', roleId);
      }
      
      final workersResult = await workersQuery.order('full_name');

      // 3. Load current assignments for THIS role
      final assignmentsResult = await supabase
          .from('project_labor_assignments')
          .select('worker_id')
          .eq('project_labor_id', widget.projectLaborId);

      // 4. Load GLOBAL assignments to identify busy workers (Simplified)
      final globalBusyResult = await supabase
          .from('project_labor_assignments')
          .select('worker_id')
          .neq('project_labor_id', widget.projectLaborId);

      if (mounted) {
        final busyMap = <String, String>{};
        try {
          if (globalBusyResult != null && globalBusyResult is List) {
            for (final row in globalBusyResult) {
              final workerId = row['worker_id']?.toString();
              if (workerId != null) {
                busyMap[workerId] = 'Another project/role';
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing global busy workers: $e');
        }

        setState(() {
          _allWorkers = List<Map<String, dynamic>>.from(workersResult ?? []);
          _assignedWorkerIds = (assignmentsResult as List? ?? [])
              .map((a) => a['worker_id'].toString())
              .toSet();
          _globalBusyWorkers = busyMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading assignments: $e')),
        );
      }
    }
  }

  Future<void> _toggleAssignment(String workerId, bool assign) async {
    try {
      final supabase = Supabase.instance.client;
      if (assign) {
        await supabase.from('project_labor_assignments').insert({
          'project_labor_id': widget.projectLaborId,
          'worker_id': workerId,
        });
        setState(() => _assignedWorkerIds.add(workerId));
      } else {
        await supabase
            .from('project_labor_assignments')
            .delete()
            .eq('project_labor_id', widget.projectLaborId)
            .eq('worker_id', workerId);
        setState(() => _assignedWorkerIds.remove(workerId));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating assignment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
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
                        'Assign Crew',
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.slate900,
                        ),
                      ),
                      Text(
                        'Select workers for ${widget.roleName}',
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
            const Divider(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ))
            else if (_allWorkers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'No active workers found for this role.',
                    style: GoogleFonts.manrope(color: AppTheme.slate500),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _allWorkers.length,
                  itemBuilder: (context, index) {
                    final worker = _allWorkers[index];
                    final isAssignedHere = _assignedWorkerIds.contains(worker['id']);
                    final busyProject = _globalBusyWorkers[worker['id']];
                    final isBusyElsewhere = busyProject != null;
                    
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
                      child: Opacity(
                        opacity: isBusyElsewhere ? 0.6 : 1.0,
                        child: CheckboxListTile(
                          enabled: !isBusyElsewhere,
                          value: isAssignedHere,
                          onChanged: (val) {
                            if (isBusyElsewhere) return;
                            final isChecking = val ?? false;
                            if (isChecking && _assignedWorkerIds.length >= widget.expectedEmployees) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Limit reached: Only ${widget.expectedEmployees} workers required for this role.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            _toggleAssignment(worker['id'], isChecking);
                          },
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  worker['full_name'],
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w600,
                                    color: isBusyElsewhere ? AppTheme.slate500 : AppTheme.slate900,
                                  ),
                                ),
                              ),
                              if (isBusyElsewhere)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorRed.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'BUSY: $busyProject',
                                    style: GoogleFonts.manrope(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.errorRed,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            'ID: ${worker['id_number']}',
                            style: GoogleFonts.manrope(
                              fontSize: 12, 
                              color: isBusyElsewhere ? AppTheme.slate400 : AppTheme.slate500
                            ),
                          ),
                          activeColor: AppTheme.primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
                child: Text('Done', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
