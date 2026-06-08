import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../../../../shared/widgets/top_header.dart';
import '../widgets/payroll_period_dialog.dart';

class PayrollListPage extends ConsumerStatefulWidget {
  final String projectId;

  const PayrollListPage({super.key, required this.projectId});

  @override
  ConsumerState<PayrollListPage> createState() => _PayrollListPageState();
}

class _PayrollListPageState extends ConsumerState<PayrollListPage> {
  List<Map<String, dynamic>> _periods = [];
  String _projectTitle = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(payrollServiceProvider);
      _periods = await service.getPeriods(widget.projectId);
      final proj = await Supabase.instance.client
          .from('projects')
          .select('title')
          .eq('id', widget.projectId)
          .single();
      _projectTitle = proj['title'] ?? '';
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _createPeriod() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => PayrollPeriodDialog(projectId: widget.projectId),
    );
    if (result != null) {
      try {
        final service = ref.read(payrollServiceProvider);
        await service.createPeriod(result);
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _deletePeriod(Map<String, dynamic> period) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Period'),
        content: Text('Delete "${period['name']}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final service = ref.read(payrollServiceProvider);
        await service.deletePeriod(period['id'] as String);
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  String _formatCurrency(num value) {
    return '\$${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['name'] ?? 'Admin User';
    final userEmail = user?.email ?? '';
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) return _buildMobileLayout(userName, userEmail);
    return _buildDesktopLayout(userName, userEmail);
  }

  Widget _buildDesktopLayout(String userName, String userEmail) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Row(
        children: [
          Sidebar(
            userName: userName,
            userEmail: userEmail,
            currentPath: '/payroll',
            onLogout: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/signin');
            },
          ),
          Expanded(
            child: Column(
              children: [
                TopHeader(userName: userName, breadcrumbs: const ['Projects', 'Labor Cost']),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(String userName, String userEmail) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('Labor Cost', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPeriod,
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Error: $_error', style: GoogleFonts.manrope(color: Colors.red)),
          const SizedBox(height: 16),
          FilledButton(onPressed: _loadData, child: const Text('Retry')),
        ]),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Labor Cost',
                      style: GoogleFonts.manrope(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.slate900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _projectTitle,
                      style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate500),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _createPeriod,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('New Period'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_periods.isEmpty)
            Container(
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: Center(
                child: Column(children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.slate200),
                  const SizedBox(height: 16),
                  Text('No payroll periods yet', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.slate600)),
                  const SizedBox(height: 8),
                  Text('Create a period to calculate labor costs.', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate400)),
                ]),
              ),
            )
          else
            ..._periods.map((p) => _buildPeriodCard(p)),
        ],
      ),
    );
  }

  Widget _buildPeriodCard(Map<String, dynamic> p) {
    final status = p['status'] as String? ?? 'calculated';
    final isClosed = status == 'closed';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/projects/${widget.projectId}/payroll/${p['id']}'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isClosed ? AppTheme.slate50 : AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isClosed ? Icons.lock_outline : Icons.receipt_long_outlined,
                color: isClosed ? AppTheme.slate400 : AppTheme.primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['name'] ?? '', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.slate900)),
                  const SizedBox(height: 4),
                  Text(
                    '${p['start_date']} - ${p['end_date']}',
                    style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isClosed ? AppTheme.slate50 : AppTheme.primaryGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status.toUpperCase(),
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isClosed ? AppTheme.slate500 : AppTheme.primaryGreen,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${p['total_workers'] ?? 0} workers',
                  style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatCurrency((p['total_cost'] ?? 0).toDouble()),
                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                ),
              ],
            ),
            const SizedBox(width: 16),
            PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'delete') _deletePeriod(p);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'delete', child: Row(
                  children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete')],
                )),
              ],
              icon: const Icon(Icons.more_vert, color: AppTheme.slate400),
            ),
          ]),
        ),
      ),
    );
  }
}
