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
import 'package:uuid/uuid.dart';
import '../utils/labor_segments.dart';
import '../utils/machinery_intervals.dart';
import '../widgets/labor_reassign_dialog.dart';
import '../widgets/daily_transfers_panel.dart';
import '../widgets/crew_report_review_dialog.dart';

class DailyReportWizardPage extends ConsumerStatefulWidget {
  final String projectId;
  final String? reportId;
  final DailyExecutionService? executionService;
  final AccessContext? accessContext;

  const DailyReportWizardPage({
    super.key,
    required this.projectId,
    this.reportId,
    this.executionService,
    this.accessContext,
  });

  @override
  ConsumerState<DailyReportWizardPage> createState() =>
      _DailyReportWizardPageState();
}

class _DailyReportWizardPageState extends ConsumerState<DailyReportWizardPage> {
  bool _isCompleted = false;
  int _currentStep = 0;
  bool _isInitializing = true;
  String? _error;

  String? _reportId;
  String _projectName = '';
  Map<String, dynamic> _reportData = {};
  Map<String, dynamic> _affectedServices = {};
  Map<String, dynamic> _machineryProgress = {};
  Map<String, dynamic> _transferContext = {};
  Map<String, dynamic> _breakContext = {};
  List<Map<String, dynamic>> _transfers = [];

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

  AccessContext _access = const AccessContext();
  String? _crewId;
  List<Map<String, dynamic>> _crews = [];
  List<Map<String, dynamic>> _sections = [];
  Map<String, dynamic>? _section;
  bool _hasSections = false;
  bool _legacyResources = false;
  bool _saving = false;
  bool _uploadingEvidence = false;
  bool get _busy => _saving || _uploadingEvidence;
  void _onUploadChanged(bool value) {
    if (mounted) setState(() => _uploadingEvidence = value);
  }

  bool _dirty = false;
  int _loadGeneration = 0;
  int _editorVersion = 0;
  int _scopePickerVersion = 0;
  final _sectionNotes = TextEditingController();
  List<Map<String, dynamic>> _signature = [];
  List<String> _photos = [];

  DailyExecutionService get _execution =>
      widget.executionService ??
      DailyExecutionService(Supabase.instance.client);
  bool get _sectionMode => _crewId != null;
  bool get _writeBlocked =>
      _isCompleted ||
      ['approved', 'submitted'].contains(_reportData['status']) ||
      (_sectionMode &&
          ['approved', 'submitted'].contains(_section?['status'])) ||
      (_access.isForeman && !_sectionMode);
  bool get _locked => _writeBlocked || _busy;
  bool get _resourceWriteBlocked =>
      _writeBlocked ||
      (!_sectionMode &&
          (_hasSections || _crews.isNotEmpty && !_legacyResources));
  bool get _resourcesReadOnly => _resourceWriteBlocked || _saving;

  @override
  void dispose() {
    _sectionNotes.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() {
      _isInitializing = true;
      _error = null;
    });
    try {
      _access =
          widget.accessContext ??
          await AccessService(Supabase.instance.client).load();
      await _loadDate(
        DateTime.now().toIso8601String().split('T')[0],
        reportId: widget.reportId,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _loadDate(
    String date, {
    String? reportId,
    String? crewId,
  }) async {
    final generation = ++_loadGeneration;
    setState(() {
      _isInitializing = true;
      _error = null;
    });
    try {
      final entry = await _execution.entry(
        widget.projectId,
        date,
        reportId: reportId,
      );
      final crews = DailyExecutionService.rows(entry['crews']);
      final legacy = entry['legacy_resources'] == true;
      final selected = legacy
          ? null
          : crewId ??
                (_access.isForeman && crews.isNotEmpty
                    ? crews.first['id'] as String
                    : null);
      final day = entry['date'] as String;
      if (selected != null && !crews.any((c) => c['id'] == selected)) {
        throw StateError('This crew is not authorized for the selected date.');
      }
      Map<String, dynamic> report = Map<String, dynamic>.from(
        entry['report'] as Map? ??
            {'report_date': day, 'day_type': 'working', 'status': 'draft'},
      );
      Map<String, dynamic>? section;
      var sections = <Map<String, dynamic>>[];
      var affected = <String, dynamic>{};
      var machineryProgress = <String, dynamic>{};
      var breakContext = <String, dynamic>{};
      final transferContext = selected != null || !_access.isForeman
          ? await _execution.transferContext(widget.projectId, day, selected)
          : <String, dynamic>{};
      final transfers = DailyExecutionService.rows(
        transferContext['transfers'],
      );
      List<List<Map<String, dynamic>>> resources;
      if (selected != null) {
        final workspace = await _execution.workspace(
          widget.projectId,
          day,
          selected,
        );
        machineryProgress = Map<String, dynamic>.from(
          workspace['machinery_progress'] as Map? ?? {},
        );
        breakContext = await _execution.breakContext(
          widget.projectId,
          day,
          selected,
        );
        section = workspace['section'] == null
            ? null
            : Map<String, dynamic>.from(workspace['section'] as Map);
        sections = DailyExecutionService.rows(workspace['sections']);
        final labor = DailyExecutionService.rows(workspace['labor']);
        for (final l in labor) {
          final net = (l['total_net_hours'] as num?)?.toDouble() ?? 0.0;
          l['regular_hours'] = net.clamp(0.0, 8.0).toDouble();
          l['overtime_hours'] = (net - 8)
              .clamp(0.0, double.infinity)
              .toDouble();
          l['total_net_hours'] = net;
        }
        final planned = withBorrowedWorkers(
          DailyExecutionService.rows(workspace['planned_labor']),
          DailyExecutionService.rows(workspace['workers']),
          transfers,
          selected,
          day,
        );
        resources = [
          labor,
          DailyExecutionService.rows(workspace['machinery']),
          DailyExecutionService.rows(workspace['materials']),
          planned,
          planned,
          DailyExecutionService.rows(workspace['planned_machinery']),
          DailyExecutionService.rows(workspace['planned_materials']),
          <Map<String, dynamic>>[],
          DailyExecutionService.rows(workspace['deviation_reasons']),
          DailyExecutionService.rows(workspace['workers']),
          <Map<String, dynamic>>[],
          <Map<String, dynamic>>[],
        ];
      } else if (_access.isForeman) {
        // Never issue unrestricted fallback queries when Foreman has no eligible crew.
        resources = List.generate(12, (_) => <Map<String, dynamic>>[]);
      } else {
        machineryProgress = {
          ...await _execution.machineryProgress(widget.projectId, day),
          // Consolidated inputs already contain every current-day section.
          'scope': 'report',
        };
        final service = ref.read(dailyReportServiceProvider);
        final id = report['id'] as String?;
        if (id != null) report = await service.getReportById(id);
        affected = await service.getActiveDisruptedServices(
          widget.projectId,
          day,
        );
        resources = await Future.wait([
          if (id != null)
            service.getLaborLogsForReport(id)
          else
            Future.value(<Map<String, dynamic>>[]),
          if (id != null)
            service.getMachineryLogsForReport(id)
          else
            Future.value(<Map<String, dynamic>>[]),
          if (id != null)
            service.getMaterialUsageForReport(id)
          else
            Future.value(<Map<String, dynamic>>[]),
          service.getPlannedLaborForProject(widget.projectId, day),
          service.getPlannedLaborForProject(
            widget.projectId,
            day,
            filterByDate: false,
          ),
          service.getPlannedMachineryForProject(widget.projectId, day),
          service.getPlannedMaterialsForProject(widget.projectId, day),
          Future.value(<Map<String, dynamic>>[]),
          service.getDeviationReasons(),
          ref.read(workersServiceProvider).getWorkers(),
          ref.read(catalogsServiceProvider).getMachinery(),
          ref.read(catalogsServiceProvider).getMaterials(),
        ]);
        if (entry['has_sections'] == true) {
          final data = await Supabase.instance.client
              .from('daily_report_sections')
              .select()
              .eq('daily_report_id', id!);
          sections = DailyExecutionService.rows(data);
        }
      }
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _crewId = selected;
        _crews = crews;
        _section = section;
        _sections = sections;
        _hasSections = entry['has_sections'] == true;
        _legacyResources = legacy;
        _reportId = report['id'] as String?;
        _reportData = report;
        _affectedServices = affected;
        _machineryProgress = machineryProgress;
        _transferContext = transferContext;
        _breakContext = breakContext;
        _transfers = transfers;
        _projectName = entry['project']['title'] as String? ?? '';
        _isCompleted = entry['project']['status'] != 'active';
        _laborLogs = resources[0];
        _machineryLogs = resources[1];
        _materialUsage = resources[2];
        _plannedLabor = resources[3];
        _unfilteredPlannedLabor = resources[4];
        _plannedMachinery = resources[5];
        _plannedMaterials = resources[6];
        _deviationReasons = resources[8];
        _workers = resources[9];
        for (final worker in _workers) {
          if (_sectionMode) worker['role'] = worker['labor_roles'];
        }
        _machineryCatalog = resources[10];
        _materialsCatalog = resources[11];
        _sectionNotes.text = section?['notes'] as String? ?? '';
        _signature = DailyExecutionService.rows(section?['signature_points']);
        _photos = (section?['evidence_photos'] as List? ?? []).cast<String>();
        _editorVersion++;
        _dirty = false;
        _isInitializing = false;
      });
    } catch (e) {
      if (mounted && generation == _loadGeneration) {
        setState(() {
          _error = e.toString();
          _isInitializing = false;
        });
      }
    }
  }

  Future<bool> _confirmDiscard() async {
    if (_busy) return false;
    if (!_dirty) return true;
    return await showSafeDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Unsaved changes'),
            content: const Text(
              'Save your changes before continuing, or discard them.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep editing'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Discard changes'),
              ),
            ],
          ),
        ) ==
        true;
  }

  Future<void> _changeScope({String? date, String? crewId}) async {
    if (_busy) return;
    if (!await _confirmDiscard() || !mounted) {
      if (mounted) setState(() => _scopePickerVersion++);
      return;
    }
    setState(() => _dirty = false);
    await _loadDate(
      date ?? _reportData['report_date'] as String,
      crewId: crewId,
    );
  }

  Future<bool> _saveSection({bool submit = false}) async {
    if (_locked || !_sectionMode) return false;
    setState(() => _saving = true);
    try {
      // Do not silently filter unfinished entries as the legacy writer does.
      if (_laborLogs.any(
        (l) =>
            l['worker_id'] == null ||
            l['project_labor_id'] == null ||
            l['check_in_time'] == null,
      )) {
        throw StateError(
          'Complete the worker, service and check-in time for every attendance segment.',
        );
      }
      for (var i = 0; i < _machineryLogs.length; i++) {
        final error = machineryIntervalError(
          _machineryLogs[i],
          _machineryLogs,
          _laborLogs,
        );
        if (error != null)
          throw StateError('Machinery interval ${i + 1}: $error');
      }
      final section =
          _section ??
          await _execution.open(
            widget.projectId,
            _reportData['report_date'] as String,
            _crewId!,
          );
      // Retain the server identity if creation succeeds but validation/save fails.
      if (mounted) {
        setState(() {
          _section = section;
          _reportId = section['daily_report_id'] as String;
          _hasSections = true;
        });
      }
      final saved = await _execution.save(
        section: section,
        notes: _sectionNotes.text,
        labor: _laborLogs,
        machinery: _machineryLogs,
        materials: _materialUsage,
        signature: _signature,
        photos: _photos,
        submit: submit,
      );
      if (!mounted) return true;
      setState(() {
        _section = saved;
        _dirty = false;
      });
      await _loadDate(_reportData['report_date'] as String, crewId: _crewId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              submit ? 'Crew report submitted for review' : 'Crew report saved',
            ),
          ),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save crew report: $e')),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _transferMessage(Object error) {
    if (!mounted) return;
    final message = error is PostgrestException
        ? error.message
        : error.toString();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _reassignWorker(Map<String, dynamic> entry) async {
    if (_locked || _crewId == null) return;
    final checkout = entry['check_out_time'] as String?;
    if (checkout == null || checkout.isEmpty) {
      _transferMessage(
        'Set the current segment’s check-out time before reassigning the worker.',
      );
      return;
    }
    final day = _reportData['report_date'] as String;
    final crew = _crewId!;
    final worker = entry['worker_id'] as String;
    final names = _workers.where((w) => w['id'] == worker);
    final choice = await showSafeDialog<LaborReassignment>(
      context: context,
      builder: (_) => LaborReassignDialog(
        crew: crew,
        labor: entry['project_labor_id'] as String,
        workerName: names.isEmpty
            ? 'worker'
            : names.first['full_name'] as String? ?? 'worker',
        initialStart: checkout,
        borrowed: entry['transfer_id'] != null,
        crews: DailyExecutionService.rows(_transferContext['crews']),
        laborOptions: DailyExecutionService.rows(_transferContext['labor']),
      ),
    );
    if (choice == null || !mounted) return;
    if (_laborLogs.any(
      (row) => overlapsSegment(row, worker, choice.start, choice.end),
    )) {
      _transferMessage(
        'The selected interval overlaps existing attendance. Adjust the times first.',
      );
      return;
    }
    if (choice.crew == crew) {
      final loanId = entry['transfer_id'] as String?;
      final matching = _transfers.where((t) => t['id'] == loanId);
      if (loanId != null &&
          (matching.isEmpty ||
              timeMinutes(choice.start) <
                  timeMinutes(matching.first['starts_at'] as String) ||
              timeMinutes(choice.end) >
                  timeMinutes(matching.first['ends_at'] as String))) {
        _transferMessage(
          'A borrowed worker must stay within the authorized loan interval.',
        );
        return;
      }
      if (_transfers.any(
        (t) =>
            t['status'] == 'approved' &&
            t['id'] != loanId &&
            overlapsSegment(
              {
                'worker_id': t['worker_id'],
                'check_in_time': t['starts_at'],
                'check_out_time': t['ends_at'],
              },
              worker,
              choice.start,
              choice.end,
            ),
      )) {
        _transferMessage(
          'The worker is assigned to another crew during this interval.',
        );
        return;
      }
      final row = newLaborSegment(
        id: const Uuid().v4(),
        worker: worker,
        labor: choice.labor,
        start: choice.start,
        end: choice.end,
        reason: choice.reason,
        transfer: loanId,
      );
      final assigned = _plannedLabor.where((l) => l['id'] == choice.labor);
      row['is_unplanned'] =
          assigned.isEmpty ||
          !(assigned.first['project_labor_assignments'] as List? ?? []).any(
            (a) => a['worker_id'] == worker,
          );
      setState(() {
        _laborLogs = [..._laborLogs, row];
        reconcileAutomaticLaborBreaks(_laborLogs, _breakContext);
        _dirty = true;
      });
      return;
    }
    // Persist closed origin attendance before requesting authorization.
    if (!await _saveSection() || !mounted) return;
    setState(() => _saving = true);
    try {
      final id = await _execution.requestTransfer(
        report: _reportId!,
        worker: worker,
        crew: choice.crew,
        labor: choice.labor,
        start: choice.start,
        end: choice.end,
        reason: choice.reason,
      );
      if (_access.isAdmin || _access.isSupervisor)
        await _execution.reviewTransfer(id, true);
      _transferMessage(
        _access.isForeman
            ? 'Temporary loan requested. Awaiting authorization.'
            : 'Temporary loan authorized.',
      );
    } catch (e) {
      _transferMessage(e);
    } finally {
      if (mounted) await _loadDate(day, crewId: crew);
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _transferAction(
    Map<String, dynamic> transfer,
    String action,
  ) async {
    if (_busy || !await _confirmDiscard() || !mounted) return;
    String? cancellation;
    if (action == 'cancel') {
      final input = TextEditingController();
      cancellation = await showSafeDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cancel temporary loan'),
          content: TextField(
            controller: input,
            decoration: const InputDecoration(labelText: 'Reason (required)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: () {
                if (input.text.trim().isNotEmpty)
                  Navigator.pop(ctx, input.text.trim());
              },
              child: const Text('Cancel loan'),
            ),
          ],
        ),
      );
      input.dispose();
      if (cancellation == null || !mounted) return;
    }
    setState(() => _saving = true);
    try {
      if (action == 'cancel') {
        await _execution.cancelTransfer(
          transfer['id'] as String,
          cancellation!,
        );
      } else {
        await _execution.reviewTransfer(
          transfer['id'] as String,
          action == 'approve',
        );
      }
      if (mounted) {
        _dirty = false;
        await _loadDate(_reportData['report_date'] as String, crewId: _crewId);
      }
    } catch (e) {
      _transferMessage(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _crewStatusLabel(String? status) => switch (status) {
    null => 'Not started',
    'draft' => 'Draft',
    'submitted' => 'Submitted',
    'approved' => 'Approved',
    'returned' => 'Returned',
    _ => status,
  };

  Widget _buildCrewPicker() => SizedBox(
    width: 240,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _access.isForeman ? 'Crew' : 'Report scope',
          key: const ValueKey('report-scope-label'),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey('scope-$_editorVersion-$_scopePickerVersion'),
          initialValue: _crewId,
          isExpanded: true,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          hint: Text(
            _access.isForeman
                ? 'No crew available'
                : 'Project consolidated report',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          items: [
            if (!_access.isForeman)
              const DropdownMenuItem<String>(
                value: null,
                child: Text(
                  'Project consolidated report',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ..._crews.map(
              (c) => DropdownMenuItem<String>(
                value: c['id'] as String,
                enabled: !_legacyResources,
                child: Text(
                  c['name'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: _busy || _legacyResources
              ? null
              : (value) => _changeScope(crewId: value),
        ),
      ],
    ),
  );

  Widget _buildScopeControls() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          OutlinedButton.icon(
            key: const ValueKey('report-date'),
            onPressed: _busy
                ? null
                : () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.parse(
                        _reportData['report_date'] as String,
                      ),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (date != null && mounted) {
                      await _changeScope(
                        date: date.toIso8601String().split('T')[0],
                        crewId: _crewId,
                      );
                    }
                  },
            icon: const Icon(Icons.calendar_month),
            label: Text(_reportData['report_date'] as String),
          ),
          _buildCrewPicker(),
          if (_sectionMode)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  label: Text(
                    'Crew: ${_crewStatusLabel(_section?['status'] as String?)}',
                  ),
                ),
                if (_section != null && _canReviewSection(_section!))
                  _buildCrewReviewActions(_section!),
              ],
            ),
        ],
      ),
      const SizedBox(height: 12),
      if (_legacyResources)
        const Text(
          'This report uses the previous entry format. Continue in the consolidated report; existing entries will not be assigned to crews automatically.',
        ),
      if (!_sectionMode && !_legacyResources && _crews.isNotEmpty)
        const Text(
          'Select a crew to record resources. Manage general information and the final review in the consolidated report.',
        ),
      if (_access.isForeman && !_sectionMode)
        const Text(
          'No editable crew report is available for this date. Contact your supervisor about previous reports.',
        ),
      if (_sectionMode) ...[
        const Text(
          'General information applies to the project. Record only the selected crew’s work here.',
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('section-notes'),
          controller: _sectionNotes,
          readOnly: _locked,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Crew notes'),
          onChanged: (_) => setState(() => _dirty = true),
        ),
        if (_section?['review_notes'] != null)
          Text('Review: ${_section!['review_notes']}'),
      ],
      if (!_access.isForeman)
        ..._sections
            .where((s) => s['crew_id'] != _crewId)
            .map(_buildSectionReview),
      DailyTransfersPanel(
        transfers: _transfers,
        canReview: _access.isAdmin || _access.isSupervisor,
        readOnly:
            _busy ||
            _isCompleted ||
            ['approved', 'submitted'].contains(_reportData['status']),
        currentUser: _execution.currentUserId,
        onAction: _transferAction,
      ),
      const SizedBox(height: 16),
    ],
  );

  bool _canReviewSection(Map<String, dynamic> section) =>
      (_access.isAdmin || _access.isSupervisor) &&
      !_isCompleted &&
      !_busy &&
      ['draft', 'rejected'].contains(_reportData['status']) &&
      section['status'] == 'submitted' &&
      section['created_by'] != _execution.currentUserId &&
      section['last_saved_by'] != _execution.currentUserId;

  Widget _buildCrewReviewActions(Map<String, dynamic> section) => Wrap(
    spacing: 4,
    runSpacing: 4,
    children: [
      TextButton.icon(
        onPressed: () => _reviewSection(section, true),
        icon: const Icon(Icons.check_circle_outline, size: 18),
        label: const Text('Approve crew report'),
      ),
      TextButton.icon(
        onPressed: () => _reviewSection(section, false),
        icon: const Icon(Icons.undo, size: 18),
        label: const Text('Return for correction'),
      ),
    ],
  );

  Widget _buildSectionReview(Map<String, dynamic> section) {
    final crew = _crews.where((c) => c['id'] == section['crew_id']);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TextButton(
            onPressed: _busy
                ? null
                : () => _changeScope(crewId: section['crew_id'] as String?),
            child: Text(
              crew.isEmpty ? 'No crew' : crew.first['name'] as String,
            ),
          ),
          Chip(label: Text(_crewStatusLabel(section['status'] as String?))),
          if (_canReviewSection(section)) _buildCrewReviewActions(section),
        ],
      ),
    );
  }

  Future<void> _reviewSection(
    Map<String, dynamic> section,
    bool approve,
  ) async {
    if (!await _confirmDiscard() || !mounted) return;
    final reviewReason = await showSafeDialog<String>(
      context: context,
      builder: (_) => CrewReportReviewDialog(approve: approve),
    );
    if (reviewReason == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await _execution.review(
        section['id'] as String,
        approve: approve,
        reason: reviewReason,
      );
      await _loadDate(_reportData['report_date'] as String, crewId: _crewId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not review crew report: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _saveReportHeader() async {
    if (_sectionMode || _access.isForeman || _writeBlocked) return true;
    try {
      if (_reportId == null) {
        final report = await _execution.ensureReport(
          widget.projectId,
          _reportData['report_date'] as String,
        );
        _reportId = report['id'] as String;
      }
      if ((_reportData['report_date'] as String? ?? '').isEmpty) return false;
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
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save report information: $e')),
        );
      }
      return false;
    }
  }

  Future<void> _syncNonWorkingDays() async {
    final dayType = _reportData['day_type'] as String? ?? 'working';
    final reportDate = _reportData['report_date'] as String?;
    if (reportDate == null || reportDate.isEmpty) return;

    final client = Supabase.instance.client;

    if (dayType == 'working') {
      await client
          .from('project_non_working_days')
          .delete()
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

  Future<bool> _saveLaborLogs() async {
    if (_resourceWriteBlocked || _sectionMode || _reportId == null) return true;
    try {
      await ref
          .read(dailyReportServiceProvider)
          .saveLaborLogs(
            _reportId!,
            _laborLogs
                .where(
                  (log) =>
                      log['worker_id'] != null && log['check_in_time'] != null,
                )
                .toList(),
          );
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save labor entries: $e')),
        );
      }
      return false;
    }
  }

  void _onReportDataChanged(Map<String, dynamic> data) {
    final oldDate = _reportData['report_date'];
    final newDate = data['report_date'];
    if (oldDate != newDate &&
        newDate != null &&
        (newDate as String).isNotEmpty) {
      _switchToDate(newDate);
      return;
    }
    setState(() {
      _reportData = data;
      _dirty = true;
    });
  }

  Future<void> _switchToDate(String date) =>
      _changeScope(date: date, crewId: _crewId);

  void _onLaborLogsChanged(List<Map<String, dynamic>> logs) {
    setState(() {
      _laborLogs = logs;
      _dirty = true;
    });
  }

  void _onMachineryLogsChanged(List<Map<String, dynamic>> logs) {
    setState(() {
      _machineryLogs = logs;
      _dirty = true;
    });
  }

  void _onMaterialUsageChanged(List<Map<String, dynamic>> usage) {
    setState(() {
      _materialUsage = usage;
      _dirty = true;
    });
  }

  Future<bool> _saveMachineryLogs() async {
    if (_resourceWriteBlocked || _sectionMode || _reportId == null) return true;
    try {
      final valid = _machineryLogs
          .where(
            (log) => log['operator_id'] != null && log['machinery_id'] != null,
          )
          .toList();
      await ref
          .read(dailyReportServiceProvider)
          .saveMachineryLogs(_reportId!, valid);
      return true;
    } catch (e) {
      debugPrint('Error saving machinery logs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving machinery: $e',
              style: GoogleFonts.manrope(),
            ),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
      return false;
    }
  }

  Future<bool> _saveMaterialUsage() async {
    if (_resourceWriteBlocked || _sectionMode || _reportId == null) return true;
    try {
      final valid = _materialUsage
          .where((u) => u['material_id'] != null)
          .toList();
      await ref
          .read(dailyReportServiceProvider)
          .saveMaterialUsage(_reportId!, valid);
      return true;
    } catch (e) {
      debugPrint('Error saving material usage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving materials: $e',
              style: GoogleFonts.manrope(),
            ),
            backgroundColor: AppTheme.errorRed,
          ),
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
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorRed,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading report',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: GoogleFonts.manrope(color: AppTheme.slate500),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initialize,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: !_dirty && !_busy,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _busy) return;
        if (await _confirmDiscard() && context.mounted) {
          setState(() => _dirty = false);
          if (context.canPop()) context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _confirmDiscard() && context.mounted) {
                setState(() => _dirty = false);
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/projects/${widget.projectId}/daily-reports');
                }
              }
            },
          ),
          title: Text(
            _projectName.isNotEmpty
                ? 'Daily Report — $_projectName — ${_reportData['report_date'] ?? ''}'
                : 'Daily Report — ${_reportData['report_date'] ?? ''}',
            style: GoogleFonts.manrope(fontSize: 14),
          ),
          actions: [
            if (!_locked && (!_access.isForeman || _sectionMode))
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed: _locked ? null : _saveDraft,
                  icon: const Icon(Icons.save, size: 16),
                  label: Text(
                    'Save Draft',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade600,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
          ],
        ),
        body: CompletedProjectBanner(
          key: ValueKey('project-status-$_editorVersion'),
          knownReadOnly: _isCompleted,
          projectId: widget.projectId,
          isCompletedCallback: (completed) {
            if (completed != _isCompleted) {
              setState(() => _isCompleted = completed);
            }
          },
          child: AbsorbPointer(
            absorbing: _busy,
            child: Stepper(
              currentStep: _currentStep,
              onStepContinue: _onStepContinue,
              onStepCancel: _currentStep > 0
                  ? () => setState(() => _currentStep--)
                  : null,
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
                          child: Text(
                            'Back',
                            style: GoogleFonts.manrope(
                              color: AppTheme.slate500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
                  state: _currentStep > 0
                      ? StepState.complete
                      : StepState.indexed,
                  content: Column(
                    children: [
                      _buildScopeControls(),
                      if ([
                        ..._laborLogs,
                        ..._machineryLogs,
                        ..._materialUsage,
                      ].any((l) => l['crew_report_id'] != null))
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            'This report includes approved crew contributions. Sections containing contributions are read-only to preserve their authorship, hours and history.',
                          ),
                        ),
                      StepGeneralInfo(
                        reportData: _reportData,
                        onChanged: _onReportDataChanged,
                        isReadOnly: _locked || _sectionMode,
                      ),
                    ],
                  ),
                ),
                Step(
                  title: Text('Crew', style: _stepTitleStyle(1)),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1
                      ? StepState.complete
                      : StepState.indexed,
                  content: StepLabor(
                    // Crew reports use the same automatic break policy as
                    // consolidated reports; daily OT is only a display value.
                    key: ValueKey('labor-$_editorVersion'),
                    plannedLabor: _plannedLabor,
                    executionCrewId: _crewId,
                    breakContext: _breakContext,
                    transfers: _transfers,
                    onReassign: _sectionMode && !_resourcesReadOnly
                        ? _reassignWorker
                        : null,
                    laborLogs: _laborLogs,
                    workers: _workers,
                    deviationReasons: _deviationReasons,
                    isReadOnly:
                        _resourcesReadOnly ||
                        _laborLogs.any((l) => l['crew_report_id'] != null),
                    onLogsChanged: _onLaborLogsChanged,
                    onNavigateToBaseline: _sectionMode
                        ? null
                        : _navigateToBaseline,
                    stoppedAt: _reportData['stopped_at'] as String?,
                    affectedServices: _affectedServices,
                  ),
                ),
                Step(
                  title: Text('Machinery', style: _stepTitleStyle(2)),
                  isActive: _currentStep >= 2,
                  state: _currentStep > 2
                      ? StepState.complete
                      : StepState.indexed,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_legacyResources &&
                          _crews.isNotEmpty &&
                          !_access.isForeman)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCrewPicker(),
                              if (!_sectionMode && !_writeBlocked) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'This is the consolidated view. Select a crew to add or edit machinery for the report date.',
                                ),
                              ],
                            ],
                          ),
                        ),
                      StepMachinery(
                        key: ValueKey('machinery-$_editorVersion'),
                        operationalMode: _sectionMode,
                        canEditRates: _access.isAdmin,
                        progressSnapshot: _machineryProgress,
                        onUploadStateChanged: _onUploadChanged,
                        projectId: widget.projectId,
                        plannedMachinery: _plannedMachinery,
                        machineryLogs: _machineryLogs,
                        workers: _workers,
                        deviationReasons: _deviationReasons,
                        laborLogs: _laborLogs,
                        plannedLabor: _unfilteredPlannedLabor,
                        machineryCatalog: _machineryCatalog,
                        isReadOnly:
                            _resourcesReadOnly ||
                            _machineryLogs.any(
                              (l) => l['crew_report_id'] != null,
                            ),
                        onLogsChanged: _onMachineryLogsChanged,
                        onNavigateToBaseline: _sectionMode
                            ? null
                            : _navigateToBaseline,
                        reportDate: _reportData['report_date'] as String?,
                        affectedServices: _affectedServices,
                      ),
                    ],
                  ),
                ),
                Step(
                  title: Text('Materials', style: _stepTitleStyle(3)),
                  isActive: _currentStep >= 3,
                  state: _currentStep > 3
                      ? StepState.complete
                      : StepState.indexed,
                  content: StepMaterials(
                    key: ValueKey('materials-$_editorVersion'),
                    loadProjectTotals: !_sectionMode,
                    projectId: widget.projectId,
                    plannedMaterials: _plannedMaterials,
                    materialUsage: _materialUsage,
                    isReadOnly:
                        _resourcesReadOnly ||
                        _materialUsage.any((l) => l['crew_report_id'] != null),
                    onUsageChanged: _onMaterialUsageChanged,
                    affectedServices: _affectedServices,
                  ),
                ),
                Step(
                  title: Text('Review', style: _stepTitleStyle(4)),
                  isActive: _currentStep >= 4,
                  state: _currentStep > 4
                      ? StepState.complete
                      : StepState.indexed,
                  content: StepReviewSign(
                    key: ValueKey('review-$_editorVersion'),
                    onUploadStateChanged: _onUploadChanged,
                    initialSignature: _signature,
                    initialPhotos: _photos,
                    onEvidenceChanged: _sectionMode
                        ? (signature, photos) {
                            setState(() {
                              _signature = signature;
                              _photos = photos;
                              _dirty = true;
                            });
                          }
                        : null,
                    submitLabel: _sectionMode
                        ? 'Submit crew report for review'
                        : null,
                    reportData: _reportData,
                    laborLogs: _laborLogs,
                    machineryLogs: _machineryLogs,
                    materialUsage: _materialUsage,
                    isReadOnly: _writeBlocked || _saving,
                    onSubmit: _isCompleted ? () async {} : _handleSubmit,
                  ),
                ),
              ],
            ),
          ),
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

  Future<bool> _saveLegacyDraft() async {
    if (_locked || _access.isForeman) return false;
    setState(() => _saving = true);
    try {
      if (!await _saveReportHeader() ||
          !await _saveLaborLogs() ||
          !await _saveMachineryLogs() ||
          !await _saveMaterialUsage()) {
        return false;
      }
      if (mounted) setState(() => _dirty = false);
      return true;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _saveDraft() async {
    if (_sectionMode) {
      await _saveSection();
      return;
    }
    if (await _saveLegacyDraft() && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Draft saved')));
    }
  }

  Future<bool> _saveCurrentStep() async =>
      _sectionMode ? _saveSection() : _saveLegacyDraft();

  Future<void> _navigateToBaseline() async {
    final confirmed = await showSafeDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add resource to baseline'),
        content: const Text(
          'The current progress will be saved as draft and the baseline module will open to add the resource.\n\nWhen you return, the planned resources will refresh.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!await _saveCurrentStep()) return;
    if (!mounted) return;
    final reportDate =
        _reportData['report_date'] as String? ??
        DateTime.now().toIso8601String().split('T')[0];
    await context.push(
      '/projects/${widget.projectId}/baseline?reportDate=$reportDate',
    );
    if (!mounted) return;
    await _refreshPlannedData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Resources refreshed. Assign workers for the new resources.',
          style: GoogleFonts.manrope(),
        ),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  Future<void> _refreshPlannedData() async {
    try {
      final service = ref.read(dailyReportServiceProvider);
      final date =
          _reportData['report_date'] as String? ??
          DateTime.now().toIso8601String().split('T')[0];
      final results = await Future.wait([
        service.getPlannedLaborForProject(widget.projectId, date),
        service.getPlannedLaborForProject(
          widget.projectId,
          date,
          filterByDate: false,
        ),
        service.getPlannedMachineryForProject(widget.projectId, date),
        service.getPlannedMaterialsForProject(widget.projectId, date),
      ]);
      if (!mounted) return;
      setState(() {
        _plannedLabor = List<Map<String, dynamic>>.from(results[0] as List);
        _unfilteredPlannedLabor = List<Map<String, dynamic>>.from(
          results[1] as List,
        );
        _plannedMachinery = List<Map<String, dynamic>>.from(results[2] as List);
        _plannedMaterials = List<Map<String, dynamic>>.from(results[3] as List);
      });
    } catch (e) {
      debugPrint('Error refreshing planned data: $e');
    }
  }

  /// Services affected by an active disruption CO that also have logged
  /// activity (labor, machinery or material) in this report.
  List<Map<String, dynamic>> _loggedAffectedServices() {
    if (_affectedServices.isEmpty) return [];
    final laborQs = <String, String>{
      for (final pl in _unfilteredPlannedLabor)
        if (pl['id'] != null && pl['quote_service_id'] != null)
          pl['id'] as String: pl['quote_service_id'] as String,
    };
    final machineryQs = <String, String>{
      for (final pm in _plannedMachinery)
        if (pm['id'] != null && pm['quote_service_id'] != null)
          pm['id'] as String: pm['quote_service_id'] as String,
    };
    final materialQs = <String, String>{
      for (final pm in _plannedMaterials)
        if (pm['id'] != null && pm['quote_service_id'] != null)
          pm['id'] as String: pm['quote_service_id'] as String,
    };

    final logged = <String>{};
    for (final l in _laborLogs) {
      final pid = l['project_labor_id'] as String?;
      if (pid != null) {
        final qs = laborQs[pid];
        if (qs != null) logged.add(qs);
      }
    }
    for (final m in _machineryLogs) {
      final pid = m['project_machinery_id'] as String?;
      if (pid != null) {
        final qs = machineryQs[pid];
        if (qs != null) logged.add(qs);
      }
    }
    for (final u in _materialUsage) {
      final pid = u['project_material_id'] as String?;
      if (pid != null) {
        final qs = materialQs[pid];
        if (qs != null) logged.add(qs);
      }
    }

    final result = <Map<String, dynamic>>[];
    for (final qsId in logged) {
      final svc = _affectedServices[qsId] as Map<String, dynamic>?;
      if (svc == null) continue;
      result.add({
        'task_name': svc['task_name'],
        'affectation_type': svc['affectation_type'],
        'change_orders': {
          'co_number': svc['co_number'],
          'title': svc['co_title'],
        },
      });
    }
    return result;
  }

  String _affectationLabel(String? type) {
    switch (type) {
      case 'total_stop':
        return 'TOTAL STOP';
      case 'partial':
        return 'PARTIAL';
      case 'indirect':
        return 'INDIRECT';
      default:
        return '';
    }
  }

  Future<void> _handleSubmit() async {
    if (_sectionMode) {
      await _saveSection(submit: true);
      return;
    }
    if (!await _saveLegacyDraft()) return;

    final conflicts = _loggedAffectedServices();
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
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 40,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFF1F5F9)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            size: 20,
                            color: AppTheme.errorRed,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Disruption Service Conflict',
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.slate900,
                          ),
                        ),
                        const Spacer(),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.slate200.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: AppTheme.slate400,
                              ),
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
                            'This report logs activity for services affected by an '
                            'active disruption Change Order:',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: AppTheme.slate700,
                            ),
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
                                    c['task_name'] ?? 'Unknown service',
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppTheme.slate900,
                                    ),
                                  ),
                                  Text(
                                    'CO #${c['change_orders']?['co_number'] ?? ''} — '
                                    '${c['change_orders']?['title'] ?? ''}'
                                    '${c['affectation_type'] != null ? ' · ${_affectationLabel(c['affectation_type'] as String?)}' : ''}',
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
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: AppTheme.slate700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(
                            'Review',
                            style: GoogleFonts.manrope(
                              color: AppTheme.slate500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Submit anyway',
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
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

    if (!mounted) return;
    setState(() => _saving = true);
    try {
      await ref.read(dailyReportServiceProvider).submitReport(_reportId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Report submitted for review',
            style: GoogleFonts.manrope(),
          ),
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static const List<String> _steps = [
    'General',
    'Crew',
    'Machinery',
    'Materials',
    'Review',
  ];
}
