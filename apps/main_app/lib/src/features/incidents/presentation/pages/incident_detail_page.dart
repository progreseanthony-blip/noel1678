import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import '../widgets/incident_status_badge.dart';
import '../widgets/incident_priority_badge.dart';
import '../widgets/affected_items_section.dart';
import '../widgets/incident_action_timeline.dart';

class IncidentDetailPage extends ConsumerStatefulWidget {
  final String projectId;
  final String incidentId;

  const IncidentDetailPage({super.key, required this.projectId, required this.incidentId});

  @override
  ConsumerState<IncidentDetailPage> createState() => _IncidentDetailPageState();
}

class _IncidentDetailPageState extends ConsumerState<IncidentDetailPage> {
  Map<String, dynamic>? _incident;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(incidentsServiceProvider);
      _incident = await service.getById(widget.incidentId);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _addAction() async {
    final ctrl = TextEditingController();
    final result = await showSafeDialog<Map<String, dynamic>>(
      context: context,
      fullscreenOnMobile: true,
      builder: (ctx) {
        DateTime? dueDate;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Add Action'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Describe the action...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (v) => Navigator.pop(ctx, {
                    'description': v.trim(),
                    'due_date': dueDate?.toUtc().toIso8601String(),
                  }),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: Text(
                      dueDate != null
                          ? 'Due: ${dueDate!.year}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}'
                          : 'Due date (optional)',
                      style: GoogleFonts.manrope(fontSize: 13, color: dueDate != null ? AppTheme.slate900 : AppTheme.slate400),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: dueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setDialogState(() => dueDate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(dueDate != null ? 'Change' : 'Pick Date', style: GoogleFonts.manrope(fontSize: 12)),
                  ),
                ]),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, {
                  'description': ctrl.text.trim(),
                  'due_date': dueDate?.toUtc().toIso8601String(),
                }),
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
    if (result == null || (result['description'] as String).trim().isEmpty) return;
    try {
      await ref.read(incidentsServiceProvider).addAction(widget.incidentId, {
        'description': (result['description'] as String).trim(),
        if (result['due_date'] != null) 'due_date': result['due_date'],
      });
      await _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _completeAction(String actionId) async {
    try {
      await ref.read(incidentsServiceProvider).completeAction(actionId);
      await _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteAction(String actionId) async {
    final confirmed = await showSafeDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Action'),
        content: const Text('Remove this action? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(incidentsServiceProvider).deleteAction(actionId);
      await _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action deleted'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _resolveIncident() async {
    final solutionCtrl = TextEditingController();
    final result = await showSafeDialog<Map<String, String>>(
      context: context,
      fullscreenOnMobile: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Incident'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Describe the solution applied:'),
            const SizedBox(height: 12),
            TextField(
              controller: solutionCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'What was done to resolve this incident?',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, {'solution': solutionCtrl.text.trim()}),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
    if (result == null) return;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      await ref.read(incidentsServiceProvider).update(widget.incidentId, {
        'status': 'resolved',
        'ended_at': DateTime.now().toUtc().toIso8601String(),
        'resolved_by': userId,
        'resolved_at': DateTime.now().toUtc().toIso8601String(),
        'resolution_notes': result['solution'] ?? '',
      });
      await _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incident resolved'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _closeIncident() async {
    final notesCtrl = TextEditingController();
    final notes = await showSafeDialog<String>(
      context: context,
      fullscreenOnMobile: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Incident'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Additional closing notes (optional):'),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Final observations...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, notesCtrl.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.slate700),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    if (notes == null) return;
    try {
      final existing = _incident!['resolution_notes'] as String? ?? '';
      final combined = [if (existing.isNotEmpty) existing, if (notes.isNotEmpty) notes].join('\n---\n');
      await ref.read(incidentsServiceProvider).update(widget.incidentId, {
        'status': 'closed',
        'resolution_notes': combined,
      });
      await _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incident closed'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showFullScreenPhoto(String url) {
    showSafeDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              height: 200,
              color: AppTheme.slate200,
              child: const Center(child: Icon(Icons.broken_image, size: 64, color: AppTheme.slate400)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _startProgress() async {
    final confirmed = await showSafeDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Progress'),
        content: const Text('Move this incident to In Progress?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
            child: const Text('Start'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(incidentsServiceProvider).update(widget.incidentId, {'status': 'in_progress'});
      await _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incident in progress'), backgroundColor: Colors.blue));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    if (_incident == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Not found')));

    final i = _incident!;
    final category = i['incident_categories'] as Map<String, dynamic>?;
    final catName = category?['name'] as String? ?? 'General';
    final reporter = i['reported_by_profile'] as Map<String, dynamic>?;
    final reporterName = reporter?['name'] as String? ?? 'Unknown';
    final resolver = i['resolved_by_profile'] as Map<String, dynamic>?;
    final resolvedAt = i['resolved_at'] as String?;
    final items = List<Map<String, dynamic>>.from(i['incident_affected_items'] ?? []);
    final actions = List<Map<String, dynamic>>.from(i['incident_actions'] ?? []);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final photos = List<String>.from((i['evidence_photos'] as List?)?.map((p) => p.toString()) ?? []);
    final status = i['status'] as String? ?? 'open';
    final isOpen = status == 'open' || status == 'in_progress';
    final isResolved = status == 'resolved';
    final isClosed = status == 'closed';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(i['title'] as String? ?? '', style: GoogleFonts.manrope(fontSize: 14)),
            Text('Incident Details', style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate400)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section('Category & Status', [
              Row(children: [
                IncidentStatusBadge(status: i['status'] as String? ?? 'open'),
                const SizedBox(width: 8),
                IncidentPriorityBadge(priority: i['priority'] as String? ?? 'medium'),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.slate50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(catName, style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate500)),
                ),
              ]),
            ]),
            const SizedBox(height: 16),
            _section('Description', [
              Text(i['description'] as String? ?? 'No description',
                  style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate700)),
            ]),
            if (photos.isNotEmpty) ...[
              const SizedBox(height: 16),
              _section('Evidence Photos', [
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, idx) => GestureDetector(
                      onTap: () => _showFullScreenPhoto(photos[idx]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          photos[idx],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 100, height: 100,
                            color: AppTheme.slate200,
                            child: const Icon(Icons.broken_image, color: AppTheme.slate400),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ],
            const SizedBox(height: 16),
            _section('Impact', [
              _infoRow('Started', _formatDate(i['started_at'])),
              _infoRow('Ended', i['ended_at'] != null ? _formatDate(i['ended_at']) : '-'),
              _infoRow('Time Lost', i['time_impact_hours'] != null ? '${(i['time_impact_hours'] as num).toStringAsFixed(1)}h' : '—'),
              _infoRow('Cost Impact (time×rate)', i['cost_impact'] != null ? '\$${(i['cost_impact'] as num).toStringAsFixed(0)}' : '—'),
              _infoRow('Actual Expenses', '\$${(i['actual_expenses'] as num?)?.toStringAsFixed(0) ?? '0'}'),
              if (resolvedAt != null) ...[
                const SizedBox(height: 4),
                _infoRow('Resolved by', resolver?['name'] as String? ?? 'Unknown'),
                _infoRow('Resolved at', _formatDate(resolvedAt)),
              ],
            ]),
            const SizedBox(height: 16),
            _section('Reported by', [
              Text(reporterName, style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate700)),
              Text(_formatDate(i['reported_at']), style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate400)),
            ]),
            if (i['resolution_notes'] != null && (i['resolution_notes'] as String).isNotEmpty) ...[
              const SizedBox(height: 16),
              _section('Resolution Notes', [
                Text(i['resolution_notes'] as String,
                    style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate700)),
              ]),
            ],
            const SizedBox(height: 16),
            _section('Affected Resources', [
              AffectedItemsSection(items: items),
            ]),
            const SizedBox(height: 16),
            IncidentActionTimeline(
              actions: actions,
              currentUserId: userId,
              onComplete: isClosed ? null : _completeAction,
              onAddAction: isClosed ? null : _addAction,
              onDeleteAction: isClosed ? null : _deleteAction,
            ),
            if (!isClosed) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 44,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await context.push('/projects/${widget.projectId}/incidents/${widget.incidentId}/edit');
                    _loadData();
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text('Edit Incident', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primarySlate,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
            if (status == 'open') ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 44,
                child: FilledButton.icon(
                  onPressed: _startProgress,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: Text('Start Progress', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
            if (isOpen) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 44,
                child: FilledButton.icon(
                  onPressed: _resolveIncident,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text('Mark as Resolved', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
            if (isResolved) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 44,
                child: FilledButton.icon(
                  onPressed: _closeIncident,
                  icon: const Icon(Icons.lock_outline, size: 18),
                  label: Text('Close Incident', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.slate700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 40,
              child: TextButton.icon(
                onPressed: () async {
                  final confirmed = await showSafeDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Incident'),
                      content: const Text('This action cannot be undone. Are you sure?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && mounted) {
                    await ref.read(incidentsServiceProvider).delete(widget.incidentId);
                    if (mounted) context.pop();
                  }
                },
                icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.errorRed),
                label: Text('Delete Incident', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.errorRed)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate500, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        SizedBox(width: 130, child: Text(label, style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate400))),
        Expanded(child: Text(value, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.slate900))),
      ]),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}
