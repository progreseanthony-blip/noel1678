import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../../../../shared/widgets/top_header.dart';

class MonitoringProjectsPage extends StatefulWidget {
  const MonitoringProjectsPage({super.key});

  @override
  State<MonitoringProjectsPage> createState() => _MonitoringProjectsPageState();
}

class _MonitoringProjectsPageState extends State<MonitoringProjectsPage> {
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userName = currentUser?.userMetadata?['name'] ?? 'Admin User';
    final userEmail = currentUser?.email ?? '';
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      key: _mobileScaffoldKey,
      backgroundColor: AppTheme.backgroundLight,
      drawer: isMobile ? Drawer(
        backgroundColor: const Color(0xFF0F172A),
        child: Sidebar(
          userName: userName,
          userEmail: userEmail,
          currentPath: '/monitoring',
          onLogout: () async {
            await Supabase.instance.client.auth.signOut();
            if (context.mounted) context.go('/signin');
          },
        ),
      ) : null,
      body: Row(children: [
        if (!isMobile)
          Sidebar(
            userName: userName,
            userEmail: userEmail,
            currentPath: '/monitoring',
            onLogout: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/signin');
            },
          ),
        Expanded(
          child: Column(children: [
            if (!isMobile)
              TopHeader(userName: userName, breadcrumbs: const ['Projects', 'Monitoring Dashboard']),
            if (isMobile)
              _buildMobileHeader(userName),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                  : _projects.isEmpty
                      ? _emptyState()
                      : _buildProjectList(isMobile),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildMobileHeader(String userName) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16, bottom: 12),
      child: Row(children: [
        GestureDetector(
          onTap: () => _mobileScaffoldKey.currentState?.openDrawer(),
          child: const Icon(Icons.menu, color: AppTheme.slate700, size: 24),
        ),
        const SizedBox(width: 12),
        Text('Monitoring Dashboard', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
      ]),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.dashboard, size: 64, color: AppTheme.slate400),
        const SizedBox(height: 16),
        Text('No projects available', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.slate600)),
        const SizedBox(height: 8),
        Text('Create a project and submit daily reports to see monitoring data.', style: GoogleFonts.manrope(color: AppTheme.slate400)),
      ]),
    );
  }

  Widget _buildProjectList(bool isMobile) {
    return ListView.separated(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      itemCount: _projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final p = _projects[i];
        final title = p['title'] ?? 'N/A';
        final client = p['client_name'] ?? '-';

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppTheme.slate200)),
          child: InkWell(
            onTap: () => context.push('/projects/${p['id']}/monitoring'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.dashboard, color: AppTheme.primaryGreen, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.slate900)),
                    const SizedBox(height: 4),
                    Text('Client: $client', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate500)),
                  ]),
                ),
                Text('View Dashboard', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppTheme.slate400),
              ]),
            ),
          ),
        );
      },
    );
  }
}
