import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import '../widgets/incident_card.dart';

class IncidentsListPage extends ConsumerStatefulWidget {
  final String projectId;
  const IncidentsListPage({super.key, required this.projectId});

  @override
  ConsumerState<IncidentsListPage> createState() => _IncidentsListPageState();
}

class _IncidentsListPageState extends ConsumerState<IncidentsListPage> {
  List<Map<String, dynamic>> _incidents = [];
  Map<String, dynamic>? _project;
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final service = ref.read(incidentsServiceProvider);
      _incidents = await service.getByProject(widget.projectId);
      final project = await Supabase.instance.client
          .from('projects')
          .select('title')
          .eq('id', widget.projectId)
          .single();
      if (!mounted) return;
      setState(() {
        _project = project as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_statusFilter == 'all') return _incidents;
    return _incidents.where((i) => i['status'] == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final projectName = _project?['title'] as String? ?? 'Project';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Incidents — $projectName', style: GoogleFonts.manrope(fontSize: 14)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: GoogleFonts.manrope(color: AppTheme.errorRed)))
              : Column(children: [
                  _buildFilterBar(),
                  Expanded(child: _incidents.isEmpty ? _emptyState() : _buildList()),
                ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/projects/${widget.projectId}/incidents/new');
          if (mounted) _loadData();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Incident'),
        backgroundColor: AppTheme.errorRed,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        _filterChip('All', 'all'),
        const SizedBox(width: 8),
        _filterChip('Open', 'open'),
        const SizedBox(width: 8),
        _filterChip('In Progress', 'in_progress'),
        const SizedBox(width: 8),
        _filterChip('Resolved', 'resolved'),
        const SizedBox(width: 8),
        _filterChip('Closed', 'closed'),
      ]),
    );
  }

  Widget _filterChip(String label, String value) {
    final active = _statusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryGreen : AppTheme.slate50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppTheme.slate600,
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_outline, size: 64, color: AppTheme.primaryGreen.withAlpha(60)),
        const SizedBox(height: 16),
        Text('No incidents', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.slate600)),
        const SizedBox(height: 8),
        Text('Tap the button below to report an incident', style: GoogleFonts.manrope(color: AppTheme.slate400)),
      ]),
    );
  }

  Widget _buildList() {
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return Center(
        child: Text('No incidents with this status', style: GoogleFonts.manrope(color: AppTheme.slate400)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final incident = filtered[i];
        return IncidentCard(
          incident: incident,
          onTap: () async {
            await context.push('/projects/${widget.projectId}/incidents/${incident['id']}');
            if (mounted) _loadData();
          },
        );
      },
    );
  }
}
