import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'schedule_calendar_view.dart';
import 'machinery_selection_dialog.dart';

class ServiceEstimationDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> service;
  const ServiceEstimationDialog({super.key, required this.service});

  @override
  ConsumerState<ServiceEstimationDialog> createState() =>
      _ServiceEstimationDialogState();
}

class _ServiceEstimationDialogState
    extends ConsumerState<ServiceEstimationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  // Form Controllers
  final _topsoilCtrl = TextEditingController(text: '0');
  final _compactedCtrl = TextEditingController(text: '0');
  final _swellFactorCtrl = TextEditingController(text: '0.15');
  final _thicknessCtrl = TextEditingController(text: '0');
  final _gravelThicknessCtrl = TextEditingController(text: '0');
  final _trenchWidthCtrl = TextEditingController(text: '0');
  final _trenchDepthCtrl = TextEditingController(text: '0');
  DateTime _startDate = DateTime.now();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAreaBased = false;
  bool _isLinearBased = false;
  bool _isAcresBased = false;
  String? _estimationId;

  List<Map<String, dynamic>> _machineryCatalog = [];

  /// Flat list of all resources (primaries + supports).
  /// Each resource has:
  ///   'id'                  → local UUID (temp, maps to DB id after save)
  ///   'is_primary_mover'    → bool
  ///   'parent_resource_id'  → local UUID of primary (null for primaries)
  ///   'machine_id', 'machine_name', 'photo_url'
  ///   'quantity', 'trips_per_day', 'capacity_per_trip'
  ///   'qtyCtrl', 'tripsCtrl', 'capCtrl', 'perDayCtrl' (TextEditingControllers)
  List<Map<String, dynamic>> _selectedResources = [];
  List<Map<String, dynamic>> _selectedMaterials = [];
  List<Map<String, dynamic>> _materialsCatalog = [];
  int _currentStep = 0; // 0: Planning, 1: Resources, 2: Materials

  Map<String, dynamic>? _calculationResult;

  final _nFmt = NumberFormat('#,###.##');
  String? _error;
  bool _showCalendar = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _topsoilCtrl.dispose();
    _compactedCtrl.dispose();
    _swellFactorCtrl.dispose();
    _thicknessCtrl.dispose();
    _gravelThicknessCtrl.dispose();
    _trenchWidthCtrl.dispose();
    _trenchDepthCtrl.dispose();
    for (final res in _selectedResources) {
      _disposeControllers(res);
    }
    for (final mat in _selectedMaterials) {
      if (mat['qtyCtrl'] is TextEditingController) (mat['qtyCtrl'] as TextEditingController).dispose();
      if (mat['priceCtrl'] is TextEditingController) (mat['priceCtrl'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _disposeControllers(Map<String, dynamic> res) {
    if (res['qtyCtrl'] is TextEditingController) (res['qtyCtrl'] as TextEditingController).dispose();
    if (res['tripsCtrl'] is TextEditingController) (res['tripsCtrl'] as TextEditingController).dispose();
    if (res['capCtrl'] is TextEditingController) (res['capCtrl'] as TextEditingController).dispose();
    if (res['perDayCtrl'] is TextEditingController) (res['perDayCtrl'] as TextEditingController).dispose();
    if (res['perfCtrl'] is TextEditingController) (res['perfCtrl'] as TextEditingController).dispose();
  }

  double _calculateBaseVal(Map<String, dynamic> mat) {
    if (_isLinearBased) {
      final lType = mat['layer_type'] ?? 'linear';
      if (lType == 'earth') return _calculationResult?['earthCY'] ?? 0.0;
      if (lType == 'gravel') return _calculationResult?['gravelCY'] ?? 0.0;
      return double.tryParse(_compactedCtrl.text) ?? 0.0; // The LF length
    } else if (_isAreaBased) {
      final lType = mat['layer_type'] ?? 'earth';
      if (lType == 'gravel') return _calculationResult?['gravelCY'] ?? 0.0;
      if (lType == 'total') return _calculationResult?['totalCYLoose'] ?? 0.0;
      return _calculationResult?['earthCY'] ?? (_calculationResult?['totalCYLoose'] ?? 0.0);
    } else if (_isAcresBased) {
      return double.tryParse(_compactedCtrl.text) ?? 0.0;
    }
    return _calculationResult?['totalCYLoose'] ?? 0.0;
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final catalogsSvc = ref.read(catalogsServiceProvider);
      final quotesSvc = ref.read(quotesServiceProvider);

      final catalog = await catalogsSvc.getMachinery();
      _machineryCatalog = catalog;
      
      final matCatalog = await catalogsSvc.getMaterials();
      _materialsCatalog = matCatalog;

      final serviceId = widget.service['id'];
      final persistentData = widget.service['estimationData'] as Map<String, dynamic>?;

      // Check unit
      final unitRaw = (widget.service['unit_of_measure'] ?? widget.service['unit'] ?? 'und').toString().toLowerCase().trim();
      debugPrint('ESTIMATION_DEBUG: Detected Unit: "$unitRaw"');
      _isAreaBased = unitRaw == 'ft2' || 
                     unitRaw == 'sqft' || 
                     unitRaw == 'sq.ft' || 
                     unitRaw == 'sf' ||
                     unitRaw.contains('pies cuadrado') || 
                     unitRaw.contains('pie cuadrado') ||
                     unitRaw.contains('pies2');

      _isLinearBased = unitRaw == 'lf' ||
                       unitRaw == 'ft' ||
                       unitRaw == 'linear ft' ||
                       unitRaw.contains('lineal');

      _isAcresBased = unitRaw == 'ac' ||
                      unitRaw == 'acre' ||
                      unitRaw == 'acres';

      if (persistentData != null) {
        _estimationId = persistentData['id']; // Preserve DB ID if it came from DB initially
        _topsoilCtrl.text = persistentData['topsoil_volume']?.toString() ?? '0';
        _compactedCtrl.text = persistentData['compacted_volume']?.toString() ?? '0';
        _swellFactorCtrl.text = persistentData['swell_factor']?.toString() ?? '0.15';
        _thicknessCtrl.text = persistentData['thickness_inches']?.toString() ?? '0';
        _gravelThicknessCtrl.text = persistentData['gravel_thickness_inches']?.toString() ?? '0';
        _trenchWidthCtrl.text = persistentData['trench_width_inches']?.toString() ?? '0';
        _trenchDepthCtrl.text = persistentData['trench_depth_inches']?.toString() ?? '0';
        
        final sd = persistentData['start_date'];
        if (sd is DateTime) {
          _startDate = sd;
        } else if (sd is String) {
          _startDate = DateTime.tryParse(sd) ?? DateTime.now();
        }

        final resList = persistentData['resources'] as List?;
        if (resList != null) {
          _selectedResources = resList.map((r) {
            final qty = (r['quantity'] as num?)?.toDouble() ?? 1.0;
            final trips = (r['trips_per_day'] as num?)?.toDouble() ?? 0.0;
            final cap = (r['capacity_per_trip'] as num?)?.toDouble() ?? 0.0;
            final perf = (r['performance_per_day'] as num?)?.toDouble() ?? 0.0;
            final isPrimary = r['is_primary_mover'] as bool? ?? true;
            return {
              ...Map<String, dynamic>.from(r),
              'id': r['id'] ?? _uuid.v4(),
              'is_primary_mover': isPrimary,
              'parent_resource_id': r['parent_resource_id'],
              'qtyCtrl': TextEditingController(text: qty.toString()),
              'tripsCtrl': TextEditingController(text: trips.toString()),
              'capCtrl': TextEditingController(text: cap.toString()),
              'perfCtrl': TextEditingController(text: perf.toString()),
              'perDayCtrl': TextEditingController(text: isPrimary ? (trips * cap).toStringAsFixed(0) : ''),
            };
          }).toList();
        }

        final matList = persistentData['materials'] as List?;
        if (matList != null) {
          _selectedMaterials = matList.map((m) {
            final qty = (m['quantity'] as num?)?.toDouble() ?? 0.0;
            return {
              ...Map<String, dynamic>.from(m),
              'material_id': m['material_id'],
              'material_name': m['material_name'] ?? 'Unknown',
              'unit': m['unit'] ?? 'und',
              'quantity': qty,
              'unit_price': (m['unit_price'] as num?)?.toDouble() ?? 0.0,
              'layer_type': m['layer_type'] ?? 'earth',
              'qtyCtrl': TextEditingController(text: qty.toString()),
              'priceCtrl': TextEditingController(text: ((m['unit_price'] as num?)?.toDouble() ?? 0.0).toString()),
            };
          }).toList();
        }
      } else if (serviceId != null) {
        // Load from DB
        final estimation = await ref.read(quotesServiceProvider).getEstimationForService(serviceId);
        if (estimation != null) {
          _estimationId = estimation['id'];
          _topsoilCtrl.text = estimation['topsoil_volume']?.toString() ?? '0';
          _compactedCtrl.text = estimation['compacted_volume']?.toString() ?? '0';
          _swellFactorCtrl.text = estimation['swell_factor']?.toString() ?? '0.15';
          _gravelThicknessCtrl.text = estimation['gravel_thickness_inches']?.toString() ?? '0';
          _thicknessCtrl.text = estimation['thickness_inches']?.toString() ?? '0';
          _trenchWidthCtrl.text = estimation['trench_width_inches']?.toString() ?? '0';
          _trenchDepthCtrl.text = estimation['trench_depth_inches']?.toString() ?? '0';
          _startDate = DateTime.parse(estimation['start_date']);

          final resources = await ref.read(quotesServiceProvider).getResourcesForEstimation(_estimationId!);

          _selectedResources = resources.map((r) {
            final qty = (r['quantity'] as num).toDouble();
            final trips = (r['trips_per_day'] as num).toDouble();
            final cap = (r['capacity_per_trip'] as num).toDouble();
            final perf = (r['performance_per_day'] as num?)?.toDouble() ?? 0.0;
            final isPrimary = r['is_primary_mover'] as bool? ?? true;
            return {
              'id': r['id'] as String,
              'is_primary_mover': isPrimary,
              'parent_resource_id': r['parent_resource_id'],
              'machine_id': r['machine_id'],
              'machine_name': r['machinery']?['description'] ?? 'Unknown',
              'photo_url': r['machinery']?['photo_url'],
              'machinery_type': r['machinery']?['machinery_type'] ?? 'hauling',
              'quantity': qty,
              'trips_per_day': trips,
              'capacity_per_trip': cap,
              'performance_per_day': perf,
              'qtyCtrl': TextEditingController(text: qty.toString()),
              'tripsCtrl': TextEditingController(text: trips.toString()),
              'capCtrl': TextEditingController(text: cap.toString()),
              'perfCtrl': TextEditingController(text: perf.toString()),
              'perDayCtrl': TextEditingController(text: isPrimary ? (trips * cap).toStringAsFixed(0) : ''),
            };
          }).toList();

          // Load Materials from DB
          final quoteMats = await ref.read(quotesServiceProvider).getMaterialsForService(serviceId);
          _selectedMaterials = quoteMats.map((m) {
             final qty = (m['quantity'] as num).toDouble();
             return {
                ...m,
                'id': m['id'],
                'material_id': m['material_id'],
                'material_name': m['materials']?['description'] ?? 'Unknown',
                'unit': m['materials']?['unit'] ?? 'und',
                'yield_factor': (m['materials']?['yield_factor'] as num?)?.toDouble() ?? 1.0,
                'quantity': qty,
                'unit_price': (m['unit_price'] as num).toDouble(),
                'layer_type': m['layer_type'] ?? 'earth',
                'qtyCtrl': TextEditingController(text: qty.toString()),
                'priceCtrl': TextEditingController(text: (m['unit_price'] as num).toString()),
             };
          }).toList();
        }
      } else if (widget.service['id'] != null) {
        // New estimation for existing DB service
        _compactedCtrl.text = widget.service['quantity']?.toString() ?? '0';
      } else {
        // Entirely new service in wizard
        _compactedCtrl.text = widget.service['quantity']?.toString() ?? '0';
      }

      _runCalculation();
    } catch (e) {
      debugPrint('Error loading estimation: $e');
    }
    setState(() => _isLoading = false);
  }

  // ── Add Primary Machine ──
  void _addPrimary(Map<String, dynamic> machine) {
    setState(() {
      final qty = 1.0;
      final trips = (machine['trips_per_day'] as num?)?.toDouble() ?? 60.0;
      final capacity = (machine['capacity_yards'] as num?)?.toDouble() ?? 30.0;
      _selectedResources.add({
        'id': _uuid.v4(),
        'is_primary_mover': true,
        'parent_resource_id': null,
        'machine_id': machine['id'],
        'machine_name': machine['description'],
        'photo_url': machine['photo_url'],
        'machinery_type': machine['machinery_type'] ?? 'hauling',
        'operator_role_id': machine['operator_role_id'],
        'quantity': qty,
        'trips_per_day': trips,
        'capacity_per_trip': capacity,
        'performance_per_day': 0.0, // Initial
        'qtyCtrl': TextEditingController(text: qty.toString()),
        'tripsCtrl': TextEditingController(text: trips.toString()),
        'capCtrl': TextEditingController(text: capacity.toString()),
        'perfCtrl': TextEditingController(text: '0'),
        'perDayCtrl': TextEditingController(text: (trips * capacity).toStringAsFixed(0)),
      });
      _runCalculation();
    });
  }

  // ── Add Support Machine ──
  void _addSupport(Map<String, dynamic> machine, String parentLocalId) {
    setState(() {
      _selectedResources.add({
        'id': _uuid.v4(),
        'is_primary_mover': false,
        'parent_resource_id': parentLocalId,
        'machine_id': machine['id'],
        'machine_name': machine['description'],
        'photo_url': machine['photo_url'],
        'machinery_type': machine['machinery_type'] ?? 'support',
        'operator_role_id': machine['operator_role_id'],
        'quantity': 1.0,
        'trips_per_day': 0.0,
        'capacity_per_trip': 0.0,
        'performance_per_day': 0.0,
        'qtyCtrl': TextEditingController(text: '1'),
        'tripsCtrl': TextEditingController(text: '0'),
        'capCtrl': TextEditingController(text: '0'),
        'perfCtrl': TextEditingController(text: '0'),
        'perDayCtrl': TextEditingController(text: ''),
      });
      // No recalculate — supports don't affect calculation
    });
  }

  void _removeResource(String localId) {
    setState(() {
      // Remove resource and any supports that belong to it
      final toRemove = _selectedResources
          .where((r) => r['id'] == localId || r['parent_resource_id'] == localId)
          .toList();
      for (final r in toRemove) {
        _disposeControllers(r);
      }
      _selectedResources.removeWhere((r) => r['id'] == localId || r['parent_resource_id'] == localId);
      _runCalculation();
    });
  }

  void _runCalculation() {
    if (_topsoilCtrl.text.isEmpty || _compactedCtrl.text.isEmpty) return;

    // Only primary movers contribute to the calculation
    final result = EstimationCalculator.calculate(
      topsoilVolume: double.tryParse(_topsoilCtrl.text) ?? 0,
      compactedVolume: double.tryParse(_compactedCtrl.text) ?? 0,
      swellFactor: double.tryParse(_swellFactorCtrl.text) ?? 0.15,
      startDate: _startDate,
      resources: _selectedResources
          .where((r) => r['is_primary_mover'] == true)
          .map((r) => {
                'quantity': r['quantity'],
                'trips_per_day': r['trips_per_day'],
                'capacity_per_trip': r['capacity_per_trip'],
                'performance_per_day': r['performance_per_day'],
                'machine_name': r['machine_name'],
                'machinery_type': r['machinery_type'],
              })
          .toList(),
      isAreaBased: _isAreaBased,
      isLinearBased: _isLinearBased,
      isAcresBased: _isAcresBased,
      totalArea: _isAreaBased ? (double.tryParse(_compactedCtrl.text) ?? 0) : 0,
      totalLength: _isLinearBased ? (double.tryParse(_compactedCtrl.text) ?? 0) : 0,
      totalAcres: _isAcresBased ? (double.tryParse(_compactedCtrl.text) ?? 0) : 0,
      thicknessInches: double.tryParse(_thicknessCtrl.text) ?? 0,
      gravelThicknessInches: double.tryParse(_gravelThicknessCtrl.text) ?? 0,
      trenchWidthInches: double.tryParse(_trenchWidthCtrl.text) ?? 0,
      trenchDepthInches: double.tryParse(_trenchDepthCtrl.text) ?? 0,
    );

    setState(() {
      _calculationResult = result;
    });
  }

  Future<void> _save() async {
    // Attempt validation
    bool isValid = _formKey.currentState?.validate() ?? true;

    if (!isValid) {
      if (mounted) {
        setState(() => _currentStep = 0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please correct the validation errors in the Planning phase'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
      return;
    }

    final topVal = double.tryParse(_topsoilCtrl.text) ?? 0;
    final compVal = double.tryParse(_compactedCtrl.text) ?? 0;
    final swellVal = double.tryParse(_swellFactorCtrl.text) ?? 0.15;
    final thickVal = double.tryParse(_thicknessCtrl.text) ?? 0;
    final gravelThickVal = double.tryParse(_gravelThicknessCtrl.text) ?? 0;

    // Build serializable resources (strip controllers)
    List<Map<String, dynamic>> serializableResources() {
      return _selectedResources.map((r) => {
        'id': r['id'],
        'is_primary_mover': r['is_primary_mover'],
        'parent_resource_id': r['parent_resource_id'],
        'machine_id': r['machine_id'],
        'machine_name': r['machine_name'],
        'photo_url': r['photo_url'],
        'machinery_type': r['machinery_type'],
        'operator_role_id': r['operator_role_id'],
        'quantity': r['quantity'],
        'trips_per_day': r['trips_per_day'],
        'capacity_per_trip': r['capacity_per_trip'],
        'performance_per_day': r['performance_per_day'],
      }).toList();
    }

    // Build serializable materials
    List<Map<String, dynamic>> serializableMaterials() {
      return _selectedMaterials.map((m) => {
        'material_id': m['material_id'],
        'material_name': m['material_name'],
        'quantity': m['quantity'],
        'unit_price': m['unit_price'],
        'unit': m['unit'],
        'notes': m['notes'],
        'layer_type': m['layer_type'] ?? 'earth',
      }).toList();
    }

    if (widget.service['id'] == null) {
      // Local application for unsaved wizard services
      if (mounted) {
        Navigator.pop(context, {
          'applied': true,
          'total_cy_loose': compVal,
          'calculated_loose': _calculationResult?['totalCYLoose'] ?? 0,
          'working_days': _calculationResult?['workingDays'] ?? 0,
          'workingDays': _calculationResult?['workingDays'] ?? 0,
          'total_working_days': _calculationResult?['workingDays'] ?? 0,
          'end_date': _calculationResult?['endDate'],
          'resources': serializableResources(),
          'materials': serializableMaterials(),
          'topsoil_volume': topVal,
          'compacted_volume': compVal,
          'swell_factor': swellVal,
          'thickness_inches': thickVal,
          'gravel_thickness_inches': gravelThickVal,
          'trench_width_inches': double.tryParse(_trenchWidthCtrl.text) ?? 0,
          'trench_depth_inches': double.tryParse(_trenchDepthCtrl.text) ?? 0,
          'start_date': _startDate,
        });
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      final estimationData = {
        if (_estimationId != null) 'id': _estimationId,
        'quote_service_id': widget.service['id'],
        'topsoil_volume': topVal,
        'compacted_volume': compVal,
        'swell_factor': swellVal,
        'thickness_inches': thickVal,
        'gravel_thickness_inches': gravelThickVal,
        'trench_width_inches': double.tryParse(_trenchWidthCtrl.text) ?? 0,
        'trench_depth_inches': double.tryParse(_trenchDepthCtrl.text) ?? 0,
        'total_cy_loose': _calculationResult?['totalCYLoose'] ?? 0,
        'start_date': _startDate.toIso8601String(),
        'end_date': (_calculationResult?['endDate'] as DateTime?)?.toIso8601String(),
        'total_working_days': _calculationResult?['workingDays'] ?? 0,
      };

      final savedEstimation = await ref.read(quotesServiceProvider).upsertEstimation(estimationData);
      await ref.read(quotesServiceProvider).saveResources(savedEstimation['id'], serializableResources());
      await ref.read(quotesServiceProvider).saveMaterials(widget.service['id'], serializableMaterials());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estimate saved successfully'), backgroundColor: AppTheme.primaryGreen),
        );
        Navigator.pop(context, {
          'applied': true,
          'total_cy_loose': compVal,
          'calculated_loose': _calculationResult?['totalCYLoose'] ?? 0,
          'working_days': _calculationResult?['workingDays'] ?? 0,
          'workingDays': _calculationResult?['workingDays'] ?? 0,
          'total_working_days': _calculationResult?['workingDays'] ?? 0,
          'end_date': _calculationResult?['endDate'],
          'resources': serializableResources(),
          'materials': serializableMaterials(),
          'topsoil_volume': topVal,
          'compacted_volume': compVal,
          'swell_factor': swellVal,
          'thickness_inches': thickVal,
          'gravel_thickness_inches': gravelThickVal,
          'trench_width_inches': double.tryParse(_trenchWidthCtrl.text) ?? 0,
          'trench_depth_inches': double.tryParse(_trenchDepthCtrl.text) ?? 0,
          'start_date': _startDate,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
    setState(() => _isSaving = false);
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        width: 1600,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 20)),
          ],
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
            : Column(
                children: [
                  _buildHeader(),
                  _buildStepIndicator(),
                  if (_currentStep > 0) _buildPlanningSummaryBanner(),
                  Expanded(
                    child: _showCalendar ? _buildCalendarView() : _buildStepContent(),
                  ),
                  _buildFooter(),
                ],
              ),
      ),
    );
  }

  Widget _buildPlanningSummaryBanner() {
    final cy = _calculationResult?['totalCYLoose'] ?? 0.0;
    final earthCY = _calculationResult?['earthCY'] ?? 0.0;
    final gravelCY = _calculationResult?['gravelCY'] ?? 0.0;
    final area = double.tryParse(_compactedCtrl.text) ?? 0.0;
    final thick = double.tryParse(_thicknessCtrl.text) ?? 0.0;
    final gravelThick = double.tryParse(_gravelThicknessCtrl.text) ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
      color: AppTheme.slate900,
      child: Row(
        children: [
          _summaryItem(Icons.water_drop_outlined, 'VOLUME', '${NumberFormat('#,###.##').format(cy)} CY'),
          _divider(),
          if (_isAcresBased) ...[
            _summaryItem(Icons.landscape, 'ACRES', '${NumberFormat('#,###.##').format(area)} AC'),
            _divider(),
          ] else if (_isLinearBased) ...[
            _summaryItem(Icons.straighten, 'LENGTH', '${NumberFormat('#,###').format(area)} LF'),
            _divider(),
            _summaryItem(Icons.unfold_more, 'WIDTH', '${_trenchWidthCtrl.text}"'),
            _divider(),
            _summaryItem(Icons.height, 'T. DEPTH', '${_thicknessCtrl.text}"'),
            _divider(),
            _summaryItem(Icons.layers_outlined, 'B. DEPTH', '${_trenchDepthCtrl.text}"'),
            _divider(),
          ] else if (_isAreaBased) ...[
            _summaryItem(Icons.square_foot, 'AREA', '${NumberFormat('#,###').format(area)} SQFT'),
            _divider(),
            _summaryItem(Icons.layers_outlined, 'SAND (ARENA)', '${thick.toStringAsFixed(1)}" → ${NumberFormat('#,###').format(earthCY)} CY'),
            _divider(),
            if (gravelThick > 0) ...[
              _summaryItem(Icons.grain, 'GRAVEL (GRAVA)', '${gravelThick.toStringAsFixed(1)}" → ${NumberFormat('#,###').format(gravelCY)} CY'),
              _divider(),
            ],
          ],
          _summaryItem(Icons.calendar_today, 'START', DateFormat('MMM dd, yyyy').format(_startDate)),
          const Spacer(),
          Text('CURRENT PLAN CONTEXT', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen.withOpacity(0.5), letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _summaryItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.primaryGreen),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: GoogleFonts.manrope(fontSize: 8, fontWeight: FontWeight.w800, color: AppTheme.slate400)),
            Text(value, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ],
    );
  }

  Widget _divider() => Container(height: 20, width: 1, margin: const EdgeInsets.symmetric(horizontal: 24), color: AppTheme.slate700);

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        border: Border(bottom: BorderSide(color: AppTheme.slate200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _stepIcon(0, 'Planning', Icons.tune),
          _stepLine(0),
          _stepIcon(1, 'Resources', Icons.construction),
          _stepLine(1),
          _stepIcon(2, 'Materials', Icons.inventory_2),
        ],
      ),
    );
  }

  Widget _stepIcon(int step, String label, IconData icon) {
    final isActive = _currentStep == step;
    final isDone = _currentStep > step;
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _currentStep = step),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryGreen : (isDone ? AppTheme.primaryGreen.withOpacity(0.2) : Colors.white),
              shape: BoxShape.circle,
              border: Border.all(color: isActive ? AppTheme.primaryGreen : AppTheme.slate200, width: 2),
            ),
            child: Icon(isDone ? Icons.check : icon, color: isActive ? const Color(0xFF0F172A) : (isDone ? AppTheme.primaryGreen : AppTheme.slate400), size: 20),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: isActive ? AppTheme.slate900 : AppTheme.slate400)),
      ],
    );
  }

  Widget _stepLine(int afterStep) {
    final isDone = _currentStep > afterStep;
    return Container(
      width: 100,
      height: 2,
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      color: isDone ? AppTheme.primaryGreen : AppTheme.slate200,
    );
  }

  Widget _buildStepContent() {
    return IndexedStack(
      index: _currentStep,
      children: [
        _buildPlanningStep(),
        _buildResourcesStep(),
        _buildMaterialsStep(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.calculate_outlined, color: AppTheme.primaryGreen, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Work Projection', style: GoogleFonts.manrope(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                Text('Field Planning & Timeline · ${widget.service['name']}', style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 13)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _viewToggleButton('Calculator', Icons.analytics_outlined, !_showCalendar, () => setState(() => _showCalendar = false)),
                _viewToggleButton('Calendar', Icons.calendar_month_outlined, _showCalendar, () => setState(() => _showCalendar = true)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _viewToggleButton(String label, IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: active ? AppTheme.primaryGreen : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(icon, size: 16, color: active ? const Color(0xFF0F172A) : Colors.white),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.manrope(color: active ? const Color(0xFF0F172A) : Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanningStep() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 30, 40, 30),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Factors
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Production Factors'),
                    const SizedBox(height: 20),
                    if (_isAcresBased) ...[
                      _textField(_compactedCtrl, 'Total Acres (AC)', Icons.landscape),
                    ] else if (_isLinearBased) ...[
                      _textField(_compactedCtrl, 'Total Length (LF)', Icons.straighten),
                      const SizedBox(height: 20),
                      _sectionHeader('Trench dimensions for bedding volume'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _textField(_trenchWidthCtrl, 'Trench Width (In)', Icons.straighten_outlined)),
                          const SizedBox(width: 16),
                          Expanded(child: _textField(_thicknessCtrl, 'Trench Depth (In)', Icons.height)),
                          const SizedBox(width: 16),
                          Expanded(child: _textField(_trenchDepthCtrl, 'Bedding Depth (In)', Icons.layers_outlined)),
                        ],
                      ),
                    ] else if (_isAreaBased) ...[
                      _textField(_compactedCtrl, 'Total Area (SQFT)', Icons.square_foot),
                      const SizedBox(height: 20),
                      _layerCard(
                        label: 'Layer 1: Sand (Arena)',
                        icon: Icons.layers_outlined,
                        color: const Color(0xFFD4AF37),
                        controller: _thicknessCtrl,
                        fieldLabel: 'Thickness (Inches)',
                        volumeKey: 'earthCY',
                      ),
                      const SizedBox(height: 12),
                      _layerCard(
                        label: 'Layer 2: Gravel (Grava)',
                        icon: Icons.grain,
                        color: const Color(0xFF607D8B),
                        controller: _gravelThicknessCtrl,
                        fieldLabel: 'Thickness (Inches)',
                        volumeKey: 'gravelCY',
                      ),
                    ] else ...[
                      _textField(_topsoilCtrl, 'Topsoil Volume (CY)', Icons.layers_outlined),
                      const SizedBox(height: 16),
                      _textField(_compactedCtrl, 'Compacted Volume (CY)', Icons.compress_outlined),
                    ],
                    const SizedBox(height: 16),
                    _textField(_swellFactorCtrl, 'Swell Factor %', Icons.expand_outlined),
                    const SizedBox(height: 24),
                    _sectionHeader('Schedule'),
                    const SizedBox(height: 16),
                    _datePicker(),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 40),
            // Right: Explanation/Guide
            Expanded(
              flex: 6,
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.slate200)),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('How it works', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
                      const SizedBox(height: 16),
                      _guideItem(Icons.info_outline, 'Calculations are based on the unit of measure of the service (${widget.service['unit']}).'),
                      if (_isAcresBased)
                         _guideItem(Icons.calculate_outlined, 'Total duration is calculated based on the production rate of Acres per Day (AC/D).')
                      else if (_isLinearBased)
                         _guideItem(Icons.calculate_outlined, 'We calculate the Required Bedding Volume (CY) based on trench cross-section.')
                      else if (_isAreaBased)
                         _guideItem(Icons.calculate_outlined, 'We convert Area to Volume automatically if thickness is provided.'),
                      _guideItem(Icons.calendar_month_outlined, 'The production timeline will be generated after assigning machinery in the next step.'),
                      const SizedBox(height: 48),
                      _buildCalculationSummaryMini(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourcesStep() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _inputLabel('Assigned Machinery & Support'),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ..._buildHierarchicalResources(),
                        const SizedBox(height: 8),
                        _addPrimaryButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 30),
          Expanded(
            flex: 5,
            child: _buildCalculationSummary(),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppTheme.slate900));
  }

  Widget _guideItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryGreen),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate600, height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildCalculationSummaryMini() {
    if (_calculationResult == null) return const SizedBox();
    final cy = _calculationResult?['totalCYLoose'] ?? 0.0;
    final earthCY = _calculationResult?['earthCY'] ?? 0.0;
    final gravelCY = _calculationResult?['gravelCY'] ?? 0.0;
    final totalLen = _isLinearBased ? (double.tryParse(_compactedCtrl.text) ?? 0.0) : 0.0;
    final totalAcres = _isAcresBased ? (double.tryParse(_compactedCtrl.text) ?? 0.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isAcresBased 
              ? 'TOTAL ACRES' 
              : (_isLinearBased ? 'TOTAL ESTIMATED LENGTH' : 'TOTAL CALCULATED VOLUME'), 
            style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate500)
          ),
          Text(
            _isAcresBased 
              ? '${NumberFormat('#,###.##').format(totalAcres)} AC' 
              : (_isLinearBased ? '${NumberFormat('#,###').format(totalLen)} LF' : '${NumberFormat('#,###.##').format(cy)} CY'), 
            style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen)
          ),
          if (_isLinearBased && cy > 0) ...[
             const SizedBox(height: 8),
             _miniVolumeBadge('Trench Fill', cy, AppTheme.primaryGreen),
          ] else if (_isAreaBased && (earthCY > 0 || gravelCY > 0)) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (earthCY > 0)
                  _miniVolumeBadge('Sand', earthCY, const Color(0xFFD4AF37)),
                if (earthCY > 0 && gravelCY > 0)
                  const SizedBox(width: 12),
                if (gravelCY > 0)
                  _miniVolumeBadge('Gravel', gravelCY, const Color(0xFF607D8B)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniVolumeBadge(String label, double cy, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text('$label: ${NumberFormat('#,###').format(cy)} CY', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _layerCard({
    required String label,
    required IconData icon,
    required Color color,
    required TextEditingController controller,
    required String fieldLabel,
    required String volumeKey,
  }) {
    final volume = _calculationResult?[volumeKey] ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
              const Spacer(),
              if (volume > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text('${NumberFormat('#,###').format(volume)} CY', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _textField(controller, fieldLabel, Icons.height),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  HIERARCHICAL RESOURCES
  // ══════════════════════════════════════════════════════════════

  List<Widget> _buildHierarchicalResources() {
    final List<Widget> items = [];
    final primaries = _selectedResources.where((r) => r['is_primary_mover'] == true).toList();

    for (final primary in primaries) {
      final localId = primary['id'] as String;
      final supports = _selectedResources.where((r) => r['parent_resource_id'] == localId).toList();

      items.add(_primaryResourceCard(primary, supports));
    }
    return items;
  }

  Widget _primaryResourceCard(Map<String, dynamic> res, List<Map<String, dynamic>> supports) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Primary machine row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _machineryHeader(res, isPrimary: true),
                const SizedBox(height: 10),
                _primaryInputs(res),
              ],
            ),
          ),

          // Support machines (indented)
          if (supports.isNotEmpty) ...[
            Divider(height: 1, color: AppTheme.slate200),
            ...supports.map((sup) => _supportResourceRow(sup)),
          ],

          // + Add Support button (Subtle)
          InkWell(
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
            onTap: () => _showMachinerySelector(forPrimaryId: res['id'] as String),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
                border: Border(top: BorderSide(color: AppTheme.slate200)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Text('Add support machine', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _supportResourceRow(Map<String, dynamic> res) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 10, 12, 10),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: AppTheme.slate200, width: 3)),
        color: AppTheme.slate50.withOpacity(0.5),
      ),
      child: Row(
        children: [
          // Support icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.slate200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.build_outlined, size: 14, color: AppTheme.slate600),
          ),
          const SizedBox(width: 10),
          // Photo
          _machineryPhoto(res, size: 36),
          const SizedBox(width: 10),
          // Name + badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(res['machine_name'] ?? '', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                _supportBadge(),
              ],
            ),
          ),
          // QTY input (only field for support)
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('QTY', style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.slate400)),
                const SizedBox(height: 2),
                SizedBox(
                  height: 28,
                  child: TextFormField(
                    controller: res['qtyCtrl'] as TextEditingController,
                    keyboardType: TextInputType.number,
                    onTap: () {
                      final ctrl = res['qtyCtrl'] as TextEditingController;
                      if (ctrl.text == '0') ctrl.text = ''; // Clear if zero for easier typing
                      ctrl.selection = TextSelection(baseOffset: 0, extentOffset: ctrl.text.length);
                    },
                    onChanged: (val) {
                      res['quantity'] = double.tryParse(val) ?? 1.0;
                    },
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppTheme.slate200)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Remove support
          IconButton(
            onPressed: () => _removeResource(res['id'] as String),
            icon: const Icon(Icons.remove_circle_outline, color: AppTheme.errorRed, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _machineryHeader(Map<String, dynamic> res, {required bool isPrimary}) {
    return Row(
      children: [
        // Primary icon: star
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.star_rounded, size: 16, color: AppTheme.primaryGreen),
        ),
        const SizedBox(width: 10),
        _machineryPhoto(res, size: 40),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(res['machine_name'] ?? '', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
              _primaryBadge(),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _removeResource(res['id'] as String),
          icon: const Icon(Icons.remove_circle_outline, color: AppTheme.errorRed, size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _machineryPhoto(Map<String, dynamic> res, {double size = 40}) {
    // Look up photo from catalog if not directly on res
    final photoUrl = (res['photo_url'] as String?) ??
        (_machineryCatalog.firstWhere(
              (m) => m['id'] == res['machine_id'],
              orElse: () => {},
            )['photo_url'] as String?);

    if (photoUrl == null || photoUrl.isEmpty) return SizedBox(width: size, height: size * 0.7);
    return Container(
      width: size,
      height: size * 0.7,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.white,
        border: Border.all(color: AppTheme.slate200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(photoUrl, fit: BoxFit.cover,
          errorBuilder: (c, e, s) => const Icon(Icons.settings, size: 14, color: AppTheme.slate400)),
    );
  }

  Widget _primaryInputs(Map<String, dynamic> res) {
    if (_isLinearBased || _isAcresBased) {
      final perfLabel = _isAcresBased ? 'PERFORMANCE (AC/D)' : (_isLinearBased ? 'PERFORMANCE (LF/D)' : 'PERFORMANCE (SQFT/D)');
      return Row(
        children: [
          _miniInput('QTY', (val) {
            res['quantity'] = double.tryParse(val) ?? 1.0;
            _runCalculation();
          }, res['qtyCtrl'] as TextEditingController),
          const SizedBox(width: 8),
          _miniInput(perfLabel, (val) {
            res['performance_per_day'] = double.tryParse(val) ?? 0.0;
            _runCalculation();
          }, res['perfCtrl'] as TextEditingController),
        ],
      );
    }
    return Row(
      children: [
        _miniInput('QTY', (val) {
          res['quantity'] = double.tryParse(val) ?? 1.0;
          _runCalculation();
        }, res['qtyCtrl'] as TextEditingController),
        const SizedBox(width: 8),
        _miniInput('TRIPS/D', (val) {
          final tripsVal = double.tryParse(val) ?? 60.0;
          res['trips_per_day'] = tripsVal;
          final capVal = double.tryParse((res['capCtrl'] as TextEditingController).text) ?? 0;
          (res['perDayCtrl'] as TextEditingController).text = (tripsVal * capVal).toStringAsFixed(0);
          _runCalculation();
        }, res['tripsCtrl'] as TextEditingController),
        const SizedBox(width: 8),
        _miniInput('CAP (CY)', (val) {
          final capVal = double.tryParse(val) ?? 30.0;
          res['capacity_per_trip'] = capVal;
          final tripsVal = double.tryParse((res['tripsCtrl'] as TextEditingController).text) ?? 0;
          (res['perDayCtrl'] as TextEditingController).text = (tripsVal * capVal).toStringAsFixed(0);
          _runCalculation();
        }, res['capCtrl'] as TextEditingController),
        const SizedBox(width: 8),
        _miniInput('CY/D (UNIT)', (val) {
          final totalVal = double.tryParse(val) ?? 0;
          final tripsVal = double.tryParse((res['tripsCtrl'] as TextEditingController).text) ?? 60.0;
          if (tripsVal > 0) {
            final newCap = totalVal / tripsVal;
            res['capacity_per_trip'] = newCap;
            (res['capCtrl'] as TextEditingController).text = newCap.toStringAsFixed(2);
          }
          _runCalculation();
        }, res['perDayCtrl'] as TextEditingController),
      ],
    );
  }

  Widget _primaryBadge() {
    return Container(
      margin: const EdgeInsets.only(top: 3),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_shipping_outlined, size: 9, color: AppTheme.primaryGreen),
          const SizedBox(width: 3),
          Text('PRIMARY', style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen)),
        ],
      ),
    );
  }

  Widget _supportBadge() {
    return Container(
      margin: const EdgeInsets.only(top: 3),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: AppTheme.slate200, borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.build_outlined, size: 9, color: AppTheme.slate600),
          const SizedBox(width: 3),
          Text('APOYO', style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.slate600)),
        ],
      ),
    );
  }

  Widget _addPrimaryButton() {
    return InkWell(
      onTap: () => _showMachinerySelector(forPrimaryId: null),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_circle, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text('ADD PRIMARY MACHINE', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens machinery selector.
  /// [forPrimaryId] == null → adding a primary; else adding support to that primary.
  Future<void> _showMachinerySelector({required String? forPrimaryId}) async {
    final result = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (context) => MachinerySelectionDialog(
        serviceId: widget.service['id']?.toString() ?? widget.service['catalog_service_id']?.toString() ?? '',
      ),
    );
    if (result == null || result.isEmpty) return;
    for (final m in result) {
      if (forPrimaryId == null) {
        _addPrimary(m);
      } else {
        _addSupport(m, forPrimaryId);
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  CALCULATION SUMMARY
  // ══════════════════════════════════════════════════════════════

  Widget _buildCalculationSummary() {
    if (_calculationResult == null) return Center(child: Text('Enter data to calculate', style: GoogleFonts.manrope(color: AppTheme.slate400)));

    final totalCY = (_calculationResult!['totalCYLoose'] as num).toDouble();
    final totalLinear = _isLinearBased ? (double.tryParse(_compactedCtrl.text) ?? 0.0) : 0.0;
    final totalAcres = _isAcresBased ? (double.tryParse(_compactedCtrl.text) ?? 0.0) : 0.0;
    final workingDays = _calculationResult!['workingDays'] as int;
    final endDate = _calculationResult!['endDate'] as DateTime;
    final calendarDays = endDate.difference(_startDate).inDays;
    final months = calendarDays / 30.44;

    Widget looseCard;
    if (_isAcresBased) {
      looseCard = _resultCard('Total Acres', totalAcres.toStringAsFixed(2), 'AC', Icons.landscape, AppTheme.primaryGreen);
    } else if (_isLinearBased) {
      looseCard = _resultCard('Total Length', '${totalLinear.toStringAsFixed(0)} LF', 'Service length', Icons.straighten, AppTheme.primaryGreen);
    } else {
      looseCard = _resultCard('Total Loose', totalCY.toStringAsFixed(0), _isAreaBased ? 'Generated CY (Loose)' : 'CY with swell', Icons.dashboard_customize_outlined, AppTheme.primaryGreen);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inputLabel('Calculation Results'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: looseCard),
              const SizedBox(width: 10),
              Expanded(child: _resultCard('Completion', DateFormat('MMM dd').format(endDate), 'Estimated end', Icons.event_available_outlined, Colors.blue)),
            ],
          ),
          const SizedBox(height: 10),
          _resultCardExtended('Project Duration', '$workingDays Working Days', 'Calendar: $calendarDays d | Months: ${months.toStringAsFixed(1)}', Icons.timer_outlined, Colors.orange),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.1)),
            ),
            child: Text('Sat: 50% production | Sun/Hol: Non-working', textAlign: TextAlign.center, style: GoogleFonts.manrope(fontSize: 10, color: AppTheme.slate700, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(String title, String value, String sub, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.slate200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Icon(icon, color: color, size: 16)),
            const Spacer(),
            Text(title, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate500)),
          ]),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
          const SizedBox(height: 2),
          Text(sub, style: GoogleFonts.manrope(fontSize: 10, color: AppTheme.slate400)),
        ],
      ),
    );
  }

  Widget _resultCardExtended(String title, String value, String subContent, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.slate200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Icon(icon, color: color, size: 16)),
            const Spacer(),
            Text(title, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate500)),
          ]),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
          const SizedBox(height: 6),
          Text(subContent, style: GoogleFonts.manrope(fontSize: 10, color: AppTheme.slate500, height: 1.2, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  CALENDAR VIEW
  // ══════════════════════════════════════════════════════════════

  Widget _buildCalendarView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ScheduleCalendarView(
        dailySchedule: List<Map<String, dynamic>>.from(_calculationResult?['dailySchedule'] ?? []),
        // Only pass primary movers to the calendar
        resources: _selectedResources.where((r) => r['is_primary_mover'] == true).toList(),
        unit: _isAcresBased ? 'AC' : (_isLinearBased ? 'LF' : (_isAreaBased ? 'SQFT' : 'CY')),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  MATERIALS STEP
  // ══════════════════════════════════════════════════════════════

  Widget _buildMaterialsStep() {
    final calculatedCY = _calculationResult?['totalCYLoose'] ?? 0.0;

    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionHeader('Project Materials & Supplies'),
              ElevatedButton.icon(
                onPressed: _showMaterialSelector,
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const Text('Add Material'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Quantities are suggested based on the calculated volume: ${NumberFormat('#,###.##').format(calculatedCY)} CY', 
               style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500)),
          const SizedBox(height: 20),
          Expanded(
            child: _selectedMaterials.isEmpty
                ? _emptyMaterialsPlaceholder()
                : ListView.builder(
                    itemCount: _selectedMaterials.length,
                    itemBuilder: (ctx, idx) => _materialItemRow(_selectedMaterials[idx], calculatedCY),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyMaterialsPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.slate200),
          const SizedBox(height: 16),
          Text('No materials added yet', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.slate400)),
          const SizedBox(height: 8),
          Text('Click "Add Material" to select supplies from the catalog', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate400)),
        ],
      ),
    );
  }

  Widget _buildLayerSelector(Map<String, dynamic> mat) {
    final earthCY = _calculationResult?['earthCY'] ?? 0.0;
    final gravelCY = _calculationResult?['gravelCY'] ?? 0.0;
    
    // Safety check for value mismatch across modes
    String currentType = mat['layer_type'] ?? 'earth';
    if (_isLinearBased) {
       if (currentType != 'linear' && currentType != 'earth' && currentType != 'gravel') {
         currentType = 'linear';
         mat['layer_type'] = 'linear';
       }
    } else {
       if (currentType == 'linear' || currentType == 'earth' || currentType == 'gravel') {
         currentType = 'earth';
         mat['layer_type'] = 'earth';
       }
    }

    return Row(
      children: [
        Text('LAYER:', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate500)),
        const SizedBox(width: 8),
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
             color: AppTheme.slate50,
             border: Border.all(color: AppTheme.slate200),
             borderRadius: BorderRadius.circular(6)
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentType,
              icon: const Icon(Icons.arrow_drop_down, size: 16),
              isDense: true,
              style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate700),
              onChanged: (v) {
                setState(() {
                  mat['layer_type'] = v;
                  // Auto-update quantity when layer changes
                  final baseVal = _calculateBaseVal(mat);
                  final yield = (mat['yield_factor'] as num?)?.toDouble() ?? 1.0;
                  final suggested = baseVal * yield;
                  mat['quantity'] = suggested;
                  if (mat['qtyCtrl'] is TextEditingController) {
                    (mat['qtyCtrl'] as TextEditingController).text = suggested.toStringAsFixed(2);
                  }
                });
              },
              items: _isLinearBased
                  ? [
                      DropdownMenuItem(value: 'linear', child: Text('Linear Measure (${NumberFormat('#,###').format(double.tryParse(_compactedCtrl.text) ?? 0)} LF)')),
                      DropdownMenuItem(value: 'earth', child: Text('Trench (${NumberFormat('#,###').format(earthCY)} CY)')),
                      DropdownMenuItem(value: 'gravel', child: Text('Bedding (${NumberFormat('#,###').format(gravelCY)} CY)')),
                    ]
                  : [
                      DropdownMenuItem(value: 'earth', child: Text(_isAreaBased ? 'Sand (${NumberFormat('#,###').format(earthCY)} CY)' : 'Earth (${NumberFormat('#,###').format(earthCY)} CY)')),
                      if (gravelCY > 0)
                        DropdownMenuItem(value: 'gravel', child: Text('Gravel (${NumberFormat('#,###').format(gravelCY)} CY)')),
                      DropdownMenuItem(value: 'total', child: Text('Total (${NumberFormat('#,###').format(earthCY + gravelCY)} CY)')),
                    ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _materialItemRow(Map<String, dynamic> mat, double calculatedCY) {
    final yield = (mat['yield_factor'] as num?)?.toDouble() ?? 1.0;
    
    final baseVal = _calculateBaseVal(mat);
    
    final suggested = baseVal * yield;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.slate200)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.slate50, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.category_outlined, color: AppTheme.slate600),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mat['material_name'] ?? 'Material', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
                Text('Unit: ${mat['unit']} | Yield: ${yield.toStringAsFixed(2)} per Unit', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500)),
                if (_isAreaBased || _isLinearBased) ...[
                  const SizedBox(height: 8),
                  _buildLayerSelector(mat),
                ],
              ],
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('QUANTITY', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate500)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() {
                        mat['quantity'] = suggested;
                        (mat['qtyCtrl'] as TextEditingController).text = suggested.toStringAsFixed(2);
                      }),
                      child: Text('AUTO', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: mat['qtyCtrl'] as TextEditingController,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => mat['quantity'] = double.tryParse(v) ?? 0,
                  onTap: () {
                    final ctrl = mat['qtyCtrl'] as TextEditingController;
                    ctrl.selection = TextSelection(baseOffset: 0, extentOffset: ctrl.text.length);
                  },
                  decoration: InputDecoration(
                    suffixText: mat['unit'],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Unit Price Field
          SizedBox(
            width: 130,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UNIT PRICE (\$)', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate500)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: mat['priceCtrl'] as TextEditingController,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() => mat['unit_price'] = double.tryParse(v) ?? 0),
                  onTap: () {
                    final ctrl = mat['priceCtrl'] as TextEditingController;
                    ctrl.selection = TextSelection(baseOffset: 0, extentOffset: ctrl.text.length);
                  },
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Subtotal Display
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('SUBTOTAL', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate500)),
                const SizedBox(height: 6),
                Text('\$${NumberFormat('#,###.00').format((mat['quantity'] ?? 0) * (mat['unit_price'] ?? 0))}', 
                     style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          IconButton(
            onPressed: () => setState(() => _selectedMaterials.remove(mat)),
            icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
          ),
        ],
      ),
    );
  }

  void _showMaterialSelector() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Select Material', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _materialsCatalog.length,
            itemBuilder: (c, i) {
              final m = _materialsCatalog[i];
              return ListTile(
                title: Text(m['description'] ?? ''),
                subtitle: Text('Unit: ${m['unit'] ?? 'und'}'),
                onTap: () {
                  _addMaterial(m);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _addMaterial(Map<String, dynamic> catalogItem) {
    setState(() {
      final yield = (catalogItem['yield_factor'] as num?)?.toDouble() ?? 1.0;
      
      final baseVal = _calculateBaseVal({
        'layer_type': _isLinearBased ? 'linear' : 'earth',
      });
      
      final suggested = baseVal * yield;
      
      _selectedMaterials.add({
        'material_id': catalogItem['id'],
        'material_name': catalogItem['description'],
        'unit': catalogItem['unit'] ?? 'und',
        'layer_type': _isLinearBased ? 'linear' : 'earth',
        'yield_factor': yield,
        'quantity': suggested,
        'unit_price': 0.0,
        'notes': '',
        'qtyCtrl': TextEditingController(text: suggested.toStringAsFixed(2)),
        'priceCtrl': TextEditingController(text: '0'),
      });
    });
  }

  // ══════════════════════════════════════════════════════════════
  //  FOOTER
  // ══════════════════════════════════════════════════════════════

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppTheme.slate200))),
      child: Row(
        children: [
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('Previous', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppTheme.slate700)),
            )
          else
             OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('Cancel', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppTheme.slate700)),
            ),
          const Spacer(),
          if (_currentStep < 2)
            ElevatedButton(
              onPressed: () => setState(() => _currentStep++),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                children: [
                  Text('Next Step', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            )
          else
            _isSaving
                ? const CircularProgressIndicator(color: AppTheme.primaryGreen)
                : ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Finish & Save Estimate', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                  ),
        ],
      ),
    );
  }

  // ── Shared Helpers ──

  Widget _inputLabel(String text) => Text(text.toUpperCase(), style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppTheme.slate500));

  Widget _textField(TextEditingController ctrl, String label, IconData icon) {
    return TextFormField(
      controller: ctrl,
      onTap: () {
        ctrl.selection = TextSelection(baseOffset: 0, extentOffset: ctrl.text.length);
      },
      onChanged: (_) => _runCalculation(),
      keyboardType: TextInputType.number,
      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppTheme.slate400),
        filled: true,
        fillColor: AppTheme.slate50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _datePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
        if (picked != null) {
          setState(() => _startDate = picked);
          _runCalculation();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: AppTheme.slate50, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryGreen),
            const SizedBox(width: 12),
            Text(DateFormat('MMM dd, yyyy').format(_startDate), style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _miniInput(String label, Function(String) onChange, TextEditingController ctrl) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.slate500, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          SizedBox(
            height: 32,
            child: TextFormField(
              controller: ctrl,
              onTap: () => ctrl.selection = TextSelection(baseOffset: 0, extentOffset: ctrl.text.length),
              onChanged: onChange,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppTheme.slate200)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerButton(String label, Color bg, Color text, VoidCallback? onTap, {bool border = false}) {
    final bool isDisabled = onTap == null;
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled ? AppTheme.slate200 : bg,
        foregroundColor: isDisabled ? AppTheme.slate400 : text,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: border ? BorderSide(color: AppTheme.slate200) : BorderSide.none,
        ),
      ),
      child: Text(label, style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
    );
  }
}
