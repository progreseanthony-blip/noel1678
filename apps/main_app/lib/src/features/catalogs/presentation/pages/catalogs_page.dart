import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/labor_roles_tab.dart';
import '../widgets/machinery_tab.dart';
import '../widgets/services_tab.dart';

class CatalogsPage extends ConsumerStatefulWidget {
  const CatalogsPage({super.key});

  @override
  ConsumerState<CatalogsPage> createState() => _CatalogsPageState();
}

class _CatalogsPageState extends ConsumerState<CatalogsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Widget _buildDesktopLayout(String userName, String userEmail) {
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 32, top: 16, right: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text(
                              'Catalogs',
                              style: GoogleFonts.manrope(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.slate900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage your system base catalogs for roles, machinery, and services.',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                color: AppTheme.slate500,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: _buildTabsHeader(),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: const [
                            LaborRolesTab(),
                            MachineryTab(),
                            ServicesTab(),
                          ],
                        ),
                      ),
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

  Widget _buildTabsHeader() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.slate200)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppTheme.primaryGreen,
        unselectedLabelColor: AppTheme.slate500,
        indicatorColor: AppTheme.primaryGreen,
        indicatorWeight: 3,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14),
        tabs: const [
          Tab(text: 'LABOR ROLES'),
          Tab(text: 'MACHINERY'),
          Tab(text: 'SERVICES'),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(String userName, String userEmail) {
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
          _buildMobileHeader(userName),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Text(
                        'Catalogs',
                        style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.slate900,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildTabsHeader(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      LaborRolesTab(),
                      MachineryTab(),
                      ServicesTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
              _buildBottomNavItem(Icons.group_outlined, 'Users', false, () => context.go('/users')),
              _buildBottomNavItem(Icons.request_quote_rounded, 'Quotes', false, () => context.go('/quotes')),
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
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _mobileScaffoldKey.currentState?.openDrawer(),
              child: const Icon(Icons.menu, color: AppTheme.slate700, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Global Golf',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.slate900,
            ),
          ),
          const Spacer(),
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.slate200),
            child: Center(child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.slate500))),
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
}

class _Sidebar extends StatelessWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;
  final double? width;

  const _Sidebar({
    required this.userName,
    required this.userEmail,
    required this.onLogout,
    this.width = 280,
  });

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
                  _NavItem(icon: Icons.folder_copy_outlined, label: 'Catalogs', isActive: true, onTap: () {}),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
            ),
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
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.chevron_right, size: 16, color: AppTheme.slate400)),
              Text('Catalogs', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate900, fontWeight: FontWeight.w700)),
            ],
          ),
           Row(
            children: [
              const Icon(Icons.notifications_none, color: AppTheme.slate500),
              const SizedBox(width: 24),
              Container(width: 1, height: 24, color: AppTheme.slate200),
              const SizedBox(width: 24),
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
                child: Center(child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate700))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
