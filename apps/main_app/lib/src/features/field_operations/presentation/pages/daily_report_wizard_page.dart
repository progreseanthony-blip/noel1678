import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';

import '../widgets/step_general_info.dart';
import '../widgets/step_labor.dart';
import '../widgets/step_machinery.dart';
import '../widgets/step_materials.dart';
import '../widgets/step_review_sign.dart';
import '../../../../shared/widgets/completed_project_banner.dart';
import 'package:noel_ui_components/noel_ui_components.dart';

class DailyReportWizardPage extends ConsumerStatefulWidget {
  final String projectId;
  final String? reportId;

  const DailyReportWizardPage({super.key, required this.projectId, this.reportId});

  @override
  ConsumerState<DailyReportWizardPage> createState() =>
      _DailyReportWizardPageState();
}

class _DailyReportWizardPageState
    extends ConsumerState<DailyReportWizardPage> {
  bool _isCompleted = false;
  int _currentStep = 0;
  bool _isInitializing = true;
  String? _error;

  String? _reportId;
  String _projectName = '';
  Map<String, dynamic> _reportData = {};

  List<Map<String, dynamic>> _laborLogs = [];
  // ignore: unused_field - will be used in A4/A5
  List<Map<String, dynamic>> _machineryLogs = [];
  // ignore: unused_field
  List<Map<String, dynamic>> _materialUsage = [];
  List<Map<String, dynamic>> _plannedLabor = [];
  // ignore: unused_field - used by StepMachinery for unfiltered operator assignments
  List<Map<String, dynamic>> _unfilteredPlannedLabor = [];
  // ignore: unused_field
  List<Map<String, dynamic>> _plannedMachinery = [];
  // ignore: unused_field
  List<Map<String, dynamic>> _plannedMaterials = [];
  List<Map<String, dynamic>> _projectTasks = [];
  List<Map<String, dynamic>> _deviationReasons = [];
  List<Map<String, dynamic>> _workers = [];
  // ignore: unused_field
  List<Map<String, dynamic>> _machineryCatalog = [];
  // ignore: unused_field
  List<Map<String, dynamic>> _materialsCatalog = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final service = ref.read(dailyReportServiceProvider);

      String? reportId;
      Map<String, dynamic>? report;
      String reportDate = '';

      if (widget.reportId != null) {
        report = await service.getReportById(widget.reportId!);
        reportId = report['id'] as String;
        reportDate = report['report_date'] as String? ?? DateTime.now().toIso8601String().split('T')[0];
      }

      final projectName = await Supabase.instance.client
          .from('projects')
          .select('title')
          .eq('id', widget.projectId)
          .single()
          .then((p) => p['title'] as String? ?? '');

      final results = await Future.wait([
        if (reportId != null) service.getLaborLogsForReport(reportId) else Future.value(<Map<String, dynamic>>[]),
        if (reportId != null) service.getMachineryLogsForReport(reportId) else Future.value(<Map<String, dynamic>>[]),
        if (reportId != null) service.getMaterialUsageForReport(reportId) else Future.value(<Map<String, dynamic>>[]),
        if (reportDate.isNotEmpty) service.getPlannedLaborForProject(widget.projectId, reportDate) else Future.value(<Map<String, dynamic>>[]),
        if (reportDate.isNotEmpty) service.getPlannedLaborForProject(widget.projectId, reportDate, filterByDate: false) else Future.value(<Map<String, dynamic>>[]),
        if (reportDate.isNotEmpty) service.getPlannedMachineryForProject(widget.projectId, reportDate) else Future.value(<Map<String, dynamic>>[]),
        if (reportDate.isNotEmpty) service.getPlannedMaterialsForProject(widget.projectId, reportDate) else Future.value(<Map<String, dynamic>>[]),
        service.getProjectTasks(widget.projectId),
        service.getDeviationReasons(),
        ref.read(workersServiceProvider).getWorkers(),
        ref.read(catalogsServiceProvider).getMachinery(),
        ref.read(catalogsServiceProvider).getMaterials(),
      ]);

      if (!mounted) return;

      setState(() {
        _reportId = reportId;
        _projectName = projectName;
        _reportData = report ?? {'report_date': '', 'day_type': 'working'};
        _laborLogs = List<Map<String, dynamic>>.from(results[0] as List);
        _machineryLogs = List<Map<String, dynamic>>.from(results[1] as List);
        _materialUsage = List<Map<String, dynamic>>.from(results[2] as List);
        _plannedLabor = List<Map<String, dynamic>>.from(results[3] as List);
        _unfilteredPlannedLabor = List<Map<String, dynamic>>.from(results[4] as List);
        _plannedMachinery = List<Map<String, dynamic>>.from(results[5] as List);
        _plannedMaterials = List<Map<String, dynamic>>.from(results[6] as List);
        _projectTasks = List<Map<String, dynamic>>.from(results[7] as List);
        _deviationReasons = List<Map<String, dynamic>>.from(results[8] as List);
        _workers = List<Map<String, dynamic>>.from(results[9] as List);
        _machineryCatalog = List<Map<String, dynamic>>.from(results[10] as List);
        _materialsCatalog = List<Map<String, dynamic>>.from(results[11] as List);
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isInitializing = false;
      });
    }
  }

  Future<void> _saveReportHeader() async {
    if (_reportId == null) return;
    if ((_reportData['report_date'] as String? ?? '').isEmpty) return;
    try {
      await ref.read(dailyReportServiceProvider).updateReport(_reportId!, {
        'weather_condition': _reportData['weather_condition'],
        'general_notes': _reportData['general_notes'],
        'report_date': _reportData['report_date'],
        'day_type': _reportData['day_type'] ?? 'working',
        'non_working_reason': _reportData['non_working_reason'],
        'stopped_at': _reportData['stopped_at'],
        'disruption_active': _reportData['disruption_active'] ?? false,
      });
      await _syncNonWorkingDays();
    } catch (e) {
      debugPrint('Error saving report: $e');
    }
  }

  Future<void> _syncNonWorkingDays() async {
    final dayType = _reportData['day_type'] as String? ?? 'working';
    final reportDate = _reportData['report_date'] as String?;
    if (reportDate == null || reportDate.isEmpty) return;

    final client = Supabase.instance.client;

    if (dayType == 'working') {
      await client.from('project_non_working_days').delete()
          .eq('project_id', widget.projectId)
          .eq('date', reportDate);
    } else {
      double partialRatio;
      if (dayType == 'non_working') {
        partialRatio = 1.0;
      } else {
        final stoppedAt = _reportData['stopped_at'] as String? ?? '';
        final parts = stoppedAt.split(':');
        final hours = (int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0);
        final minutes = (int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0);
        final stoppedHour = hours + minutes / 60;
        final workedHours = (stoppedHour - 7).clamp(0.0, 8.0);
        partialRatio = 1.0 - (workedHours / 8.0);
      }
      await client.from('project_non_working_days').upsert({
        'project_id': widget.projectId,
        'date': reportDate,
        'reason': _reportData['non_working_reason'],
        'partial_ratio': partialRatio,
        'daily_report_id': _reportId,
      });
    }
  }

  Future<void> _saveLaborLogs() async {
    if (_reportId == null) return;
    try {
      await ref.read(dailyReportServiceProvider).saveLaborLogs(
            _reportId!,
            _laborLogs
                .where((log) =>
                    log['worker_id'] != null && log['check_in_time'] != null)
                .toList(),
          );
    } catch (e) {
      debugPrint('Error saving labor logs: $e');
    }
  }

  void _onReportDataChanged(Map<String, dynamic> data) {
    final oldDate = _reportData['report_date'];
    final newDate = data['report_date'];
    if (oldDate != newDate && newDate != null && (newDate as String).isNotEmpty) {
      _switchToDate(newDate);
      return;
    }
    setState(() => _reportData = data);
  }

  Future<void> _switchToDate(String date) async {
    final service = ref.read(dailyReportServiceProvider);
    final existing = await service.getReportByDate(widget.projectId, date);

    if (existing != null && existing['status'] == 'draft') {
      final reportId = existing['id'] as String;
      final results = await Future.wait([
        service.getLaborLogsForReport(reportId),
        service.getMachineryLogsForReport(reportId),
        service.getMaterialUsageForReport(reportId),
        service.getPlannedLaborForProject(widget.projectId, date),
        service.getPlannedLaborForProject(widget.projectId, date, filterByDate: false),
        service.getPlannedMachineryForProject(widget.projectId, date),
        service.getPlannedMaterialsForProject(widget.projectId, date),
        service.getProjectTasks(widget.projectId),
        service.getDeviationReasons(),
        ref.read(workersServiceProvider).getWorkers(),
        ref.read(catalogsServiceProvider).getMachinery(),
        ref.read(catalogsServiceProvider).getMaterials(),
      ]);
      if (!mounted) return;
      setState(() {
        _reportId = reportId;
        _reportData = Map<String, dynamic>.from(existing)..['report_date'] = date;
        _laborLogs = List<Map<String, dynamic>>.from(results[0] as List);
        _machineryLogs = List<Map<String, dynamic>>.from(results[1] as List);
        _materialUsage = List<Map<String, dynamic>>.from(results[2] as List);
        _plannedLabor = List<Map<String, dynamic>>.from(results[3] as List);
        _unfilteredPlannedLabor = List<Map<String, dynamic>>.from(results[4] as List);
        _plannedMachinery = List<Map<String, dynamic>>.from(results[5] as List);
        _plannedMaterials = List<Map<String, dynamic>>.from(results[6] as List);
        _projectTasks = List<Map<String, dynamic>>.from(results[7] as List);
        _deviationReasons = List<Map<String, dynamic>>.from(results[8] as List);
        _workers = List<Map<String, dynamic>>.from(results[9] as List);
        _machineryCatalog = List<Map<String, dynamic>>.from(results[10] as List);
        _materialsCatalog = List<Map<String, dynamic>>.from(results[11] as List);
      });
    } else if (existing != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('A report for $date already exists (${existing['status']})', style: GoogleFonts.manrope()),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() => _reportData['report_date'] = date);
    } else {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      final newReport = await service.createReport({
        'project_id': widget.projectId,
        'report_date': date,
        'supervisor_id': currentUserId,
        'status': 'draft',
      });
      final results = await Future.wait([
        service.getPlannedLaborForProject(widget.projectId, date),
        service.getPlannedLaborForProject(widget.projectId, date, filterByDate: false),
        service.getPlannedMachineryForProject(widget.projectId, date),
        service.getPlannedMaterialsForProject(widget.projectId, date),
        service.getProjectTasks(widget.projectId),
        service.getDeviationReasons(),
        ref.read(workersServiceProvider).getWorkers(),
        ref.read(catalogsServiceProvider).getMachinery(),
        ref.read(catalogsServiceProvider).getMaterials(),
      ]);
      if (!mounted) return;
      setState(() {
        _reportId = newReport['id'];
        _reportData = newReport;
        _laborLogs = [];
        _machineryLogs = [];
        _materialUsage = [];
        _plannedLabor = List<Map<String, dynamic>>.from(results[0] as List);
        _unfilteredPlannedLabor = List<Map<String, dynamic>>.from(results[1] as List);
        _plannedMachinery = List<Map<String, dynamic>>.from(results[2] as List);
        _plannedMaterials = List<Map<String, dynamic>>.from(results[3] as List);
        _projectTasks = List<Map<String, dynamic>>.from(results[4] as List);
        _deviationReasons = List<Map<String, dynamic>>.from(results[5] as List);
        _workers = List<Map<String, dynamic>>.from(results[6] as List);
        _machineryCatalog = List<Map<String, dynamic>>.from(results[7] as List);
        _materialsCatalog = List<Map<String, dynamic>>.from(results[8] as List);
      });
    }
  }

  Future<void> _reloadPlannedLabor(String date) async {
    try {
      final service = ref.read(dailyReportServiceProvider);
      final results = await Future.wait([
        service.getPlannedLaborForProject(widget.projectId, date),
        service.getPlannedLaborForProject(widget.projectId, date, filterByDate: false),
        service.getPlannedMachineryForProject(widget.projectId, date),
        service.getPlannedMaterialsForProject(widget.projectId, date),
      ]);
      if (!mounted) return;
      setState(() {
        _plannedLabor = results[0] as List<Map<String, dynamic>>;
        _unfilteredPlannedLabor = results[1] as List<Map<String, dynamic>>;
        _plannedMachinery = results[2] as List<Map<String, dynamic>>;
        _plannedMaterials = results[3] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      debugPrint('Error reloading planned labor: $e');
    }
  }

  void _onLaborLogsChanged(List<Map<String, dynamic>> logs) {
    setState(() => _laborLogs = logs);
  }

  void _onMachineryLogsChanged(List<Map<String, dynamic>> logs) {
    setState(() => _machineryLogs = logs);
  }

  void _onMaterialUsageChanged(List<Map<String, dynamic>> usage) {
    setState(() => _materialUsage = usage);
  }

  Future<bool> _saveMachineryLogs() async {
    if (_reportId == null) return true;
    try {
      final valid = _machineryLogs
          .where((log) => log['operator_id'] != null && log['machinery_id'] != null)
          .toList();
      await ref.read(dailyReportServiceProvider).saveMachineryLogs(_reportId!, valid);
      return true;
    } catch (e) {
      debugPrint('Error saving machinery logs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving machinery: $e', style: GoogleFonts.manrope()), backgroundColor: AppTheme.errorRed),
        );
      }
      return false;
    }
  }

  Future<bool> _saveMaterialUsage() async {
    if (_reportId == null) return true;
    try {
      final valid = _materialUsage
          .where((u) => u['material_id'] != null)
          .toList();
      await ref.read(dailyReportServiceProvider).saveMaterialUsage(_reportId!, valid);
      return true;
    } catch (e) {
      debugPrint('Error saving material usage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving materials: $e', style: GoogleFonts.manrope()), backgroundColor: AppTheme.errorRed),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daily Report')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daily Report')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
              const SizedBox(height: 16),
              Text('Error loading report', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(_error!, style: GoogleFonts.manrope(color: AppTheme.slate500)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _initialize, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: Text(
            _projectName.isNotEmpty
                ? 'Daily Report — $_projectName — ${_reportData['report_date'] ?? ''}'
                : 'Daily Report — ${_reportData['report_date'] ?? ''}',
            style: GoogleFonts.manrope(fontSize: 14),
          ),
        actions: [
          if (_reportData['status'] == 'draft')
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: _isCompleted ? null : _saveDraft,
                icon: const Icon(Icons.save, size: 16),
                label: Text('Save Draft', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade600,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                ),
              ),
            ),
        ],
      ),
      body: CompletedProjectBanner(
        projectId: widget.projectId,
        isCompletedCallback: (completed) {
          if (completed != _isCompleted) setState(() => _isCompleted = completed);
        },
        child: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _currentStep > 0 ? () => setState(() => _currentStep--) : null,
        onStepTapped: (step) => setState(() => _currentStep = step),
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Row(
              children: [
                if (_currentStep < _steps.length - 1)
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: const Text('Next'),
                  ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: Text('Back', style: GoogleFonts.manrope(color: AppTheme.slate500, fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: Text('General', style: _stepTitleStyle(0)),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: StepGeneralInfo(
              reportData: _reportData,
              onChanged: _onReportDataChanged,
              isReadOnly: _reportData['status'] == 'approved' || _reportData['status'] == 'submitted',
            ),
          ),
          Step(
            title: Text('Crew', style: _stepTitleStyle(1)),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: StepLabor(
              plannedLabor: _plannedLabor,
              laborLogs: _laborLogs,
              workers: _workers,
              deviationReasons: _deviationReasons,
              isReadOnly: _reportData['status'] == 'approved' || _reportData['status'] == 'submitted',
              onLogsChanged: _onLaborLogsChanged,
              onNavigateToBaseline: _navigateToBaseline,
              stoppedAt: _reportData['stopped_at'] as String?,
            ),
          ),
          Step(
            title: Text('Machinery', style: _stepTitleStyle(2)),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: StepMachinery(
              projectId: widget.projectId,
              plannedMachinery: _plannedMachinery,
              machineryLogs: _machineryLogs,
              workers: _workers,
              deviationReasons: _deviationReasons,
              laborLogs: _laborLogs,
              plannedLabor: _unfilteredPlannedLabor,
              machineryCatalog: _machineryCatalog,
              isReadOnly: _reportData['status'] == 'approved' || _reportData['status'] == 'submitted',
              onLogsChanged: _onMachineryLogsChanged,
              onNavigateToBaseline: _navigateToBaseline,
              reportDate: _reportData['report_date'] as String?,
            ),
          ),
          Step(
            title: Text('Materials', style: _stepTitleStyle(3)),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.indexed,
            content: StepMaterials(
              projectId: widget.projectId,
              plannedMaterials: _plannedMaterials,
              materialUsage: _materialUsage,
              isReadOnly: _reportData['status'] == 'approved' || _reportData['status'] == 'submitted',
              onUsageChanged: _onMaterialUsageChanged,
            ),
          ),
          Step(
            title: Text('Review', style: _stepTitleStyle(4)),
            isActive: _currentStep >= 4,
            state: _currentStep > 4 ? StepState.complete : StepState.indexed,
            content: StepReviewSign(
              reportData: _reportData,
              laborLogs: _laborLogs,
              machineryLogs: _machineryLogs,
              materialUsage: _materialUsage,
              isReadOnly: _reportData['status'] == 'approved' || _reportData['status'] == 'submitted',
              onSubmit: _isCompleted ? () async {} : _handleSubmit,
            ),
          ),
        ],
      ),
      ),
    );
  }

  TextStyle _stepTitleStyle(int step) {
    final isCurrent = _currentStep == step;
    return GoogleFonts.manrope(
      fontSize: 13,
      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
      color: isCurrent ? AppTheme.primaryGreen : AppTheme.slate600,
    );
  }

  void _onStepContinue() async {
    setState(() => _currentStep++);
  }

  void _saveDraft() async {
    await _saveReportHeader();
    await _saveLaborLogs();
    final machOk = await _saveMachineryLogs();
    final matOk = await _saveMaterialUsage();
    if (!mounted) return;
    if (!machOk || !matOk) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Draft saved', style: GoogleFonts.manrope()),
        backgroundColor: AppTheme.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveCurrentStep() async {
    if (_currentStep == 0) await _saveReportHeader();
    if (_currentStep == 1) await _saveLaborLogs();
    if (_currentStep == 2) await _saveMachineryLogs();
    if (_currentStep == 3) await _saveMaterialUsage();
  }

  Future<void> _navigateToBaseline() async {
    final confirmed = await showSafeDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add resource to baseline'),
        content: const Text('The current progress will be saved as draft and the baseline module will open to add the resource.\n\nWhen you return, the planned resources will refresh.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _saveCurrentStep();
    if (!mounted) return;
    final reportDate = _reportData['report_date'] as String? ?? DateTime.now().toIso8601String().split('T')[0];
    await context.push('/projects/${widget.projectId}/baseline?reportDate=$reportDate');
    if (!mounted) return;
    await _refreshPlannedData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Resources refreshed. Assign workers for the new resources.', style: GoogleFonts.manrope()),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  Future<void> _refreshPlannedData() async {
    try {
      final service = ref.read(dailyReportServiceProvider);
      final date = _reportData['report_date'] as String? ?? DateTime.now().toIso8601String().split('T')[0];
      final results = await Future.wait([
        service.getPlannedLaborForProject(widget.projectId, date),
        service.getPlannedLaborForProject(widget.projectId, date, filterByDate: false),
        service.getPlannedMachineryForProject(widget.projectId, date),
        service.getPlannedMaterialsForProject(widget.projectId, date),
      ]);
      if (!mounted) return;
      setState(() {
        _plannedLabor = List<Map<String, dynamic>>.from(results[0] as List);
        _unfilteredPlannedLabor = List<Map<String, dynamic>>.from(results[1] as List);
        _plannedMachinery = List<Map<String, dynamic>>.from(results[2] as List);
        _plannedMaterials = List<Map<String, dynamic>>.from(results[3] as List);
      });
    } catch (e) {
      debugPrint('Error refreshing planned data: $e');
    }
  }

  Future<void> _handleSubmit() async {
    if (_reportId == null) return;
    await _saveReportHeader();
    await _saveLaborLogs();
    final machOk = await _saveMachineryLogs();
    final matOk = await _saveMaterialUsage();
    if (!machOk || !matOk) return;

    if (_reportData['disruption_active'] == true) {
      final laborIds = _laborLogs
          .map((l) => l['project_labor_id'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toList();
      if (laborIds.isNotEmpty) {
        final conflicts = await ref
            .read(dailyReportServiceProvider)
            .getDisruptionResourceConflicts(laborIds);
        if (conflicts.isNotEmpty && mounted) {
          final proceed = await showSafeDialog<bool>(
            context: context,
            builder: (ctx) => BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  width: 500,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 4)),
                      BoxShadow(color: Color(0x0F000000), blurRadius: 40, offset: Offset(0, 12)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: AppTheme.errorRed.withAlpha(25), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.warning_amber_rounded, size: 20, color: AppTheme.errorRed),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Disruption Service Conflict',
                              style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                            ),
                            const Spacer(),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(ctx),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(color: AppTheme.slate200.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                  child: const Icon(Icons.close, size: 18, color: AppTheme.slate400),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'This report logs hours for services that are marked as '
                                'TOTAL STOP in an active disruption Change Order:',
                                style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate700),
                              ),
                              const SizedBox(height: 16),
                              ...conflicts.map(
                                (c) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorRed.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.errorRed.withOpacity(0.15),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c['project_tasks']?['name'] ?? 'Unknown task',
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: AppTheme.slate900,
                                        ),
                                      ),
                                      Text(
                                        'CO #${c['change_orders']?['co_number'] ?? ''} — '
                                        '${c['change_orders']?['title'] ?? ''}',
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          color: AppTheme.slate500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Are you sure you want to submit this report?',
                                style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate700),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                          border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: Text('Review', style: GoogleFonts.manrope(color: AppTheme.slate500, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.errorRed,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                'Submit anyway',
                                style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          if (proceed != true) return;
        }
      }
    }

    try {
      await ref.read(dailyReportServiceProvider).submitReport(_reportId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report submitted for review', style: GoogleFonts.manrope()),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting: $e', style: GoogleFonts.manrope()),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  static const List<String> _steps = ['General', 'Crew', 'Machinery', 'Materials', 'Review'];
}
