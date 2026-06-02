import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../../../../shared/widgets/top_header.dart';

void _showProjectMenu(BuildContext context, Map<String, dynamic> project) {
  final title = project['title'] ?? 'Project';
  final pid = project['id'] as String;

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.slate900)),
      content: Text('What would you like to do with this project?',
          style: GoogleFonts.manrope(color: AppTheme.slate500, fontSize: 13)),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/projects/$pid');
                },
                icon: const Icon(Icons.build_circle, size: 20),
                label: Text('Planificar Recursos', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.slate900,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/projects/$pid/daily-reports');
                },
                icon: const Icon(Icons.assignment, size: 20),
                label: Text('Reporte Diario', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.manrope(color: AppTheme.slate400, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    ),
  );
}

class ProjectsListPage extends StatefulWidget {
  const ProjectsListPage({super.key});

  @override
  State<ProjectsListPage> createState() => _ProjectsListPageState();
}

class _ProjectsListPageState extends State<ProjectsListPage> {
  List<Map<String, dynamic>>? _projects;
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  int _currentPage = 1;
  static const int _pageSize = 10;
  
  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client
          .from('projects')
          .select()
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _projects = List<Map<String, dynamic>>.from(response ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load projects: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredProjects {
    final base = _projects ?? [];
    if (_searchQuery.isEmpty) return base;
    
    final q = _searchQuery.toLowerCase();
    return base.where((u) {
      final title = (u['title'] ?? '').toString().toLowerCase();
      final client = (u['client_name'] ?? '').toString().toLowerCase();
      return title.contains(q) || client.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _paginatedProjects {
    final filtered = _filteredProjects;
    final start = (_currentPage - 1) * _pageSize;
    if (start >= filtered.length) return [];
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int get _totalPages => (_filteredProjects.length / _pageSize).ceil().clamp(1, 9999);

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userName = currentUser?.userMetadata?['name'] ?? 'Admin User';
    final userEmail = currentUser?.email ?? '';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      key: _mobileScaffoldKey,
      backgroundColor: AppTheme.backgroundLight,
      drawer: isMobile ? Drawer(
        backgroundColor: const Color(0xFF0F172A),
        child: Sidebar(
          userName: userName,
          userEmail: userEmail,
          currentPath: '/projects',
          onLogout: () async {
            await Supabase.instance.client.auth.signOut();
            if (context.mounted) context.go('/signin');
          },
        ),
      ) : null,
      body: Row(
        children: [
          if (!isMobile)
            Sidebar(
              userName: userName,
              userEmail: userEmail,
              currentPath: '/projects',
              onLogout: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/signin');
              },
            ),
          Expanded(
            child: Column(
              children: [
                if (!isMobile)
                  TopHeader(userName: userName, breadcrumbs: const ['Operations', 'Projects']),
                if (isMobile)
                  _buildMobileHeader(userName),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen, strokeWidth: 3))
                      : _error != null
                          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                          : _buildMainContent(isMobile),
                ),
              ],
            ),
          ),
        ],
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
          GestureDetector(
            onTap: () => _mobileScaffoldKey.currentState?.openDrawer(),
            child: const Icon(Icons.menu, color: AppTheme.slate700, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'Projects',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.slate900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Projects',
            style: GoogleFonts.manrope(
              fontSize: isMobile ? 24 : 30,
              fontWeight: FontWeight.w800,
              color: AppTheme.slate900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Monitor and manage your operational projects and machinery.',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppTheme.slate500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _buildSearchFilters(),
          const SizedBox(height: 24),
          _buildTable(isMobile),
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
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.slate200),
        ),
        child: TextField(
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
              _currentPage = 1;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search by title or client...',
            hintStyle: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: AppTheme.slate400, size: 18),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate900),
        ),
      ),
    );
  }

  Widget _buildTable(bool isMobile) {
    final items = _paginatedProjects;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        children: [
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  Expanded(flex: 25, child: _colHeader('PROJECT TITLE')),
                  Expanded(flex: 20, child: _colHeader('CLIENT')),
                  Expanded(flex: 15, child: _colHeader('START DATE')),
                  Expanded(flex: 15, child: _colHeader('STATUS')),
                ],
              ),
            ),
          if (items.isEmpty)
             const Padding(padding: EdgeInsets.all(32), child: Center(child: Text("No projects found.")))
          else
            ...items.map((q) => _buildTableRow(q, isMobile)),
            
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${items.isEmpty ? 0 : (_currentPage - 1) * _pageSize + 1}-${(_currentPage - 1) * _pageSize + items.length} of ${_filteredProjects.length} results',
                  style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    _buildPageButton(Icons.chevron_left, _currentPage > 1 ? () {
                      setState(() => _currentPage--);
                    } : null),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$_currentPage',
                        style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildPageButton(Icons.chevron_right, _currentPage < _totalPages ? () {
                      setState(() => _currentPage++);
                    } : null),
                  ],
                ),
              ],
            ),
          ),
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

  Widget _buildTableRow(Map<String, dynamic> project, bool isMobile) {
    final title = project['title'] ?? 'N/A';
    final status = project['status'] ?? 'active';
    final date = project['start_date'] != null 
      ? DateFormat('MMM dd, yyyy').format(DateTime.parse(project['start_date']).toLocal())
      : '-';

    if (isMobile) {
      return InkWell(
        onTap: () => _showProjectMenu(context, project),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(title, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold))),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 8),
              Text(project['client_name'] ?? '-', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate600)),
              const SizedBox(height: 4),
              Text('Started: $date', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate400)),
            ],
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showProjectMenu(context, project),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
          ),
          child: Row(
            children: [
              Expanded(flex: 25, child: Padding(padding: const EdgeInsets.only(right: 16), child: Text(title, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.slate900), overflow: TextOverflow.ellipsis, maxLines: 2))),
              Expanded(flex: 20, child: Padding(padding: const EdgeInsets.only(right: 16), child: Text(project['client_name'] ?? '-', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate700), overflow: TextOverflow.ellipsis, maxLines: 2))),
              Expanded(flex: 15, child: Text(date, style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate500))),
              Expanded(flex: 15, child: _buildStatusBadge(status)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    switch(status.toLowerCase()) {
      case 'active': bg = AppTheme.primaryGreen.withOpacity(0.1); text = AppTheme.primaryGreen; break;
      case 'completed': bg = Colors.blue.withOpacity(0.1); text = Colors.blue; break;
      case 'on_hold': bg = Colors.orange.withOpacity(0.1); text = Colors.orange; break;
      default: bg = AppTheme.slate200; text = AppTheme.slate700; break;
    }
    
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(
          status.toUpperCase(),
          style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: text, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _buildPageButton(IconData icon, VoidCallback? onTap) {
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.slate200),
          ),
          child: Icon(icon, size: 16, color: onTap != null ? AppTheme.slate700 : AppTheme.slate400),
        ),
      ),
    );
  }
}
