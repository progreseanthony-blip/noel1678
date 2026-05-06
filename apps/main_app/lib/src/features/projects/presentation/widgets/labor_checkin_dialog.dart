import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';

class LaborCheckInDialog extends StatefulWidget {
  final String projectId;
  final String projectLaborId;
  final String roleName;
  final String serviceName;

  const LaborCheckInDialog({
    super.key,
    required this.projectId,
    required this.projectLaborId,
    required this.roleName,
    required this.serviceName,
  });

  @override
  State<LaborCheckInDialog> createState() => _LaborCheckInDialogState();
}

class _LaborCheckInDialogState extends State<LaborCheckInDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _workers = [];
  List<Map<String, dynamic>> _tasks = [];
  String? _selectedWorkerId;
  String? _selectedTaskId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadWorkers(),
      _loadTasks(),
    ]);
  }

  Future<void> _loadTasks() async {
    try {
      final supabase = Supabase.instance.client;
      final result = await supabase
          .from('project_tasks')
          .select('id, name')
          .eq('project_id', widget.projectId)
          .order('name');

      if (mounted) {
        setState(() {
          _tasks = List<Map<String, dynamic>>.from(result);
          // Try to auto-select task matching service name if any
          final matchingTask = _tasks.where((t) => t['name'] == widget.serviceName).firstOrNull;
          if (matchingTask != null) {
            _selectedTaskId = matchingTask['id'];
          } else if (_tasks.isNotEmpty) {
            _selectedTaskId = _tasks.first['id'];
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
  }

  bool _showAllQualified = false;

  Future<void> _loadWorkers() async {
    try {
      final supabase = Supabase.instance.client;
      
      // 1. Get current busy workers (already checked in)
      final activeCheckins = await supabase
          .from('labor_checkins')
          .select('worker_id')
          .eq('status', 'active');
      
      final List<String> busyWorkerIds = (activeCheckins as List)
          .map((c) => c['worker_id'].toString())
          .toList();

      List<Map<String, dynamic>> availableWorkers = [];

      if (!_showAllQualified) {
        // 2. Load PRE-ASSIGNED workers for this labor category (FILTERED BY TODAY)
        final today = DateTime.now().toIso8601String().split('T')[0];
        final assignedRes = await supabase
            .from('project_labor_assignments')
            .select('workers(id, full_name, id_number)')
            .eq('project_labor_id', widget.projectLaborId)
            .lte('start_date', today)
            .gte('end_date', today);
        
        availableWorkers = (assignedRes as List)
            .map((a) => a['workers'] as Map<String, dynamic>)
            .where((w) => !busyWorkerIds.contains(w['id']))
            .toList();
      } else {
        // 3. Fallback: Load ALL qualified workers by role
        final laborData = await supabase
            .from('project_labor')
            .select('quote_service_labor_id(role_id)')
            .eq('id', widget.projectLaborId)
            .single();
        
        final requiredRoleId = laborData['quote_service_labor_id']?['role_id'];

        var query = supabase
            .from('workers')
            .select('id, full_name, id_number')
            .eq('status', 'Active');
        
        if (requiredRoleId != null) {
          query = query.eq('role_id', requiredRoleId);
        }

        final result = await query.order('full_name');
        availableWorkers = List<Map<String, dynamic>>.from(result)
            .where((w) => !busyWorkerIds.contains(w['id']))
            .toList();
      }

      if (mounted) {
        setState(() {
          _workers = availableWorkers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading workers: $e')),
        );
      }
    }
  }

  Future<void> _handleCheckIn() async {
    if (_selectedWorkerId == null) return;

    setState(() => _isSaving = true);
    try {
      final supabase = Supabase.instance.client;
      
      await supabase.from('labor_checkins').insert({
        'project_id': widget.projectId,
        'project_labor_id': widget.projectLaborId,
        'worker_id': _selectedWorkerId,
        'project_task_id': _selectedTaskId,
        'status': 'active',
        'check_in': DateTime.now().toIso8601String(),
      });

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during check-in: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 450,
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_add_alt_1, color: AppTheme.primaryGreen),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Worker Check-in',
                        style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                      ),
                      Text(
                        '${widget.roleName} - ${widget.serviceName}',
                        style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate500, fontWeight: FontWeight.w600),
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
            
            // Task Selection
            Text(
              'Specific Task / Activity',
              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate700),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTaskId,
                  hint: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Select an activity...', style: GoogleFonts.manrope(color: AppTheme.slate400)),
                  ),
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(12),
                  items: _tasks.map((t) {
                    return DropdownMenuItem<String>(
                      value: t['id'],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(t['name'], style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedTaskId = val),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              'Select Worker',
              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate700),
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_workers.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No available active workers found.',
                        style: GoogleFonts.manrope(fontSize: 13, color: Colors.orange[800], fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.slate200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedWorkerId,
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Choose a worker...', style: GoogleFonts.manrope(color: AppTheme.slate400)),
                    ),
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(12),
                    items: _workers.map((w) {
                      return DropdownMenuItem<String>(
                        value: w['id'],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('${w['full_name']} (${w['id_number']})', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedWorkerId = val),
                  ),
                ),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_selectedWorkerId == null || _selectedTaskId == null || _isSaving) ? null : _handleCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Confirm Check-in',
                        style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
