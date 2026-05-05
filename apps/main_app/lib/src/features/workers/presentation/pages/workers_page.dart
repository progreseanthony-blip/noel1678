import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../../../../shared/widgets/top_header.dart';
import '../controllers/workers_controller.dart';
import '../widgets/worker_form_dialog.dart';
import '../widgets/worker_profile_dialog.dart';
import '../../../catalogs/presentation/controllers/catalogs_controller.dart';

class WorkersPage extends ConsumerStatefulWidget {
  const WorkersPage({super.key});

  @override
  ConsumerState<WorkersPage> createState() => _WorkersPageState();
}

class _WorkersPageState extends ConsumerState<WorkersPage> {
  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Active, Inactive
  String _roleFilter = 'All'; // Role ID or 'All'

  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(workersControllerProvider);
    final rolesAsync = ref.watch(laborRolesControllerProvider);
    
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userName = currentUser?.userMetadata?['name'] ?? 'Admin User';
    final userEmail = currentUser?.email ?? '';
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      return _buildMobileLayout(userName, userEmail, workersAsync, rolesAsync);
    }
    return _buildDesktopLayout(userName, userEmail, workersAsync, rolesAsync);
  }

  // ══════════════════════════════════════════════════════════════
  //  DESKTOP LAYOUT
  // ══════════════════════════════════════════════════════════════
  Widget _buildDesktopLayout(
    String userName, 
    String userEmail, 
    AsyncValue<List<Map<String, dynamic>>> workersAsync,
    AsyncValue<List<Map<String, dynamic>>> rolesAsync,
  ) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Row(
        children: [
          Sidebar(
            userName: userName,
            userEmail: userEmail,
            currentPath: '/workers',
            onLogout: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/signin');
            },
          ),
          Expanded(
            child: Column(
              children: [
                TopHeader(userName: userName, breadcrumbs: const ['Administration', 'Workers']),
                Expanded(
                  child: workersAsync.when(
                    data: (workers) => rolesAsync.when(
                      data: (roles) => _buildMainContent(workers, roles),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Center(child: Text('Error: $e')),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
                    error: (e, st) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(List<Map<String, dynamic>> workers, List<Map<String, dynamic>> roles) {
    final filtered = workers.where((w) {
      final matchesStatus = _statusFilter == 'All' || w['status'] == _statusFilter;
      final matchesSearch = (w['full_name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRole = _roleFilter == 'All' || w['role_id'] == _roleFilter;
      return matchesStatus && matchesSearch && matchesRole;
    }).toList();

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
                      'Workers Directory',
                      style: GoogleFonts.manrope(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.slate900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage workers, assign roles & verify salaries globally.',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: AppTheme.slate500,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              FilledButton.icon(
                onPressed: () => _showWorkerForm(context),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Worker'),
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
          _buildSearchFilters(roles),
          const SizedBox(height: 24),
          _buildTable(filtered),
        ],
      ),
    );
  }

  Widget _buildSearchFilters(List<Map<String, dynamic>> roles) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search by name...',
                  hintStyle: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.slate400, size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate900),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _roleFilter,
                  isExpanded: true,
                  hint: Text('Filter by Role', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate500)),
                  items: [
                    const DropdownMenuItem(value: 'All', child: Text('All Roles')),
                    ...roles.map((r) => DropdownMenuItem(value: r['id'], child: Text(r['description'] ?? 'No Desc'))),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _roleFilter = val);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _statusFilter,
                items: ['All', 'Active', 'Inactive']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _statusFilter = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> workers) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
            child: Row(
              children: [
                Expanded(flex: 30, child: _colHeader('FULL NAME & ID')),
                Expanded(flex: 20, child: _colHeader('ASSIGNED ROLE')),
                Expanded(flex: 20, child: _colHeader('SALARY')),
                Expanded(flex: 15, child: _colHeader('STATUS')),
                Expanded(flex: 15, child: _colHeader('ACTIONS')),
              ],
            ),
          ),
          if (workers.isEmpty)
             const Padding(padding: EdgeInsets.all(32), child: Center(child: Text("No workers found.")))
          else
            ...workers.map((w) => _buildTableRow(w)),
        ],
      ),
    );
  }

  Widget _colHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: AppTheme.slate500,
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> w) {
    final role = w['role']?['description'] ?? 'No role';
    final isActive = w['status'] == 'Active';
    final rate = w['role'] != null ? '\$${w['role']['hourly_rate']} / hr' : '-';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showWorkerProfile(context, w),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
          child: Row(
            children: [
              Expanded(
                flex: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w['full_name'] ?? 'N/A', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.slate900)),
                    Text(w['id_number'] ?? 'N/A', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500)),
                  ],
                ),
              ),
              Expanded(
                flex: 20, 
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.slate200.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.slate200),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.slate600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(flex: 20, child: Text(rate, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen))),
              Expanded(flex: 15, child: _buildStatusBadge(w['status'] ?? 'Active')),
              Expanded(
                flex: 15,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppTheme.slate500, size: 20),
                      onPressed: () => _showWorkerForm(context, worker: w),
                      tooltip: 'Edit Worker',
                    ),
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, color: AppTheme.slate500, size: 20),
                      onPressed: () => _showWorkerProfile(context, w),
                      tooltip: 'View Profile',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 20),
                      onPressed: () => _confirmDeleteWorker(context, w),
                      tooltip: 'Delete Worker',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isActive = status == 'Active';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryGreen.withOpacity(0.1) : AppTheme.errorRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status.toUpperCase(),
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: isActive ? AppTheme.primaryGreen : AppTheme.errorRed,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  MOBILE LAYOUT
  // ══════════════════════════════════════════════════════════════
  Widget _buildMobileLayout(String userName, String userEmail, AsyncValue<List<Map<String, dynamic>>> workersAsync, AsyncValue<List<Map<String, dynamic>>> rolesAsync) {
    return Scaffold(
      key: _mobileScaffoldKey,
      backgroundColor: AppTheme.backgroundLight,
      drawer: Drawer(
        backgroundColor: const Color(0xFF0F172A),
        child: Sidebar(
          userName: userName,
          userEmail: userEmail,
          currentPath: '/workers',
          onLogout: () async {
            Navigator.of(context).pop();
            await Supabase.instance.client.auth.signOut();
            if (context.mounted) context.go('/signin');
          },
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16, bottom: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _mobileScaffoldKey.currentState?.openDrawer(),
                  child: const Icon(Icons.menu, color: AppTheme.slate700, size: 24),
                ),
                const SizedBox(width: 12),
                Text('Workers', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Expanded(
            child: workersAsync.when(
              data: (workers) {
                final filtered = workers.where((w) {
                  final matchesStatus = _statusFilter == 'All' || w['status'] == _statusFilter;
                  final matchesSearch = (w['full_name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesRole = _roleFilter == 'All' || w['role_id'] == _roleFilter;
                  return matchesStatus && matchesSearch && matchesRole;
                }).toList();
                
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextField(
                      decoration: const InputDecoration(hintText: 'Search...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                    const SizedBox(height: 16),
                    if (filtered.isEmpty) const Text('No workers.')
                    else ...filtered.map((w) => Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppTheme.slate200)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(w['full_name'], style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(w['role']?['description'] ?? 'No role', style: GoogleFonts.manrope(fontSize: 12)),
                            const SizedBox(height: 4),
                            _buildStatusBadge(w['status'] ?? 'Active'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppTheme.slate500, size: 22),
                              onPressed: () => _showWorkerForm(context, worker: w),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, color: AppTheme.slate400),
                              onPressed: () => _showWorkerProfile(context, w),
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error: $e'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWorkerForm(context),
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showWorkerForm(BuildContext context, {Map<String, dynamic>? worker}) {
    showDialog(context: context, builder: (context) => WorkerFormDialog(worker: worker));
  }

  void _showWorkerProfile(BuildContext context, Map<String, dynamic> worker) {
    showDialog(context: context, builder: (context) => WorkerProfileDialog(worker: worker));
  }

  Future<void> _confirmDeleteWorker(BuildContext context, Map<String, dynamic> worker) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Worker', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete ${worker['full_name']}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client.from('workers').delete().eq('id', worker['id']);
        ref.invalidate(workersControllerProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Worker deleted successfully')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting worker: $e')));
        }
      }
    }
  }
}
