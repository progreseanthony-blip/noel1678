import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../providers/change_order_providers.dart';
import '../providers/change_order_controller.dart';
import '../widgets/standby_form_section.dart';
import '../widgets/baseline_impact_section.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../../../../shared/widgets/completed_project_banner.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import '../../../../features/quotes/presentation/widgets/service_estimation_dialog.dart';

class ChangeOrderFormPage extends ConsumerStatefulWidget {
  final String projectId;
  final String? coId;

  const ChangeOrderFormPage({super.key, required this.projectId, this.coId});

  bool get isEditing => coId != null;

  @override
  ConsumerState<ChangeOrderFormPage> createState() =>
      _ChangeOrderFormPageState();
}

class _ChangeOrderFormPageState extends ConsumerState<ChangeOrderFormPage> {
  bool _isCompleted = false;
  String _projectTitle = '';
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _schedDaysCtrl = TextEditingController();
  int _schedDays = 0;
  bool _saving = false;
  bool _loadingData = false;

  String _coType = 'scope_change';
  String? _originalStatus;
  String? _disruptionReasonId;
  DateTime? _disruptionStart;
  DateTime? _disruptionEnd;
  int _delayDays = 0;
  final _disruptionServices = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _availableTasks = [];

  final _lines = <Map<String, dynamic>>[];
  final _resourcePlans = <String, List<Map<String, dynamic>>>{};
  final _fmt = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    _loadProjectName();
    if (widget.isEditing) _loadData();
  }

  Future<void> _loadProjectName() async {
    try {
      final data = await Supabase.instance.client
          .from('projects')
          .select('title')
          .eq('id', widget.projectId)
          .maybeSingle();
      if (mounted && data != null) {
        setState(() => _projectTitle = data['title']?.toString() ?? '');
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _schedDaysCtrl.dispose();
    super.dispose();
  }

  double get _totalAdjustment => _lines.fold(0.0, (s, l) {
    final lt = l['line_type'] as String?;
    if (lt == 'standby_labor' || lt == 'standby_machinery') {
      final hrs = (l['standby_hours'] as num?)?.toDouble() ?? 0;
      final rate = (l['standby_rate'] as num?)?.toDouble() ?? 0;
      return s + (hrs * rate);
    } else if (lt == 'standby_material') {
      final loss = (l['quantity_lost'] as num?)?.toDouble() ?? 0;
      final cost = (l['replacement_unit_cost'] as num?)?.toDouble() ?? 0;
      return s + (loss * cost);
    }
    final qty = (l['quantity_change'] as num?)?.toDouble() ?? 0;
    final up = (l['unit_price'] as num?)?.toDouble() ?? 0;
    return s + (qty * up);
  });

  bool get _isEditing => widget.isEditing;

  Future<void> _loadData() async {
    setState(() => _loadingData = true);
    try {
      final svc = ref.read(billingServiceProvider);
      final co = await ref.read(changeOrderDetailProvider(widget.coId!).future);
      final details = co['details'] as List<dynamic>? ?? [];

      _titleCtrl.text = co['title'] ?? '';
      _descCtrl.text = co['description'] ?? '';
      _schedDays = (co['schedule_days_change'] as num?)?.toInt() ?? 0;
      _schedDaysCtrl.text = _schedDays == 0 ? '' : _schedDays.toString();
      _coType = co['co_type'] ?? 'scope_change';
      _originalStatus = co['status']?.toString();
      _lines.clear();
      for (final d in details) {
        _lines.add(Map<String, dynamic>.from(d as Map));
      }

      // Load resource plans for each detail
      _resourcePlans.clear();
      for (final d in details) {
        final detailId = d['id'] as String?;
        if (detailId != null) {
          final plans = await svc.getResourcePlans(detailId);
          if (plans.isNotEmpty) {
            final key = BaselineImpactSection.planKey(d);
            _resourcePlans[key] = plans;
          }
        }
      }

      // Recalculate unit_price from loaded plans
      for (final line in _lines) {
        final key = BaselineImpactSection.planKey(line);
        final plans = _resourcePlans[key];
        if (plans != null && plans.isNotEmpty) {
          final qty = (line['quantity_change'] as num?)?.toDouble() ?? 1;
          if (qty > 0) {
            final meta = line['estimation_metadata'] as Map<String, dynamic>? ?? {};
            line['unit_price'] = _computeSalePrice(
              plans, qty,
              overheadPercentage: (meta['overhead_percentage'] as num?)?.toDouble(),
              profitPercentage: (meta['profit_percentage'] as num?)?.toDouble(),
            );
          }
        }
      }

      // Load disruption records if type is disruption
      if (_coType == 'disruption') {
        final disruptions = await svc.getDisruptionRecords(widget.coId!);
        if (disruptions.isNotEmpty) {
          final first = disruptions.first;
          final reasonCode = first['disruption_type'] as String?;
          if (reasonCode != null) {
            final reasons = await ref.read(disruptionReasonListProvider.future);
            final match = reasons.firstWhere(
              (r) => r['code'] == reasonCode,
              orElse: () => <String, dynamic>{},
            );
            _disruptionReasonId = match['id'] as String?;
          }
          _disruptionStart = first['start_date'] != null
              ? DateTime.tryParse(first['start_date'].toString())
              : null;
          _disruptionEnd = first['end_date'] != null
              ? DateTime.tryParse(first['end_date'].toString())
              : null;
        }

        final existingServices =
            await svc.getDisruptionServices(widget.coId!);
        _disruptionServices.addAll(existingServices.map((s) {
          if (_delayDays == 0) {
            _delayDays = (s['delay_days'] as num?)?.toInt() ?? 0;
          }
          return {
            'project_task_id': s['project_task_id'],
            'affectation_type': s['affectation_type'] ?? 'total_stop',
            'notes': s['notes'],
            'task_name': s['project_tasks']?['name'] ?? 'Unknown',
          };
        }));
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingData = false);
  }

  Future<void> _addExistingService() async {
    final services = await ref.read(
      quoteServiceListProvider(widget.projectId).future,
    );
    if (!mounted) return;

    final selected = await showSafeDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (ctx) => SimpleDialog(
        title: Text(
          'Select Service',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
        children: services
            .map(
              (s) => SimpleDialogOption(
                onPressed: () => Navigator.of(ctx).pop(s),
                child: ListTile(
                  dense: true,
                  title: Text(
                    s['name'] ?? '',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${s['unit_of_measure'] ?? ''}',
                    style: GoogleFonts.manrope(fontSize: 11),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );

    if (selected != null && mounted) {
      final directCost = (selected['direct_cost'] as num?)?.toDouble() ?? 0;
      final svcQty = (selected['quantity'] as num?)?.toDouble() ?? 1;
      final unitPrice = svcQty > 0 ? (directCost / svcQty).toDouble() : 0.0;
      final svcId = selected['id'] as String?;
      final isProjectService = selected['is_project_service'] == true;

      // Fetch estimation for auto-calculating schedule days
      double totalWorkingDays = 0;
      if (svcId != null && _coType == 'scope_change' && !isProjectService) {
        try {
          final estData = await Supabase.instance.client
              .from('quote_service_estimations')
              .select('total_working_days')
              .eq('quote_service_id', svcId)
              .maybeSingle();
          totalWorkingDays = (estData?['total_working_days'] as num?)?.toDouble() ?? 0;
        } catch (_) {}
      }

      final result = await _showLineEditor(
        serviceName: selected['name'] ?? '',
        unitOfMeasure: selected['unit_of_measure'] ?? 'und',
        quoteServiceId: isProjectService ? null : svcId,
        projectServiceId: isProjectService ? svcId : null,
        lineType: 'existing_service',
        initialUnitPrice: unitPrice,
      );

      // Auto-calculate schedule days for scope_change
      if (result != null && _coType == 'scope_change' && totalWorkingDays > 0 && svcQty > 0) {
        final qtyChange = (result['quantity_change'] as num?)?.toDouble() ?? 0;
        if (qtyChange > 0) {
          final factor = qtyChange / svcQty;
          final additionalDays = (totalWorkingDays * factor).ceil();
          _schedDays += additionalDays;
          _schedDaysCtrl.text = _schedDays == 0 ? '' : _schedDays.toString();
          if (mounted) setState(() {});
        }
      }
    }
  }

  Future<void> _addNewService() async {
    final catalog = await ref.read(servicesCatalogProvider.future);
    if (!mounted) return;

    final selected = await showSafeDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (ctx) => SimpleDialog(
        title: Text(
          'Select from Catalog',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
        children: catalog
            .map(
              (s) => SimpleDialogOption(
                onPressed: () => Navigator.of(ctx).pop(s),
                child: ListTile(
                  dense: true,
                  title: Text(
                    s['description'] ?? '',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    s['unit'] ?? '',
                    style: GoogleFonts.manrope(fontSize: 11),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );

    if (selected != null && mounted) {
      // Pre-load catalogs for enrichment
      final catSvc = ref.read(catalogsServiceProvider);
      final catResults = await Future.wait([
        catSvc.getMachinery(),
        catSvc.getLaborRoles(),
        catSvc.getMaterials(),
        catSvc.getLogisticsEquipment(),
      ]);

      final result = await showSafeDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => ServiceEstimationDialog(
          service: {
            'id': null,
            'catalog_service_id': selected['id'] as String?,
            'name': selected['description'] ?? '',
            'quantity': 1,
            'unit': selected['unit'] ?? 'und',
            'estimationData': null,
          },
        ),
      );

      if (result != null && result is Map && result['applied'] == true && mounted) {
        final line = _estimationResultToLine(result, selected);
        final plans = _estimationResultToResourcePlans(
          result,
          catalogMachinery: catResults[0],
          catalogLaborRoles: catResults[1],
          catalogMaterials: catResults[2],
        );
        final key = BaselineImpactSection.planKey(line);
        // Compute months using same formula as quote module (calendarDays / 30.44)
        final startDate = result['start_date'] as DateTime?;
        final endDate = result['end_date'] as DateTime?;
        final months = (startDate != null && endDate != null)
            ? double.parse(
                ((endDate.difference(startDate).inDays + 1) / 30.44)
                    .toStringAsFixed(1))
            : 1.0;

        // Auto-calculate schedule days from estimation for new service
        if (_coType == 'scope_change' && startDate != null && endDate != null) {
          int workingDays = 0;
          var current = startDate;
          while (!current.isAfter(endDate)) {
            if (current.weekday != DateTime.sunday) workingDays++;
            current = current.add(const Duration(days: 1));
          }
          _schedDays += workingDays;
          _schedDaysCtrl.text = _schedDays == 0 ? '' : _schedDays.toString();
        }

        final enrichedPlans = _enrichPlansWithMonths(plans, months);
        final qty = (line['quantity_change'] as num?)?.toDouble() ?? 1;
        if (enrichedPlans.isNotEmpty && qty > 0) {
          final meta = line['estimation_metadata'] as Map<String, dynamic>? ?? {};
          line['unit_price'] = _computeSalePrice(
            enrichedPlans, qty,
            overheadPercentage: (meta['overhead_percentage'] as num?)?.toDouble(),
            profitPercentage: (meta['profit_percentage'] as num?)?.toDouble(),
          );
        }
        setState(() {
          _lines.add(line);
          if (enrichedPlans.isNotEmpty) {
            _resourcePlans[key] = enrichedPlans;
          }
        });
      }
    }
  }

  double _computePlansTotal(List<Map<String, dynamic>> plans) {
    var total = 0.0;
    for (final p in plans) {
      switch (p['resource_type'] as String? ?? '') {
        case 'machinery':
          final qty = (p['quantity'] as num?)?.toDouble() ?? 1;
          final rent = (p['monthly_rent_cost'] as num?)?.toDouble() ?? 0;
          final monthsUse = (p['months_to_use'] as num?)?.toDouble() ?? 1;
          final gph = (p['fuel_gph'] as num?)?.toDouble() ?? 0;
          final fuelP = (p['fuel_price'] as num?)?.toDouble() ?? 0;
          final delivery = (p['delivery_cost'] as num?)?.toDouble() ?? 0;
          total += rent * monthsUse * qty + gph * 220 * monthsUse * fuelP * qty + delivery;
        case 'labor':
          final emp = (p['employees_quantity'] as num?)?.toDouble() ?? 1;
          final rate = (p['hourly_rate'] as num?)?.toDouble() ?? 0;
          final perDiem = (p['per_diem'] as num?)?.toDouble() ?? 0;
          final monthsWork = (p['months_to_work'] as num?)?.toDouble() ?? 1;
          total += rate * 220 * monthsWork * emp + perDiem * 30 * monthsWork * emp;
        case 'material':
          final qty = (p['quantity'] as num?)?.toDouble() ?? 0;
          final cost = (p['unit_cost'] as num?)?.toDouble() ?? 0;
          total += qty * cost;
        case 'instrument':
          final qty = (p['quantity'] as num?)?.toDouble() ?? 1;
          final days = (p['days'] as num?)?.toDouble() ?? 1;
          final price = (p['unit_price'] as num?)?.toDouble() ?? 0;
          total += qty * days * price;
      }
    }
    return total;
  }

  double _computeSalePrice(
    List<Map<String, dynamic>> plans,
    double qty, {
    double? overheadPercentage,
    double? profitPercentage,
  }) {
    final subtotal = _computePlansTotal(plans);
    final oh = overheadPercentage ?? 10;
    final profit = profitPercentage ?? 5;
    final ohAmount = subtotal * (oh / 100);
    final profitAmount = (subtotal + ohAmount) * (profit / 100);
    final totalSale = subtotal + ohAmount + profitAmount;
    return qty > 0 ? totalSale / qty : 0.0;
  }

  List<Map<String, dynamic>> _enrichPlansWithMonths(
    List<Map<String, dynamic>> plans,
    double months,
  ) {
    return plans.map((p) {
      final type = p['resource_type'] as String? ?? '';
      if (type == 'machinery' && (p['months_to_use'] == null || (p['months_to_use'] as num?) == 0)) {
        p['months_to_use'] = months;
      }
      if (type == 'labor' && (p['months_to_work'] == null || (p['months_to_work'] as num?) == 0)) {
        p['months_to_work'] = months;
      }
      return p;
    }).toList();
  }

  Map<String, dynamic> _estimationResultToLine(
    Map<String, dynamic> result,
    Map<String, dynamic> catalogItem,
  ) {
    final qty = (result['calculated_loose'] as num?)?.toDouble() ??
        (result['total_cy_loose'] as num?)?.toDouble() ?? 1;
    final workingDays =
        (result['working_days'] as num?)?.toInt() ?? 0;

    final meta = <String, dynamic>{
      'working_days': workingDays,
      'end_date': result['end_date']?.toString(),
      'start_date': result['start_date']?.toString(),
      'total_cy_loose': (result['total_cy_loose'] as num?)?.toDouble(),
      'calculated_loose': (result['calculated_loose'] as num?)?.toDouble(),
      'swell_factor': (result['swell_factor'] as num?)?.toDouble(),
      'topsoil_volume': result['topsoil_volume'],
      'compacted_volume': result['compacted_volume'],
      'thickness_inches': result['thickness_inches'],
      'gravel_thickness_inches': result['gravel_thickness_inches'],
      'trench_width_inches': result['trench_width_inches'],
      'trench_depth_inches': result['trench_depth_inches'],
    };
    final resList = result['resources'] as List?;
    if (resList != null && resList.isNotEmpty) {
      meta['resources'] = resList;
    }
    final matList = result['materials'] as List?;
    if (matList != null && matList.isNotEmpty) {
      meta['materials'] = matList;
    }

    return {
      'service_name': catalogItem['description'] ?? '',
      'unit_of_measure': catalogItem['unit'] ?? 'und',
      'catalog_service_id': catalogItem['id'] as String?,
      'line_type': 'new_service',
      'quantity_change': qty,
      'unit_price': 0,
      'estimation_metadata': meta,
    };
  }

  List<Map<String, dynamic>> _estimationResultToResourcePlans(
    Map<String, dynamic> result, {
    List<Map<String, dynamic>> catalogMachinery = const [],
    List<Map<String, dynamic>> catalogLaborRoles = const [],
    List<Map<String, dynamic>> catalogMaterials = const [],
  }) {
    final plans = <Map<String, dynamic>>[];
    final resources = (result['resources'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final materials = (result['materials'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    // Build lookup maps
    final machMap = {
      for (final m in catalogMachinery)
        if (m['id'] != null) m['id'] as String: m
    };
    final laborMap = {
      for (final l in catalogLaborRoles)
        if (l['id'] != null) l['id'] as String: l
    };
    final matMap = {
      for (final m in catalogMaterials)
        if (m['id'] != null) m['id'] as String: m
    };

    // Build primary→name map for parent references
    final primaryNames = <String, String>{};
    for (final r in resources) {
      if (r['is_primary_mover'] == true) {
        primaryNames[r['id'] as String] = r['machine_name'] as String? ?? '';
      }
    }

    for (final r in resources) {
      final machId = r['machine_id'] as String?;
      final catalogMach = machId != null ? machMap[machId] : null;
      final isPrimary = r['is_primary_mover'] == true;
      final localId = r['id'] as String;
      final parentId = r['parent_resource_id'] as String?;

      plans.add({
        'resource_type': 'machinery',
        'resource_name': r['machine_name'] as String? ?? 'Machinery',
        'quantity': (r['quantity'] as num?)?.toDouble() ?? 1,
        'is_principal': isPrimary,
        'parent_resource_name':
            parentId != null ? (primaryNames[parentId] ?? '') : null,
        'catalog_id': machId,
        'monthly_rent_cost':
            catalogMach?['monthly_rent_cost']?.toDouble() ??
                (r['monthly_rent_cost'] as num?)?.toDouble() ??
                0,
        'delivery_cost': null,
        'fuel_gph': catalogMach?['fuel_gallons']?.toDouble() ??
            (r['fuel_gallons'] as num?)?.toDouble() ??
            0,
        'fuel_price': catalogMach?['gallon_cost']?.toDouble() ??
            (r['gallon_cost'] as num?)?.toDouble() ??
            0,
        'months_to_use': null,
        'trips_per_day': (r['trips_per_day'] as num?)?.toDouble(),
        'capacity_per_trip': (r['capacity_per_trip'] as num?)?.toDouble(),
        'performance_per_day':
            (r['performance_per_day'] as num?)?.toDouble(),
        'calculation_metadata': {
          'machinery_type': r['machinery_type'],
        },
      });

      // Operator labor for this machine
      final operatorRoleId = r['operator_role_id'] as String? ??
          _findDefaultOperatorRole(catalogLaborRoles);
      if (operatorRoleId != null) {
        final catalogRole = laborMap[operatorRoleId];
        plans.add({
          'resource_type': 'labor',
          'resource_name':
              catalogRole?['description'] as String? ??
                  'Operator - ${r['machine_name'] ?? 'Machinery'}',
          'quantity': (r['quantity'] as num?)?.toDouble() ?? 1,
          'catalog_id': operatorRoleId,
          'hourly_rate': catalogRole?['hourly_rate']?.toDouble() ?? 0,
          'per_diem': null,
          'employees_quantity': (r['quantity'] as num?)?.toDouble() ?? 1,
          'months_to_work': null,
          'calculation_metadata': {
            'source_resource_id': localId,
            'is_operator': true,
          },
        });
      }
    }

    for (final m in materials) {
      final matId = m['material_id'] as String?;
      final catalogMat = matId != null ? matMap[matId] : null;
      plans.add({
        'resource_type': 'material',
        'resource_name': m['material_name'] as String? ?? 'Material',
        'quantity': (m['quantity'] as num?)?.toDouble() ?? 0,
        'unit': m['unit'] as String? ?? 'und',
        'unit_cost': catalogMat?['unit_price']?.toDouble() ??
            (m['unit_price'] as num?)?.toDouble() ??
            0,
        'catalog_id': matId,
        'calculation_metadata': {
          'layer_type': m['layer_type'],
          'notes': m['notes'],
        },
      });
    }

    return plans;
  }

  String? _findDefaultOperatorRole(List<Map<String, dynamic>> roles) {
    for (final role in roles) {
      final desc = (role['description'] as String?)?.toLowerCase() ?? '';
      if (desc.contains('operator')) return role['id'] as String?;
    }
    return null;
  }

  Future<void> _editLine(Map<String, dynamic> line) async {
    final lineType = line['line_type'] as String? ?? '';
    if (lineType == 'new_service') {
      final catSvc = ref.read(catalogsServiceProvider);
      final catResults = await Future.wait([
        catSvc.getMachinery(),
        catSvc.getLaborRoles(),
        catSvc.getMaterials(),
      ]);

      final result = await showSafeDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => ServiceEstimationDialog(
          service: {
            'id': null,
            'catalog_service_id': line['catalog_service_id'] as String?,
            'name': line['service_name'] as String? ?? '',
            'quantity': (line['quantity_change'] as num?)?.toDouble() ?? 1,
            'unit': line['unit_of_measure'] as String? ?? 'und',
            'estimationData': line['estimation_metadata'],
          },
        ),
      );

      if (result != null && result is Map && result['applied'] == true && mounted) {
        final updatedLine = _estimationResultToLine(result, {
          'description': line['service_name'],
          'unit': line['unit_of_measure'],
          'id': line['catalog_service_id'],
        });
        final plans = _estimationResultToResourcePlans(
          result,
          catalogMachinery: catResults[0],
          catalogLaborRoles: catResults[1],
          catalogMaterials: catResults[2],
        );
        final startDate = result['start_date'] as DateTime?;
        final endDate = result['end_date'] as DateTime?;
        final months = (startDate != null && endDate != null)
            ? double.parse(
                ((endDate.difference(startDate).inDays + 1) / 30.44)
                    .toStringAsFixed(1))
            : 1.0;
        final enrichedPlans = _enrichPlansWithMonths(plans, months);
        final qty = (updatedLine['quantity_change'] as num?)?.toDouble() ?? 1;
        if (enrichedPlans.isNotEmpty && qty > 0) {
          final meta = updatedLine['estimation_metadata'] as Map<String, dynamic>? ?? {};
          updatedLine['unit_price'] = _computeSalePrice(
            enrichedPlans, qty,
            overheadPercentage: (meta['overhead_percentage'] as num?)?.toDouble(),
            profitPercentage: (meta['profit_percentage'] as num?)?.toDouble(),
          );
        }
        final key = BaselineImpactSection.planKey(updatedLine);
        setState(() {
          final idx = _lines.indexOf(line);
          if (idx >= 0) _lines[idx] = updatedLine;
          if (enrichedPlans.isNotEmpty) {
            _resourcePlans[key] = enrichedPlans;
          } else {
            _resourcePlans.remove(key);
          }
        });
      }
      return;
    }
    _showLineEditor(
      serviceName: line['service_name'] as String? ?? '',
      unitOfMeasure: line['unit_of_measure'] as String? ?? 'und',
      quoteServiceId: line['quote_service_id'] as String?,
      projectServiceId: line['project_service_id'] as String?,
      catalogServiceId: line['catalog_service_id'] as String?,
      lineType: lineType,
      existing: line,
    );
  }

  Future<Map<String, dynamic>?> _showLineEditor({
    required String serviceName,
    required String unitOfMeasure,
    String? quoteServiceId,
    String? projectServiceId,
    String? catalogServiceId,
    String lineType = 'existing_service',
    Map<String, dynamic>? existing,
    double initialUnitPrice = 0,
  }) async {
    final qtyCtrl = TextEditingController(
      text: existing?['quantity_change']?.toString() ?? '',
    );
    final priceCtrl = TextEditingController(
      text: existing?['unit_price']?.toString() ??
          (initialUnitPrice > 0 ? initialUnitPrice.toString() : ''),
    );
    String type = existing?['line_type'] ?? lineType;

    final result = await showSafeDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          serviceName,
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(
                    value: 'existing_service',
                    child: Text('Modify Existing Service'),
                  ),
                  DropdownMenuItem(
                    value: 'deduction',
                    child: Text('Deduction'),
                  ),
                ],
                onChanged: (v) => type = v ?? 'existing_service',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Quantity Change (+/-)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'Unit Price (\$)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(qtyCtrl.text) ?? 0;
              final price = double.tryParse(priceCtrl.text) ?? 0;
              Navigator.of(ctx).pop({
                'service_name': serviceName,
                'unit_of_measure': unitOfMeasure,
                'quote_service_id': quoteServiceId,
                'project_service_id': projectServiceId,
                'catalog_service_id': catalogServiceId,
                'line_type': type,
                'quantity_change': qty,
                'unit_price': price,
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (existing != null) {
          final idx = _lines.indexOf(existing);
          if (idx >= 0) _lines[idx] = result;
        } else {
          _lines.add(result);
        }
      });
    }
    return result;
  }

  Future<void> _loadTasks() async {
    final svc = ref.read(billingServiceProvider);
    final tasks = await svc.getProjectTasksForDisruption(widget.projectId);
    if (mounted) setState(() => _availableTasks = tasks);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Title is required', style: GoogleFonts.manrope()),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    if (_coType == 'disruption') {
      if (_disruptionReasonId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Disruption reason is required',
                style: GoogleFonts.manrope(),
              ),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
        return;
      }
      if (_disruptionStart == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Start date is required',
                style: GoogleFonts.manrope(),
              ),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final controller = ref.read(changeOrderControllerProvider.notifier);
      final startDateStr = _disruptionStart?.toIso8601String().split('T')[0];
      final endDateStr = _disruptionEnd?.toIso8601String().split('T')[0];

      String? disruptionType;
      if (_coType == 'disruption') {
        final reasons = await ref.read(disruptionReasonListProvider.future);
        final reason = reasons.firstWhere(
          (r) => r['id'] == _disruptionReasonId,
        );
        disruptionType = reason['code'] as String?;
      }

        if (_isEditing) {
        await controller.updateChangeOrder(widget.coId!, {
          'title': _titleCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'schedule_days_change': _schedDays,
          'co_type': _coType,
        });

        if (_originalStatus == 'rejected') {
          await controller.submitChangeOrder(widget.coId!);
        }

        if (_coType == 'scope_change' && _lines.isNotEmpty) {
          final savedDetails =
              await controller.saveDetails(widget.coId!, _lines);
          await _saveResourcePlans(controller, savedDetails);
        }

        if (_coType == 'disruption') {
          await controller.saveDisruptionRecords(widget.coId!, [
            {
              'disruption_type': disruptionType,
              'start_date': startDateStr,
              'end_date': endDateStr,
            },
          ]);

          await controller.saveDisruptionServices(
            widget.coId!,
            _disruptionServices.map((s) => {
              ...s,
              'delay_days': _delayDays,
            }).toList(),
          );

          if (_lines.isNotEmpty) {
            await controller.saveDetails(widget.coId!, _lines);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Change Order updated',
                style: GoogleFonts.manrope(color: Colors.white),
              ),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
          context.go(
            '/projects/${widget.projectId}/change-orders/${widget.coId}',
          );
        }
      } else {
        final co = await controller.createChangeOrder({
          'project_id': widget.projectId,
          'title': _titleCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'co_type': _coType,
          'executed_date': DateTime.now().toIso8601String().split('T')[0],
          'original_contract_amount': 0,
          'schedule_days_change': _schedDays,
          'created_by': Supabase.instance.client.auth.currentUser?.id,
        });

        if (_coType == 'scope_change' && _lines.isNotEmpty) {
          final savedDetails =
              await controller.saveDetails(co['id'], _lines);
          await _saveResourcePlans(controller, savedDetails);
        }

        if (_coType == 'disruption') {
          await controller.saveDisruptionRecords(co['id'], [
            {
              'disruption_type': disruptionType,
              'start_date': startDateStr,
              'end_date': endDateStr,
            },
          ]);

          await controller.saveDisruptionServices(
            co['id'],
            _disruptionServices.map((s) => {
              ...s,
              'delay_days': _delayDays,
            }).toList(),
          );

          if (_lines.isNotEmpty) {
            await controller.saveDetails(co['id'], _lines);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Change Order created',
                style: GoogleFonts.manrope(color: Colors.white),
              ),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
          context.go('/projects/${widget.projectId}/change-orders/${co['id']}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.manrope()),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userName = currentUser?.userMetadata?['name'] ?? 'Admin';
    final userEmail = currentUser?.email ?? '';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1250;

    if (_loadingData) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      drawer: isMobile
          ? Sidebar(
              userName: userName,
              userEmail: userEmail,
              currentPath: '/projects/${widget.projectId}/change-orders',
              onLogout: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/signin');
              },
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            Sidebar(
              userName: userName,
              userEmail: userEmail,
              currentPath: '/projects/${widget.projectId}/change-orders',
              onLogout: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/signin');
              },
            ),
          Expanded(
            child: Column(
              children: [
                _buildTopHeader(userName, isMobile),
                Expanded(
                  child: _buildForm(isMobile),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(String userName, bool isMobile) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.slate200)),
      ),
      child: Row(
        children: [
          if (isMobile)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: AppTheme.slate700),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () =>
                  context.go('/projects/${widget.projectId}/change-orders'),
              child: const Icon(
                Icons.arrow_back,
                size: 18,
                color: AppTheme.slate500,
              ),
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 8),
            Text(
              _projectTitle.isNotEmpty ? _projectTitle : 'Change Orders',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.slate500,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.chevron_right,
                size: 16,
                color: AppTheme.slate400,
              ),
            ),
            Text(
              'Change Orders',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.slate500,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.chevron_right,
                size: 16,
                color: AppTheme.slate400,
              ),
            ),
            Text(
              _isEditing ? 'Edit' : 'New',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.slate900,
              ),
            ),
          ],
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _isCompleted || _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save, size: 18, color: Colors.white),
            label: Text(
              'Save',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isMobile) {
    return CompletedProjectBanner(
      projectId: widget.projectId,
      isCompletedCallback: (completed) {
        if (completed != _isCompleted) setState(() => _isCompleted = completed);
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 20 : 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Edit Change Order' : 'New Change Order',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.slate900,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title *'),
                style: GoogleFonts.manrope(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description of Change',
                ),
                maxLines: 4,
                style: GoogleFonts.manrope(),
              ),
              const SizedBox(height: 20),
              Text(
                'Type',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _coTypeButton('Scope Change', 'scope_change'),
                  const SizedBox(width: 12),
                  _coTypeButton('Disruption / Standby', 'disruption'),
                ],
              ),
              if (_coType == 'scope_change') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _schedDaysCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Schedule Days Change (+/-)',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _schedDays = int.tryParse(v) ?? 0,
                  style: GoogleFonts.manrope(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_coType == 'scope_change') ...[
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Line Items',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.slate900,
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _addExistingService,
                      icon: const Icon(Icons.edit, size: 16),
                      label: Text(
                        'Add Existing Service',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: BorderSide(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _addNewService,
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: Text(
                        'Add New Service',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: BorderSide(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_lines.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No line items yet. Add services to modify.',
                        style: GoogleFonts.manrope(color: AppTheme.slate500),
                      ),
                    ),
                  )
                else ...[
                  if (isMobile)
                    Column(
                      children: _lines
                          .asMap()
                          .entries
                          .map((e) => _lineCard(e.key, e.value))
                          .toList(),
                    )
                  else
                    _linesTable(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          BaselineImpactSection(
            lines: _lines,
            initialPlans: _resourcePlans,
            onPlansChanged: (plans) {
        setState(() {
                _resourcePlans
                  ..clear()
                  ..addAll(plans);
                for (final line in _lines) {
                  final key = BaselineImpactSection.planKey(line);
                  final linePlans = _resourcePlans[key];
                  if (linePlans != null && linePlans.isNotEmpty) {
                    final qty = (line['quantity_change'] as num?)?.toDouble() ?? 1;
                    if (qty > 0) {
                      final meta = line['estimation_metadata'] as Map<String, dynamic>? ?? {};
                      line['unit_price'] = _computeSalePrice(
                        linePlans, qty,
                        overheadPercentage: (meta['overhead_percentage'] as num?)?.toDouble(),
                        profitPercentage: (meta['profit_percentage'] as num?)?.toDouble(),
                      );
                    }
                  }
                }
              });
            },
            onReestimate: (index) {
              if (index >= 0 && index < _lines.length) {
                _editLine(_lines[index]);
              }
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total Adjustment: \$${_fmt.format(_totalAdjustment)}',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _totalAdjustment >= 0
                        ? AppTheme.primaryGreen
                        : AppTheme.errorRed,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_coType == 'disruption') ...[
          _buildAffectedServices(),
          const SizedBox(height: 24),
          StandbyFormSection(
            projectId: widget.projectId,
            selectedDisruptionReasonId: _disruptionReasonId,
            disruptionStart: _disruptionStart,
            disruptionEnd: _disruptionEnd,
            delayDays: _delayDays,
            onDelayDaysChanged: (v) => setState(() => _delayDays = v),
            lines: _lines,
            allowedQuoteServiceIds: _selectedQuoteServiceIds,
            allowedProjectServiceIds: _selectedProjectServiceIds,
            onDisruptionReasonChanged: (v) =>
                setState(() => _disruptionReasonId = v),
            onDisruptionStartChanged: (v) =>
                setState(() => _disruptionStart = v),
            onDisruptionEndChanged: (v) => setState(() => _disruptionEnd = v),
            onLinesChanged: (v) => setState(
              () => _lines
                ..clear()
                ..addAll(v),
            ),
          ),
        ],
      ],
      ),
    ),
  );
  }

  List<String>? get _selectedQuoteServiceIds {
    final ids = <String>{};
    for (final s in _disruptionServices) {
      final taskId = s['project_task_id'] as String?;
      if (taskId != null) {
        final task = _availableTasks.firstWhere(
          (t) => t['id'] == taskId,
          orElse: () => <String, dynamic>{},
        );
        final qsid = task['quote_service_id'] as String?;
        if (qsid != null) ids.add(qsid);
      } else {
        debugPrint('[_selectedQuoteServiceIds] taskId=$taskId NOT found in _availableTasks (${_availableTasks.length} tasks)');
      }
    }
    final result = ids.isEmpty ? null : ids.toList();
    debugPrint('[_selectedQuoteServiceIds] returning: $result from ${_disruptionServices.length} disruption services');
    return result;
  }

  List<String>? get _selectedProjectServiceIds {
    final ids = <String>{};
    for (final s in _disruptionServices) {
      final taskId = s['project_task_id'] as String?;
      if (taskId != null) {
        final task = _availableTasks.firstWhere(
          (t) => t['id'] == taskId,
          orElse: () => <String, dynamic>{},
        );
        final psid = task['project_service_id'] as String?;
        if (psid != null) ids.add(psid);
      } else {
        debugPrint('[_selectedProjectServiceIds] taskId=$taskId NOT found in _availableTasks');
      }
    }
    final result = ids.isEmpty ? null : ids.toList();
    debugPrint('[_selectedProjectServiceIds] returning: $result from ${_disruptionServices.length} disruption services');
    return result;
  }

  Widget _buildAffectedServices() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.build_circle, size: 20, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'Affected Services / Tasks',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.orange.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_disruptionServices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No services marked as affected by this disruption.',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.slate500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ..._disruptionServices.asMap().entries.map(
              (e) => _buildServiceChip(e.key, e.value),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showAddServiceDialog,
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                'Add Service / Task',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
                side: BorderSide(color: Colors.orange.withOpacity(0.3)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddServiceDialog() async {
    if (_availableTasks.isEmpty) {
      await _loadTasks();
      if (!mounted) return;
    }

    final usedIds = _disruptionServices
        .map((s) => s['project_task_id'] as String?)
        .toSet();
    final available = _availableTasks
        .where((t) => !usedIds.contains(t['id'] as String?))
        .toList();

    if (available.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'All available services have been added',
              style: GoogleFonts.manrope(),
            ),
          ),
        );
      }
      return;
    }

    final selected = await showSafeDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Select Service',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: available.map((t) {
              final name = t['name'] as String? ?? '';
              final status = t['status'] as String? ?? '';
              return ListTile(
                dense: true,
                title: Text(
                  name,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Status: $status',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppTheme.slate500,
                  ),
                ),
                onTap: () => Navigator.of(ctx).pop(t),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _disruptionServices.add({
          'project_task_id': selected['id'],
          'task_name': selected['name'] ?? '',
          'affectation_type': 'total_stop',
          'notes': null,
        });
      });
    }
  }

  Widget _buildServiceChip(int index, Map<String, dynamic> service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['task_name'] ?? '',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: service['affectation_type'] == 'total_stop'
                            ? Colors.red.withOpacity(0.1)
                            : service['affectation_type'] == 'partial'
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        service['affectation_type']
                            .toString()
                            .replaceAll('_', ' '),
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: service['affectation_type'] == 'total_stop'
                              ? Colors.red.shade700
                              : service['affectation_type'] == 'partial'
                                  ? Colors.orange.shade700
                                  : Colors.blue.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showChangeAffectationType(index),
                      child: Icon(
                        Icons.edit,
                        size: 14,
                        color: AppTheme.slate400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppTheme.errorRed),
            onPressed: () => setState(() => _disruptionServices.removeAt(index)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangeAffectationType(int index) async {
    final current = _disruptionServices[index]['affectation_type'] as String? ??
        'total_stop';
    final selected = await showSafeDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(
          'Affectation Type',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
              children: ['total_stop', 'partial'].map((type) {
          return SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(type),
            child: ListTile(
              dense: true,
              selected: type == current,
              title: Text(
                type.replaceAll('_', ' '),
                style: GoogleFonts.manrope(
                  fontWeight:
                      type == current ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _disruptionServices[index]['affectation_type'] = selected;
      });
    }
  }

  Future<void> _saveResourcePlans(
    ChangeOrderController controller,
    List<Map<String, dynamic>> savedDetails,
  ) async {
    for (final detail in savedDetails) {
      final key = BaselineImpactSection.planKey(detail);
      var plans = _resourcePlans[key];
      if (plans == null || plans.isEmpty) {
        final originalLine = _lines.firstWhere(
          (l) => BaselineImpactSection.planKey(l) == key,
          orElse: () => <String, dynamic>{},
        );
        final embedded = (originalLine['resource_plans'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>();
        if (embedded != null && embedded.isNotEmpty) {
          plans = embedded;
        }
      }
      if (plans != null && plans.isNotEmpty) {
        await controller.saveResourcePlans(detail['id'], plans);
      }
    }
  }

  Widget _coTypeButton(String label, String value) {
    final selected = _coType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _coType = value;
            _lines.clear();
            _resourcePlans.clear();
            _disruptionServices.clear();
          });
          if (value == 'disruption') _loadTasks();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppTheme.primaryGreen : AppTheme.slate200,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppTheme.slate700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _linesTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(
            label: Text(
              'Service',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          DataColumn(
            label: Text(
              'Type',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          DataColumn(
            label: Text(
              'Qty Change',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'Unit Price',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'Total',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            numeric: true,
          ),
          DataColumn(label: Text('', style: TextStyle(fontSize: 12))),
        ],
        rows: _lines.asMap().entries.map((e) {
          final i = e.key;
          final l = e.value;
          final qty = (l['quantity_change'] as num?)?.toDouble() ?? 0;
          final up = (l['unit_price'] as num?)?.toDouble() ?? 0;
          return DataRow(
            cells: [
              DataCell(
                Text(
                  l['service_name'] ?? '',
                  style: GoogleFonts.manrope(fontSize: 12),
                ),
              ),
              DataCell(
                Text(
                  l['line_type']?.toString().replaceAll('_', ' ') ?? '',
                  style: GoogleFonts.manrope(fontSize: 11),
                ),
              ),
              DataCell(
                Text(qty.toString(), style: GoogleFonts.manrope(fontSize: 12)),
              ),
              DataCell(
                Text(
                  '\$${_fmt.format(up)}',
                  style: GoogleFonts.manrope(fontSize: 12),
                ),
              ),
              DataCell(
                Text(
                  '\$${_fmt.format(qty * up)}',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 16,
                        color: AppTheme.slate400,
                      ),
                      onPressed: () => _editLine(l),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppTheme.errorRed,
                      ),
                      onPressed: () => setState(() => _lines.removeAt(i)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _lineCard(int i, Map<String, dynamic> l) {
    final qty = (l['quantity_change'] as num?)?.toDouble() ?? 0;
    final up = (l['unit_price'] as num?)?.toDouble() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _editLine(l),
                  child: Text(
                    l['service_name'] ?? '',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  size: 14,
                  color: AppTheme.slate400,
                ),
                onPressed: () => _editLine(l),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: AppTheme.errorRed,
                ),
                onPressed: () => setState(() => _lines.removeAt(i)),
              ),
            ],
          ),
          Text(
            '${l['line_type']?.toString().replaceAll('_', ' ') ?? ''} | Qty: $qty | \$${_fmt.format(up)} | Total: \$${_fmt.format(qty * up)}',
            style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate500),
          ),
        ],
      ),
    );
  }
}
