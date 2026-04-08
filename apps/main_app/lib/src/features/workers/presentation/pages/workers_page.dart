import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/workers_controller.dart';
import '../widgets/worker_form_dialog.dart';
import '../widgets/worker_profile_dialog.dart';

class WorkersPage extends ConsumerStatefulWidget {
  const WorkersPage({super.key});

  @override
  ConsumerState<WorkersPage> createState() => _WorkersPageState();
}

class _WorkersPageState extends ConsumerState<WorkersPage> {
  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Active, Inactive

  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(workersControllerProvider);
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userName = currentUser?.userMetadata?['name'] ?? 'Admin User';
    final userEmail = currentUser?.email ?? '';
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      return _buildMobileLayout(userName, userEmail, workersAsync);
    }
    return _buildDesktopLayout(userName, userEmail, workersAsync);
  }

  // ══════════════════════════════════════════════════════════════
  //  DESKTOP LAYOUT
  // ══════════════════════════════════════════════════════════════
  Widget _buildDesktopLayout(String userName, String userEmail, AsyncValue<List<Map<String, dynamic>>> workersAsync) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Row(
        children: [
          _Sidebar(
            userName: userName,
            userEmail: userEmail,
            onLogout: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/signin');
            },
          ),
          Expanded(
            child: Column(
              children: [
                _TopHeader(userName: userName),
                Expanded(
                  child: workersAsync.when(
                    data: (workers) => _buildMainContent(workers),
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

  Widget _buildMainContent(List<Map<String, dynamic>> workers) {
    final filtered = workers.where((w) {
      final matchesStatus = _statusFilter == 'All' || w['status'] == _statusFilter;
      final matchesSearch = (w['full_name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
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
          _buildSearchFilters(),
          const SizedBox(height: 24),
          _buildTable(filtered),
        ],
      ),
    );
  }

  Widget _buildSearchFilters() {
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
          DropdownButton<String>(
            value: _statusFilter,
            items: ['All', 'Active', 'Inactive']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _statusFilter = val);
            },
            underline: const SizedBox(),
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
              Expanded(flex: 20, child: Text(role, style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate700))),
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
  Widget _buildMobileLayout(String userName, String userEmail, AsyncValue<List<Map<String, dynamic>>> workersAsync) {
    return Scaffold(
      key: _mobileScaffoldKey,
      backgroundColor: AppTheme.backgroundLight,
      drawer: Drawer(
        backgroundColor: const Color(0xFF0F172A),
        child: _Sidebar(
          userName: userName,
          userEmail: userEmail,
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
                  return matchesStatus && matchesSearch;
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
}

// ══════════════════════════════════════════════════════════════
//  COMPONENTS
// ══════════════════════════════════════════════════════════════
class _Sidebar extends StatelessWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;
  final double? width;

  const _Sidebar({required this.userName, required this.userEmail, required this.onLogout, this.width = 280});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(10)),
                  child: const Center(child: Icon(Icons.golf_course, color: Colors.white, size: 22)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Global Golf', style: GoogleFonts.manrope(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.2)),
                    Text('CONSTRUCTION', style: GoogleFonts.manrope(color: AppTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 2.5)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _NavItem(icon: Icons.group_outlined, label: 'User Management', isActive: false, onTap: () => context.go('/users')),
                  const SizedBox(height: 4),
                  _NavItem(icon: Icons.request_quote_rounded, label: 'Quotes', isActive: false, onTap: () => context.go('/quotes')),
                  const SizedBox(height: 4),
                  _NavItem(icon: Icons.folder_copy_outlined, label: 'Catalogs', isActive: false, onTap: () => context.go('/catalogs')),
                  const SizedBox(height: 4),
                  _NavItem(icon: Icons.engineering_outlined, label: 'Workers', isActive: true, onTap: () {}),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1))),
            child: Column(
              children: [
                _NavItem(icon: Icons.settings_outlined, label: 'Settings', isActive: false, onTap: () {}),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryGreen.withOpacity(0.15), border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.25))),
                        child: const Icon(Icons.person, color: AppTheme.primaryGreen, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(userName, style: GoogleFonts.manrope(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                            Text(userEmail, style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 11), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      IconButton(onPressed: onLogout, icon: const Icon(Icons.logout, color: AppTheme.slate400, size: 18)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.isActive, required this.onTap});
  @override State<_NavItem> createState() => _NavItemState();
}
class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;
  @override Widget build(BuildContext context) {
    final color = widget.isActive ? AppTheme.primaryGreen : (_isHovered ? Colors.white : AppTheme.slate400);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isActive ? AppTheme.primaryGreen.withOpacity(0.1) : (_isHovered ? Colors.white.withOpacity(0.03) : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: color, size: 20),
              const SizedBox(width: 14),
              Text(widget.label, style: GoogleFonts.manrope(color: color, fontSize: 14, fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String userName;
  const _TopHeader({required this.userName});
  @override Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppTheme.slate200))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text('Administration', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate500, fontWeight: FontWeight.w500)),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.chevron_right, size: 16, color: AppTheme.slate400)),
              Text('Workers', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate900, fontWeight: FontWeight.w700)),
            ],
          ),
          Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(userName, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate900)),
                  Text('Active User', style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate500)),
                ],
              ),
              const SizedBox(width: 12),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: AppTheme.slate200, shape: BoxShape.circle),
                child: Center(child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
