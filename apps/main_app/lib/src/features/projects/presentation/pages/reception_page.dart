import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../../../../shared/widgets/top_header.dart';
import '../../../../shared/widgets/completed_project_banner.dart';
import '../widgets/machinery_reception_dialog.dart';
import '../widgets/machinery_history_dialog.dart';
import '../widgets/machinery_return_dialog.dart';
import '../widgets/material_reception_dialog.dart';
import '../widgets/material_history_dialog.dart';
import '../widgets/instrument_reception_dialog.dart';
import '../widgets/instrument_history_dialog.dart';
import '../widgets/instrument_return_dialog.dart';

class ReceptionPage extends StatefulWidget {
  final String projectId;
  const ReceptionPage({super.key, required this.projectId});

  @override
  State<ReceptionPage> createState() => _ReceptionPageState();
}

class _ReceptionPageState extends State<ReceptionPage> with TickerProviderStateMixin {
  bool _isCompleted = false;
  List<Map<String, dynamic>> _machinery = [];
  List<Map<String, dynamic>> _materials = [];
  List<Map<String, dynamic>> _instruments = [];
  Map<String, dynamic>? _project;
  Map<String, String?> _machineryPhotos = {};
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  String _selectedServiceFilter = 'All Services';
  List<String> _projectServices = [];
  Map<String, double> _materialUsage = {};

  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, int> _activeRentalCounts = {};
  Map<String, int> _activeInstrumentCounts = {};
  Map<String, int> _returnedMachineryCounts = {};
  Map<String, int> _returnedInstrumentCounts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;

      final pResult = await supabase.from('projects').select('title, project_type, client_name, status').eq('id', widget.projectId).maybeSingle();
      final mResult = await supabase
          .from('project_machinery')
          .select('*, quote_services(name, quote_service_estimations(total_working_days)), project_services(name), quote_service_machineries(quote_services(name, quote_service_estimations(total_working_days)))')
          .eq('project_id', widget.projectId)
          .order('machinery_name');
      final matResult = await supabase.from('project_materials').select('*, quote_services(name, quote_service_estimations(total_working_days)), project_services(name), quote_service_materials(quote_services(name, quote_service_estimations(total_working_days)))').eq('project_id', widget.projectId).order('material_name');
      final iResult = await supabase
          .from('project_instruments')
          .select('*, quote_services(name, quote_service_estimations(total_working_days)), project_services(name), quote_service_instruments(quote_services(name, quote_service_estimations(total_working_days)))')
          .eq('project_id', widget.projectId)
          .order('instrument_name');

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
              dynamic service = item['quote_services'];
              if (service == null) {
                final data = item[relationName];
                if (data is List && data.isNotEmpty) {
                  service = data[0]['quote_services'];
                } else if (data is Map) {
                  service = data['quote_services'];
                }
              }
              if (service == null) {
                service = item['project_services'];
              }
              if (service != null) {
                final sData = (service is List && service.isNotEmpty) ? service[0] : (service is Map ? service : null);
                if (sData != null) {
                  final name = sData['name']?.toString();
                  if (name != null) {
                    allServices.add(name);
                  }
                }
              }
            } catch (e) {
              debugPrint('addServiceSafely error ($relationName): $e');
            }
          }
        }
        addServiceSafely(mResult, 'quote_service_machineries');
        addServiceSafely(matResult, 'quote_service_materials');
        addServiceSafely(iResult, 'quote_service_instruments');

        Map<String, double> matUsage = {};
        try {
          matUsage = await ProjectBalanceHelper.getMaterialUsage(supabase, widget.projectId);
        } catch (e) {
          debugPrint('Error loading material usage: $e');
        }

        // Load rental/return counts
        final Map<String, int> rentalCounts = {};
        final Map<String, int> instrCounts = {};
        final Map<String, int> returnedMachCounts = {};
        final Map<String, int> returnedInstrCounts = {};
        try {
          final machRentals = await supabase
              .from('machinery_inspections')
              .select('project_machinery_id')
              .is_('returned_at', null)
              .eq('ownership_type', 'rented');
          for (final r in (machRentals as List? ?? [])) {
            final pmId = r['project_machinery_id'] as String?;
            if (pmId != null) rentalCounts[pmId] = (rentalCounts[pmId] ?? 0) + 1;
          }
        } catch (_) {}
        try {
          final instrRentals = await supabase
              .from('instrument_inspections')
              .select('project_instrument_id')
              .is_('returned_at', null);
          for (final r in (instrRentals as List? ?? [])) {
            final piId = r['project_instrument_id'] as String?;
            if (piId != null) instrCounts[piId] = (instrCounts[piId] ?? 0) + 1;
          }
        } catch (_) {}
        try {
          final machReturned = await supabase
              .from('machinery_inspections')
              .select('project_machinery_id, returned_at');
          for (final r in (machReturned as List? ?? [])) {
            if (r['returned_at'] != null) {
              final pmId = r['project_machinery_id'] as String?;
              if (pmId != null) returnedMachCounts[pmId] = (returnedMachCounts[pmId] ?? 0) + 1;
            }
          }
        } catch (_) {}
        try {
          final instrReturned = await supabase
              .from('instrument_inspections')
              .select('project_instrument_id, returned_at');
          for (final r in (instrReturned as List? ?? [])) {
            if (r['returned_at'] != null) {
              final piId = r['project_instrument_id'] as String?;
              if (piId != null) returnedInstrCounts[piId] = (returnedInstrCounts[piId] ?? 0) + 1;
            }
          }
        } catch (_) {}

        setState(() {
          _project = pResult;
          _machinery = List<Map<String, dynamic>>.from(mResult as List? ?? []);
          _materials = List<Map<String, dynamic>>.from(matResult as List? ?? []);
          _instruments = List<Map<String, dynamic>>.from(iResult as List? ?? []);
          _machineryPhotos = photoMap;
          _activeRentalCounts = rentalCounts;
          _activeInstrumentCounts = instrCounts;
          _returnedMachineryCounts = returnedMachCounts;
          _returnedInstrumentCounts = returnedInstrCounts;
          _materialUsage = matUsage;
          _projectServices = allServices.toList()..sort((a, b) {
            if (a == 'All Services') return -1;
            if (b == 'All Services') return 1;
            return a.compareTo(b);
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('ERROR in _loadData: $e');
      if (mounted) {
        setState(() {
          _error = 'Error loading reception data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupByService(List<Map<String, dynamic>> items, String relationName) {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final item in items) {
      String serviceName = 'General / Unassigned';
      dynamic service = item['quote_services'];
      if (service == null) {
        final data = item[relationName];
        if (data != null) {
          final dData = (data is List && data.isNotEmpty) ? data[0] : (data is Map ? data : null);
          if (dData != null) {
            service = dData['quote_services'];
          }
        }
      }
      if (service == null) {
        service = item['project_services'];
      }
      if (service != null) {
        final sData = (service is List && service.isNotEmpty) ? service[0] : (service is Map ? service : null);
        if (sData != null && sData['name'] != null) {
          serviceName = sData['name'].toString();
        }
      }
      if (!groups.containsKey(serviceName)) {
        groups[serviceName] = [];
      }
      groups[serviceName]!.add(item);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userName = currentUser?.userMetadata?['name'] ?? 'Admin User';
    final userEmail = currentUser?.email ?? '';
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Scaffold(
      key: _mobileScaffoldKey,
      drawer: isMobile
          ? Drawer(
              child: Sidebar(
                userName: userName,
                userEmail: userEmail,
                onLogout: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) context.go('/signin');
                },
                currentPath: '/projects/${widget.projectId}/reception',
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            Sidebar(
              userName: userName,
              userEmail: userEmail,
              onLogout: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/signin');
              },
              currentPath: '/projects/${widget.projectId}/reception',
            ),
          Expanded(
            child: Column(
              children: [
                if (!isMobile)
                  TopHeader(userName: userName, breadcrumbs: const ['Operations', 'Projects', 'Resource Reception']),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline, size: 64, color: AppTheme.slate400),
                                    const SizedBox(height: 16),
                                    Text(_error!, style: GoogleFonts.manrope(color: AppTheme.slate600, fontSize: 16)),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _loadData,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _buildContent(isMobile)),
                        ],
                      ),
                    ),
          ],
        ),
      );
  }

  Widget _buildContent(bool isMobile) {
    return CompletedProjectBanner(
      projectId: widget.projectId,
      isCompletedCallback: (completed) {
        if (completed != _isCompleted) setState(() => _isCompleted = completed);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
          width: double.infinity,
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(isMobile ? 16 : 32, isMobile ? 12 : 16, isMobile ? 16 : 32, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.go('/projects/${widget.projectId}'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back, size: 16, color: AppTheme.slate500),
                    const SizedBox(width: 6),
                    Text('Back to Project', style: GoogleFonts.manrope(color: AppTheme.slate500, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildServiceFilterBar(),
              const SizedBox(height: 16),
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
                  Tab(text: 'Instruments'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMachineryTab(isMobile),
              _buildMaterialsTab(isMobile),
              _buildInstrumentsTab(isMobile),
            ],
          ),
        ),
        ],
      ),
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _projectServices.map((service) {
            final isSelected = _selectedServiceFilter == service;
            return ChoiceChip(
              label: Text(service),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _selectedServiceFilter = service);
              },
              labelStyle: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.slate600,
              ),
              backgroundColor: Colors.white,
              selectedColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryGreen : AppTheme.slate200,
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildServiceHeader(String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            name.toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.slate500,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
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
            Text('No machinery registered.', style: GoogleFonts.manrope(color: AppTheme.slate500)),
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
        child: Text('No machinery found for this service filter.', style: GoogleFonts.manrope(color: AppTheme.slate500)),
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
              final returnedCount = _returnedMachineryCounts[m['id']] ?? 0;
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
                    Stack(
                      children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            image: photoUrl != null && photoUrl.isNotEmpty
                                ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                                : null,
                          ),
                          child: (photoUrl == null || photoUrl.isEmpty)
                            ? const Icon(Icons.precision_manufacturing, color: Colors.orange)
                            : null,
                        ),
                        if (returnedCount >= received && received > 0)
                          Positioned(
                            top: -2, right: -2,
                            child: Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.check, size: 14, color: Colors.white),
                            ),
                          ),
                      ],
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
                            'Received: $received / $expected unidades',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isComplete ? AppTheme.primaryGreen : AppTheme.slate500,
                            ),
                          ),
                          if (received > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Returned: $returnedCount / $received',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: returnedCount >= received ? AppTheme.primaryGreen : Colors.orange,
                                  ),
                                ),
                                if (returnedCount >= received) ...[
                                  const SizedBox(width: 4),
                                  Icon(Icons.check_circle, size: 14, color: AppTheme.primaryGreen),
                                ],
                              ],
                            ),
                          ],
                          if (!isComplete && expected > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              height: 6,
                              width: double.infinity,
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(3)),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: (received / expected).clamp(0.0, 1.0),
                                child: Container(decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(3))),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (received > 0)
                      IconButton(
                        onPressed: () {
                          showSafeDialog(
                            context: context,
                            barrierColor: Colors.black.withOpacity(0.5),
                            builder: (_) => MachineryHistoryDialog(
                              projectId: widget.projectId,
                              projectMachineryId: m['id'],
                              machineryName: mName,
                              serviceName: sName,
                            ),
                          ).then((updated) {
                            if (updated == true) _loadData();
                          });
                        },
                        icon: const Icon(Icons.history, color: Colors.orange),
                        tooltip: 'View History',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    if (returnedCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, size: 14, color: AppTheme.primaryGreen),
                            const SizedBox(width: 4),
                            Text('$returnedCount returned', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
                          ],
                        ),
                      ),
                    ],
                    if (_activeRentalCounts[m['id']] != null && _activeRentalCounts[m['id']]! > 0) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isCompleted ? null : () {
                          showSafeDialog(
                            context: context,
                            barrierColor: Colors.black.withOpacity(0.5),
                            builder: (_) => MachineryHistoryDialog(
                              projectId: widget.projectId,
                              projectMachineryId: m['id'],
                              machineryName: mName,
                              serviceName: sName,
                            ),
                          ).then((updated) {
                            if (updated == true) _loadData();
                          });
                        },
                        icon: const Icon(Icons.outbound_outlined, size: 16, color: Colors.white),
                        label: Text('Return (${_activeRentalCounts[m['id']]})', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCompleted ? AppTheme.slate400 : Colors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                    if (received > 0) const SizedBox(width: 8),
                    if (!isComplete && !_isCompleted)
                      ElevatedButton.icon(
                        onPressed: () {
                          showSafeDialog(
                            context: context,
                            barrierColor: Colors.black.withOpacity(0.5),
                            builder: (_) => MachineryReceptionDialog(
                              projectId: widget.projectId,
                              projectMachineryId: m['id'],
                              machineryName: mName,
                              serviceName: sName,
                            ),
                          ).then((received) {
                            if (received == true) _loadData();
                          });
                        },
                        icon: const Icon(Icons.add_box, size: 16, color: Colors.white),
                        label: Text('Receive', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isComplete ? AppTheme.slate400 : Colors.orange,
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

  Widget _buildMaterialsTab(bool isMobile) {
    if (_materials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text('No materials registered.', style: GoogleFonts.manrope(color: AppTheme.slate500)),
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
        child: Text('No materials found for this service filter.', style: GoogleFonts.manrope(color: AppTheme.slate500)),
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
                      child: Icon(Icons.inventory, color: isComplete ? AppTheme.primaryGreen : Colors.blue),
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
                            'Received: $received / $expected $unitName${_materialUsage.containsKey(m['id']) ? ' · Used: ${_materialUsage[m['id']]!.toStringAsFixed(1)} · Rem: ${(expected - _materialUsage[m['id']]!).toStringAsFixed(1)}' : ''}',
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
                        onPressed: _isCompleted ? null : () {
                          showSafeDialog(
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
                            if (updated == true) _loadData();
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
                    if (!isComplete && !_isCompleted)
                      ElevatedButton.icon(
                        onPressed: () {
                          showSafeDialog(
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
                            if (received == true) _loadData();
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

  Widget _buildInstrumentsTab(bool isMobile) {
    if (_instruments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.handyman_outlined, size: 64, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text('No instruments registered.', style: GoogleFonts.manrope(color: AppTheme.slate500)),
          ],
        ),
      );
    }

    final grouped = _groupByService(_instruments, 'quote_service_instruments');
    final serviceNames = grouped.keys.toList()
        .where((s) => _selectedServiceFilter == 'All Services' || s == _selectedServiceFilter)
        .toList()
        ..sort();

    if (serviceNames.isEmpty) {
      return Center(
        child: Text('No instruments found for this service filter.', style: GoogleFonts.manrope(color: AppTheme.slate500)),
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
              final returnedCount = _returnedInstrumentCounts[m['id']] ?? 0;
              final mName = m['instrument_name'] ?? 'Unknown Instrument';

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
                    Stack(
                      children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            color: isComplete ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.handyman, color: isComplete ? AppTheme.primaryGreen : Colors.purple),
                        ),
                        if (returnedCount >= received && received > 0)
                          Positioned(
                            top: -2, right: -2,
                            child: Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.check, size: 14, color: Colors.white),
                            ),
                          ),
                      ],
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
                            'Received: $received / $expected',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isComplete ? AppTheme.primaryGreen : AppTheme.slate500,
                            ),
                          ),
                          if (received > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Returned: $returnedCount / $received',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: returnedCount >= received ? AppTheme.primaryGreen : Colors.orange,
                                  ),
                                ),
                                if (returnedCount >= received) ...[
                                  const SizedBox(width: 4),
                                  Icon(Icons.check_circle, size: 14, color: AppTheme.primaryGreen),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (received > 0)
                      IconButton(
                        onPressed: () {
                          showSafeDialog(
                            context: context,
                            barrierColor: Colors.black.withOpacity(0.5),
                            builder: (_) => InstrumentHistoryDialog(
                              projectId: widget.projectId,
                              projectInstrumentId: m['id'],
                              instrumentName: mName,
                              serviceName: sName,
                            ),
                          ).then((updated) {
                            if (updated == true) _loadData();
                          });
                        },
                        icon: const Icon(Icons.history, color: AppTheme.primaryGreen),
                        tooltip: 'View History',
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    if (returnedCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, size: 14, color: AppTheme.primaryGreen),
                            const SizedBox(width: 4),
                            Text('$returnedCount returned', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
                          ],
                        ),
                      ),
                    ],
                    if (_activeInstrumentCounts[m['id']] != null && _activeInstrumentCounts[m['id']]! > 0) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isCompleted ? null : () {
                          showSafeDialog(
                            context: context,
                            barrierColor: Colors.black.withOpacity(0.5),
                            builder: (_) => InstrumentHistoryDialog(
                              projectId: widget.projectId,
                              projectInstrumentId: m['id'],
                              instrumentName: mName,
                              serviceName: sName,
                            ),
                          ).then((updated) {
                            if (updated == true) _loadData();
                          });
                        },
                        icon: const Icon(Icons.outbound_outlined, size: 16, color: Colors.white),
                        label: Text('Return (${_activeInstrumentCounts[m['id']]})', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCompleted ? AppTheme.slate400 : Colors.purple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                    if (received > 0) const SizedBox(width: 8),
                    if (!isComplete && !_isCompleted)
                      ElevatedButton.icon(
                        onPressed: () {
                          showSafeDialog(
                            context: context,
                            barrierColor: Colors.black.withOpacity(0.5),
                            builder: (_) => InstrumentReceptionDialog(
                              projectId: widget.projectId,
                              projectInstrumentId: m['id'],
                              instrumentName: mName,
                              serviceName: sName,
                            ),
                          ).then((received) {
                            if (received == true) _loadData();
                          });
                        },
                        icon: const Icon(Icons.qr_code_scanner, size: 16, color: Colors.white),
                        label: Text('Receive', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
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
}
