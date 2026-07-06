import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_data/noel_data.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../../../../shared/widgets/top_header.dart';
import '../widgets/inspection_card.dart';

class WeeklyInspectionsListPage extends StatefulWidget {
  final String projectId;
  const WeeklyInspectionsListPage({super.key, required this.projectId});

  @override
  State<WeeklyInspectionsListPage> createState() =>
      _WeeklyInspectionsListPageState();
}

class _WeeklyInspectionsListPageState extends State<WeeklyInspectionsListPage> {
  List<Map<String, dynamic>> _inspections = [];
  Map<String, dynamic>? _project;
  bool _isLoading = true;
  String? _error;
  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final supabase = Supabase.instance.client;
      final service = InspectionService(supabase);

      final project = await supabase
          .from('projects')
          .select('id, title')
          .eq('id', widget.projectId)
          .maybeSingle();
      final inspections = await service.getInspectionsByProject(widget.projectId);

      if (mounted) {
        setState(() {
          _project = project;
          _inspections = inspections;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userName = currentUser?.userMetadata?['name'] ?? 'Admin User';
    final userEmail = currentUser?.email ?? '';
    final isMobile = MediaQuery.of(context).size.width < 768;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      key: _mobileScaffoldKey,
      backgroundColor: const Color(0xFF0F172A),
      drawer: isMobile
          ? Drawer(
              backgroundColor: const Color(0xFF0F172A),
              child: Sidebar(
                userName: userName,
                userEmail: userEmail,
                currentPath: '/projects/${widget.projectId}/weekly-inspections',
                onLogout: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) context.go('/signin');
                },
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            Sidebar(
              userName: userName,
              userEmail: userEmail,
              currentPath: '/projects/${widget.projectId}/weekly-inspections',
              onLogout: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/signin');
              },
            ),
          Expanded(
            child: Column(
              children: [
                if (!isMobile)
                  TopHeader(
                    userName: userName,
                    breadcrumbs: [
                      'Operations',
                      'Projects',
                      _project?['title'] ?? 'Project',
                      'Weekly Inspections'
                    ],
                  ),
                if (isMobile) _buildMobileHeader(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primaryGreen))
                      : _error != null
                          ? _buildError()
                          : _buildContent(isMobile, dateFormat),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          '/projects/${widget.projectId}/weekly-inspections/new',
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: const Color(0xFF0F172A),
        icon: const Icon(Icons.add),
        label: Text(
          'New Inspection',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      color: const Color(0xFF1E293B),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _mobileScaffoldKey.currentState?.openDrawer(),
            child: const Icon(Icons.menu, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Weekly Inspections',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isMobile, DateFormat dateFormat) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back,
                    size: 16, color: AppTheme.slate400),
                const SizedBox(width: 6),
                Text(
                  'Back to Project',
                  style: GoogleFonts.manrope(
                    color: AppTheme.slate400,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Weekly Inspections',
            style: GoogleFonts.manrope(
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            _project?['title'] ?? '',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.slate400,
            ),
          ),
          const SizedBox(height: 24),
          if (_inspections.isEmpty)
            _buildEmptyState()
          else
            for (final inspection in _inspections) ...[
              InspectionCard(
                inspection: inspection,
                projectId: widget.projectId,
                dateFormat: dateFormat,
                onTap: () => context.push(
                  '/projects/${widget.projectId}/weekly-inspections/${inspection['id']}',
                ),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.satellite_alt_outlined,
              size: 64, color: AppTheme.slate600.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No inspections yet',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Register a drone or GPS inspection\nto start comparing progress.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppTheme.slate500,
            ),
          ),
        ],
      ),
    );
  }
}
