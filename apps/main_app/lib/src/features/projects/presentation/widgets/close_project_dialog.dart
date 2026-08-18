import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CloseProjectDialog extends StatefulWidget {
  final String projectId;
  final String projectTitle;
  final bool isAdmin;

  const CloseProjectDialog({
    super.key,
    required this.projectId,
    required this.projectTitle,
    required this.isAdmin,
  });

  @override
  State<CloseProjectDialog> createState() => _CloseProjectDialogState();
}

class _CloseProjectDialogState extends State<CloseProjectDialog> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  TextEditingController _notesController = TextEditingController();

  // Validation items
  final List<_ValidationItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadValidation();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadValidation() async {
    final supabase = Supabase.instance.client;
    try {
      final project = await supabase.from('projects').select('quote_id').eq('id', widget.projectId).single();
      final quoteId = project['quote_id'] as String?;

      // Services completion check
      int completedServices = 0;
      int totalServices = 0;
      if (quoteId != null) {
        final services = await supabase
            .from('quote_services')
            .select('id, completion_pct, direct_cost')
            .eq('quote_id', quoteId);
        totalServices = (services as List).length;
        for (final s in services) {
          final pct = (s['completion_pct'] as num?)?.toDouble() ?? 0;
          if (pct >= 100) completedServices++;
        }
      }

      // Machinery reception & return
      final machCounts = await supabase
          .from('project_machinery')
          .select('expected_quantity, received_quantity')
          .eq('project_id', widget.projectId);
      int machTotalExpected = 0;
      int machTotalReceived = 0;
      for (final m in (machCounts as List)) {
        machTotalExpected += (m['expected_quantity'] as num?)?.toInt() ?? 0;
        machTotalReceived += (m['received_quantity'] as num?)?.toInt() ?? 0;
      }

      // Machinery returned
      int machReturned = 0;
      int machTotalInspected = 0;
      final inspections = await supabase
          .from('machinery_inspections')
          .select('returned_at, project_machinery!inner(project_id)')
          .eq('project_machinery.project_id', widget.projectId);
      for (final i in (inspections as List)) {
        machTotalInspected++;
        if (i['returned_at'] != null) machReturned++;
      }

      // Materials reception
      final matCounts = await supabase
          .from('project_materials')
          .select('expected_quantity, received_quantity')
          .eq('project_id', widget.projectId);
      int matTotalExpected = 0;
      int matTotalReceived = 0;
      for (final m in (matCounts as List)) {
        matTotalExpected += (m['expected_quantity'] as num?)?.toInt() ?? 0;
        matTotalReceived += (m['received_quantity'] as num?)?.toInt() ?? 0;
      }

      // Instruments reception & return
      final instCounts = await supabase
          .from('project_instruments')
          .select('expected_quantity, received_quantity')
          .eq('project_id', widget.projectId);
      int instTotalExpected = 0;
      int instTotalReceived = 0;
      for (final i in (instCounts as List)) {
        instTotalExpected += (i['expected_quantity'] as num?)?.toInt() ?? 0;
        instTotalReceived += (i['received_quantity'] as num?)?.toInt() ?? 0;
      }

      setState(() {
        _items.addAll([
          _ValidationItem(
            label: 'All services completed',
            passed: totalServices > 0 && completedServices >= totalServices,
            detail: totalServices > 0 ? '$completedServices of $totalServices' : 'No services found',
          ),
          _ValidationItem(
            label: 'Machinery received',
            passed: machTotalExpected == 0 || machTotalReceived >= machTotalExpected,
            detail: '$machTotalReceived of $machTotalExpected units',
          ),
          _ValidationItem(
            label: 'Machinery returned',
            passed: machTotalInspected == 0 || machReturned >= machTotalInspected,
            detail: '$machReturned of $machTotalInspected units returned',
          ),
          _ValidationItem(
            label: 'Materials received',
            passed: matTotalExpected == 0 || matTotalReceived >= matTotalExpected,
            detail: '$matTotalReceived of $matTotalExpected units',
          ),
          _ValidationItem(
            label: 'Instruments received',
            passed: instTotalExpected == 0 || instTotalReceived >= instTotalExpected,
            detail: '$instTotalReceived of $instTotalExpected units',
          ),
        ]);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading validation: $e';
        _isLoading = false;
      });
    }
  }

  bool get _allPassed => _items.every((i) => i.passed);

  Future<void> _closeProject() async {
    setState(() => _isSaving = true);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    try {
      await supabase.from('projects').update({
        'status': 'completed',
        'completed_at': DateTime.now().toUtc().toIso8601String(),
        'completed_by': user?.id,
        'completion_notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      }).eq('id', widget.projectId);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error closing project: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveDialogShell(
      title: 'Close Project',
      subtitle: widget.projectTitle,
      icon: widget.isAdmin ? Icons.checklist : Icons.lock_outline,
      maxWidth: 520,
      bodyPadding: const EdgeInsets.all(32),
      onClose: () => Navigator.of(context).pop(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                              if (!widget.isAdmin) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Only Administrators can close projects.',
                                          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              Text(
                                'Validation Checklist',
                                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate700),
                              ),
                              const SizedBox(height: 12),
                              ..._items.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 22, height: 22,
                                          decoration: BoxDecoration(
                                            color: item.passed ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            item.passed ? Icons.check : Icons.close,
                                            size: 14,
                                            color: item.passed ? AppTheme.primaryGreen : Colors.red,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.label,
                                                style: GoogleFonts.manrope(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.slate700,
                                                ),
                                              ),
                                              Text(
                                                item.detail,
                                                style: GoogleFonts.manrope(
                                                  fontSize: 11,
                                                  color: AppTheme.slate500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _notesController,
                                maxLines: 3,
                                enabled: widget.isAdmin,
                                decoration: InputDecoration(
                                  hintText: 'Completion notes (optional)',
                                  hintStyle: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 13),
                                  filled: true,
                                  fillColor: AppTheme.slate50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.all(12),
                                ),
                                style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate900),
                              ),
                            ],
                          ),

      footer: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate500)),
          ),
          ElevatedButton.icon(
            onPressed: (!widget.isAdmin || _isSaving || _isLoading || !_allPassed) ? null : _closeProject,
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check_circle, size: 16, color: Colors.white),
            label: Text(
              _isSaving ? 'Closing...' : 'Close Project',
              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _allPassed ? AppTheme.primaryGreen : AppTheme.slate400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationItem {
  final String label;
  final bool passed;
  final String detail;

  const _ValidationItem({
    required this.label,
    required this.passed,
    required this.detail,
  });
}
