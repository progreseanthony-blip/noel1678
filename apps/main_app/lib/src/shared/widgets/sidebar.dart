import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import 'package:noel_data/noel_data.dart';

class Sidebar extends StatefulWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;
  final String currentPath;
  final double? width;
  final Future<AccessContext> Function()? accessLoader;

  const Sidebar({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
    required this.currentPath,
    this.width = 280,
    this.accessLoader,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  AccessContext? _access;
  Future<void> _loadAccess() async {
    AccessContext value;
    try {
      value =
          await (widget.accessLoader?.call() ??
              AccessService(Supabase.instance.client).load());
    } catch (_) {
      value = const AccessContext();
    }
    if (mounted) setState(() => _access = value);
  }

  final ScrollController _scrollController = ScrollController();

  final _userMgmtKey = GlobalKey();
  final _estimatesKey = GlobalKey();
  final _portfolioKey = GlobalKey();
  final _resourcePlanningKey = GlobalKey();
  final _receptionKey = GlobalKey();
  final _dailyReportsKey = GlobalKey();
  final _pendingApprovalsKey = GlobalKey();
  final _incidentsKey = GlobalKey();
  final _laborCostKey = GlobalKey();
  final _productionMetricsKey = GlobalKey();
  final _monitoringDashKey = GlobalKey();
  final _billingKey = GlobalKey();
  final _changeOrdersKey = GlobalKey();
  final _weeklyInspectionsKey = GlobalKey();
  final _customersKey = GlobalKey();
  final _catalogsKey = GlobalKey();
  final _workersKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadAccess();
    _scrollToActiveItem();
  }

  @override
  void didUpdateWidget(covariant Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPath != oldWidget.currentPath) {
      _scrollToActiveItem();
    }
  }

  void _scrollToActiveItem() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        _scrollToActiveKey();
      });
    });
  }

  void _scrollToActiveKey() {
    final path = widget.currentPath;
    GlobalKey? activeKey;

    if (path == '/' || path.startsWith('/users')) {
      activeKey = _userMgmtKey;
    } else if (path.startsWith('/quotes')) {
      activeKey = _estimatesKey;
    } else if (path == '/projects' || path.contains('/dashboard')) {
      activeKey = _portfolioKey;
    } else if (path.startsWith('/projects') &&
        !path.contains('/dashboard') &&
        path.endsWith('/baseline')) {
      activeKey = _resourcePlanningKey;
    } else if (path.startsWith('/resource-planning')) {
      activeKey = _resourcePlanningKey;
    } else if (path.contains('/reception')) {
      activeKey = _receptionKey;
    } else if (path.startsWith('/daily-reports/pending')) {
      activeKey = _pendingApprovalsKey;
    } else if (path.startsWith('/daily-reports') ||
        path.contains('/daily-report')) {
      activeKey = _dailyReportsKey;
    } else if (path.startsWith('/incidents') || path.contains('/incidents')) {
      activeKey = _incidentsKey;
    } else if (path.contains('/payroll') || path.contains('/labor-cost')) {
      activeKey = _laborCostKey;
    } else if (path.contains('/production-measurement')) {
      activeKey = _productionMetricsKey;
    } else if (path.contains('/monitoring')) {
      activeKey = _monitoringDashKey;
    } else if (path.contains('/billing')) {
      activeKey = _billingKey;
    } else if (path.contains('/change-orders')) {
      activeKey = _changeOrdersKey;
    } else if (path.startsWith('/weekly-inspections') ||
        path.contains('/weekly-inspections')) {
      activeKey = _weeklyInspectionsKey;
    } else if (path.startsWith('/customers')) {
      activeKey = _customersKey;
    } else if (path.startsWith('/catalogs')) {
      activeKey = _catalogsKey;
    } else if (path.startsWith('/workers')) {
      activeKey = _workersKey;
    }

    if (activeKey?.currentContext != null) {
      Scrollable.ensureVisible(
        activeKey!.currentContext!,
        alignment: 0.35,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildBrand() => Padding(
    padding: const EdgeInsets.all(28),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Icon(Icons.golf_course, color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Global Golf',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              Text(
                'CONSTRUCTION',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  color: AppTheme.primaryGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildAccountPanel({required bool includeSettings}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
    ),
    child: Column(
      children: [
        if (includeSettings) ...[
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            isActive: false,
            onTap: () {},
          ),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryGreen.withOpacity(0.15),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withOpacity(0.25),
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppTheme.primaryGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!includeSettings)
                      Text(
                        _access?.role ?? 'Access pending',
                        style: GoogleFonts.manrope(
                          color: AppTheme.slate400,
                          fontSize: 11,
                        ),
                      ),
                    Text(
                      widget.userEmail,
                      style: GoogleFonts.manrope(
                        color: AppTheme.slate400,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Sign out',
                onPressed: widget.onLogout,
                icon: const Icon(
                  Icons.logout,
                  color: AppTheme.slate400,
                  size: 18,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildSidebarShell({
    required Widget navigation,
    bool includeSettings = false,
  }) => SizedBox(
    width: widget.width,
    child: Material(
      color: AppTheme.slate900,
      child: SafeArea(
        child: Column(
          children: [
            _buildBrand(),
            Expanded(
              child: ScrollIndicator(
                controller: _scrollController,
                backgroundColor: AppTheme.slate900,
                iconColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: navigation,
              ),
            ),
            _buildAccountPanel(includeSettings: includeSettings),
          ],
        ),
      ),
    ),
  );

  GlobalKey? _restrictedKey(String target) => switch (target) {
    '/projects' => _portfolioKey,
    '/resource-planning' => _resourcePlanningKey,
    '/daily-reports' => _dailyReportsKey,
    '/daily-reports/pending' => _pendingApprovalsKey,
    '/labor-cost' => _laborCostKey,
    _ => null,
  };

  bool _restrictedActive(String path, String target) => switch (target) {
    '/projects' => path == '/projects',
    '/resource-planning' =>
      path == target ||
          RegExp(r'^/projects/[^/]+(?:/baseline|/timeline)?$').hasMatch(path),
    '/daily-reports' =>
      path == target ||
          RegExp(r'^/projects/[^/]+/daily-reports?(?:/.*)?$').hasMatch(path),
    '/daily-reports/pending' => path == target,
    '/labor-cost' =>
      path == target || RegExp(r'^/projects/[^/]+/labor-hours$').hasMatch(path),
    _ => path == target,
  };

  @override
  Widget build(BuildContext context) {
    final currentPath = widget.currentPath;
    if (_access?.isAdmin != true) {
      final access = _access;
      final links = <(String, String, IconData)>[
        if (access?.isSupervisor == true) ...[
          ('Projects', '/projects', Icons.folder_outlined),
          (
            'Resource Planning',
            '/resource-planning',
            Icons.build_circle_outlined,
          ),
          ('Daily Reports', '/daily-reports', Icons.assignment_outlined),
          (
            'Pending Approvals',
            '/daily-reports/pending',
            Icons.fact_check_outlined,
          ),
        ],
        if (access?.isActive == true) ...[
          if (access?.isForeman == true)
            ('Daily Reports', '/daily-reports', Icons.assignment_outlined),
          ('Labor Cost', '/labor-cost', Icons.schedule),
        ],
      ];
      return _buildSidebarShell(
        navigation: Column(
          children: [
            if (access == null) const LinearProgressIndicator(),
            for (final link in links)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _NavItem(
                  key: _restrictedKey(link.$2),
                  icon: link.$3,
                  label: link.$1,
                  isActive: _restrictedActive(currentPath, link.$2),
                  onTap: () => context.go(link.$2),
                ),
              ),
          ],
        ),
      );
    }
    return _buildSidebarShell(
      includeSettings: true,
      navigation: Column(
        children: [
          _NavItem(
            key: _userMgmtKey,
            icon: Icons.group_outlined,
            label: 'User Management',
            isActive: currentPath.startsWith('/users') || currentPath == '/',
            onTap: () => context.go('/users'),
          ),
          const SizedBox(height: 4),
          _NavItem(
            key: _estimatesKey,
            icon: Icons.request_quote_rounded,
            label: 'Estimates',
            isActive: currentPath.startsWith('/quotes'),
            onTap: () => context.go('/quotes'),
          ),
          const SizedBox(height: 4),
          _ExpandableNavItem(
            icon: Icons.rocket_launch_outlined,
            label: 'Projects',
            isActive:
                currentPath.startsWith('/projects') ||
                currentPath.startsWith('/resource-planning') ||
                currentPath.startsWith('/daily-reports') ||
                currentPath.startsWith('/payroll') ||
                currentPath.startsWith('/labor-cost') ||
                currentPath.startsWith('/production-measurement') ||
                currentPath.startsWith('/monitoring') ||
                currentPath.startsWith('/billing') ||
                currentPath.startsWith('/change-orders') ||
                currentPath.startsWith('/incidents') ||
                currentPath.startsWith('/reception') ||
                currentPath.startsWith('/weekly-inspections'),
            initiallyExpanded:
                currentPath.startsWith('/projects') ||
                currentPath.startsWith('/resource-planning') ||
                currentPath.startsWith('/daily-reports') ||
                currentPath.startsWith('/payroll') ||
                currentPath.startsWith('/labor-cost') ||
                currentPath.startsWith('/production-measurement') ||
                currentPath.startsWith('/monitoring') ||
                currentPath.startsWith('/billing') ||
                currentPath.startsWith('/change-orders') ||
                currentPath.startsWith('/incidents') ||
                currentPath.startsWith('/reception') ||
                currentPath.startsWith('/weekly-inspections'),
            scrollController: _scrollController,
            children: [
              _SubNavItem(
                key: _portfolioKey,
                icon: Icons.space_dashboard,
                label: 'Portfolio',
                isActive:
                    currentPath == '/projects' ||
                    currentPath.endsWith('/dashboard'),
                onTap: () => context.go('/projects'),
              ),
              _SubExpandableNavItem(
                label: 'Planning',
                isActive:
                    currentPath.startsWith('/projects') &&
                        currentPath != '/projects' &&
                        !currentPath.endsWith('/dashboard') &&
                        (currentPath.endsWith('/baseline') ||
                            currentPath.contains('/reception')) ||
                    currentPath.startsWith('/reception') ||
                    currentPath.startsWith('/resource-planning'),
                initiallyExpanded: true,
                scrollController: _scrollController,
                children: [
                  _SubNavItem(
                    key: _resourcePlanningKey,
                    indent: 4,
                    icon: Icons.build_circle,
                    label: 'Resource Planning',
                    isActive:
                        currentPath.startsWith('/projects') &&
                            currentPath != '/projects' &&
                            !currentPath.endsWith('/dashboard') &&
                            (currentPath.split('/').length <= 3 ||
                                currentPath.endsWith('/baseline')) ||
                        currentPath.startsWith('/resource-planning'),
                    onTap: () {
                      final projectId = currentPath
                          .replaceAll(RegExp(r'/projects/'), '')
                          .split('/')
                          .first;
                      if (projectId.isNotEmpty) {
                        context.go('/projects/$projectId');
                      } else {
                        context.go('/resource-planning');
                      }
                    },
                  ),
                  _SubNavItem(
                    key: _receptionKey,
                    indent: 4,
                    icon: Icons.inventory,
                    label: 'Receive / Return',
                    isActive: currentPath.contains('/reception'),
                    onTap: () {
                      final projectId = currentPath
                          .replaceAll(RegExp(r'/projects/'), '')
                          .split('/')
                          .first;
                      if (projectId.isNotEmpty) {
                        context.go('/projects/$projectId/reception');
                      } else {
                        context.go('/reception');
                      }
                    },
                  ),
                ],
              ),
              _SubExpandableNavItem(
                label: 'Field Execution',
                isActive:
                    currentPath.startsWith('/daily-reports') ||
                    currentPath.startsWith('/incidents') ||
                    currentPath.startsWith('/weekly-inspections') ||
                    currentPath.contains('/weekly-inspections'),
                initiallyExpanded:
                    currentPath.startsWith('/daily-reports') ||
                    currentPath.startsWith('/incidents') ||
                    currentPath.startsWith('/weekly-inspections') ||
                    currentPath.contains('/weekly-inspections'),
                scrollController: _scrollController,
                children: [
                  _SubNavItem(
                    key: _dailyReportsKey,
                    indent: 4,
                    icon: Icons.assignment,
                    label: 'Daily Reports',
                    isActive:
                        (currentPath.startsWith('/daily-reports') &&
                            !currentPath.contains('/pending')) ||
                        currentPath.contains('/daily-report'),
                    onTap: () => context.go('/daily-reports'),
                  ),
                  _SubNavItem(
                    key: _pendingApprovalsKey,
                    indent: 4,
                    icon: Icons.fact_check_outlined,
                    label: 'Pending Approvals',
                    isActive: currentPath.startsWith('/daily-reports/pending'),
                    onTap: () => context.go('/daily-reports/pending'),
                  ),
                  _SubNavItem(
                    key: _incidentsKey,
                    indent: 4,
                    icon: Icons.warning_amber_rounded,
                    label: 'Incidents',
                    isActive:
                        currentPath.startsWith('/incidents') ||
                        currentPath.contains('/incidents'),
                    onTap: () => context.go('/incidents'),
                  ),
                  _SubNavItem(
                    key: _weeklyInspectionsKey,
                    indent: 4,
                    icon: Icons.satellite_alt,
                    label: 'Weekly Inspections',
                    isActive:
                        currentPath.startsWith('/weekly-inspections') ||
                        currentPath.contains('/weekly-inspections'),
                    onTap: () => context.go('/weekly-inspections'),
                  ),
                ],
              ),
              _SubExpandableNavItem(
                label: 'Monitoring',
                isActive:
                    currentPath.contains('/payroll') ||
                    currentPath.contains('/labor-cost') ||
                    currentPath.contains('/production-measurement') ||
                    currentPath.contains('/monitoring') ||
                    currentPath.contains('/billing') ||
                    currentPath.contains('/change-orders'),
                initiallyExpanded:
                    currentPath.contains('/payroll') ||
                    currentPath.contains('/labor-cost') ||
                    currentPath.contains('/production-measurement') ||
                    currentPath.contains('/monitoring') ||
                    currentPath.contains('/billing') ||
                    currentPath.contains('/change-orders'),
                scrollController: _scrollController,
                children: [
                  _SubNavItem(
                    key: _laborCostKey,
                    indent: 4,
                    icon: Icons.attach_money,
                    label: 'Labor Cost',
                    isActive:
                        currentPath.contains('/payroll') ||
                        currentPath.contains('/labor-cost'),
                    onTap: () => context.go('/labor-cost'),
                  ),
                  _SubNavItem(
                    key: _productionMetricsKey,
                    indent: 4,
                    icon: Icons.speed,
                    label: 'Production Metrics',
                    isActive: currentPath.contains('/production-measurement'),
                    onTap: () => context.go('/production-measurement'),
                  ),
                  _SubNavItem(
                    key: _monitoringDashKey,
                    indent: 4,
                    icon: Icons.dashboard,
                    label: 'Monitoring Dashboard',
                    isActive: currentPath.contains('/monitoring'),
                    onTap: () => context.go('/monitoring'),
                  ),
                  _SubNavItem(
                    key: _billingKey,
                    indent: 4,
                    icon: Icons.receipt_long_outlined,
                    label: 'Billing',
                    isActive: currentPath.contains('/billing'),
                    onTap: () {
                      final projectId = currentPath
                          .replaceAll(RegExp(r'/projects/'), '')
                          .split('/')
                          .first;
                      if (projectId.isNotEmpty)
                        context.go('/projects/$projectId/billing');
                      else
                        context.go('/billing');
                    },
                  ),
                  _SubNavItem(
                    key: _changeOrdersKey,
                    indent: 4,
                    icon: Icons.swap_horizontal_circle_outlined,
                    label: 'Change Orders',
                    isActive: currentPath.contains('/change-orders'),
                    onTap: () {
                      final projectId = currentPath
                          .replaceAll(RegExp(r'/projects/'), '')
                          .split('/')
                          .first;
                      if (projectId.isNotEmpty)
                        context.go('/projects/$projectId/change-orders');
                      else
                        context.go('/change-orders');
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          _NavItem(
            key: _customersKey,
            icon: Icons.person_search_outlined,
            label: 'Customers',
            isActive: currentPath.startsWith('/customers'),
            onTap: () => context.go('/customers'),
          ),
          const SizedBox(height: 4),
          _NavItem(
            key: _catalogsKey,
            icon: Icons.folder_copy_outlined,
            label: 'Catalogs',
            isActive: currentPath.startsWith('/catalogs'),
            onTap: () => context.go('/catalogs'),
          ),
          const SizedBox(height: 4),
          _NavItem(
            key: _workersKey,
            icon: Icons.engineering_outlined,
            label: 'Workers',
            isActive: currentPath.startsWith('/workers'),
            onTap: () => context.go('/workers'),
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

  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive
        ? AppTheme.primaryGreen
        : (_isHovered ? Colors.white : AppTheme.slate400);
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
            color: widget.isActive
                ? AppTheme.primaryGreen.withOpacity(0.1)
                : (_isHovered
                      ? Colors.white.withOpacity(0.03)
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: color, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.manrope(
                    color: color,
                    fontSize: 14,
                    fontWeight: widget.isActive
                        ? FontWeight.w700
                        : FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
  final ScrollController? scrollController;

  const _ExpandableNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.initiallyExpanded,
    required this.children,
    this.scrollController,
  });

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

  void _toggleExpand() {
    final wasExpanded = _isExpanded;
    setState(() => _isExpanded = !_isExpanded);
    final controller = widget.scrollController;
    if (!wasExpanded && controller != null && controller.hasClients) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (controller.hasClients) {
          final position = controller.position;
          if (position.extentAfter < 140) {
            controller.animateTo(
              position.pixels + 140,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive
        ? AppTheme.primaryGreen
        : (_isHovered ? Colors.white : AppTheme.slate400);
    return Column(
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _toggleExpand,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.isActive
                    ? AppTheme.primaryGreen.withOpacity(0.1)
                    : (_isHovered
                          ? Colors.white.withOpacity(0.03)
                          : Colors.transparent),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: color, size: 20),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: GoogleFonts.manrope(
                        color: color,
                        fontSize: 14,
                        fontWeight: widget.isActive
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isExpanded ? 0.5 : 0.0,
                    child: Icon(Icons.expand_more, color: color, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppTheme.slate700, width: 1.5),
                ),
              ),
              padding: const EdgeInsets.only(left: 32),
              child: Column(children: widget.children),
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _SubExpandableNavItem extends StatefulWidget {
  final String label;
  final bool isActive;
  final bool initiallyExpanded;
  final List<Widget> children;
  final ScrollController? scrollController;

  const _SubExpandableNavItem({
    required this.label,
    required this.isActive,
    required this.initiallyExpanded,
    required this.children,
    this.scrollController,
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

  void _toggleExpand() {
    final wasExpanded = _isExpanded;
    setState(() => _isExpanded = !_isExpanded);
    final controller = widget.scrollController;
    if (!wasExpanded && controller != null && controller.hasClients) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (controller.hasClients) {
          final position = controller.position;
          if (position.extentAfter < 120) {
            controller.animateTo(
              position.pixels + 120,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive
        ? AppTheme.primaryGreen
        : (_isHovered ? Colors.white : AppTheme.slate400);
    return Column(
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _toggleExpand,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.only(
                left: 4,
                right: 16,
                top: 10,
                bottom: 10,
              ),
              decoration: BoxDecoration(
                color: widget.isActive
                    ? AppTheme.primaryGreen.withOpacity(0.08)
                    : (_isHovered
                          ? Colors.white.withOpacity(0.03)
                          : Colors.transparent),
                borderRadius: BorderRadius.circular(8),
                border: widget.isActive
                    ? const Border(
                        left: BorderSide(
                          color: AppTheme.primaryGreen,
                          width: 3,
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Text(
                    widget.label,
                    style: GoogleFonts.manrope(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isExpanded ? 0.5 : 0.0,
                    child: Icon(Icons.expand_more, color: color, size: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(left: 0),
            child: Container(
              decoration: BoxDecoration(
                border: const Border(
                  left: BorderSide(color: Color(0xFF334155), width: 1.5),
                ),
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(0, 4, 4, 4),
              child: Column(children: widget.children),
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _SubNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final double indent;

  const _SubNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.indent = 28.0,
  });

  @override
  State<_SubNavItem> createState() => _SubNavItemState();
}

class _SubNavItemState extends State<_SubNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive
        ? AppTheme.primaryGreen
        : (_isHovered ? Colors.white : AppTheme.slate400);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.only(
            left: widget.indent,
            right: 16,
            top: 10,
            bottom: 10,
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppTheme.primaryGreen.withOpacity(0.08)
                : (_isHovered
                      ? Colors.white.withOpacity(0.03)
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: color, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.manrope(
                    color: color,
                    fontSize: 13,
                    fontWeight: widget.isActive
                        ? FontWeight.w600
                        : FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
