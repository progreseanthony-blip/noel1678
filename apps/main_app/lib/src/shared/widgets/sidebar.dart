import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';

class Sidebar extends StatelessWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;
  final String currentPath;
  final double? width;

  const Sidebar({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
    required this.currentPath,
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
              child: SingleChildScrollView(
                child: Column(
                children: [
                  _NavItem(icon: Icons.group_outlined, label: 'User Management', isActive: currentPath.startsWith('/users') || currentPath == '/', onTap: () => context.go('/users')),
                  const SizedBox(height: 4),
                  _NavItem(icon: Icons.request_quote_rounded, label: 'Estimates', isActive: currentPath.startsWith('/quotes'), onTap: () => context.go('/quotes')),
                  const SizedBox(height: 4),
                  _ExpandableNavItem(
                    icon: Icons.rocket_launch_outlined,
                    label: 'Projects',
                    isActive: currentPath.startsWith('/projects') || currentPath.startsWith('/daily-reports') || currentPath.startsWith('/payroll') || currentPath.startsWith('/labor-cost') || currentPath.startsWith('/production-measurement') || currentPath.startsWith('/monitoring'),
                    initiallyExpanded: currentPath.startsWith('/projects') || currentPath.startsWith('/daily-reports') || currentPath.startsWith('/payroll') || currentPath.startsWith('/labor-cost') || currentPath.startsWith('/production-measurement') || currentPath.startsWith('/monitoring'),
                    children: [
                      _SubExpandableNavItem(
                        label: 'Planning',
                        isActive: currentPath.startsWith('/projects') && (currentPath == '/projects' || currentPath.endsWith('/baseline') || currentPath.contains('/reception')),
                        initiallyExpanded: true,
                        children: [
                          _SubNavItem(icon: Icons.build_circle, label: 'Resource Planning', isActive: currentPath.startsWith('/projects') && (currentPath == '/projects' || currentPath.endsWith('/baseline')), left: 44, onTap: () => context.go('/projects')),
                          _SubNavItem(icon: Icons.inventory, label: 'Reception', isActive: currentPath.contains('/reception'), left: 44, onTap: () {
                            final projectId = currentPath.replaceAll(RegExp(r'/projects/'), '').split('/').first;
                            if (projectId.isNotEmpty) {
                              context.go('/projects/$projectId/reception');
                            } else {
                              context.go('/projects');
                            }
                          }),
                        ],
                      ),
                      _SubExpandableNavItem(
                        label: 'Field Execution',
                        isActive: currentPath.startsWith('/daily-reports'),
                        initiallyExpanded: currentPath.startsWith('/daily-reports'),
                        children: [
                          _SubNavItem(icon: Icons.assignment, label: 'Daily Reports', isActive: (currentPath.startsWith('/daily-reports') && !currentPath.contains('/pending')) || currentPath.contains('/daily-report'), left: 44, onTap: () => context.go('/daily-reports')),
                          _SubNavItem(icon: Icons.fact_check_outlined, label: 'Pending Approvals', isActive: currentPath.startsWith('/daily-reports/pending'), left: 44, onTap: () => context.go('/daily-reports/pending')),
                          _SubNavItem(icon: Icons.warning_amber_rounded, label: 'Incidents', isActive: currentPath.startsWith('/incidents') || currentPath.contains('/incidents'), left: 44, onTap: () => context.go('/incidents')),
                        ],
                      ),
                      _SubExpandableNavItem(
                        label: 'Monitoring',
                        isActive: currentPath.contains('/payroll') || currentPath.contains('/labor-cost') || currentPath.startsWith('/production-measurement') || currentPath.startsWith('/monitoring') || currentPath.contains('/monitoring'),
                        initiallyExpanded: currentPath.contains('/payroll') || currentPath.contains('/labor-cost') || currentPath.startsWith('/production-measurement') || currentPath.startsWith('/monitoring') || currentPath.contains('/monitoring'),
                        children: [
                          _SubNavItem(icon: Icons.attach_money, label: 'Labor Cost', isActive: currentPath.contains('/payroll') || currentPath.contains('/labor-cost'), left: 44, onTap: () => context.go('/labor-cost')),
                          _SubNavItem(icon: Icons.speed, label: 'Production Metrics', isActive: currentPath.startsWith('/production-measurement'), left: 44, onTap: () => context.go('/production-measurement')),
                          _SubNavItem(icon: Icons.dashboard, label: 'Monitoring Dashboard', isActive: currentPath.contains('/monitoring'), left: 44, onTap: () => context.go('/monitoring')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _NavItem(icon: Icons.person_search_outlined, label: 'Customers', isActive: currentPath.startsWith('/customers'), onTap: () => context.go('/customers')),
                  const SizedBox(height: 4),
                  _NavItem(icon: Icons.folder_copy_outlined, label: 'Catalogs', isActive: currentPath.startsWith('/catalogs'), onTap: () => context.go('/catalogs')),
                  const SizedBox(height: 4),
                  _NavItem(icon: Icons.engineering_outlined, label: 'Workers', isActive: currentPath.startsWith('/workers'), onTap: () => context.go('/workers')),
                ],
              ),
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
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: onLogout,
                          child: const Icon(Icons.logout, color: AppTheme.slate400, size: 18),
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
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
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
          child: Row(children: [
            Icon(widget.icon, color: color, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(widget.label, style: GoogleFonts.manrope(color: color, fontSize: 14, fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w600), overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ExpandableNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool initiallyExpanded;
  final List<Widget> children;

  const _ExpandableNavItem({required this.icon, required this.label, required this.isActive, required this.initiallyExpanded, required this.children});

  @override
  State<_ExpandableNavItem> createState() => _ExpandableNavItemState();
}

class _ExpandableNavItemState extends State<_ExpandableNavItem> {
  bool _isHovered = false;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant _ExpandableNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initiallyExpanded != oldWidget.initiallyExpanded) {
      _isExpanded = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive ? AppTheme.primaryGreen : (_isHovered ? Colors.white : AppTheme.slate400);
    return Column(children: [
      MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isActive ? AppTheme.primaryGreen.withOpacity(0.1) : (_isHovered ? Colors.white.withOpacity(0.03) : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(widget.icon, color: color, size: 20),
              const SizedBox(width: 14),
              Expanded(child: Text(widget.label, style: GoogleFonts.manrope(color: color, fontSize: 14, fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w600))),
              AnimatedRotation(duration: const Duration(milliseconds: 200), turns: _isExpanded ? 0.5 : 0.0, child: Icon(Icons.expand_more, color: color, size: 18)),
            ]),
          ),
        ),
      ),
      AnimatedCrossFade(
        duration: const Duration(milliseconds: 200),
        crossFadeState: _isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        firstChild: Padding(padding: const EdgeInsets.only(left: 16), child: Column(children: widget.children)),
        secondChild: const SizedBox.shrink(),
      ),
    ]);
  }
}

class _SubExpandableNavItem extends StatefulWidget {
  final String label;
  final bool isActive;
  final bool initiallyExpanded;
  final List<Widget> children;

  const _SubExpandableNavItem({
    required this.label,
    required this.isActive,
    required this.initiallyExpanded,
    required this.children,
  });

  @override
  State<_SubExpandableNavItem> createState() => _SubExpandableNavItemState();
}

class _SubExpandableNavItemState extends State<_SubExpandableNavItem> {
  bool _isHovered = false;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant _SubExpandableNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initiallyExpanded != oldWidget.initiallyExpanded) {
      _isExpanded = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive ? AppTheme.primaryGreen : (_isHovered ? Colors.white : AppTheme.slate500);
    return Column(children: [
      MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.only(left: 36, right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? AppTheme.primaryGreen.withOpacity(0.08)
                  : (_isHovered ? Colors.white.withOpacity(0.03) : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: widget.isActive
                  ? const Border(left: BorderSide(color: AppTheme.primaryGreen, width: 3))
                  : null,
            ),
            child: Row(children: [
              Text(widget.label, style: GoogleFonts.manrope(color: color, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              const Spacer(),
              AnimatedRotation(duration: const Duration(milliseconds: 200), turns: _isExpanded ? 0.5 : 0.0, child: Icon(Icons.expand_more, color: color, size: 16)),
            ]),
          ),
        ),
      ),
      AnimatedCrossFade(
        duration: const Duration(milliseconds: 200),
        crossFadeState: _isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        firstChild: Padding(padding: const EdgeInsets.only(left: 16), child: Column(children: widget.children)),
        secondChild: const SizedBox.shrink(),
      ),
    ]);
  }
}

class _SubNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final double left;

  const _SubNavItem({required this.icon, required this.label, required this.isActive, required this.onTap, this.left = 36});

  @override
  State<_SubNavItem> createState() => _SubNavItemState();
}

class _SubNavItemState extends State<_SubNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive ? AppTheme.primaryGreen : (_isHovered ? Colors.white : AppTheme.slate400);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.only(left: widget.left, right: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: widget.isActive ? AppTheme.primaryGreen.withOpacity(0.08) : (_isHovered ? Colors.white.withOpacity(0.03) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(widget.icon, color: color, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(widget.label, style: GoogleFonts.manrope(color: color, fontSize: 12, fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500), overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      ),
    );
  }
}
