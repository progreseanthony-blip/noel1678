import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../../../../shared/widgets/top_header.dart';

import '../widgets/user_form_dialog.dart';
import '../widgets/role_management_dialog.dart';

class UserListPage extends ConsumerStatefulWidget {
  const UserListPage({super.key});

  @override
  ConsumerState<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends ConsumerState<UserListPage> {
  List<Map<String, dynamic>>? _users;
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String? _filterField;
  String? _filterValue;
  int _currentPage = 1;
  static const int _pageSize = 5;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .order('name');
      setState(() {
        _users = List<Map<String, dynamic>>.from(response ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_users == null) return [];
    final hasFieldFilter = _filterField != null && _filterValue != null && _filterValue!.isNotEmpty;
    if (_searchQuery.isEmpty && !hasFieldFilter) return _users!;
    return _users!.where((u) {
      if (hasFieldFilter) {
        String fieldValue;
        if (_filterField == 'Status') {
          fieldValue = (u['status'] ?? 'active').toString().toLowerCase();
        } else {
          final column = _fieldToColumn(_filterField!);
          fieldValue = (u[column] ?? '').toString().toLowerCase();
        }
        if (!fieldValue.contains(_filterValue!.toLowerCase())) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (u['name'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        final role = (u['role'] ?? '').toString().toLowerCase();
        if (!name.contains(q) && !email.contains(q) && !role.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> get _paginatedUsers {
    final filtered = _filteredUsers;
    final start = (_currentPage - 1) * _pageSize;
    if (start >= filtered.length) return [];
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int get _totalPages => (_filteredUsers.length / _pageSize).ceil().clamp(1, 9999);

  int get _activeCount {
    if (_users == null) return 0;
    return _users!
        .where((u) =>
            (u['status'] ?? 'active').toString().toLowerCase() == 'active')
        .length;
  }

  int get _uniqueRoles {
    if (_users == null) return 0;
    return _users!.map((u) => (u['role'] ?? '').toString()).toSet().length;
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _fieldToColumn(String field) {
    switch (field) {
      case 'Name': return 'name';
      case 'Email': return 'email';
      case 'Role': return 'role';
      case 'Status': return 'status';
      default: return '';
    }
  }

  Future<void> _showUserForm({Map<String, dynamic>? user}) async {
    final result = await showSafeDialog<bool>(
      context: context,
      fullscreenOnMobile: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => UserFormDialog(userToEdit: user),
    );

    if (result == true) {
      _loadUsers();
    }
  }

  void _showRoleManager() {
    showSafeDialog(
      context: context,
      fullscreenOnMobile: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => const RoleManagementDialog(),
    );
  }

  // Mobile scaffold key for drawer
  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();

  // Mobile filter state
  String _mobileFilter = 'all'; // 'all', 'active', 'inactive'

  List<Map<String, dynamic>> get _mobileFilteredUsers {
    final base = _filteredUsers;
    if (_mobileFilter == 'active') {
      return base.where((u) => (u['status'] ?? 'active').toString().toLowerCase() == 'active').toList();
    } else if (_mobileFilter == 'inactive') {
      return base.where((u) => (u['status'] ?? 'active').toString().toLowerCase() != 'active').toList();
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userName = currentUser?.userMetadata?['name'] ?? 'Admin User';
    final userEmail = currentUser?.email ?? '';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (isMobile) {
      return _buildMobileLayout(userName, userEmail);
    }
    return _buildDesktopLayout(userName, userEmail);
  }

  // ══════════════════════════════════════════════════════════════
  //  DESKTOP LAYOUT (existing)
  // ══════════════════════════════════════════════════════════════
  Widget _buildDesktopLayout(String userName, String userEmail) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Row(
        children: [
          Sidebar(
            userName: userName,
            userEmail: userEmail,
            currentPath: '/users',
            onLogout: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/signin');
            },
          ),
          Expanded(
            child: Column(
              children: [
                TopHeader(userName: userName, breadcrumbs: const ['Administration', 'User Management']),
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen, strokeWidth: 3))
                      : _error != null
                          ? _buildErrorState()
                          : _buildMainContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  MOBILE / TABLET LAYOUT
  // ══════════════════════════════════════════════════════════════
  Widget _buildMobileLayout(String userName, String userEmail) {
    return Scaffold(
      key: _mobileScaffoldKey,
      backgroundColor: AppTheme.backgroundLight,

      // ── Drawer (same sidebar style) ──
      drawer: Drawer(
        backgroundColor: const Color(0xFF0F172A),
        child: Sidebar(
          userName: userName,
          userEmail: userEmail,
          currentPath: '/users',
          onLogout: () async {
            Navigator.of(context).pop(); // close drawer first
            await Supabase.instance.client.auth.signOut();
            if (context.mounted) context.go('/signin');
          },
        ),
      ),

      body: Column(
        children: [
          // ── Sticky Mobile Header ──
          _buildMobileHeader(userName),

          // ── Content ──
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen, strokeWidth: 3))
                : _error != null
                    ? _buildErrorState()
                    : _buildMobileContent(),
          ),
        ],
      ),

      // ── Bottom Navigation Bar ──
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.slate200)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBottomNavItem(Icons.group_outlined, 'Users', true, () {}),
              _buildBottomNavItem(Icons.request_quote_rounded, 'Quotes', false, () => context.go('/quotes')),
              _buildBottomNavItem(Icons.person_search_outlined, 'Customers', false, () => context.go('/customers')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileHeader(String userName) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16, right: 16, bottom: 12,
      ),
      child: Row(
        children: [
          // Hamburger menu
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _mobileScaffoldKey.currentState?.openDrawer(),
              child: Icon(Icons.menu, color: AppTheme.slate700, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          // Logo
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.sports_golf, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Global Golf',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.slate900,
              ),
            ),
          ),
          const Spacer(),
          // Search icon
          IconButton(
            icon: Icon(Icons.search, color: AppTheme.slate500),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.slate200,
              border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
            ),
            child: Center(
              child: Text(
                _getInitials(userName),
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileContent() {
    final users = _mobileFilteredUsers;
    final total = _filteredUsers.length;
    final activeCount = _filteredUsers.where(
      (u) => (u['status'] ?? 'active').toString().toLowerCase() == 'active',
    ).length;
    final inactiveCount = total - activeCount;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 24),

        // ── Title ──
        Text(
          'User Management',
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.slate900,
          ),
        ),
        const SizedBox(height: 20),

        // ── Filter Tabs ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterTab('All Users ($total)', 'all'),
              const SizedBox(width: 8),
              _buildFilterTab('Active', 'active'),
              const SizedBox(width: 8),
              _buildFilterTab('Inactive', 'inactive'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── User Cards ──
        if (users.isEmpty)
          _buildMobileEmptyState()
        else
          ...users.map((u) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMobileUserCard(u),
              )),

        const SizedBox(height: 80), // Space for FAB + bottom nav
      ],
    );
  }

  Widget _buildFilterTab(String label, String filterValue) {
    final isSelected = _mobileFilter == filterValue;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _mobileFilter = filterValue),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: isSelected ? null : Border.all(color: AppTheme.slate200),
          ),
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppTheme.slate500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileUserCard(Map<String, dynamic> user) {
    final name = user['name']?.toString() ?? 'Sin Nombre';
    final email = user['email']?.toString() ?? '';
    final role = user['role']?.toString() ?? 'Employee';
    final isActive = (user['status'] ?? 'active').toString().toLowerCase() == 'active';
    final initials = _getInitials(name);
    final isAdmin = role.toLowerCase() == 'admin';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Top row: avatar + name + role badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with status dot
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? AppTheme.primaryGreen.withOpacity(0.1)
                          : AppTheme.slate200,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isActive ? AppTheme.primaryGreen : AppTheme.slate400,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? AppTheme.primaryGreen : AppTheme.errorRed,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Name + Email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? AppTheme.primaryGreen.withOpacity(0.1)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  role.toUpperCase(),
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isAdmin ? AppTheme.primaryGreen : AppTheme.slate500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Divider
          Container(height: 1, color: const Color(0xFFF8FAFC)),
          const SizedBox(height: 12),
          // Bottom row: status + more button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isActive ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: isActive ? AppTheme.primaryGreen : AppTheme.errorRed,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isActive ? 'ACTIVE' : 'INACTIVE',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isActive ? AppTheme.primaryGreen : AppTheme.errorRed,
                    ),
                  ),
                ],
              ),
              _MobileMoreButton(
                onEdit: () => _showUserForm(user: user),
                onDelete: () {},
                onManageRoles: _showRoleManager,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 48, color: AppTheme.slate400),
          const SizedBox(height: 12),
          Text(
            'No users found',
            style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.slate900),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: isActive ? AppTheme.primaryGreen : AppTheme.slate400),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.manrope(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: isActive ? AppTheme.primaryGreen : AppTheme.slate400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
          const SizedBox(height: 16),
          Text('Error al cargar usuarios',
              style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate900)),
          const SizedBox(height: 8),
          Text(_error!,
              style: GoogleFonts.manrope(
                  fontSize: 13, color: AppTheme.slate500)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _loadUsers();
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page Title & Add Button ──
          _buildTitleRow(),
          const SizedBox(height: 24),

          // ── Search & Filters ──
          _buildSearchFilters(),
          const SizedBox(height: 24),

          // ── Users Table ──
          _buildUsersTable(),
          const SizedBox(height: 32),

          // ── Stats Cards ──
          _buildStatsRow(),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // TITLE ROW
  // ────────────────────────────────────────────────────────────
  Widget _buildTitleRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Team Directory',
                style: GoogleFonts.manrope(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.slate900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage access levels, assign roles, and monitor status for all personnel involved in projects.',
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
        // Manage Roles button
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _showRoleManager,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.admin_panel_settings_outlined, color: AppTheme.slate500, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Manage Roles',
                    style: GoogleFonts.manrope(
                      color: AppTheme.slate700,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────
  // SEARCH & FILTERS
  // ────────────────────────────────────────────────────────────
  Widget _buildSearchFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Search field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.slate50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() {
                      _searchQuery = v;
                      _currentPage = 1;
                    }),
                    style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate900),
                    decoration: InputDecoration(
                      hintText: 'Search by name, email or project...',
                      hintStyle: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate400),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.slate400, size: 22),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Filters dropdown
              _buildFilterButton(),
            ],
          ),
          // Active filter row
          if (_filterField != null) ...[
            const SizedBox(height: 12),
            _buildActiveFilterRow(),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    final fields = ['Name', 'Email', 'Role', 'Status'];
    return PopupMenuButton<String?>(
      onSelected: (value) {
        setState(() {
          if (value == null) {
            _filterField = null;
            _filterValue = null;
          } else {
            _filterField = value;
            _filterValue = null;
          }
          _currentPage = 1;
        });
      },
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.white,
      elevation: 4,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: null,
          child: Row(
            children: [
              Icon(
                _filterField == null ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18, color: AppTheme.primaryGreen,
              ),
              const SizedBox(width: 8),
              Text('All Fields',
                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.slate900)),
            ],
          ),
        ),
        ...fields.map((field) => PopupMenuItem(
          value: field,
          child: Row(
            children: [
              Icon(
                _filterField == field ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18, color: AppTheme.primaryGreen,
              ),
              const SizedBox(width: 8),
              Text(field,
                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.slate900)),
            ],
          ),
        )),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _filterField != null ? AppTheme.primaryGreen.withOpacity(0.1) : AppTheme.slate50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.filter_list, size: 18,
              color: _filterField != null ? AppTheme.primaryGreen : const Color(0xFF475569)),
            const SizedBox(width: 8),
            Text(
              'Filters',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _filterField != null ? AppTheme.primaryGreen : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterRow() {
    return Row(
      children: [
        Icon(Icons.filter_alt, size: 16, color: AppTheme.primaryGreen),
        const SizedBox(width: 8),
        Text(
          '$_filterField:',
          style: GoogleFonts.manrope(
            fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.slate700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.slate50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: TextField(
              onChanged: (v) => setState(() {
                _filterValue = v;
                _currentPage = 1;
              }),
              style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate900),
              decoration: InputDecoration(
                hintText: 'Enter $_filterField...',
                hintStyle: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate400),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() {
              _filterField = null;
              _filterValue = null;
              _currentPage = 1;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.slate50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.close, size: 14, color: AppTheme.slate400),
                  const SizedBox(width: 4),
                  Text(
                    'Clear',
                    style: GoogleFonts.manrope(
                      fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────
  // USERS TABLE
  // ────────────────────────────────────────────────────────────
  Widget _buildUsersTable() {
    final paginated = _paginatedUsers;
    final total = _filteredUsers.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table Header
          Container(
            color: const Color(0xFFFAFAFB),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                _thCell('NAME', flex: 3),
                _thCell('EMAIL ADDRESS', flex: 3),
                _thCell('ROLE', flex: 2),
                _thCell('STATUS', flex: 2),
                _thCell('ACTIONS', flex: 1, align: TextAlign.right),
              ],
            ),
          ),
          Container(height: 1, color: AppTheme.slate200),

          // Table Body
          if (paginated.isEmpty && !_isLoading)
            _buildEmptyList()
          else
            ...paginated.map((u) => _UserRow(
                  name: u['name']?.toString() ?? 'Sin Nombre',
                  email: u['email']?.toString() ?? '',
                  role: u['role']?.toString() ?? 'Employee',
                  isActive: (u['status'] ?? 'active').toString().toLowerCase() == 'active',
                  initials: _getInitials(u['name']?.toString() ?? ''),
                  onEdit: () => _showUserForm(user: u),
                  onDelete: () {},
                )),

          // Pagination
          if (total > 0) _buildPaginationBar(total),
        ],
      ),
    );
  }

  Widget _thCell(String label, {int flex = 1, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.slate500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildEmptyList() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 48, color: AppTheme.slate400),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No users registered yet' : 'No results found',
            style: GoogleFonts.manrope(
                fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.slate900),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // PAGINATION
  // ────────────────────────────────────────────────────────────
  Widget _buildPaginationBar(int totalItems) {
    final start = ((_currentPage - 1) * _pageSize) + 1;
    final end = (_currentPage * _pageSize).clamp(0, totalItems);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFB),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $start-$end of $totalItems results',
            style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate500),
          ),
          Row(
            children: [
              _PaginationArrow(
                icon: Icons.chevron_left,
                enabled: _currentPage > 1,
                onTap: () => setState(() => _currentPage--),
              ),
              const SizedBox(width: 6),
              ..._buildPageButtons(),
              const SizedBox(width: 6),
              _PaginationArrow(
                icon: Icons.chevron_right,
                enabled: _currentPage < _totalPages,
                onTap: () => setState(() => _currentPage++),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageButtons() {
    final total = _totalPages;
    final widgets = <Widget>[];

    void addBtn(int p) {
      widgets.add(_PageBtn(
        page: p,
        isSelected: p == _currentPage,
        onTap: () => setState(() => _currentPage = p),
      ));
    }

    void addDots() {
      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text('...', style: GoogleFonts.manrope(color: AppTheme.slate400)),
      ));
    }

    if (total <= 5) {
      for (var i = 1; i <= total; i++) addBtn(i);
    } else {
      addBtn(1);
      if (_currentPage > 3) addDots();
      for (var i = (_currentPage - 1).clamp(2, total - 1);
          i <= (_currentPage + 1).clamp(2, total - 1);
          i++) {
        addBtn(i);
      }
      if (_currentPage < total - 2) addDots();
      addBtn(total);
    }
    return widgets;
  }

  // ────────────────────────────────────────────────────────────
  // STATS CARDS
  // ────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
            child: _StatCard(
                icon: Icons.groups_rounded,
                label: 'Total Personnel',
                value: '${_users?.length ?? 0}')),
        const SizedBox(width: 20),
        Expanded(
            child: _StatCard(
                icon: Icons.radio_button_checked,
                label: 'Active Today',
                value: '$_activeCount')),
        const SizedBox(width: 20),
        Expanded(
            child: _StatCard(
                icon: Icons.person_pin_rounded,
                label: 'Site Assignments',
                value: '$_uniqueRoles Roles')),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SIDEBAR
// ══════════════════════════════════════════════════════════════


// ══════════════════════════════════════════════════════════════
//  USER ROW
// ══════════════════════════════════════════════════════════════
class _UserRow extends StatefulWidget {
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final String initials;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserRow({
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.initials,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFFAFAFB) : Colors.white,
          border:
              const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Row(
          children: [
            // Name (flex: 3)
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  // Avatar circle
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isActive
                          ? AppTheme.primaryGreen.withOpacity(0.1)
                          : AppTheme.slate200,
                    ),
                    child: Center(
                      child: Text(
                        widget.initials,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: widget.isActive
                              ? AppTheme.primaryGreen
                              : AppTheme.slate400,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.name,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.slate900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Email (flex: 3)
            Expanded(
              flex: 3,
              child: Text(
                widget.email,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: const Color(0xFF475569),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Role (flex: 2)
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      widget.role,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.slate700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Status (flex: 2)
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.isActive
                          ? AppTheme.primaryGreen.withOpacity(0.1)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: widget.isActive
                            ? AppTheme.primaryGreen.withOpacity(0.2)
                            : AppTheme.slate200,
                      ),
                    ),
                    child: Text(
                      widget.isActive ? 'Active' : 'Inactive',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: widget.isActive
                            ? AppTheme.primaryGreen
                            : AppTheme.slate400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Actions (flex: 1)
            Expanded(
              flex: 1,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _hovered ? 1.0 : 0.0,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HoverIcon(
                        icon: Icons.edit_outlined,
                        onTap: widget.onEdit,
                        hoverBg: AppTheme.slate200,
                        color: const Color(0xFF475569),
                      ),
                      const SizedBox(width: 4),
                      _HoverIcon(
                        icon: Icons.delete_outline,
                        onTap: widget.onDelete,
                        hoverBg: const Color(0xFFFEF2F2),
                        color: AppTheme.errorRed,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hover Icon Button ──
class _HoverIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color hoverBg;
  final Color color;

  const _HoverIcon({
    required this.icon,
    required this.onTap,
    required this.hoverBg,
    required this.color,
  });

  @override
  State<_HoverIcon> createState() => _HoverIconState();
}

class _HoverIconState extends State<_HoverIcon> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _h ? widget.hoverBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(widget.icon, size: 18, color: widget.color),
          ),
        ),
      ),
    );
  }
}

// ── Small Button (Filters / Export) ──
class _SmallButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SmallButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_SmallButton> createState() => _SmallButtonState();
}

class _SmallButtonState extends State<_SmallButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFE2E8F0) : AppTheme.slate50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 18, color: const Color(0xFF475569)),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pagination Arrow ──
class _PaginationArrow extends StatefulWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PaginationArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_PaginationArrow> createState() => _PaginationArrowState();
}

class _PaginationArrowState extends State<_PaginationArrow> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _h && widget.enabled ? const Color(0xFFF1F5F9) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.slate200),
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: 18,
              color: widget.enabled ? AppTheme.slate400 : AppTheme.slate200,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Page Number Button ──
class _PageBtn extends StatelessWidget {
  final int page;
  final bool isSelected;
  final VoidCallback onTap;

  const _PageBtn({
    required this.page,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? null : Border.all(color: AppTheme.slate200),
          ),
          child: Center(
            child: Text(
              '$page',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF475569),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stat Card ──
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(icon, color: AppTheme.primaryGreen, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate500,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.slate900,
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

// ══════════════════════════════════════════════════════════════
//  MOBILE MORE BUTTON (3-dot menu)
// ══════════════════════════════════════════════════════════════
class _MobileMoreButton extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManageRoles;

  const _MobileMoreButton({
    required this.onEdit,
    required this.onDelete,
    required this.onManageRoles,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: AppTheme.slate400, size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.white,
      elevation: 4,
      offset: const Offset(0, 32),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
          case 'delete':
            onDelete();
          case 'roles':
            onManageRoles();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: AppTheme.slate500),
              const SizedBox(width: 8),
              Text('Edit User', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'roles',
          child: Row(
            children: [
              Icon(Icons.admin_panel_settings_outlined, size: 18, color: AppTheme.slate500),
              const SizedBox(width: 8),
              Text('Manage Roles', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppTheme.errorRed),
              const SizedBox(width: 8),
              Text('Delete User', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.errorRed)),
            ],
          ),
        ),
      ],
    );
  }
}
