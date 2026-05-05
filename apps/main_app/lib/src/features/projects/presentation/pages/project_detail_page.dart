import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../../../../shared/widgets/top_header.dart';
import '../widgets/machinery_reception_dialog.dart';
import '../widgets/machinery_history_dialog.dart';
import '../widgets/material_reception_dialog.dart';
import '../widgets/material_history_dialog.dart';
import '../widgets/labor_checkin_dialog.dart';
import '../widgets/labor_history_dialog.dart';
import '../widgets/worker_assignment_dialog.dart';

class ProjectDetailPage extends StatefulWidget {
  final String projectId;
  const ProjectDetailPage({super.key, required this.projectId});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _project;
  List<Map<String, dynamic>> _machinery = [];
  List<Map<String, dynamic>> _materials = [];
  List<Map<String, dynamic>> _labor = [];
  Map<String, String?> _machineryPhotos = {};
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  String _selectedServiceFilter = 'All Services';
  List<String> _projectServices = [];

  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProjectData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final supabase = Supabase.instance.client;
      debugPrint('Loading project data for: ${widget.projectId}');

      // 1. Project Details
      final pResult = await supabase.from('projects').select().eq('id', widget.projectId).maybeSingle();
      if (pResult == null) throw 'Project not found';

      // 2. Machinery
      final mResult = await supabase.from('project_machinery').select('*, quote_service_machineries(quote_services(name))').eq('project_id', widget.projectId).order('machinery_name');

      // 3. Materials
      final matResult = await supabase.from('project_materials').select('*, quote_service_materials(quote_services(name))').eq('project_id', widget.projectId).order('material_name');

      // 4. Labor
      final labResult = await supabase.from('project_labor').select('*, quote_service_labors(quote_services(name)), project_labor_assignments(count)').eq('project_id', widget.projectId).order('role_name');

      // 5. Machinery Photos (Catalog)
      final photoMap = <String, String?>{};
      try {
        final catResult = await supabase.from('machinery').select('description, photo_url');
        if (catResult != null && catResult is List) {
          for (final item in catResult) {
            if (item['description'] != null) {
              photoMap[item['description'].toString()] = item['photo_url']?.toString();
            }
          }
        }
      } catch (e) {
        debugPrint('Non-critical error loading photos: $e');
      }

      if (mounted) {
        final allServices = <String>{'All Services'};
        
        void addServiceSafely(dynamic list, String relationName) {
          if (list == null || list is! List) return;
          for (final item in list) {
            try {
              final data = item[relationName];
              dynamic service;
              if (data is List && data.isNotEmpty) {
                service = data[0]['quote_services'];
              } else if (data is Map) {
                service = data['quote_services'];
              }
              
              if (service != null) {
                final name = (service is List && service.isNotEmpty) 
                    ? service[0]['name'] 
                    : (service is Map ? service['name'] : null);
                if (name != null) allServices.add(name.toString());
              }
            } catch (_) {}
          }
        }

        addServiceSafely(mResult, 'quote_service_machineries');
        addServiceSafely(matResult, 'quote_service_materials');
        addServiceSafely(labResult, 'quote_service_labors');

        setState(() {
          _project = pResult;
          _machinery = List<Map<String, dynamic>>.from(mResult as List? ?? []);
          _materials = List<Map<String, dynamic>>.from(matResult as List? ?? []);
          _labor = List<Map<String, dynamic>>.from(labResult as List? ?? []);
          _machineryPhotos = photoMap;
          _projectServices = allServices.toList()..sort((a, b) => a == 'All Services' ? -1 : a.compareTo(b));
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('CRITICAL ERROR in _loadProjectData: $e');
      if (mounted) {
        setState(() {
          _error = 'Error loading project: $e';
          _isLoading = false;
        });
      }
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupByService(List<Map<String, dynamic>> items, String relationName) {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final item in items) {
      final data = item[relationName];
      String serviceName = 'General / Unassigned';
      
      if (data != null) {
        dynamic service;
        if (data is List && data.isNotEmpty) {
          service = data[0]['quote_services'];
        } else if (data is Map) {
          service = data['quote_services'];
        }
        
        if (service != null) {
          final name = (service is List && service.isNotEmpty) 
              ? service[0]['name'] 
              : (service is Map ? service['name'] : null);
          if (name != null) serviceName = name.toString();
        }
      }
      
      if (!groups.containsKey(serviceName)) {
        groups[serviceName] = [];
      }
      groups[serviceName]!.add(item);
    }
    return groups;
  }

  Widget _buildServiceHeader(String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 14, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 10),
          Text(
            name.toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 11, 
              fontWeight: FontWeight.w900, 
              color: AppTheme.slate600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: AppTheme.slate200, thickness: 1)),
        ],
      ),
    );
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
                  TopHeader(userName: userName, breadcrumbs: const ['Operations', 'Projects', 'Details']),
                if (isMobile)
                  _buildMobileHeader(userName),
                  
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
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
            'Project Details',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(isMobile ? 16 : 32, isMobile ? 12 : 16, isMobile ? 16 : 32, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.go('/projects'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back, size: 16, color: AppTheme.slate500),
                    const SizedBox(width: 6),
                    Text('Back to Projects', style: GoogleFonts.manrope(color: AppTheme.slate500, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      _project?['title'] ?? 'Unknown Project',
                      style: GoogleFonts.manrope(
                        fontSize: isMobile ? 20 : 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.slate900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  _buildStatusBadge(_project?['status'] ?? 'active'),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Client: ${_project?['client_name'] ?? '-'}',
                style: GoogleFonts.manrope(fontSize: 15, color: AppTheme.slate600, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              
              // Service Filter
              _buildServiceFilterBar(),
              const SizedBox(height: 16),
              
              // Tabs
              TabBar(
                controller: _tabController,
                isScrollable: isMobile,
                labelColor: AppTheme.primaryGreen,
                unselectedLabelColor: AppTheme.slate500,
                indicatorColor: AppTheme.primaryGreen,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14),
                tabs: const [
                  Tab(text: 'Machinery'),
                  Tab(text: 'Materials'),
                  Tab(text: 'Labor'),
                ],
              ),
            ],
          ),
        ),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMachineryTab(isMobile),
              _buildMaterialsTab(isMobile),
              _buildLaborTab(isMobile),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceFilterBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FILTER BY SERVICE',
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppTheme.slate500,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _projectServices.length,
            itemBuilder: (context, index) {
              final service = _projectServices[index];
              final isSelected = _selectedServiceFilter == service;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(service),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() => _selectedServiceFilter = service);
                  },
                  labelStyle: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.slate600,
                  ),
                  backgroundColor: Colors.white,
                  selectedColor: AppTheme.primaryGreen,
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryGreen : AppTheme.slate200,
                    ),
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMachineryTab(bool isMobile) {
    if (_machinery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.precision_manufacturing_outlined, size: 64, color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text('No machinery registered for this project.', style: GoogleFonts.manrope(color: AppTheme.slate500)),
          ],
        ),
      );
    }

    final grouped = _groupByService(_machinery, 'quote_service_machineries');
    
    final serviceNames = grouped.keys.toList()
        .where((s) => _selectedServiceFilter == 'All Services' || s == _selectedServiceFilter)
        .toList()
        ..sort();

    if (serviceNames.isEmpty) {
      return Center(
        child: Text(
          'No machinery found for this service filter.',
          style: GoogleFonts.manrope(color: AppTheme.slate500),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      itemCount: serviceNames.length,
      itemBuilder: (context, sIndex) {
        final sName = serviceNames[sIndex];
        final groupItems = grouped[sName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServiceHeader(sName),
            ...groupItems.map((m) {
              final mName = m['machinery_name'] ?? 'Unknown Machine';
              final expected = (m['expected_quantity'] as num?)?.toInt() ?? 0;
              final received = (m['received_quantity'] as num?)?.toInt() ?? 0;
              final isComplete = received >= expected;
              final photoUrl = _machineryPhotos[mName];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.slate200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: isComplete ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        image: photoUrl != null && photoUrl.isNotEmpty
                            ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                            : null,
                      ),
                      child: (photoUrl == null || photoUrl.isEmpty) 
                        ? Icon(
                            Icons.precision_manufacturing, 
                            color: isComplete ? AppTheme.primaryGreen : Colors.orange,
                          )
                        : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m['machinery_name'] ?? 'Unknown Machine',
                            style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.slate900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Received: $received / $expected',
                            style: GoogleFonts.manrope(
                              fontSize: 13, 
                              fontWeight: FontWeight.w600,
                              color: isComplete ? AppTheme.primaryGreen : AppTheme.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (received > 0)
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierColor: Colors.black.withOpacity(0.5),
                            builder: (_) => MachineryHistoryDialog(
                              projectId: widget.projectId,
                              projectMachineryId: m['id'],
                              machineryName: mName,
                              serviceName: sName,
                            ),
                          ).then((updated) {
                            if (updated == true) _loadProjectData();
                          });
                        },
                        icon: const Icon(Icons.history, color: AppTheme.primaryGreen),
                        tooltip: 'View History & Edit',
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    if (received > 0) const SizedBox(width: 8),
                    if (!isComplete)
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierColor: Colors.black.withOpacity(0.5),
                            builder: (_) => MachineryReceptionDialog(
                              projectId: widget.projectId,
                              projectMachineryId: m['id'],
                              machineryName: mName,
                              serviceName: sName,
                            ),
                          ).then((received) {
                            if (received == true) {
                              _loadProjectData();
                            }
                          });
                        },
                        icon: const Icon(Icons.qr_code_scanner, size: 16, color: Colors.white),
                        label: Text('Receive', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildLaborStatusInfo(String label, int current, int total, Color color) {
    final isComplete = current >= total;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: isComplete ? color : AppTheme.slate200,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $current / $total',
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isComplete ? AppTheme.slate900 : AppTheme.slate500,
          ),
        ),
      ],
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
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: text, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildMaterialsTab(bool isMobile) {
    if (_materials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text('No materials registered for this project.', style: GoogleFonts.manrope(color: AppTheme.slate500)),
          ],
        ),
      );
    }

    final grouped = _groupByService(_materials, 'quote_service_materials');
    
    final serviceNames = grouped.keys.toList()
        .where((s) => _selectedServiceFilter == 'All Services' || s == _selectedServiceFilter)
        .toList()
        ..sort();

    if (serviceNames.isEmpty) {
      return Center(
        child: Text(
          'No materials found for this service filter.',
          style: GoogleFonts.manrope(color: AppTheme.slate500),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      itemCount: serviceNames.length,
      itemBuilder: (context, sIndex) {
        final sName = serviceNames[sIndex];
        final groupItems = grouped[sName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServiceHeader(sName),
            ...groupItems.map((m) {
              final expected = (m['expected_quantity'] as num?)?.toDouble() ?? 0.0;
              final received = (m['received_quantity'] as num?)?.toDouble() ?? 0.0;
              final isComplete = received >= expected;
              final mName = m['material_name'] ?? 'Unknown Material';
              final unitName = m['unit_name'] ?? 'units';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.slate200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: isComplete ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.inventory, 
                        color: isComplete ? AppTheme.primaryGreen : Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mName,
                            style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.slate900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Received: $received / $expected $unitName',
                            style: GoogleFonts.manrope(
                              fontSize: 13, 
                              fontWeight: FontWeight.w600,
                              color: isComplete ? AppTheme.primaryGreen : AppTheme.slate500,
                            ),
                          ),
                          if (!isComplete && expected > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              height: 6,
                              width: double.infinity,
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(3)),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: (received / expected).clamp(0.0, 1.0),
                                child: Container(decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(3))),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (received > 0)
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierColor: Colors.black.withOpacity(0.5),
                            builder: (_) => MaterialHistoryDialog(
                              projectId: widget.projectId,
                              projectMaterialId: m['id'],
                              materialName: mName,
                              serviceName: sName,
                              unitName: unitName,
                              expectedQuantity: expected,
                            ),
                          ).then((updated) {
                            if (updated == true) _loadProjectData();
                          });
                        },
                        icon: const Icon(Icons.history, color: AppTheme.primaryGreen),
                        tooltip: 'View History & Edit',
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    if (received > 0) const SizedBox(width: 8),
                    if (!isComplete || received > 0)
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierColor: Colors.black.withOpacity(0.5),
                            builder: (_) => MaterialReceptionDialog(
                              projectId: widget.projectId,
                              projectMaterialId: m['id'],
                              materialName: mName,
                              serviceName: sName,
                              unitName: unitName,
                              expectedQuantity: expected,
                              currentReceived: received,
                            ),
                          ).then((received) {
                            if (received == true) {
                              _loadProjectData();
                            }
                          });
                        },
                        icon: const Icon(Icons.add_box, size: 16, color: Colors.white),
                        label: Text('Receive', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isComplete ? AppTheme.slate400 : Colors.blue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildLaborTab(bool isMobile) {
    if (_labor.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text('No labor resources registered for this project.', style: GoogleFonts.manrope(color: AppTheme.slate500)),
          ],
        ),
      );
    }

    final grouped = _groupByService(_labor, 'quote_service_labors');
    
    final serviceNames = grouped.keys.toList()
        .where((s) => _selectedServiceFilter == 'All Services' || s == _selectedServiceFilter)
        .toList()
        ..sort();

    if (serviceNames.isEmpty) {
      return Center(
        child: Text(
          'No labor found for this service filter.',
          style: GoogleFonts.manrope(color: AppTheme.slate500),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      itemCount: serviceNames.length,
      itemBuilder: (context, sIndex) {
        final sName = serviceNames[sIndex];
        final groupItems = grouped[sName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServiceHeader(sName),
            ...groupItems.map((l) {
              final expected = (l['expected_employees'] as num?)?.toInt() ?? 0;
              final active = (l['active_employees'] as num?)?.toInt() ?? 0;
              final roleName = l['role_name'] ?? 'General Worker';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.slate200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.engineering, color: AppTheme.primaryGreen),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                            roleName,
                            style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.slate900),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildLaborStatusInfo(
                                'Crew Status', 
                                (l['project_labor_assignments'] != null && (l['project_labor_assignments'] as List).isNotEmpty)
                                    ? (l['project_labor_assignments'][0]['count'] ?? 0).toInt()
                                    : 0, 
                                expected,
                                Colors.blue
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierColor: Colors.black.withOpacity(0.5),
                          builder: (_) => WorkerAssignmentDialog(
                            projectLaborId: l['id'],
                            roleName: roleName,
                            expectedEmployees: expected,
                          ),
                        ).then((updated) {
                          if (updated == true) _loadProjectData();
                        });
                      },
                      icon: const Icon(Icons.group_add, color: Colors.blue),
                      tooltip: 'Assign Crew (Build Team)',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
