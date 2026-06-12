import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
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
    final desc = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Action'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Describe the action...'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ''), child: const Text('Add')),
        ],
      ),
    );
    if (desc == null || desc.trim().isEmpty) return;
    try {
      await ref.read(incidentsServiceProvider).addAction(widget.incidentId, {
        'description': desc.trim(),
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

  Future<void> _resolveIncident() async {
    final solutionCtrl = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
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
    final notes = await showDialog<String>(
      context: context,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    if (_incident == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Not found')));

    final i = _incident!;
    final category = i['incident_categories'] as Map<String, dynamic>?;
    final catName = category?['name'] as String? ?? 'General';
    final reporter = i['reported_by_profile'] as Map<String, dynamic>?;
    final reporterName = reporter?['name'] as String? ?? 'Unknown';
    final items = List<Map<String, dynamic>>.from(i['incident_affected_items'] ?? []);
    final actions = List<Map<String, dynamic>>.from(i['incident_actions'] ?? []);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final status = i['status'] as String? ?? 'open';
    final isOpen = status == 'open' || status == 'in_progress';
    final isResolved = status == 'resolved';
    final isClosed = status == 'closed';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text(i['title'] as String? ?? '', style: GoogleFonts.manrope(fontSize: 14)),
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
            const SizedBox(height: 16),
            _section('Impact', [
              _infoRow('Started', _formatDate(i['started_at'])),
              _infoRow('Ended', i['ended_at'] != null ? _formatDate(i['ended_at']) : '-'),
              _infoRow('Time Lost', i['time_impact_hours'] != null ? '${(i['time_impact_hours'] as num).toStringAsFixed(1)}h' : '—'),
              _infoRow('Budget Impact', i['cost_impact'] != null ? '\$${(i['cost_impact'] as num).toStringAsFixed(0)}' : '—'),
              _infoRow('Actual Expenses', '\$${(i['actual_expenses'] as num?)?.toStringAsFixed(0) ?? '0'}'),
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
            ),
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
            const SizedBox(height: 32),
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
