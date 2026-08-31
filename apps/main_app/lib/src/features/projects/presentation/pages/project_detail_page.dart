import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:noel_data/noel_data.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../../../../shared/widgets/top_header.dart';
import '../../../../shared/widgets/completed_project_banner.dart';
import '../widgets/worker_assignment_dialog.dart';
import '../widgets/machinery_scheduling_dialog.dart';
import '../widgets/instrument_scheduling_dialog.dart';
import '../widgets/labor_scheduling_dialog.dart';
import 'package:flutter/gestures.dart';
import 'package:printing/printing.dart';
import '../utils/timeline_pdf_generator.dart';

class ProjectDetailPage extends StatefulWidget {
  final String projectId;
  const ProjectDetailPage({super.key, required this.projectId});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> with TickerProviderStateMixin {
  Map<String, dynamic>? _project;
  List<Map<String, dynamic>> _machinery = [];
  List<Map<String, dynamic>> _materials = [];
  List<Map<String, dynamic>> _labor = [];
  List<Map<String, dynamic>> _instruments = [];
  Map<String, String?> _machineryPhotos = {};
  Map<String, double?> _serviceDurations = {};
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  String _selectedServiceFilter = 'All Services';
  bool _machineryTableView = false;
  List<String> _projectServices = [];
  double _dailyBurnRate = 1500.0;
  final Map<String, bool> _expandedServices = {};
  Map<String, dynamic>? _latestSnapshot;
  int? _baselineVersion;
  Map<String, double> _materialUsage = {};
  Map<String, double> _machineryProduction = {};


  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadProjectData();
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted && _isLoading) {
        setState(() {
          _error = 'Error: Loading timed out. One or more database queries may be too slow.';
          _isLoading = false;
        });
      }
    });
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

      // 2. Load Machinery
      final mResult = await supabase
          .from('project_machinery')
          .select('*, quote_services(name, unit_of_measure, quote_service_estimations(total_working_days)), project_services(name), project_machinery_assignments(*), quote_service_machineries(quote_services(name, unit_of_measure, quote_service_estimations(total_working_days))), machinery_inspections(*)')
          .eq('project_id', widget.projectId)
          .order('machinery_name');

      // 3. Materials
      final matResult = await supabase.from('project_materials').select('*, quote_services(name, quote_service_estimations(total_working_days)), project_services(name), quote_service_materials(quote_services(name, quote_service_estimations(total_working_days)))').eq('project_id', widget.projectId).order('material_name');

      // 4. Load Instruments
      final iResult = await supabase
          .from('project_instruments')
          .select('*, quote_services(name, quote_service_estimations(total_working_days)), project_services(name), project_instrument_assignments(*), quote_service_instruments(quote_services(name, quote_service_estimations(total_working_days)))')
          .eq('project_id', widget.projectId)
          .order('instrument_name');

      // 5. Labor
      final labResult = await supabase
          .from('project_labor')
          .select('*, quote_services(name, quote_service_estimations(total_working_days)), project_services(name), quote_service_labors(quote_services(name, quote_service_estimations(total_working_days))), project_labor_assignments(start_date, end_date, workers(full_name))')
          .eq('project_id', widget.projectId)
          .order('role_name');

      // 6. Machinery Photos (Catalog)
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
        
        final serviceDurations = <String, double?>{};
        
        void addServiceSafely(dynamic list, String relationName) {
          if (list == null || list is! List) return;
          for (final item in list) {
            try {
              // Priority 1: Direct link (for unplanned)
              dynamic service = item['quote_services'];
              
              // Priority 2: Relation link (for planned)
              if (service == null) {
                final data = item[relationName];
                if (data is List && data.isNotEmpty) {
                  service = data[0]['quote_services'];
                } else if (data is Map) {
                  service = data['quote_services'];
                }
              }

              // Priority 3: CO-created service (project_services)
              if (service == null) {
                service = item['project_services'];
              }
              
              if (service != null) {
                final sData = (service is List && service.isNotEmpty) ? service[0] : (service is Map ? service : null);
                if (sData != null) {
                  final name = sData['name']?.toString();
                  if (name != null) {
                    allServices.add(name);
                    
                    // Extract duration
                    final est = sData['quote_service_estimations'];
                    dynamic duration;
                    if (est is List && est.isNotEmpty) {
                      duration = est[0]['total_working_days'];
                    } else if (est is Map) {
                      duration = est['total_working_days'];
                    }
                    if (duration != null) {
                      serviceDurations[name] = (duration as num).toDouble();
                    }
                  }
                }
              }
            } catch (e) {
              debugPrint('addServiceSafely error (${relationName}): $e');
            }
          }
        }
        addServiceSafely(mResult, 'quote_service_machineries');
        addServiceSafely(matResult, 'quote_service_materials');
        addServiceSafely(iResult, 'quote_service_instruments');
        addServiceSafely(labResult, 'quote_service_labors');

        // Calculate dynamic baseline daily burn rate based on actual project assets
        double calculatedBurnRate = 0;
        for (var m in mResult as List? ?? []) {
          double rent = (m['monthly_rent_cost'] as num?)?.toDouble() ?? 0;
          double dailyRent = rent > 0 ? (rent / 30) : ((m['rent_cost'] as num?)?.toDouble() ?? 0);
          double fuel = ((m['gallons_per_hour'] as num?)?.toDouble() ?? 0) * 8 * 4.5;
          int qty = (m['quantity'] as num?)?.toInt() ?? 1;
          calculatedBurnRate += (dailyRent + fuel) * qty;
        }
        for (var l in labResult as List? ?? []) {
          double rate = (l['internal_cost_rate'] as num?)?.toDouble() ?? (l['price'] as num?)?.toDouble() ?? 0;
          double perDiem = (l['per_diem'] as num?)?.toDouble() ?? 0;
          int qty = (l['quantity'] as num?)?.toInt() ?? 1;
          calculatedBurnRate += (rate + perDiem) * 8 * qty;
        }
        for (var i in iResult as List? ?? []) {
          double price = (i['price'] as num?)?.toDouble() ?? 0;
          int qty = (i['quantity'] as num?)?.toInt() ?? 1;
          calculatedBurnRate += price * qty;
        }

        // Load latest baseline snapshot
        try {
          final baselineService = BaselineService(Supabase.instance.client);
          _latestSnapshot = await baselineService.getLatestSnapshot(widget.projectId).timeout(const Duration(seconds: 10));
          _baselineVersion = _latestSnapshot?['version'] as int?;
        } catch (e) {
          debugPrint('Error loading baseline snapshot: $e');
          _latestSnapshot = null;
          _baselineVersion = null;
        }

        Map<String, double> matUsage = {};
        Map<String, double> machProd = {};
        try {
          matUsage = await ProjectBalanceHelper.getMaterialUsage(
            Supabase.instance.client, widget.projectId,
          ).timeout(const Duration(seconds: 10));
          machProd = await ProjectBalanceHelper.getMachineryProduction(
            Supabase.instance.client, widget.projectId,
          ).timeout(const Duration(seconds: 10));
        } catch (e) {
          debugPrint('Error loading balance data: $e');
        }

        setState(() {
          _project = pResult;
          _machinery = List<Map<String, dynamic>>.from(mResult as List? ?? []);
          _materials = List<Map<String, dynamic>>.from(matResult as List? ?? []);
          _labor = List<Map<String, dynamic>>.from(labResult as List? ?? []);
          _instruments = List<Map<String, dynamic>>.from(iResult as List? ?? []);
          _machineryPhotos = photoMap;
          _materialUsage = matUsage;
          _machineryProduction = machProd;
          _serviceDurations = serviceDurations;
          _projectServices = allServices.toList()..sort((a, b) {
            if (a == 'All Services') return -1;
            if (b == 'All Services') return 1;
            return a.compareTo(b);
          });
          
          if (calculatedBurnRate > 0) {
            _dailyBurnRate = calculatedBurnRate;
          } else {
            _dailyBurnRate = 1500.0;
          }
          
          final isLaborSupply = _project?['project_type'] == 'labor_supply';
          final requiredTabs = isLaborSupply ? 1 : 4;
          if (_tabController.length != requiredTabs) {
            final oldIndex = _tabController.index;
            _tabController.dispose();
            _tabController = TabController(
              length: requiredTabs, 
              vsync: this, 
              initialIndex: oldIndex < requiredTabs ? oldIndex : 0
            );
          }
          
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

  List<Map<String, dynamic>> _aggregateLaborRows(List<Map<String, dynamic>> items) {
    final Map<String, Map<String, dynamic>> merged = {};
    final Map<String, List<Map<String, dynamic>>> groups = {};

    for (final item in items) {
      final qsId = item['quote_service_id']?.toString() ?? '_';
      final role = item['role_name']?.toString() ?? 'General Worker';
      final key = '${qsId}_$role';
      (groups[key] ??= []).add(item);
    }

    for (final entry in groups.entries) {
      final rows = entry.value;
      final first = Map<String, dynamic>.from(rows.first);
      final allAssignments = <Map<String, dynamic>>[];
      int activeCount = 0;

      for (final row in rows) {
        final assignments = row['project_labor_assignments'];
        if (assignments != null && assignments is List) {
          allAssignments.addAll(assignments.cast<Map<String, dynamic>>());
        }
        if (((row['active_employees'] as num?)?.toInt() ?? 0) > 0) {
          activeCount++;
        }
      }

      first['expected_employees'] = rows.length;
      first['active_employees'] = activeCount;
      first['project_labor_assignments'] = allAssignments;
      merged[entry.key] = first;
    }

    return merged.values.toList();
  }

  Map<String, List<Map<String, dynamic>>> _groupByService(List<Map<String, dynamic>> items, String relationName) {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final item in items) {
      String serviceName = 'General / Unassigned';
      
      // Priority 1: Direct link (for unplanned)
      dynamic service = item['quote_services'];
      
      // Priority 2: Relation link (for planned)
      if (service == null) {
        final data = item[relationName];
        if (data != null) {
          final dData = (data is List && data.isNotEmpty) ? data[0] : (data is Map ? data : null);
          if (dData != null) {
            service = dData['quote_services'];
          }
        }
      }

      // Priority 3: CO-created service (project_services)
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

  Map<String, dynamic> _calculateEVMDetails(Map<String, dynamic> m) {
    final assignments = (m['project_machinery_assignments'] as List?) ?? [];
    final inspections = (m['machinery_inspections'] as List?) ?? [];
    
    DateTime? plannedStart;
    DateTime? plannedEnd;
    
    if (m['start_date'] != null) {
      plannedStart = DateTime.tryParse(m['start_date']);
    }
    if (m['end_date'] != null) {
      plannedEnd = DateTime.tryParse(m['end_date']);
    }
    
    if ((plannedStart == null || plannedEnd == null) && assignments.isNotEmpty) {
      for (var a in assignments) {
        final aStart = DateTime.tryParse(a['start_date'] ?? '');
        final aEnd = DateTime.tryParse(a['end_date'] ?? '');
        if (aStart != null && (plannedStart == null || aStart.isBefore(plannedStart!))) {
          plannedStart = aStart;
        }
        if (aEnd != null && (plannedEnd == null || aEnd.isAfter(plannedEnd!))) {
          plannedEnd = aEnd;
        }
      }
    }
    
    DateTime? actualStart;
    DateTime? actualEnd;
    bool isCompleted = false;
    
    if (inspections.isNotEmpty) {
      for (var insp in inspections) {
        if (insp['received_at'] != null) {
          final rAt = DateTime.tryParse(insp['received_at']);
          if (rAt != null && (actualStart == null || rAt.isBefore(actualStart!))) {
            actualStart = rAt;
          }
        }
      }
      
      final expectedQty = (m['expected_quantity'] as num?)?.toInt() ?? 1;
      final receivedQty = (m['received_quantity'] as num?)?.toInt() ?? 0;
      
      final allReturned = inspections.every((insp) => insp['returned_at'] != null);
      if (receivedQty >= expectedQty && allReturned) {
        isCompleted = true;
        for (var insp in inspections) {
          if (insp['returned_at'] != null) {
            final retAt = DateTime.tryParse(insp['returned_at']);
            if (retAt != null && (actualEnd == null || retAt.isAfter(actualEnd!))) {
              actualEnd = retAt;
            }
          }
        }
      }
    }
    
    String status = 'scheduled';
    int deviationDays = 0;
    
    if (actualStart != null) {
      if (isCompleted) {
        status = 'completed';
      } else {
        status = 'in_progress';
      }
    } else {
      if (plannedStart != null && DateTime.now().isAfter(plannedStart!)) {
        status = 'delayed';
      }
    }
    
    if (plannedStart != null && plannedEnd != null) {
      final plannedDur = plannedEnd.difference(plannedStart).inDays;
      
      if (actualStart != null) {
        final currentEnd = actualEnd ?? DateTime.now();
        final actualDur = currentEnd.difference(actualStart).inDays;
        deviationDays = actualDur - plannedDur;
      }
    }
    
    return {
      'plannedStart': plannedStart,
      'plannedEnd': plannedEnd,
      'actualStart': actualStart,
      'actualEnd': actualEnd,
      'status': status,
      'deviationDays': deviationDays,
      'isCompleted': isCompleted,
    };
  }

  Widget _infoChip(String text, {Color color = AppTheme.slate600, Color bgColor = const Color(0xFFF1F5F9)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _buildEVMDisplay(Map<String, dynamic> m) {
    final evm = _calculateEVMDetails(m);
    final DateFormat formatter = DateFormat('MMM dd, yyyy');
    
    final plannedStartStr = evm['plannedStart'] != null ? formatter.format(evm['plannedStart']) : '?';
    final plannedEndStr = evm['plannedEnd'] != null ? formatter.format(evm['plannedEnd']) : '?';
    
    final actualStartStr = evm['actualStart'] != null ? formatter.format(evm['actualStart']) : '-';
    final actualEndStr = evm['actualEnd'] != null ? formatter.format(evm['actualEnd']) : (evm['status'] == 'in_progress' ? 'In Progress' : '-');
    
    Color statusColor;
    String statusText;
    switch (evm['status']) {
      case 'completed':
        statusColor = AppTheme.primaryGreen;
        statusText = 'Completed';
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusText = 'In Progress';
        break;
      case 'delayed':
        statusColor = Colors.red;
        statusText = 'Delayed';
        break;
      default:
        statusColor = AppTheme.slate400;
        statusText = 'Scheduled';
    }

    final deviation = evm['deviationDays'] as int;
    Widget? deviationBadge;
    if (evm['actualStart'] != null) {
      if (deviation < 0) {
        deviationBadge = _infoChip('${deviation.abs()} days SAVED', color: Colors.green, bgColor: Colors.green.withOpacity(0.1));
      } else if (deviation > 0) {
        deviationBadge = _infoChip('${deviation} days DELAY', color: Colors.red, bgColor: Colors.red.withOpacity(0.1));
      } else {
        deviationBadge = _infoChip('On Schedule', color: Colors.blue, bgColor: Colors.blue.withOpacity(0.1));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _infoChip(statusText, color: statusColor, bgColor: statusColor.withOpacity(0.1)),
            if (deviationBadge != null) deviationBadge,
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PLANNED', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate400)),
                  const SizedBox(height: 2),
                  Text('$plannedStartStr to $plannedEndStr', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate700)),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ACTUAL (REAL)', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate400)),
                  const SizedBox(height: 2),
                  Text('$actualStartStr to $actualEndStr', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: evm['actualStart'] != null ? AppTheme.slate900 : AppTheme.slate500)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Map<String, dynamic> _calculateLaborEVMDetails(Map<String, dynamic> l) {
    final assignments = (l['project_labor_assignments'] as List?) ?? [];

    DateTime? plannedStart;
    DateTime? plannedEnd;

    if (l['start_date'] != null) {
      plannedStart = DateTime.tryParse(l['start_date']);
    }
    if (l['end_date'] != null) {
      plannedEnd = DateTime.tryParse(l['end_date']);
    }

    if ((plannedStart == null || plannedEnd == null) && assignments.isNotEmpty) {
      for (var a in assignments) {
        final aStart = DateTime.tryParse(a['start_date'] ?? '');
        final aEnd = DateTime.tryParse(a['end_date'] ?? '');
        if (aStart != null && (plannedStart == null || aStart.isBefore(plannedStart!))) {
          plannedStart = aStart;
        }
        if (aEnd != null && (plannedEnd == null || aEnd.isAfter(plannedEnd!))) {
          plannedEnd = aEnd;
        }
      }
    }

    final DateTime? actualStart = null;
    final DateTime? actualEnd = null;
    String status = 'scheduled';
    int deviationDays = 0;
    bool isCompleted = false;

    if (plannedStart != null && DateTime.now().isAfter(plannedStart!)) {
      status = 'delayed';
    }
    
    return {
      'plannedStart': plannedStart,
      'plannedEnd': plannedEnd,
      'actualStart': actualStart,
      'actualEnd': actualEnd,
      'status': status,
      'deviationDays': deviationDays,
      'isCompleted': isCompleted,
    };
  }

  Widget _buildLaborEVMDisplay(Map<String, dynamic> l) {
    final evm = _calculateLaborEVMDetails(l);
    final DateFormat formatter = DateFormat('MMM dd, yyyy');
    
    final plannedStartStr = evm['plannedStart'] != null ? formatter.format(evm['plannedStart']) : '?';
    final plannedEndStr = evm['plannedEnd'] != null ? formatter.format(evm['plannedEnd']) : '?';
    
    final actualStartStr = evm['actualStart'] != null ? formatter.format(evm['actualStart']) : '-';
    final actualEndStr = evm['actualEnd'] != null ? formatter.format(evm['actualEnd']) : (evm['status'] == 'in_progress' ? 'In Progress' : '-');
    
    Color statusColor;
    String statusText;
    switch (evm['status']) {
      case 'completed':
        statusColor = AppTheme.primaryGreen;
        statusText = 'Completed';
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusText = 'In Progress';
        break;
      case 'delayed':
        statusColor = Colors.red;
        statusText = 'Delayed';
        break;
      default:
        statusColor = AppTheme.slate400;
        statusText = 'Scheduled';
    }

    final deviation = evm['deviationDays'] as int;
    Widget? deviationBadge;
    if (evm['actualStart'] != null) {
      if (deviation < 0) {
        deviationBadge = _infoChip('${deviation.abs()} days SAVED', color: Colors.green, bgColor: Colors.green.withOpacity(0.1));
      } else if (deviation > 0) {
        deviationBadge = _infoChip('${deviation} days DELAY', color: Colors.red, bgColor: Colors.red.withOpacity(0.1));
      } else {
        deviationBadge = _infoChip('On Schedule', color: Colors.blue, bgColor: Colors.blue.withOpacity(0.1));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _infoChip(statusText, color: statusColor, bgColor: statusColor.withOpacity(0.1)),
            if (deviationBadge != null) deviationBadge,
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PLANNED', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate400)),
                  const SizedBox(height: 2),
                  Text('$plannedStartStr to $plannedEndStr', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.slate700)),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ACTUAL (REAL)', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate400)),
                  const SizedBox(height: 2),
                  Text('$actualStartStr to $actualEndStr', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: evm['actualStart'] != null ? AppTheme.slate900 : AppTheme.slate500)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? _extractServiceId(Map<String, dynamic> item, String relationName) {
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
      return sData?['id']?.toString() ?? item['project_service_id']?.toString();
    }
    return item['project_service_id']?.toString();
  }

  Widget _buildServiceHeader(String name, {String? serviceId}) {
    final duration = _serviceDurations[name];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.slate200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 14,
              color: AppTheme.slate400,
            ),
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
          if (duration != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.slate200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${duration} DAYS',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.slate600,
                ),
              ),
            ),
          ],
          const SizedBox(width: 12),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.slate200,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'PLANNING',
              style: GoogleFonts.manrope(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppTheme.slate500,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDisplay(String? mainStart, String? mainEnd, List<Map<String, dynamic>>? assignments, Color color) {
    if (assignments != null && assignments.isNotEmpty) {
      if (assignments.length == 1) {
        final a = assignments.first;
        return _buildDateChip('${a['start']} to ${a['end']}', color);
      }
      // Multiple assignments: show count
      return Row(
        children: [
          _buildDateChip('${assignments.length} Sched. Ranges', color),
          const SizedBox(width: 4),
          Tooltip(
            message: assignments.map((a) => '${a['qty']}x: ${a['start']} to ${a['end']}').join('\n'),
            child: Icon(Icons.info_outline, size: 14, color: color),
          ),
        ],
      );
    }
    
    if (mainStart != null && mainEnd != null) {
      return _buildDateChip('$mainStart to $mainEnd', color);
    }
    
    return _buildDateChip('Dates not set', AppTheme.slate400);
  }

  Widget _buildDateChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[PDP] BUILD called for project: ${widget.projectId}');
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
          currentPath: '/projects/${widget.projectId}',
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
currentPath: '/projects/${widget.projectId}',
              onLogout: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/signin');
              },
            ),
          Expanded(
            child: Column(
              children: [
                if (!isMobile)
                  TopHeader(userName: userName, breadcrumbs: const ['Operations', 'Projects', 'Resource Planning']),
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
            'Resource Planning',
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
    return CompletedProjectBanner(
      projectId: widget.projectId,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(isMobile ? 16 : 32, isMobile ? 8 : 12, isMobile ? 16 : 32, 0),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                      const SizedBox(width: 12),
                      _buildStatusBadge(_project?['status'] ?? 'active'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _loadProjectData();
                          if (!mounted) return;
                          final result = await showSafeDialog(
                            context: context,
                            builder: (context) => _FullscreenTimelineDialog(
                              projectId: widget.projectId,
                              project: _project,
                              machinery: _machinery,
                              labor: _labor,
                              instruments: _instruments,
                              selectedServiceFilter: _selectedServiceFilter,
                              onSaveBaseline: _saveBaselinePlanning,
                              isSavingBaseline: _isSavingBaseline,
                              baselineVersion: _baselineVersion,
                            ),
                          );
                          if (result == 'navigate_to_baseline' && mounted) {
                            debugPrint('Gantt → Baseline navigation triggered');
                            context.push('/projects/${widget.projectId}/baseline');
                          }
                        },
                        icon: const Icon(Icons.calendar_month, size: 16, color: Colors.white),
                        label: Text('View Timeline', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          minimumSize: const Size(0, 36),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await context.push('/projects/${widget.projectId}/baseline');
                          if (mounted) {
                            if (result == true || result == 'show_gantt') {
                              debugPrint('Baseline → Gantt navigation triggered');
                              _showGanttDialog();
                            } else {
                              _loadProjectData();
                            }
                          }
                        },
                        icon: _baselineVersion != null
                            ? Badge(
                                label: Text('v$_baselineVersion'),
                                backgroundColor: AppTheme.primaryGreen,
                                child: const Icon(Icons.analytics_outlined, size: 16, color: Colors.white),
                              )
                            : const Icon(Icons.analytics_outlined, size: 16, color: Colors.white),
                        label: Text('Baseline', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.slate900,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          minimumSize: const Size(0, 36),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/projects/${widget.projectId}/reception'),
                        icon: const Icon(Icons.inventory, size: 16, color: Colors.white),
                        label: Text('Reception', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          minimumSize: const Size(0, 36),
                        ),
                      ),

                      if (_baselineVersion != null) ...[
                        ElevatedButton.icon(
                          onPressed: _recalculateSchedule,
                          icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                          label: Text('Recalc Schedule', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            minimumSize: const Size(0, 36),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isSavingBaseline ? null : _createNewBaselineRevision,
                          icon: _isSavingBaseline
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.add_box_outlined, size: 16, color: Colors.white),
                          label: Text(_isSavingBaseline ? '...' : 'New Revision', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            minimumSize: const Size(0, 36),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Client: ${_project?['client_name'] ?? '-'}',
                style: GoogleFonts.manrope(fontSize: 15, color: AppTheme.slate600, fontWeight: FontWeight.w500),
              ),
              // Service Filter
              _buildServiceFilterBar(isMobile),
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
                tabs: (_project?['project_type'] == 'labor_supply')
                  ? const [Tab(text: 'Labor')]
                  : const [
                      Tab(text: 'Machinery'),
                      Tab(text: 'Materials'),
                      Tab(text: 'Instruments'),
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
            children: (_project?['project_type'] == 'labor_supply')
              ? [
                  _buildLaborTab(isMobile),
                ]
              : [
                  _buildMachineryTab(isMobile),
                  _buildMaterialsTab(isMobile),
                  _buildInstrumentsTab(isMobile),
                  _buildLaborTab(isMobile),
                ],
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildServiceFilterBar(bool isMobile) {
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
        if (isMobile)
          DropdownButtonFormField<String>(
            initialValue: _selectedServiceFilter,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.slate200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.slate200),
              ),
            ),
            items: _projectServices.map((service) {
              return DropdownMenuItem<String>(
                value: service,
                child: Text(
                  service,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate900),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedServiceFilter = val);
            },
          )
        else
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(isMobile ? 16 : 32, 16, isMobile ? 16 : 32, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '${serviceNames.length} service(s) · ${_machinery.length} machine(s)',
                  style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate500),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Row(
                children: [
                  _viewToggleOpt(Icons.view_list, 'Normal', !_machineryTableView, () => setState(() => _machineryTableView = false)),
                  const SizedBox(width: 4),
                  _viewToggleOpt(Icons.table_chart, 'Table', _machineryTableView, () => setState(() => _machineryTableView = true)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _machineryTableView
              ? _buildMachineryTable(grouped, serviceNames, isMobile)
              : ListView.builder(
                  padding: EdgeInsets.all(isMobile ? 16 : 32),
                  itemCount: serviceNames.length,
                  itemBuilder: (context, sIndex) {
                    final sName = serviceNames[sIndex];
                    final groupItems = grouped[sName]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildServiceHeader(sName, serviceId: _extractServiceId(groupItems.first, 'quote_service_machineries')),
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
                            child: isMobile
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          _machineryImage(photoUrl),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: _machineryInfoItems(m, mName, expected, received, isComplete),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _buildEVMDisplay(m),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: _machineryScheduleButton(
                                          projectMachineryId: m['id'],
                                          machineryName: mName,
                                          expectedQuantity: expected,
                                          serviceName: sName,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      _machineryImage(photoUrl),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ..._machineryInfoItems(m, mName, expected, received, isComplete),
                                            _buildEVMDisplay(m),
                                          ],
                                        ),
                                      ),
                                      _machineryScheduleButton(
                                        projectMachineryId: m['id'],
                                        machineryName: mName,
                                        expectedQuantity: expected,
                                        serviceName: sName,
                                      ),
                                    ],
                                  ),
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _machineryImage(String? photoUrl) {
    return Container(
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
    );
  }

  List<Widget> _machineryInfoItems(Map<String, dynamic> m, String mName, int expected, int received, bool isComplete) {
    return [
      Text(
        mName,
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
      if (m['is_principal'] == true && _machineryProduction.containsKey(m['id']))
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            'Production: ${_machineryProduction[m['id']]!.toStringAsFixed(0)} ${m['quote_services']?['unit_of_measure'] ?? ''} total',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.slate600,
            ),
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
            child: Container(decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(3))),
          ),
        ),
    ];
  }

  Widget _machineryScheduleButton({
    required String projectMachineryId,
    required String machineryName,
    required int expectedQuantity,
    required String serviceName,
  }) {
    return ElevatedButton.icon(
      onPressed: () {
        showSafeDialog(
          context: context,
          fullscreenOnMobile: true,
          builder: (_) => MachinerySchedulingDialog(
            projectMachineryId: projectMachineryId,
            machineryName: machineryName,
            expectedQuantity: expectedQuantity,
            serviceName: serviceName,
          ),
        ).then((updated) {
          if (updated == true) _loadProjectData();
        });
      },
      icon: const Icon(Icons.calendar_month, size: 16, color: Colors.white),
      label: Text('Modify Schedule', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _viewToggleOpt(IconData icon, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryGreen : AppTheme.slate200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? Colors.white : AppTheme.slate600),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : AppTheme.slate600)),
          ],
        ),
      ),
    );
  }

  Widget _buildMachineryTable(Map<String, List<Map<String, dynamic>>> grouped, List<String> serviceNames, bool isMobile) {
    final DateFormat fmt = DateFormat('MMM dd, yyyy');
    final List<Map<String, dynamic>> rows = [];
    for (final sName in serviceNames) {
      for (final m in grouped[sName]!) {
        rows.add({
          'service': sName,
          'machinery': m,
        });
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Table(
              border: TableBorder(horizontalInside: const BorderSide(color: Color(0xFFF1F5F9))),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1.3),
                4: FlexColumnWidth(1.3),
                5: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                  children: [
                    _tableHeader('Service'),
                    _tableHeader('Machinery'),
                    _tableHeader('Qty'),
                    _tableHeader('Start'),
                    _tableHeader('End'),
                    _tableHeader('Status'),
                  ],
                ),
                for (final row in rows)
                  TableRow(
                    children: [
                      _tableCell(row['service']?.toString() ?? ''),
                      _tableCell(row['machinery']?['machinery_name']?.toString() ?? '', bold: true),
                      _tableCell((row['machinery']?['expected_quantity'] as num?)?.toInt().toString() ?? ''),
                      _tableCell(row['machinery']?['start_date'] != null ? fmt.format(DateTime.parse(row['machinery']['start_date'].toString())) : '—'),
                      _tableCell(row['machinery']?['end_date'] != null ? fmt.format(DateTime.parse(row['machinery']['end_date'].toString())) : '—'),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: TextButton.icon(
                            onPressed: () => _openTableDatePicker(row['machinery'], fmt),
                            icon: const Icon(Icons.event, size: 14, color: AppTheme.primaryGreen),
                            label: Text('Set dates', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _machinery.isEmpty ? null : () => _openBatchDateRange(serviceNames, fmt),
              icon: const Icon(Icons.event_available, size: 18, color: Colors.white),
              label: Text('Schedule ALL machinery at once (bulk date range)', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableCell _tableHeader(String text) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
      ),
    );
  }

  TableCell _tableCell(String text, {bool bold = false}) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text, style: GoogleFonts.manrope(fontSize: 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w400, color: AppTheme.slate700)),
      ),
    );
  }

  Future<void> _openTableDatePicker(Map<String, dynamic> m, DateFormat fmt) async {
    final initialStart = m['start_date'] != null ? DateTime.parse(m['start_date'].toString()) : DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: initialStart,
        end: m['end_date'] != null ? DateTime.parse(m['end_date'].toString()) : initialStart.add(const Duration(days: 7)),
      ),
    );
    if (picked == null) return;
    await _applyAssignments(m['id'] as String, picked.start, picked.end);
    if (mounted) {
      setState(() {});
      _loadProjectData();
    }
  }

  Future<void> _openBatchDateRange(List<String> serviceNames, DateFormat fmt) async {
    final first = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: first, end: first.add(const Duration(days: 7))),
    );
    if (picked == null) return;
    var count = 0;
    for (final m in _machinery) {
      if (m['start_date'] == null || m['end_date'] == null) {
        await _applyAssignments(m['id'] as String, picked.start, picked.end);
        count++;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(count == 0 ? 'All machinery already scheduled.' : 'Scheduled $count machine(s) from ${fmt.format(picked.start)} to ${fmt.format(picked.end)}'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      _loadProjectData();
    }
  }

  Future<void> _applyAssignments(String projectMachineryId, DateTime start, DateTime end) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('project_machinery_assignments')
          .delete()
          .eq('project_machinery_id', projectMachineryId);
      await supabase.from('project_machinery_assignments').insert({
        'project_machinery_id': projectMachineryId,
        'start_date': start.toIso8601String().split('T')[0],
        'end_date': end.toIso8601String().split('T')[0],
        'quantity': 1,
      });
      await supabase.from('project_machinery').update({
        'start_date': start.toIso8601String().split('T')[0],
        'end_date': end.toIso8601String().split('T')[0],
      }).eq('id', projectMachineryId);
    } catch (e) {
      debugPrint('Error saving bulk machinery dates: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving dates: $e')));
      }
    }
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
            _buildServiceHeader(sName, serviceId: _extractServiceId(groupItems.first, 'quote_service_materials')),
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
            Text('No instruments registered for this project.', style: GoogleFonts.manrope(color: AppTheme.slate500)),
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
        child: Text(
          'No instruments found for this service filter.',
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
            _buildServiceHeader(sName, serviceId: _extractServiceId(groupItems.first, 'quote_service_instruments')),
            ...groupItems.map((m) {
              final expected = (m['expected_quantity'] as num?)?.toDouble() ?? 0.0;
              final received = (m['received_quantity'] as num?)?.toDouble() ?? 0.0;
              final isComplete = received >= expected;
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
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: isComplete ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.handyman, 
                        color: isComplete ? AppTheme.primaryGreen : Colors.purple,
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
                            'Received: $received / $expected',
                            style: GoogleFonts.manrope(
                              fontSize: 13, 
                              fontWeight: FontWeight.w600,
                              color: isComplete ? AppTheme.primaryGreen : AppTheme.slate500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildDateDisplay(
                            m['start_date'], 
                            m['end_date'], 
                            (m['project_instrument_assignments'] as List?)?.map((e) => {'start': e['start_date'], 'end': e['end_date'], 'qty': e['quantity']}).toList(),
                            Colors.purple
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showSafeDialog(
                          context: context,
                          fullscreenOnMobile: true,
                          builder: (_) => InstrumentSchedulingDialog(
                            projectInstrumentId: m['id'],
                            instrumentName: mName,
                            expectedQuantity: expected.toInt(),
                            serviceName: sName,
                          ),
                        ).then((updated) {
                          if (updated == true) _loadProjectData();
                        });
                      },
                      icon: const Icon(Icons.calendar_month, color: Colors.purple),
                      tooltip: 'Modify Dates',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.purple.withOpacity(0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 8),
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

    final aggregatedLabor = _aggregateLaborRows(_labor);
    final grouped = _groupByService(aggregatedLabor, 'quote_service_labors');
    
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
            _buildServiceHeader(sName, serviceId: _extractServiceId(groupItems.first, 'quote_service_labors')),
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
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _laborImage(),
                              const SizedBox(width: 16),
                              Expanded(child: _buildLaborInfoColumn(l, roleName, expected)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _laborScheduleButton(projectLaborId: l['id'], roleName: roleName, serviceName: sName),
                              const SizedBox(width: 8),
                              _laborAssignButton(projectLaborId: l['id'], roleName: roleName, expectedEmployees: expected),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          _laborImage(),
                          const SizedBox(width: 16),
                          Expanded(child: _buildLaborInfoColumn(l, roleName, expected)),
                          const SizedBox(width: 16),
                          _laborScheduleButton(projectLaborId: l['id'], roleName: roleName, serviceName: sName),
                          const SizedBox(width: 8),
                          _laborAssignButton(projectLaborId: l['id'], roleName: roleName, expectedEmployees: expected),
                          const SizedBox(width: 8),
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

  Widget _laborImage() {
    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.engineering, color: AppTheme.primaryGreen),
    );
  }

  Widget _buildLaborInfoColumn(Map<String, dynamic> l, String roleName, int expected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(roleName, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.slate900)),
        const SizedBox(height: 6),
        _buildLaborStatusInfo(
          'Crew Status',
          (l['project_labor_assignments'] != null && (l['project_labor_assignments'] as List).isNotEmpty)
              ? (l['project_labor_assignments'] as List).length
              : 0,
          expected,
          Colors.blue,
        ),
        const SizedBox(height: 8),
        _buildLaborEVMDisplay(l),
        if (l['project_labor_assignments'] != null && (l['project_labor_assignments'] as List).isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (l['project_labor_assignments'] as List).map((a) {
              final wName = a['workers']?['full_name'] ?? 'Unknown';
              final start = a['start_date'] ?? '?';
              final end = a['end_date'] ?? '?';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.slate50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.slate200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: AppTheme.slate600),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(wName, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                        Text('$start to $end', style: GoogleFonts.manrope(fontSize: 10, color: AppTheme.slate500)),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _laborScheduleButton({required String projectLaborId, required String roleName, required String serviceName}) {
    return IconButton(
      onPressed: () {
        showSafeDialog(
          context: context,
          fullscreenOnMobile: true,
          builder: (_) => LaborSchedulingDialog(
            projectLaborId: projectLaborId,
            roleName: roleName,
            serviceName: serviceName,
          ),
        ).then((updated) {
          if (updated == true) _loadProjectData();
        });
      },
      icon: const Icon(Icons.calendar_month, color: Colors.orange),
      tooltip: 'Modify Dates',
      style: IconButton.styleFrom(
        backgroundColor: Colors.orange.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _laborAssignButton({required String projectLaborId, required String roleName, required int expectedEmployees}) {
    return IconButton(
      onPressed: () {
        showSafeDialog(
          context: context,
          fullscreenOnMobile: true,
          builder: (_) => WorkerAssignmentDialog(
            projectLaborId: projectLaborId,
            roleName: roleName,
            expectedEmployees: expectedEmployees,
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
    );
  }

  void _showGanttDialog() {
    _loadProjectData().then((_) {
      if (!mounted) return;
      showSafeDialog(
        context: context,
        builder: (ctx) => _FullscreenTimelineDialog(
          projectId: widget.projectId,
          project: _project,
          machinery: _machinery,
          labor: _labor,
          instruments: _instruments,
          selectedServiceFilter: _selectedServiceFilter,
          onSaveBaseline: _saveBaselinePlanning,
          isSavingBaseline: _isSavingBaseline,
          baselineVersion: _baselineVersion,
        ),
      );
    });
  }

  Future<void> _recalculateSchedule() async {
    final supabase = Supabase.instance.client;
    final nwDays = await supabase
        .from('project_non_working_days')
        .select('date, partial_ratio, reason')
        .eq('project_id', widget.projectId);
    final fullDays = <String>[];
    final partialDays = <Map<String, dynamic>>[];
    double totalExtension = 0;
    for (final nw in nwDays ?? []) {
      final ratio = (nw['partial_ratio'] as num?)?.toDouble() ?? 0;
      if (ratio >= 1.0) {
        fullDays.add((nw['date'] as String).split('T')[0]);
        totalExtension += 1.0;
      } else if (ratio > 0) {
        partialDays.add(nw);
        totalExtension += ratio;
      }
    }
    if (!mounted) return;
    final confirmed = await showSafeDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Schedule Impact Summary', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (fullDays.isNotEmpty)
                Text('${fullDays.length} full non-working days', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate900)),
              if (partialDays.isNotEmpty)
                Text('${partialDays.length} partial days (${(totalExtension - fullDays.length).toStringAsFixed(1)}d lost)',
                    style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate900)),
              const SizedBox(height: 12), const Divider(), const SizedBox(height: 8),
              Text('Recommended extension: ${totalExtension.toStringAsFixed(1)} days',
                  style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.manrope(fontWeight: FontWeight.w600))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            child: Text('Apply Extension', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _applyScheduleExtension(totalExtension);
  }

  Future<void> _applyScheduleExtension(double extensionDays) async {
    final supabase = Supabase.instance.client;
    final duration = extensionDays.round();
    try {
      int updated = 0;
      for (final m in _machinery) {
        final endDateStr = m['end_date'] as String?;
        if (endDateStr != null && endDateStr.isNotEmpty) {
          final endDate = DateTime.tryParse(endDateStr);
          if (endDate != null) {
            await supabase.from('project_machinery').update({'end_date': endDate.add(Duration(days: duration)).toIso8601String()}).eq('id', m['id']);
            updated++;
          }
        }
      }
      for (final l in _labor) {
        final endDateStr = l['end_date'] as String?;
        if (endDateStr != null && endDateStr.isNotEmpty) {
          final endDate = DateTime.tryParse(endDateStr);
          if (endDate != null) {
            await supabase.from('project_labor').update({'end_date': endDate.add(Duration(days: duration)).toIso8601String()}).eq('id', l['id']);
            updated++;
          }
        }
      }
      for (final i in _instruments) {
        final endDateStr = i['end_date'] as String?;
        if (endDateStr != null && endDateStr.isNotEmpty) {
          final endDate = DateTime.tryParse(endDateStr);
          if (endDate != null) {
            await supabase.from('project_instruments').update({'end_date': endDate.add(Duration(days: duration)).toIso8601String()}).eq('id', i['id']);
            updated++;
          }
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$updated resources extended by $duration days'), backgroundColor: AppTheme.primaryGreen));
        _loadProjectData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed));
    }
  }

  bool _isSavingBaseline = false;

  Future<void> _createNewBaselineRevision() async {
    if (_project == null || _isSavingBaseline) return;
    setState(() => _isSavingBaseline = true);

    try {
      final supabase = Supabase.instance.client;
      final currentMeta = Map<String, dynamic>.from(_project!['calculation_metadata'] ?? {});
      currentMeta['baseline_daily_burn_rate'] = _dailyBurnRate;

      final baselineService = BaselineService(supabase);
      final snapshot = await baselineService.createSnapshot(
        projectId: widget.projectId,
        calculationMetadata: currentMeta,
        label: null,
        reason: 'New revision',
        userId: supabase.auth.currentUser?.id,
      );

      currentMeta['baseline_latest_snapshot_id'] = snapshot['id'];
      currentMeta['baseline_latest_version'] = snapshot['version'];

      await supabase.from('projects').update({
        'calculation_metadata': currentMeta,
      }).eq('id', widget.projectId);

      await _loadProjectData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lock executed: Baseline v${snapshot['version']} is now the active baseline.'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating revision: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating revision: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingBaseline = false);
    }
  }

  Future<void> _saveBaselinePlanning() async {
    if (_project == null || _isSavingBaseline) return;
    setState(() => _isSavingBaseline = true);

    try {
      final supabase = Supabase.instance.client;
      final currentMeta = Map<String, dynamic>.from(_project!['calculation_metadata'] ?? {});

      DateTime? minDate;
      DateTime? maxDate;

      final String Function(Map<String, dynamic>, String) getService = (r, table) {
        dynamic service = r['quote_services'];
        if (service == null) {
          final data = r[table];
          if (data != null) {
            final dData = (data is List && data.isNotEmpty) ? data[0] : (data is Map ? data : null);
            if (dData != null) {
              service = dData['quote_services'];
            }
          }
        }
        return service?['name']?.toString() ?? 'General / Unassigned';
      };

      for (var m in _machinery) {
        final evm = _calculateEVMDetails(m);
        if (evm['plannedStart'] != null && evm['plannedEnd'] != null) {
          final start = evm['plannedStart'] as DateTime;
          final end = evm['plannedEnd'] as DateTime;
          if (minDate == null || start.isBefore(minDate)) minDate = start;
          if (maxDate == null || end.isAfter(maxDate)) maxDate = end;
        }
      }

      for (var l in _labor) {
        final evm = _calculateLaborEVMDetails(l);
        if (evm['plannedStart'] != null && evm['plannedEnd'] != null) {
          final start = evm['plannedStart'] as DateTime;
          final end = evm['plannedEnd'] as DateTime;
          if (minDate == null || start.isBefore(minDate)) minDate = start;
          if (maxDate == null || end.isAfter(maxDate)) maxDate = end;
        }
      }

      for (var i in _instruments) {
        DateTime? pStart;
        DateTime? pEnd;
        if (i['start_date'] != null) pStart = DateTime.tryParse(i['start_date']);
        if (i['end_date'] != null) pEnd = DateTime.tryParse(i['end_date']);
        final assignments = (i['project_instrument_assignments'] as List?) ?? [];
        if ((pStart == null || pEnd == null) && assignments.isNotEmpty) {
          for (var a in assignments) {
            final aStart = DateTime.tryParse(a['start_date'] ?? '');
            final aEnd = DateTime.tryParse(a['end_date'] ?? '');
            if (aStart != null && (pStart == null || aStart.isBefore(pStart))) pStart = aStart;
            if (aEnd != null && (pEnd == null || aEnd.isAfter(pEnd))) pEnd = aEnd;
          }
        }
        if (pStart != null && pEnd != null) {
          if (minDate == null || pStart.isBefore(minDate)) minDate = pStart;
          if (pEnd.isAfter(maxDate ?? pStart)) maxDate = pEnd;
        }
      }

      int totalDays = 0;
      if (minDate != null && maxDate != null) {
        totalDays = maxDate.difference(minDate).inDays + 1;
      }

      currentMeta['baseline_daily_burn_rate'] = _dailyBurnRate;
      currentMeta['baseline_total_days'] = totalDays;
      currentMeta['baseline_resources_count'] = _machinery.length + _labor.length + _instruments.length;
      final baselineService = BaselineService(supabase);
      final snapshot = await baselineService.createSnapshot(
        projectId: widget.projectId,
        calculationMetadata: currentMeta,
        label: null,
        reason: 'Initial baseline',
        userId: supabase.auth.currentUser?.id,
      );

      currentMeta['baseline_latest_snapshot_id'] = snapshot['id'];
      currentMeta['baseline_latest_version'] = snapshot['version'];

      await supabase.from('projects').update({
        'calculation_metadata': currentMeta,
      }).eq('id', widget.projectId);

      await _loadProjectData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lock executed: Baseline v${snapshot['version']} is now the active baseline.'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving baseline: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar planificación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingBaseline = false);
      }
    }
  }
}

class _FullscreenTimelineDialog extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic>? project;
  final List<dynamic> machinery;
  final List<dynamic> labor;
  final List<dynamic> instruments;
  final String selectedServiceFilter;
  final Future<void> Function() onSaveBaseline;
  final bool isSavingBaseline;
  final int? baselineVersion;

  const _FullscreenTimelineDialog({
    Key? key,
    required this.projectId,
    required this.project,
    required this.machinery,
    required this.labor,
    required this.instruments,
    required this.selectedServiceFilter,
    required this.onSaveBaseline,
    required this.isSavingBaseline,
    this.baselineVersion,
  }) : super(key: key);

  @override
  State<_FullscreenTimelineDialog> createState() => _FullscreenTimelineDialogState();
}

class _FullscreenTimelineDialogState extends State<_FullscreenTimelineDialog> {
  final ScrollController _leftScrollController = ScrollController();
  final ScrollController _rightScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  bool _isUpdatingLeft = false;
  bool _isUpdatingRight = false;
  String _selectedServiceFilter = 'All Services';
  final Map<String, bool> _expandedServices = {};
  Map<String, double> _nonWorkingDays = {};
  // Baseline metrics
  double _baselineOriginalCost = 0;
  double _baselineDeviationCost = 0;
  double _baselineTotalDaysSaved = 0;
  double _baselineOriginalTotalDays = 0;
  double _baselineTotalCompressionSavings = 0;
  bool _baselineMetricsLoaded = false;
  List<Map<String, dynamic>> _disruptionBands = [];

  @override
  void initState() {
    super.initState();
    _selectedServiceFilter = widget.selectedServiceFilter;
    _loadNonWorkingDays();
    _loadDisruptions();

    _leftScrollController.addListener(() {
      if (_isUpdatingRight) return;
      _isUpdatingLeft = true;
      if (_rightScrollController.hasClients) {
        _rightScrollController.jumpTo(_leftScrollController.offset);
      }
      _isUpdatingLeft = false;
    });

    _rightScrollController.addListener(() {
      if (_isUpdatingLeft) return;
      _isUpdatingRight = true;
      if (_leftScrollController.hasClients) {
        _leftScrollController.jumpTo(_rightScrollController.offset);
      }
      _isUpdatingRight = false;
    });

    _loadBaselineMetrics();
  }

  Future<void> _loadBaselineMetrics() async {
    try {
      final supabase = Supabase.instance.client;

      // Compute from in-memory data (unplanned machinery, labor, instruments)
      double deviation = 0;
      double daysSaved = 0;
      double compressionSavings = 0;

      void processItems(List<dynamic> items) {
        for (var item in items) {
          // Skip CO-created resources: they are scope, not extra acceleration
          if (item['project_service_id'] != null) continue;
          final isUnplanned = item['is_unplanned'] == true;
          if (!isUnplanned) {
            final meta = _safeParseMetadata(item['calculation_metadata']);
            if (meta != null && meta['is_unplanned'] == true) {
              deviation += (item['unplanned_cost'] as num?)?.toDouble() ?? 0;
              daysSaved += (meta['days_saved'] as num?)?.toDouble() ?? 0;
              compressionSavings += (meta['compression_savings'] as num?)?.toDouble() ?? 0;
            }
            continue;
          }
          deviation += (item['unplanned_cost'] as num?)?.toDouble() ?? 0;
          final meta = _safeParseMetadata(item['calculation_metadata']);
          if (meta != null) {
            daysSaved += (meta['days_saved'] as num?)?.toDouble() ?? 0;
            compressionSavings += (meta['compression_savings'] as num?)?.toDouble() ?? 0;
          }
        }
      }

      processItems(widget.machinery);
      processItems(widget.labor);
      processItems(widget.instruments);

      // Fetch original budget and total days from Supabase
      double originalCost = 0;
      double originalTotalDays = 0;

      final quoteId = widget.project?['quote_id'];
      if (quoteId != null) {
        final quoteData = await supabase.from('quotes').select('total_amount').eq('id', quoteId).maybeSingle();
        originalCost = (quoteData?['total_amount'] as num?)?.toDouble() ?? 0;

        final estData = await supabase
            .from('quote_service_estimations')
            .select('total_working_days, quote_services!inner(quote_id)')
            .eq('quote_services.quote_id', quoteId);
        for (var e in estData) {
          originalTotalDays += (e['total_working_days'] as num?)?.toDouble() ?? 0;
        }
      }

      if (mounted) {
        setState(() {
          _baselineOriginalCost = originalCost;
          _baselineDeviationCost = deviation;
          _baselineTotalDaysSaved = daysSaved;
          _baselineOriginalTotalDays = originalTotalDays;
          _baselineTotalCompressionSavings = compressionSavings;
          _baselineMetricsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading baseline metrics: $e');
      if (mounted) setState(() => _baselineMetricsLoaded = true);
    }
  }

  Map<String, dynamic>? _safeParseMetadata(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is String && value.isNotEmpty) {
      try { return jsonDecode(value) as Map<String, dynamic>; } catch (_) {}
    }
    return null;
  }

  @override
  void dispose() {
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _localCalculateEVM(Map<String, dynamic> m) {
    final assignments = (m['project_machinery_assignments'] as List?) ?? [];
    DateTime? plannedStart;
    DateTime? plannedEnd;
    if (m['start_date'] != null) plannedStart = DateTime.tryParse(m['start_date']);
    if (m['end_date'] != null) plannedEnd = DateTime.tryParse(m['end_date']);
    if ((plannedStart == null || plannedEnd == null) && assignments.isNotEmpty) {
      for (var a in assignments) {
        final aStart = DateTime.tryParse(a['start_date'] ?? '');
        final aEnd = DateTime.tryParse(a['end_date'] ?? '');
        if (aStart != null && (plannedStart == null || aStart.isBefore(plannedStart))) plannedStart = aStart;
        if (aEnd != null && (plannedEnd == null || aEnd.isAfter(plannedEnd))) plannedEnd = aEnd;
      }
    }
    return {'plannedStart': plannedStart, 'plannedEnd': plannedEnd};
  }

  Map<String, dynamic> _localCalculateLaborEVM(Map<String, dynamic> l) {
    final assignments = (l['project_labor_assignments'] as List?) ?? [];
    DateTime? plannedStart;
    DateTime? plannedEnd;
    if (l['start_date'] != null) plannedStart = DateTime.tryParse(l['start_date']);
    if (l['end_date'] != null) plannedEnd = DateTime.tryParse(l['end_date']);
    if ((plannedStart == null || plannedEnd == null) && assignments.isNotEmpty) {
      for (var a in assignments) {
        final aStart = DateTime.tryParse(a['start_date'] ?? '');
        final aEnd = DateTime.tryParse(a['end_date'] ?? '');
        if (aStart != null && (plannedStart == null || aStart.isBefore(plannedStart))) plannedStart = aStart;
        if (aEnd != null && (plannedEnd == null || aEnd.isAfter(plannedEnd))) plannedEnd = aEnd;
      }
    }
    return {'plannedStart': plannedStart, 'plannedEnd': plannedEnd};
  }

  Future<void> _loadNonWorkingDays() async {
    try {
      final supabase = Supabase.instance.client;
      final nwDays = await supabase
          .from('project_non_working_days')
          .select('date, partial_ratio')
          .eq('project_id', widget.projectId);
      _nonWorkingDays.clear();
      for (final nw in nwDays ?? []) {
        final dateStr = nw['date'] as String?;
        final ratio = (nw['partial_ratio'] as num?)?.toDouble() ?? 0;
        if (dateStr != null) _nonWorkingDays[dateStr.split('T')[0]] = ratio;
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _loadDisruptions() async {
    try {
      debugPrint('[_loadDisruptions] loading for project ${widget.projectId}');
      final supabase = Supabase.instance.client;

      final approvedCOs = await supabase
          .from('change_orders')
          .select('id, co_number, status')
          .eq('project_id', widget.projectId)
          .eq('status', 'approved');

      debugPrint('[_loadDisruptions] approvedCOs=${approvedCOs?.length ?? 0}');
      if (approvedCOs == null || approvedCOs.isEmpty) return;

      final approvedCOIds = approvedCOs.map((c) => c['id'].toString()).toList();
      final coMap = {for (final c in approvedCOs) c['id'].toString(): c};

      final rawDisruptions = await supabase
          .from('change_order_disruptions')
          .select('id, start_date, end_date, disruption_type, change_order_id')
          .in_('change_order_id', approvedCOIds);

      debugPrint('[_loadDisruptions] disruption rows=${rawDisruptions?.length ?? 0}');
      if (rawDisruptions == null) return;

      final disruptions = List<Map<String, dynamic>>.from(rawDisruptions);
      _disruptionBands = disruptions.where((d) {
        final coId = d['change_order_id']?.toString();
        return coId != null && coMap.containsKey(coId);
      }).map((d) {
        final copy = Map<String, dynamic>.from(d);
        final coId = copy['change_order_id'].toString();
        copy['change_orders'] = Map<String, dynamic>.from(coMap[coId]!);
        return copy;
      }).toList();

      debugPrint('Gantt disruptions loaded: ${_disruptionBands.length} bands for project ${widget.projectId}');
      if (mounted) setState(() {});
    } catch (e, st) {
      debugPrint('[_loadDisruptions] ERROR: $e\n$st');
    }
  }

  Color _disruptionColor(String? type) {
    switch (type) {
      case 'WEATHER_RAIN':
      case 'WEATHER_OTHER':
        return const Color(0xFFBBDEFB);
      case 'OWNER_DELAY':
        return const Color(0xFFFFE0B2);
      case 'EXTERNAL_DEP':
      case 'PENDING_PERMIT':
        return const Color(0xFFE1BEE7);
      case 'DESIGN_CHANGE':
        return const Color(0xFFFFCDD2);
      default:
        return const Color(0xFFE0E0E0);
    }
  }

  Widget _buildDisruptionBandRow(DateTime minVal, int totalDays, double dayWidth) {
    return SizedBox(
      width: totalDays * dayWidth,
      height: 24,
      child: Stack(
        children: [
          for (final d in _disruptionBands)
            _buildDisruptionBand(d, minVal, dayWidth),
        ],
      ),
    );
  }

  Widget _buildDisruptionBand(Map<String, dynamic> d, DateTime minVal, double dayWidth) {
    final startStr = d['start_date']?.toString();
    final endStr = d['end_date']?.toString();
    if (startStr == null) return const SizedBox.shrink();

    final startDate = DateTime.tryParse(startStr);
    final endDate = endStr != null ? DateTime.tryParse(endStr) : startDate;
    if (startDate == null) return const SizedBox.shrink();

    final effectiveEnd = endDate ?? startDate;
    final startOffset = startDate.difference(minVal).inDays;
    final duration = effectiveEnd.difference(startDate).inDays + 1;

    if (startOffset < 0) return const SizedBox.shrink();
    if (duration <= 0) return const SizedBox.shrink();

    final coNumber = d['change_orders']?['co_number']?.toString() ?? '';
    final reason = (d['disruption_type'] as String? ?? '').replaceAll('_', ' ');
    final color = _disruptionColor(d['disruption_type'] as String?);
    final label = '$coNumber: $reason';

    return Positioned(
      left: startOffset * dayWidth,
      width: duration * dayWidth,
      top: 2,
      bottom: 2,
      child: Tooltip(
        message: label,
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color.withOpacity(0.4), width: 0.5),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              Icon(Icons.warning_amber, size: 10, color: color.withOpacity(0.7)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w600, color: color.withOpacity(0.8)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Segments of a resource bar that fall inside disruption periods (positioned
  // relative to the bar's own left edge). Used to visually mark disrupted days.
  List<Widget> _buildBarDisruptionOverlays(DateTime barStart, DateTime barEnd, double dayWidth) {
    if (_disruptionBands.isEmpty) return const [];

    final barSpan = barEnd.difference(barStart).inDays + 1;
    final overlays = <Widget>[];

    for (final d in _disruptionBands) {
      final startStr = d['start_date']?.toString();
      final endStr = d['end_date']?.toString();
      final dStart = startStr != null ? DateTime.tryParse(startStr) : null;
      final dEnd = endStr != null ? DateTime.tryParse(endStr) : dStart;
      if (dStart == null) continue;

      final overlapStart = dStart.isAfter(barStart) ? dStart : barStart;
      final overlapEnd = (dEnd != null && dEnd.isBefore(barEnd)) ? dEnd : barEnd;
      if (overlapStart.isAfter(overlapEnd)) continue;

      final color = _disruptionColor(d['disruption_type'] as String?);
      final offsetInBar = overlapStart.difference(barStart).inDays;
      final segmentDays = overlapEnd.difference(overlapStart).inDays + 1;

      if (offsetInBar < 0 || segmentDays <= 0 || offsetInBar + segmentDays > barSpan) continue;

      overlays.add(
        Positioned(
          left: offsetInBar * dayWidth,
          width: segmentDays * dayWidth,
          top: 0,
          bottom: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CustomPaint(
              painter: _DisruptionStripePainter(color: color, stripeSpacing: 5.0),
            ),
          ),
        ),
      );
    }
    if (overlays.isNotEmpty) {
      debugPrint('  [_buildBarDisruptionOverlays] bar $barStart->$barEnd generated ${overlays.length} overlays');
    }
    return overlays;
  }

  Widget _buildRowBackground(int totalDays, double dayWidth, bool isService, DateTime minVal) {
    return Row(
      children: List.generate(totalDays, (index) {
        final day = minVal.add(Duration(days: index));
        final isSunday = day.weekday == DateTime.sunday;
        final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final nwRatio = _nonWorkingDays[key] ?? 0;
        final isNonWorking = nwRatio >= 1.0;
        final isPartial = nwRatio > 0 && nwRatio < 1.0;
        return Container(
          width: dayWidth,
          height: isService ? 52 : 44,
          decoration: BoxDecoration(
            color: isNonWorking ? const Color(0xFFFEF3C7).withOpacity(0.6)
                : isPartial ? const Color(0xFFFEF3C7).withOpacity(0.3)
                : isSunday ? const Color(0xFFFEF2F2).withOpacity(0.5)
                : null,
            border: Border(
              right: BorderSide(
                color: isNonWorking ? const Color(0xFFF59E0B).withOpacity(0.3)
                    : isSunday ? const Color(0xFFFECACA)
                    : const Color(0xFFE2E8F0).withOpacity(0.4),
                width: 1,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimelineHeader(DateTime minVal, int totalDays, double dayWidth) {
    final List<Widget> monthHeaders = [];
    final List<Widget> dayHeaders = [];

    DateTime current = minVal;
    int currentMonthDays = 0;
    String currentMonthStr = '';

    for (int i = 0; i < totalDays; i++) {
      final day = minVal.add(Duration(days: i));
      final monthStr = DateFormat('MMMM yyyy').format(day);

      if (i == 0) {
        currentMonthStr = monthStr;
        currentMonthDays = 1;
      } else if (monthStr == currentMonthStr) {
        currentMonthDays++;
      } else {
        monthHeaders.add(
          Container(
            width: currentMonthDays * dayWidth,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              border: Border(
                right: BorderSide(color: Color(0xFF334155), width: 1),
                bottom: BorderSide(color: Color(0xFF334155), width: 1),
              ),
            ),
            child: Text(
              currentMonthStr.toUpperCase(),
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
        currentMonthStr = monthStr;
        currentMonthDays = 1;
      }

      dayHeaders.add(
        Container(
          width: dayWidth,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: day.weekday == DateTime.sunday ? const Color(0xFF2D1515) : const Color(0xFF0F172A),
            border: Border(
              right: const BorderSide(color: Color(0xFF1E293B), width: 1),
              bottom: const BorderSide(color: Color(0xFF1E293B), width: 1),
            ),
          ),
          child: Text(
            day.day.toString(),
            style: GoogleFonts.manrope(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: day.weekday == DateTime.sunday ? const Color(0xFFFCA5A5) : const Color(0xFF94A3B8),
            ),
          ),
        ),
      );
    }

    monthHeaders.add(
      Container(
        width: currentMonthDays * dayWidth,
        height: 28,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          border: Border(
            right: BorderSide(color: Color(0xFF334155), width: 1),
            bottom: BorderSide(color: Color(0xFF334155), width: 1),
          ),
        ),
        child: Text(
          currentMonthStr.toUpperCase(),
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );

    return Column(
      children: [
        Row(children: monthHeaders),
        Row(children: dayHeaders),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [];

    String getService(Map<String, dynamic> item, String relationName) {
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
      if (service is List && service.isNotEmpty) {
        service = service[0];
      }
      return service?['name']?.toString() ?? 'General / Unassigned';
    }

    for (var m in widget.machinery) {
      final evm = _localCalculateEVM(m);
      final isPlanned = (m['quote_service_machineries'] != null &&
              (m['quote_service_machineries'] is! List || (m['quote_service_machineries'] as List).isNotEmpty)) ||
          m['project_service_id'] != null;
      items.add({
        'name': m['machinery_name'] ?? 'Unknown Machine',
        'type': 'Machinery',
        'icon': Icons.precision_manufacturing,
        'service': getService(m, 'quote_service_machineries'),
        'plannedStart': evm['plannedStart'] as DateTime?,
        'plannedEnd': evm['plannedEnd'] as DateTime?,
        'isUnplanned': !isPlanned || m['calculation_metadata']?['is_unplanned'] == true,
        'calculationMetadata': m['calculation_metadata'] as Map<String, dynamic>?,
        'changeType': m['change_type'] ?? 'planning',
        'isCo': m['project_service_id'] != null,
      });
    }

    for (var l in widget.labor) {
      final evm = _localCalculateLaborEVM(l);
      final isPlanned = (l['quote_service_labors'] != null &&
              (l['quote_service_labors'] is! List || (l['quote_service_labors'] as List).isNotEmpty)) ||
          l['project_service_id'] != null;
      items.add({
        'name': l['role_name'] ?? 'Unknown Crew',
        'type': 'Labor',
        'icon': Icons.engineering,
        'service': getService(l, 'quote_service_labors'),
        'plannedStart': evm['plannedStart'] as DateTime?,
        'plannedEnd': evm['plannedEnd'] as DateTime?,
        'isUnplanned': !isPlanned || l['calculation_metadata']?['is_unplanned'] == true,
        'calculationMetadata': l['calculation_metadata'] as Map<String, dynamic>?,
        'changeType': l['change_type'] ?? 'planning',
        'isCo': l['project_service_id'] != null,
      });
    }

    for (var i in widget.instruments) {
      DateTime? plannedStart;
      DateTime? plannedEnd;
      if (i['start_date'] != null) {
        plannedStart = DateTime.tryParse(i['start_date']);
      }
      if (i['end_date'] != null) {
        plannedEnd = DateTime.tryParse(i['end_date']);
      }
      final assignments = (i['project_instrument_assignments'] as List?) ?? [];
      if ((plannedStart == null || plannedEnd == null) && assignments.isNotEmpty) {
        for (var a in assignments) {
          final aStart = DateTime.tryParse(a['start_date'] ?? '');
          final aEnd = DateTime.tryParse(a['end_date'] ?? '');
          if (aStart != null && (plannedStart == null || aStart.isBefore(plannedStart))) {
            plannedStart = aStart;
          }
          if (aEnd != null && (plannedEnd == null || aEnd.isAfter(plannedEnd))) {
            plannedEnd = aEnd;
          }
        }
      }

      final isPlanned = (i['quote_service_instruments'] != null &&
              (i['quote_service_instruments'] is! List || (i['quote_service_instruments'] as List).isNotEmpty)) ||
          i['project_service_id'] != null;
      items.add({
        'name': i['instrument_name'] ?? 'Unknown Tool',
        'type': 'Instrument',
        'icon': Icons.handyman,
        'service': getService(i, 'quote_service_instruments'),
        'plannedStart': plannedStart,
        'plannedEnd': plannedEnd,
        'isUnplanned': !isPlanned || i['calculation_metadata']?['is_unplanned'] == true,
        'calculationMetadata': i['calculation_metadata'] as Map<String, dynamic>?,
        'changeType': i['change_type'] ?? 'planning',
        'isCo': i['project_service_id'] != null,
      });
    }

    // Dynamic timeline compression logic
    final Map<String, double> serviceDaysSaved = {};
    for (var item in items) {
      if (item['isUnplanned'] == true && item['isCo'] != true && item['calculationMetadata'] != null) {
        final serviceName = item['service'] as String;
        final saved = (item['calculationMetadata']?['days_saved'] as num?)?.toDouble() ?? 0.0;
        serviceDaysSaved[serviceName] = (serviceDaysSaved[serviceName] ?? 0.0) + saved;
      }
    }

    // Compute original service max dates BEFORE compression (for ghost bars)
    final Map<String, DateTime> serviceOriginalMax = {};
    for (var item in items) {
      final serviceName = item['service'] as String;
      final end = item['plannedEnd'] as DateTime?;
      if (end != null) {
        final currentMax = serviceOriginalMax[serviceName];
        if (currentMax == null || end.isAfter(currentMax)) {
          serviceOriginalMax[serviceName] = end;
        }
      }
    }

    // Shorten the end dates of planned resources in compressed services
    for (var item in items) {
      if (item['isUnplanned'] != true) {
        final serviceName = item['service'] as String;
        final double daysSaved = serviceDaysSaved[serviceName] ?? 0.0;
        if (daysSaved > 0 && item['plannedEnd'] != null) {
          final originalEnd = item['plannedEnd'] as DateTime;
          final originalStart = item['plannedStart'] as DateTime?;
          var compressedEnd = originalEnd.subtract(Duration(days: daysSaved.round()));
          if (originalStart != null && compressedEnd.isBefore(originalStart)) {
            compressedEnd = originalStart;
          }
          item['originalPlannedEnd'] = originalEnd;
          item['plannedEnd'] = compressedEnd;
        }
      }
    }

    // Compute compressed-only max date (without original dates)
    DateTime? compressedMaxDate;
    for (var item in items) {
      final end = item['plannedEnd'] as DateTime?;
      if (end != null && (compressedMaxDate == null || end.isAfter(compressedMaxDate))) {
        compressedMaxDate = end;
      }
    }

    DateTime? minDate;
    DateTime? maxDate;

    void expandBounds(DateTime? d) {
      if (d == null) return;
      if (minDate == null || d.isBefore(minDate!)) minDate = d;
      if (maxDate == null || d.isAfter(maxDate!)) maxDate = d;
    }

    for (var item in items) {
      expandBounds(item['plannedStart']);
      expandBounds(item['plannedEnd']);
      expandBounds(item['originalPlannedEnd']); // include original end for ghost bars
    }
    // Also include service-level original max dates so ghost bars fit in viewport
    for (var d in serviceOriginalMax.values) {
      expandBounds(d);
    }

    final DateTime minVal = minDate ?? DateTime.now();
    final DateTime maxVal = maxDate ?? minVal.add(const Duration(days: 30));
    final int totalDays = maxVal.difference(minVal).inDays + 1;
    final double dayWidth = 18.0;

    final Map<String, List<Map<String, dynamic>>> groupedItems = {};
    final Set<String> allServicesInTimeline = {'All Services'};

    for (var item in items) {
      final serviceName = item['service'] as String? ?? 'General / Unassigned';
      allServicesInTimeline.add(serviceName);
      if (_selectedServiceFilter == 'All Services' || serviceName == _selectedServiceFilter) {
        if (!groupedItems.containsKey(serviceName)) {
          groupedItems[serviceName] = [];
        }
        groupedItems[serviceName]!.add(item);
      }
    }

    final List<String> serviceNames = groupedItems.keys.toList()..sort();
    final isFrozen = widget.baselineVersion != null;

    final List<Widget> leftRows = [];
    final List<Widget> rightRows = [];

    // Disruption bands overlay
    if (_disruptionBands.isNotEmpty && !isFrozen) {
      rightRows.add(_buildDisruptionBandRow(minVal, totalDays, dayWidth));
    }

    for (var sName in serviceNames) {
      final serviceItems = groupedItems[sName]!;
      final isExpanded = _expandedServices[sName] ?? true;

      DateTime? sMin;
      DateTime? sMax;
      for (var item in serviceItems) {
        final start = item['plannedStart'] as DateTime?;
        final end = item['plannedEnd'] as DateTime?;
        if (start != null && (sMin == null || start.isBefore(sMin))) sMin = start;
        if (end != null && (sMax == null || end.isAfter(sMax))) sMax = end;
      }
      final int sDuration = (sMin != null && sMax != null) ? sMax.difference(sMin).inDays + 1 : 0;
      final double savedDays = serviceDaysSaved[sName] ?? 0.0;
      final DateTime? originalSMax = serviceOriginalMax[sName];
      final bool hasCompression = originalSMax != null && sMax != null && originalSMax.isAfter(sMax);
      final int originalSDuration = (sMin != null && originalSMax != null)
          ? originalSMax.difference(sMin).inDays + 1
          : 0;

      leftRows.add(
        InkWell(
          onTap: () {
            setState(() {
              _expandedServices[sName] = !isExpanded;
            });
          },
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                right: BorderSide(color: Color(0xFFCBD5E1), width: 2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  color: AppTheme.slate600,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sName,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppTheme.slate900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (sMin != null && sMax != null)
                        Text(
                          '${DateFormat('MMM dd').format(sMin)} - ${DateFormat('MMM dd').format(sMax)} ($sDuration d)',
                          style: GoogleFonts.manrope(fontSize: 10, color: AppTheme.slate500, fontWeight: FontWeight.w600),
                        ),
                      if (hasCompression && savedDays > 0)
                        Text(
                          '-${savedDays.toStringAsFixed(1)}d from extra resources',
                          style: GoogleFonts.manrope(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryGreen,
                              ),
                            ),
                        ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      rightRows.add(
        Container(
          height: 52,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
          ),
          child: Stack(
            children: [
              _buildRowBackground(totalDays, dayWidth, true, minVal),
              // Ghost bar: original (uncompressed) duration
              if (hasCompression && sMin != null)
                Positioned(
                  left: sMin.difference(minVal).inDays * dayWidth,
                  width: originalSDuration * dayWidth,
                  top: 14,
                  height: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF64748B).withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF64748B).withOpacity(0.4),
                        width: 1,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '${originalSDuration}d orig',
                      style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
                    ),
                  ),
                ),
              // Current (compressed) bar
              if (sMin != null && sMax != null)
                Positioned(
                  left: sMin.difference(minVal).inDays * dayWidth,
                  width: sDuration * dayWidth,
                  top: 14,
                  height: 24,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                          ],
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '$sDuration d',
                          style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                      ..._buildBarDisruptionOverlays(sMin, sMax, dayWidth),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );

      if (isExpanded) {
        for (var item in serviceItems) {
          final start = item['plannedStart'] as DateTime?;
          final end = item['plannedEnd'] as DateTime?;
          final originalEnd = item['originalPlannedEnd'] as DateTime?;
          final isExtra = item['isUnplanned'] == true;
          final int itemDuration = (start != null && end != null) ? end.difference(start).inDays + 1 : 0;
          final int originalItemDuration = (start != null && originalEnd != null)
              ? originalEnd.difference(start).inDays + 1
              : 0;
          final bool itemWasCompressed = !isExtra && originalEnd != null && end != null && originalEnd.isAfter(end);

          leftRows.add(
            Container(
              height: 44,
              padding: const EdgeInsets.only(left: 36, right: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                  right: BorderSide(color: Color(0xFFCBD5E1), width: 2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    item['icon'] as IconData,
                    size: 14,
                    color: isExtra ? Colors.orange : AppTheme.primaryGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item['name'] as String,
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: AppTheme.slate700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item['changeType'] == 'change_order') ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF97316).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                'CHANGE ORDER',
                                style: GoogleFonts.manrope(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFF97316),
                                ),
                              ),
                            ),
                          ] else if (isExtra) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                'EXTRA',
                                style: GoogleFonts.manrope(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                          ],
                        ),
                        if (start != null && end != null)
                          Text(
                            '${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd').format(end)} ($itemDuration d)',
                            style: GoogleFonts.manrope(fontSize: 9, color: AppTheme.slate500),
                          )
                        else
                          Text(
                            'Pending',
                            style: GoogleFonts.manrope(fontSize: 9, color: Colors.orange, fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );

          final itemType = item['type'] as String? ?? 'Machinery';
          final List<Color> plannedColors;
          final List<Color> extraColors;
          switch (itemType) {
            case 'Labor':
              plannedColors = [Colors.blue, const Color(0xFF3B82F6)];
              extraColors = [Colors.orange, const Color(0xFFF59E0B)];
              break;
            case 'Instrument':
              plannedColors = [Colors.purple, const Color(0xFF8B5CF6)];
              extraColors = [Colors.orange, const Color(0xFFF59E0B)];
              break;
            default: // Machinery
              plannedColors = [AppTheme.primaryGreen, const Color(0xFF10B981)];
              extraColors = [Colors.orange, const Color(0xFFF59E0B)];
          }

          rightRows.add(
            Container(
              height: 44,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
              ),
              child: Stack(
                children: [
                  _buildRowBackground(totalDays, dayWidth, false, minVal),
                  // Ghost extension: original (uncompressed) segment
                  if (itemWasCompressed && start != null && end != null && originalEnd != null)
                    Positioned(
                      left: end.difference(minVal).inDays * dayWidth,
                      width: (originalEnd.difference(end).inDays + 1) * dayWidth,
                      top: 10,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: plannedColors[0].withOpacity(0.15),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                          border: Border.all(
                            color: plannedColors[0].withOpacity(0.3),
                            width: 1,
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '-${originalItemDuration - itemDuration}d',
                          style: GoogleFonts.manrope(
                            fontSize: 7,
                            fontWeight: FontWeight.w600,
                            color: plannedColors[0].withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                    if (start != null && end != null)
                    Positioned(
                      left: start.difference(minVal).inDays * dayWidth,
                      width: itemDuration * dayWidth,
                      top: 10,
                      height: 24,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isExtra ? extraColors : plannedColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: item['changeType'] == 'change_order'
                                  ? Border.all(color: const Color(0xFFF97316), width: 2)
                                  : null,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 3, offset: const Offset(0, 1)),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$itemDuration d',
                              style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          ..._buildBarDisruptionOverlays(start, end, dayWidth),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        }
      }
    }

    final sortedTimelineServices = allServicesInTimeline.toList()
      ..sort((a, b) {
        if (a == 'All Services') return -1;
        if (b == 'All Services') return 1;
        return a.compareTo(b);
      });

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: Dialog.fullscreen(
        backgroundColor: AppTheme.backgroundLight,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.slate700),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.project?['title'] ?? 'Full Timeline',
                            style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                          ),
                          const SizedBox(width: 8),
                          if (isFrozen)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Baseline v${widget.baselineVersion} Locked ✓',
                                style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        'Complete Interactive Resource Timeline',
                        style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.slate200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedServiceFilter,
                      icon: const Icon(Icons.filter_list, size: 16, color: AppTheme.slate600),
                      style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.slate700),
                      items: sortedTimelineServices.map((serviceName) {
                        return DropdownMenuItem<String>(
                          value: serviceName,
                          child: Text(serviceName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedServiceFilter = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () {
                    debugPrint('Gantt Baseline button pressed');
                    Navigator.pop(context, 'navigate_to_baseline');
                  },
                  icon: const Icon(Icons.insights, size: 14, color: AppTheme.slate600),
                  label: Text('Baseline', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate600)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _exportTimelinePdf(items, minVal, totalDays, serviceOriginalMax, serviceDaysSaved, compressedMaxDate),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 14, color: AppTheme.slate600),
                  label: Text('PDF', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate600)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                if (!isFrozen)
                  ElevatedButton.icon(
                    onPressed: widget.isSavingBaseline
                        ? null
                        : () async {
                            await widget.onSaveBaseline();
                          },
                    icon: widget.isSavingBaseline
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_outline, size: 14, color: Colors.white),
                    label: Text(
                      widget.isSavingBaseline ? 'Saving...' : 'Lock Baseline',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: widget.isSavingBaseline
                        ? null
                        : () async {
                            await widget.onSaveBaseline();
                          },
                    icon: widget.isSavingBaseline
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.add_box_outlined, size: 14, color: Colors.white),
                    label: Text(
                      widget.isSavingBaseline ? 'Saving...' : 'New Revision',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
              ],
            ),
          ),
          if (_baselineMetricsLoaded && _baselineTotalDaysSaved > 0)
            _buildBaselineSummaryLine(),
          Builder(builder: (context) {
            final int extraCount = items.where((i) => i['isUnplanned'] == true).length;
            final int plannedCount = items.length - extraCount;
            final int originalDays = _baselineOriginalTotalDays > 0 ? _baselineOriginalTotalDays.toInt() : totalDays;
            final int savedDays = _baselineTotalDaysSaved > 0 ? _baselineTotalDaysSaved.toInt() : 0;
            final int compressedWorkDays = originalDays - savedDays;
            final double roi = _baselineDeviationCost > 0 && _baselineTotalCompressionSavings > 0
                ? (_baselineTotalCompressionSavings / _baselineDeviationCost) * 100
                : 0.0;
            final DateFormat statsFmt = DateFormat('MMM dd');

            return Container(
              color: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.settings_suggest, size: 14, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text('$plannedCount${extraCount > 0 ? " +$extraCount extra" : ""}', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.blue)),
                  if (extraCount > 0) ...[
                    const SizedBox(width: 4),
                    Text('resources', style: GoogleFonts.manrope(fontSize: 10, color: const Color(0xFF64748B))),
                  ],
                  const SizedBox(width: 20),
                  Icon(Icons.calendar_today, size: 14, color: savedDays > 0 ? AppTheme.primaryGreen : Colors.orange),
                  const SizedBox(width: 6),
                  if (savedDays > 0)
                    Text('${originalDays}d → ${compressedWorkDays}d', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen))
                  else
                    Text('${originalDays}d', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.orange)),
                  const SizedBox(width: 20),
                  Icon(Icons.date_range, size: 14, color: savedDays > 0 ? AppTheme.primaryGreen : AppTheme.primaryGreen),
                  const SizedBox(width: 6),
                  if (items.isEmpty)
                    Text('Not scheduled', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white))
                  else if (savedDays > 0 && compressedMaxDate != null && compressedMaxDate.isBefore(maxVal))
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(text: '${statsFmt.format(minVal)} – ${statsFmt.format(compressedMaxDate!)}', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                        TextSpan(text: ' ◀ ${statsFmt.format(maxVal)}', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF64748B))),
                      ]),
                    )
                  else
                    Text(
                      '${statsFmt.format(minVal)} – ${statsFmt.format(maxVal)}',
                      style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  const Spacer(),
                  if (_baselineTotalCompressionSavings > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                      child: Text('${_formatCurrency(_baselineTotalCompressionSavings)} saved', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
                    ),
                    if (roi > 0) ...[
                      const SizedBox(width: 8),
                      Text('ROI ${roi.toStringAsFixed(1)}%', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF22D3EE))),
                    ],
                  ],
                  const SizedBox(width: 16),
                  _buildLegendBox('Machinery', AppTheme.primaryGreen),
                  const SizedBox(width: 10),
                  _buildLegendBox('Labor', Colors.blue),
                  const SizedBox(width: 10),
                  _buildLegendBox('Inst', Colors.purple),
                  const SizedBox(width: 10),
                  _buildLegendBox('Extra', Colors.orange),
                ],
              ),
            );
          }),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.query_builder, size: 64, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 16),
                        Text(
                          'No resources assigned or scheduled in this project.',
                          style: GoogleFonts.manrope(color: AppTheme.slate500),
                        ),
                      ],
                    ),
                  )
                : ClipRect(
                    child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 300,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 52,
                              width: 300,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E293B),
                                border: Border(
                                  bottom: BorderSide(color: Color(0xFF334155), width: 1),
                                  right: BorderSide(color: Color(0xFFCBD5E1), width: 2),
                                ),
                              ),
                              child: Text(
                                'SERVICIOS & RECURSOS',
                                style: GoogleFonts.manrope(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: _leftScrollController,
                                child: Column(
                                  children: leftRows,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Scrollbar(
                          controller: _horizontalScrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          thickness: 8.0,
                          radius: const Radius.circular(4),
                          child: SingleChildScrollView(
                            controller: _horizontalScrollController,
                            scrollDirection: Axis.horizontal,
                            child: Container(
                              width: totalDays * dayWidth,
                              color: Colors.white,
                              child: Column(
                                children: [
                                  _buildTimelineHeader(minVal, totalDays, dayWidth),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      controller: _rightScrollController,
                                      child: Column(
                                        children: rightRows,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ),
          ),
        ],
      ),
    ),);
  }

  String _formatCurrency(double amount) {
    final abs = amount.abs();
    final formatted = abs >= 1000
        ? '\$${(abs / 1000).toStringAsFixed(1)}K'
        : '\$${abs.toStringAsFixed(0)}';
    return amount < 0 ? '-$formatted' : formatted;
  }

  Widget _buildBaselineSummaryLine() {
    final compressedDays = _baselineOriginalTotalDays - _baselineTotalDaysSaved;
    final roi = _baselineDeviationCost > 0
        ? ((_baselineTotalCompressionSavings / _baselineDeviationCost) * 100)
        : 0.0;
    final netImpact = _baselineDeviationCost - _baselineTotalCompressionSavings;
    final projectedCost = _baselineOriginalCost + _baselineDeviationCost;

    return InkWell(
      onTap: () {
        debugPrint('Gantt summary line tapped → navigate to baseline');
        Navigator.pop(context, 'navigate_to_baseline');
      },
      child: Container(
        color: const Color(0xFF1E293B),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.insights, color: const Color(0xFF22D3EE).withOpacity(0.7), size: 16),
            const SizedBox(width: 8),
            Text('${_baselineTotalDaysSaved.toStringAsFixed(1)}d compressed', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF22D3EE))),
            const SizedBox(width: 16),
            Text('${_formatCurrency(projectedCost)} budget', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(width: 16),
            if (_baselineTotalCompressionSavings > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Text('${_formatCurrency(_baselineTotalCompressionSavings)} saved', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
              ),
              const SizedBox(width: 8),
            ],
            if (roi > 0)
              Text('ROI ${roi.toStringAsFixed(1)}%', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF22D3EE))),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  Future<void> _exportTimelinePdf(
    List<Map<String, dynamic>> items,
    DateTime minVal,
    int totalDays,
    Map<String, DateTime> serviceOriginalMax,
    Map<String, double> serviceDaysSaved,
    DateTime? compressedMaxDate,
  ) async {
    final extraCount = items.where((i) => i['isUnplanned'] == true).length;
    final plannedCount = items.length - extraCount;

    try {
      final pdfBytes = await TimelinePdfGenerator.generate(
        projectTitle: widget.project?['title'] ?? 'Resource Timeline',
        projectId: widget.projectId,
        items: items,
        minVal: minVal,
        totalDays: totalDays,
        expandedServices: Map<String, bool>.from(_expandedServices),
        selectedServiceFilter: _selectedServiceFilter,
        serviceOriginalMax: serviceOriginalMax,
        serviceDaysSaved: serviceDaysSaved,
        compressedMaxDate: compressedMaxDate,
        baselineOriginalTotalDays: _baselineOriginalTotalDays,
        baselineTotalDaysSaved: _baselineTotalDaysSaved,
        baselineDeviationCost: _baselineDeviationCost,
        baselineTotalCompressionSavings: _baselineTotalCompressionSavings,
        plannedCount: plannedCount,
        extraCount: extraCount,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'Timeline_${widget.projectId.substring(0, 8)}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  Widget _buildLegendBox(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}

class _DisruptionStripePainter extends CustomPainter {
  _DisruptionStripePainter({required this.color, this.stripeSpacing = 5.0});

  final Color color;
  final double stripeSpacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.55)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final gap = stripeSpacing * 1.6;
    for (double x = -size.height; x < size.width + size.height; x += stripeSpacing + gap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DisruptionStripePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.stripeSpacing != stripeSpacing;
  }
}
