import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';

class AddUnplannedResourceDialog extends ConsumerStatefulWidget {
  final String projectId;
  final Map<String, dynamic>? initialData;

  AddUnplannedResourceDialog({
    super.key, 
    required this.projectId,
    this.initialData,
  });

  @override
  ConsumerState<AddUnplannedResourceDialog> createState() => _AddUnplannedResourceDialogState();
}

class _AddUnplannedResourceDialogState extends ConsumerState<AddUnplannedResourceDialog> {
  List<Map<String, dynamic>> _projectServices = [];
  String? _selectedServiceId;
  Map<String, dynamic>? _selectedService;
  Map<String, dynamic>? _originalEstimation;

  // Advanced Cost Controllers
  final _monthlyRentController = TextEditingController();
  final _rentController = TextEditingController();
  final _fuelGphController = TextEditingController();
  final _fuelPriceController = TextEditingController(text: '4.50'); // Default fuel price
  final _hoursPerDayController = TextEditingController(text: '8');
  final _transportController = TextEditingController(text: '0');
  final _daysController = TextEditingController(text: '1');
  
  // Logic helpers
  final _tripsController = TextEditingController(text: '60');
  final _capacityController = TextEditingController(text: '30');
  final _performanceController = TextEditingController(text: '0');
  final _thicknessController = TextEditingController(text: '0');
  final _quantityController = TextEditingController(text: '1');
  final _costController = TextEditingController(text: '0.00');

  // State
  bool _isLoadingCatalogs = false;
  String? _error;
  bool _isSaving = false;
  String _selectedType = 'Machinery';
  final List<String> _types = ['Machinery', 'Labor', 'Material', 'Instrument'];
  List<Map<String, dynamic>> _catalogItems = [];
  String? _selectedCatalogItemId;
  
  bool _isPrincipal = true;
  String? _parentMachineryId;
  List<Map<String, dynamic>> _projectMachinery = [];
  
  // Duration Compression Fields
  double _originalDuration = 0;
  double _currentBaselineDuration = 0;
  double _newEstimatedDuration = 0;
  double _compressionSavings = 0;
  double _otherResourcesDailyCost = 0;
  double _originalFleetDailyProduction = 0; // CY/day or units/day of existing fleet
  List<Map<String, dynamic>> _currentServiceMachinery = [];
  List<Map<String, dynamic>> _otherUnplannedAdditions = [];

  // Service unit type (drives calculation mode)
  bool _isLinearBased = false;
  bool _isAcresBased = false;
  bool _isAreaBased = false; // SQFT — converts to CY like volumetric
  // CY/SQFT → trips×capacity; LF/Acres → performance_per_day

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _populateFromInitialData();
    }
    _loadInitialData();
  }

  void _populateFromInitialData() {
    final data = widget.initialData!;
    _selectedType = data['type'] ?? 'Machinery';
    _selectedServiceId = data['metadata']?['service_id'] ?? data['quote_service_id'];
    
    final meta = data['metadata'] as Map<String, dynamic>?;
    if (meta != null) {
      _monthlyRentController.text = (meta['monthly_rent'] ?? (meta['rent'] != null ? (meta['rent'] * 20) : 0)).toString();
      _rentController.text = (meta['rent'] ?? 0).toString();
      _fuelGphController.text = (meta['fuel_gph'] ?? 0).toString();
      _fuelPriceController.text = (meta['fuel_price'] ?? 4.5).toString();
      _hoursPerDayController.text = (meta['hours_per_day'] ?? 8).toString();
      _daysController.text = (meta['days'] ?? 1).toString();
      _transportController.text = (meta['transport'] ?? 0).toString();
      _tripsController.text = (meta['trips_per_day'] ?? 0).toString();
      _capacityController.text = (meta['capacity'] ?? 0).toString();
      _performanceController.text = (meta['performance'] ?? 0).toString();
      _quantityController.text = (meta['quantity'] ?? 1).toString();
      _isPrincipal = meta['is_principal'] ?? true;
      _parentMachineryId = meta['parent_machinery_id'];
    }
    
    // Crucial: Set the catalog item ID so it's not overwritten by defaults
    _selectedCatalogItemId = data['catalogId']?.toString();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costController.dispose();
    _monthlyRentController.dispose();
    _rentController.dispose();
    _fuelGphController.dispose();
    _fuelPriceController.dispose();
    _hoursPerDayController.dispose();
    _transportController.dispose();
    _daysController.dispose();
    _tripsController.dispose();
    _capacityController.dispose();
    _performanceController.dispose();
    _thicknessController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingCatalogs = true);
    try {
      final supabase = Supabase.instance.client;

      // Handle automatic operator lookup and sync from linked machinery
      final linkedMachId = widget.initialData?['linked_machinery_id'];
      if (linkedMachId != null) {
        try {
          final machRow = await supabase.from('project_machinery').select().eq('id', linkedMachId).single();
          _selectedServiceId = machRow['quote_service_id']?.toString() ?? _selectedServiceId;
          final machMeta = machRow['calculation_metadata'] as Map<String, dynamic>?;
          if (machMeta != null) {
            _daysController.text = (machMeta['days'] ?? 1).toString();
            _quantityController.text = (machMeta['quantity'] ?? 1).toString();
          }
        } catch (e) {
          debugPrint('Error loading linked machinery: $e');
        }
      }

      final project = await supabase.from('projects').select('quote_id').eq('id', widget.projectId).single();
      final quoteId = project['quote_id'];

      if (quoteId != null) {
        final services = await supabase.from('quote_services').select().eq('quote_id', quoteId).order('name');
        _projectServices = List<Map<String, dynamic>>.from(services);
        
        // IF IN EDIT MODE: Trigger service-specific data loading (estimations, duration, etc.)
        if (_selectedServiceId != null) {
          await _onServiceSelected(_selectedServiceId!, isInitial: true);
        }
      }

      await _loadCatalogData();
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      if (mounted) setState(() => _error = 'Failed to load catalog data. Please try again.');
    }
    setState(() => _isLoadingCatalogs = false);
  }

  Future<void> _loadCatalogData() async {
    try {
      final catalogsSvc = ref.read(catalogsServiceProvider);
      final supabase = Supabase.instance.client;

      if (_selectedType == 'Machinery') {
        _catalogItems = await catalogsSvc.getMachinery();
        final pm = await supabase
            .from('project_machinery')
            .select()
            .eq('project_id', widget.projectId)
            .eq('is_principal', true);
        _projectMachinery = List<Map<String, dynamic>>.from(pm);
      } else if (_selectedType == 'Labor') {
        _catalogItems = await catalogsSvc.getLaborRoles();
      } else if (_selectedType == 'Material') {
        _catalogItems = await catalogsSvc.getMaterials();
      } else if (_selectedType == 'Instrument') {
        _catalogItems = await catalogsSvc.getLogisticsEquipment();
      }

      if (_catalogItems.isNotEmpty && _selectedCatalogItemId == null) {
        _selectedCatalogItemId = _catalogItems.first['id'].toString();
        _onResourceSelected(_selectedCatalogItemId!);
      } else if (_selectedCatalogItemId != null) {
        // If we already have an ID (from edit mode), just make sure we trigger cost calculation
        // but WITHOUT pulling defaults from the catalog
        if (_selectedType == 'Labor') {
          final item = _catalogItems.firstWhere((i) => i['id'].toString() == _selectedCatalogItemId, orElse: () => {});
          final internalRate = (item['internal_cost_rate'] as num?)?.toDouble() ?? 0;
          final hourlyRate = (item['hourly_rate'] as num?)?.toDouble() ?? 0;
          final rate = internalRate > 0 ? internalRate : hourlyRate;
          final currentRent = double.tryParse(_rentController.text) ?? 0;
          if (currentRent <= 0 && rate > 0) {
            _rentController.text = (rate * 8).toStringAsFixed(0);
          }
        }
        _calculateCost();
      }
    } catch (e) {
      debugPrint('Error loading catalog: $e');
      if (mounted) setState(() => _error = 'Failed to load catalog items.');
    }
  }

  Future<void> _onServiceSelected(String serviceId, {bool isInitial = false}) async {
    final service = _projectServices.firstWhere((s) => s['id'] == serviceId);

    // Detect unit type
    final unitRaw = (service['unit_of_measure'] ?? service['unit'] ?? 'cy').toString().toLowerCase().trim();
    final isLinear = unitRaw == 'lf' || unitRaw == 'ft' || unitRaw.contains('lineal');
    final isAcres  = unitRaw == 'ac' || unitRaw == 'acre' || unitRaw == 'acres';
    final isArea   = unitRaw == 'ft2' || unitRaw == 'sqft' || unitRaw == 'sf' || unitRaw.contains('pie cuadrado');

    setState(() {
      _selectedServiceId = serviceId;
      _selectedService = service;
      _isLinearBased = isLinear;
      _isAcresBased = isAcres;
      _isAreaBased = isArea;
    });

    final supabase = Supabase.instance.client;

    // Load current principal machinery for this service
    final currentMach = await supabase.from('project_machinery')
        .select()
        .eq('project_id', widget.projectId)
        .eq('quote_service_id', serviceId)
        .eq('is_principal', true);
    _currentServiceMachinery = List<Map<String, dynamic>>.from(currentMach);

    final otherUnplanned = _currentServiceMachinery.where((m) =>
        m['is_unplanned'] == true &&
        (widget.initialData == null || m['id'] != widget.initialData!['id'])
    ).toList();

    // Load estimation
    final est = await supabase.from('quote_service_estimations')
        .select('*, quote_service_estimation_resources(*)')
        .eq('quote_service_id', serviceId)
        .maybeSingle();
    if (est != null) {
      _originalEstimation = est;
      _originalDuration = (est['total_working_days'] as num?)?.toDouble() ?? 0;

      // Compute original fleet daily production from estimation resources
      double fleetProd = 0;
      final estResources = est['quote_service_estimation_resources'] as List? ?? [];
      for (final r in estResources) {
        final qty   = (r['quantity'] as num?)?.toDouble() ?? 1;
        if (isLinear || isAcres) {
          // LF/Acres: performance_per_day
          fleetProd += qty * ((r['performance_per_day'] as num?)?.toDouble() ?? 0);
        } else {
          // CY and SQFT (converted to CY): trips × capacity
          final trips = (r['trips_per_day'] as num?)?.toDouble() ?? 0;
          final cap   = (r['capacity_per_trip'] as num?)?.toDouble() ?? 0;
          fleetProd += qty * trips * cap;
        }
      }
      _originalFleetDailyProduction = fleetProd;
    }

    // Real daily cost of other resources (the "burn rate" of the service)
    double otherDailyCost = 0;
    try {
      // 1. Unplanned resources already added
      final laborRows = await supabase
          .from('project_labor')
          .select('unplanned_cost, calculation_metadata')
          .eq('project_id', widget.projectId)
          .eq('quote_service_id', serviceId)
          .eq('is_unplanned', true);
      for (final r in laborRows) {
        final days = (r['calculation_metadata']?['days'] as num?)?.toDouble() ?? 1;
        final cost = (r['unplanned_cost'] as num?)?.toDouble() ?? 0;
        if (days > 0) otherDailyCost += cost / days;
      }
      final instRows = await supabase
          .from('project_instruments')
          .select('unplanned_cost, calculation_metadata')
          .eq('project_id', widget.projectId)
          .eq('quote_service_id', serviceId)
          .eq('is_unplanned', true);
      for (final r in instRows) {
        final days = (r['calculation_metadata']?['days'] as num?)?.toDouble() ?? 1;
        final cost = (r['unplanned_cost'] as num?)?.toDouble() ?? 0;
        if (days > 0) otherDailyCost += cost / days;
      }

      // 2. Original Quote Labor
      final qLabors = await supabase
          .from('quote_service_labors')
          .select('hourly_rate, per_diem, employees_quantity')
          .eq('quote_service_id', serviceId);
      for (final r in qLabors) {
        final qty = (r['employees_quantity'] as num?)?.toDouble() ?? 1;
        final rate = (r['hourly_rate'] as num?)?.toDouble() ?? 0;
        final perDiem = (r['per_diem'] as num?)?.toDouble() ?? 0;
        // Daily cost for 8 hours
        otherDailyCost += (rate + perDiem) * 8 * qty;
      }

      // 3. Original Quote Machinery (Rent + Fuel)
      final qMachs = await supabase
          .from('quote_service_machineries')
          .select('monthly_rent_cost, gallons_per_hour, gallon_cost, quantity')
          .eq('quote_service_id', serviceId);
      for (final r in qMachs) {
        final qty = (r['quantity'] as num?)?.toDouble() ?? 1;
        // Rent: monthly / 20 
        double mRent = (r['monthly_rent_cost'] as num?)?.toDouble() ?? 0;
        double dRent = mRent / 20;
        
        // Fuel
        final gph = (r['gallons_per_hour'] as num?)?.toDouble() ?? 0;
        final fPrice = (r['gallon_cost'] as num?)?.toDouble() ?? 4.5;
        // Use 8 hours as standard day for savings projection
        final dFuel = gph * fPrice * 8;

        otherDailyCost += (dRent + dFuel) * qty;
      }

      // 4. Original Quote Instruments
      final qInst = await supabase
          .from('quote_service_instruments')
          .select('unit_price, quantity, days')
          .eq('quote_service_id', serviceId);
      for (final r in qInst) {
        final qty = (r['quantity'] as num?)?.toDouble() ?? 1;
        final price = (r['unit_price'] as num?)?.toDouble() ?? 0;
        // Instruments in quote are often for total project, normalize to daily
        final totalDays = (r['days'] as num?)?.toDouble() ?? _originalDuration;
        if (totalDays > 0) {
          otherDailyCost += (price * qty); // unit_price is usually daily rate for instruments
        }
      }

    } catch (e) {
      debugPrint('Error fetching other resource costs: $e');
    }
    
    setState(() {
      _otherResourcesDailyCost = otherDailyCost;
      _otherUnplannedAdditions = otherUnplanned;
    });

    if (!isInitial && _selectedCatalogItemId != null) {
      final item = _catalogItems.firstWhere((i) => i['id'].toString() == _selectedCatalogItemId);
      
      // AUTO-SYNC DAYS: If this is Labor, try to find machinery already added to this service
      if (_selectedType == 'Labor') {
        try {
          final supabase = Supabase.instance.client;
          final machDaysRes = await supabase.from('project_machinery')
              .select('calculation_metadata')
              .eq('project_id', widget.projectId)
              .eq('quote_service_id', serviceId)
              .eq('is_unplanned', true);
          
          double maxDays = 0;
          for (var m in machDaysRes) {
            final d = (m['calculation_metadata']?['days'] as num?)?.toDouble() ?? 0;
            if (d > maxDays) maxDays = d;
          }
          if (maxDays > 0) {
            _daysController.text = maxDays.toStringAsFixed(0);
          }
        } catch (e) {
          debugPrint('Error syncing days: $e');
        }
      }

      await _syncWithEstimation(serviceId, _selectedCatalogItemId!, item['description'] ?? item['name'] ?? '');
    }
    _calculateCost();
  }

  Future<void> _onResourceSelected(String itemId) async {
    setState(() => _selectedCatalogItemId = itemId);
    final item = _catalogItems.firstWhere((i) => i['id'].toString() == itemId);
    // Auto-fill cost and production fields from catalog defaults
    _monthlyRentController.text = (item['monthly_rent_cost'] ?? '0').toString();
    
    if (_selectedType == 'Labor') {
      final internalRate = (item['internal_cost_rate'] as num?)?.toDouble() ?? 0;
      final hourlyRate = (item['hourly_rate'] as num?)?.toDouble() ?? 0;
      // internal_cost_rate = daily; hourly_rate = hourly → convert to daily
      if (internalRate > 0) {
        _rentController.text = internalRate.toStringAsFixed(0);
      } else {
        _rentController.text = (hourlyRate * 8).toStringAsFixed(0);
      }
    } else {
      _rentController.text = (item['daily_rate'] ?? item['rent_cost'] ?? '0').toString();
    }
    
    _fuelGphController.text = (item['gallons_per_hour'] ?? '0').toString();
    // For CY/SQFT: auto-fill trips and capacity
    if (!_isLinearBased && !_isAcresBased) {
      _tripsController.text = (item['default_trips_per_day'] ?? item['trips_per_day'] ?? '60').toString();
      _capacityController.text = (item['capacity_yards'] ?? '30').toString();
    }
    if (_selectedServiceId != null) {
      await _syncWithEstimation(_selectedServiceId!, itemId, item['description'] ?? item['name'] ?? '');
    }
    _calculateCost();
  }

  Future<void> _syncWithEstimation(String serviceId, String catalogId, String itemName) async {
    try {
      final supabase = Supabase.instance.client;
      final qMachs = await supabase
          .from('quote_service_machineries')
          .select()
          .eq('quote_service_id', serviceId)
          .eq('machine_name', itemName)
          .maybeSingle();

      if (qMachs != null) {
        _monthlyRentController.text = (qMachs['monthly_rent_cost'] ?? '0').toString();
        _rentController.text = (qMachs['rent_cost'] ?? '0').toString();
        _fuelGphController.text = (qMachs['fuel_gallons_per_hour'] ?? '0').toString();
        _hoursPerDayController.text = (qMachs['hours_per_day'] ?? '8').toString();
        _performanceController.text = (qMachs['loose_cubic_yards_per_hour'] ?? '0').toString();
      }
    } catch (e) {
      debugPrint('Error syncing: $e');
    }
    _calculateCost();
  }

  void _calculateCost() {
    try {
      double rent = 0;
      if (_selectedType == 'Machinery') {
        final monthlyRent = double.tryParse(_monthlyRentController.text) ?? 0;
        // Consistent with QuoteFormDialog: Monthly / 20 days (based on 160 hrs / 8 hrs day)
        rent = monthlyRent / 20; 
        _rentController.text = rent.toStringAsFixed(2);
      } else {
        rent = double.tryParse(_rentController.text) ?? 0;
      }
      
      final qty = double.tryParse(_quantityController.text) ?? 1;
      final days = double.tryParse(_daysController.text) ?? 1;
      final transport = double.tryParse(_transportController.text) ?? 0;
      double dailyRate = rent;

      // USE INTERNAL COST FOR LABOR IF AVAILABLE
      if (_selectedType == 'Labor' && _selectedCatalogItemId != null) {
        final item = _catalogItems.firstWhere((i) => i['id'].toString() == _selectedCatalogItemId, orElse: () => {});
        final internalRate = (item['internal_cost_rate'] as num?)?.toDouble();
        if (internalRate != null && internalRate > 0) {
          dailyRate = internalRate * 8; // hourly to daily (8 hr day)
        } else {
          final hourlyRate = (item['hourly_rate'] as num?)?.toDouble() ?? 0;
          if (hourlyRate > 0) {
            dailyRate = hourlyRate * 8;
          }
        }
        _rentController.text = dailyRate.toStringAsFixed(2);
      }

      final gph       = double.tryParse(_fuelGphController.text) ?? 0;
      final fuelPrice = double.tryParse(_fuelPriceController.text) ?? 4.5;
      final hours     = double.tryParse(_hoursPerDayController.text) ?? 8;

      final dailyFuel = gph * hours * fuelPrice;
      final total = ((dailyRate + dailyFuel) * days * qty) + transport;

      // ── Timeline impact ──────────────────────────────────────────────────
      if (_isPrincipal && _selectedType == 'Machinery' && _originalDuration > 0) {
        final targetVolume = (_originalEstimation?['total_cy_loose'] as num?)?.toDouble() ?? 0;
        final totalTarget  = _isLinearBased
            ? ((_originalEstimation?['compacted_volume'] as num?)?.toDouble() ?? 0)
            : _isAcresBased
                ? ((_originalEstimation?['compacted_volume'] as num?)?.toDouble() ?? 0)
                : targetVolume; // CY and SQFT both use total_cy_loose

        // 1. Fallback original fleet daily production if it's 0 or negative
        double p0 = _originalFleetDailyProduction;
        if (p0 <= 0 && _originalDuration > 0) {
          p0 = totalTarget / _originalDuration;
        }

        // 2. Calculate daily production of the current machine
        double newMachineProdDay;
        if (_isLinearBased || _isAcresBased) {
          newMachineProdDay = (double.tryParse(_performanceController.text) ?? 0) * qty;
        } else {
          final trips    = double.tryParse(_tripsController.text) ?? 0;
          final capacity = double.tryParse(_capacityController.text) ?? 0;
          newMachineProdDay = trips * capacity * qty;
        }

        // 3. Sum up the daily productions and days of all other unplanned machines
        double otherUnplannedProdSum = 0;
        double otherUnplannedDaysSavedSum = 0;
        
        for (final m in _otherUnplannedAdditions) {
          final meta = m['calculation_metadata'] as Map<String, dynamic>?;
          if (meta != null) {
            final mProd = (meta['performance_per_day'] as num?)?.toDouble() ?? 0;
            final mDaysSaved = (meta['days_saved'] as num?)?.toDouble() ?? 0;
            
            otherUnplannedProdSum += mProd;
            otherUnplannedDaysSavedSum += mDaysSaved;
          }
        }

        // 4. Calculate Current Baseline Duration (after applying other unplanned additions)
        _currentBaselineDuration = _originalDuration - otherUnplannedDaysSavedSum;
        if (_currentBaselineDuration < 0) _currentBaselineDuration = 0;

        // 5. Calculate New Projected Duration (including other unplanned additions + current machine)
        final totalFleetProdDay = p0 + otherUnplannedProdSum + newMachineProdDay;
        
        if (totalFleetProdDay > 0 && totalTarget > 0) {
          final fullAccDuration = totalTarget / totalFleetProdDay;
          final days = double.tryParse(_daysController.text) ?? 1;
          
          // Proportional linear interpolation for the current machine
          final currentFullAcc = totalTarget / (p0 + newMachineProdDay);
          final currentDiff = _originalDuration - currentFullAcc;
          double currentDaysSaved = 0;
          
          if (currentDiff > 0 && currentFullAcc > 0) {
            currentDaysSaved = days * (currentDiff / currentFullAcc);
            if (currentDaysSaved > currentDiff) {
              currentDaysSaved = currentDiff;
            }
          } else {
            currentDaysSaved = currentDiff;
          }
          
          _newEstimatedDuration = _currentBaselineDuration - currentDaysSaved;
          
          // Cap at full acceleration of the entire fleet
          if (_newEstimatedDuration < fullAccDuration) {
            _newEstimatedDuration = fullAccDuration;
          }
          
          if (_newEstimatedDuration < 0) {
            _newEstimatedDuration = 0;
          }

          // Days saved by the current machine incremental addition
          final incrementalDaysSaved = _currentBaselineDuration - _newEstimatedDuration;
          
          if (incrementalDaysSaved > 0) {
            final dailyRate = _otherResourcesDailyCost > 0 ? _otherResourcesDailyCost : 500.0;
            _compressionSavings = incrementalDaysSaved * dailyRate;
          } else {
            _compressionSavings = 0;
          }
        } else {
          _newEstimatedDuration = 0;
          _compressionSavings   = 0;
        }
      } else {
        _currentBaselineDuration = 0;
        _newEstimatedDuration = 0;
        _compressionSavings   = 0;
      }
      // ────────────────────────────────────────────────────────────────────

      setState(() => _costController.text = total.toStringAsFixed(2));
    } catch (e) {
      debugPrint('Error calculating cost: $e');
    }
  }

  Future<void> _saveResource() async {
    if (_selectedCatalogItemId == null) {
      setState(() => _error = 'Please select a resource from the catalog first.');
      return;
    }
    if (_selectedServiceId == null) {
      setState(() => _error = 'Please select a target service first.');
      return;
    }
    setState(() { _isSaving = true; _error = null; });

    try {
      final supabase = Supabase.instance.client;
      final selectedItem = _catalogItems.firstWhere((item) => item['id'].toString() == _selectedCatalogItemId);
      final itemName = selectedItem['description'] ?? selectedItem['name'] ?? 'Unknown';
      
      final cost = double.tryParse(_costController.text) ?? 0;
      final qty = int.tryParse(_quantityController.text) ?? 1;
      final days = int.tryParse(_daysController.text) ?? 1;

      // Compute CY/day for this machine (persisted for future fleet recalculations)
      final trips    = double.tryParse(_tripsController.text) ?? 0;
      final capacity = double.tryParse(_capacityController.text) ?? 0;
      final perfDay  = double.tryParse(_performanceController.text) ?? 0;
      final machineProductionPerDay = (_isLinearBased || _isAcresBased)
          ? perfDay * qty
          : trips * capacity * qty;

      final metadata = {
        'service_id': _selectedServiceId,
        'monthly_rent': double.tryParse(_monthlyRentController.text) ?? 0,
        'rent': double.tryParse(_rentController.text) ?? 0,
        'fuel_gph': double.tryParse(_fuelGphController.text) ?? 0,
        'fuel_price': double.tryParse(_fuelPriceController.text) ?? 4.5,
        'hours_per_day': double.tryParse(_hoursPerDayController.text) ?? 8,
        'days': days,
        'transport': double.tryParse(_transportController.text) ?? 0,
        'trips_per_day': trips,
        'capacity': capacity,
        'performance_per_day': machineProductionPerDay,
        'target_volume': _originalEstimation?['total_cy_loose'] ?? 0,
        'unit': _selectedService?['unit_of_measure'] ?? _selectedService?['unit'],
        'quantity': qty,
        'is_principal': _isPrincipal,
        'parent_machinery_id': _parentMachineryId,
        'original_duration_days': _originalDuration,
        'new_estimated_duration_days': _newEstimatedDuration > 0 ? _newEstimatedDuration : null,
        'days_saved': (_newEstimatedDuration > 0 && _currentBaselineDuration > _newEstimatedDuration)
            ? (_currentBaselineDuration - _newEstimatedDuration)
            : null,
        'compression_savings': _compressionSavings > 0 ? _compressionSavings : null,
        'other_resources_daily_cost': _otherResourcesDailyCost > 0 ? _otherResourcesDailyCost : null,
        'original_fleet_daily_production': _originalFleetDailyProduction,
      };

      Map<String, dynamic> payload = {
        'project_id': widget.projectId,
        'quote_service_id': _selectedServiceId,
        'is_unplanned': true,
        'unplanned_cost': cost,
        'calculation_metadata': metadata,
      };

      String table = '';
      if (_selectedType == 'Machinery') {
        table = 'project_machinery';
        payload.addAll({
          'machinery_id': selectedItem['id'],
          'machinery_name': itemName,
          'expected_quantity': qty,
          'is_principal': _isPrincipal,
          'parent_machinery_id': _isPrincipal ? null : _parentMachineryId,
        });
      } else if (_selectedType == 'Labor') {
        table = 'project_labor';
        payload.addAll({
          'role_id': selectedItem['id'],
          'role_name': itemName,
          'expected_employees': qty,
        });
      } else if (_selectedType == 'Material') {
        table = 'project_materials';
        payload.addAll({
          'material_id': selectedItem['id'],
          'material_name': itemName,
          'expected_quantity': qty,
          'unit_name': selectedItem['unit'] ?? 'units',
        });
      } else if (_selectedType == 'Instrument') {
        table = 'project_instruments';
        payload.addAll({
          'instrument_id': selectedItem['id'],
          'instrument_name': itemName,
          'expected_quantity': qty,
        });
      }

      if (widget.initialData != null) {
        await supabase.from(table).update(payload).eq('id', widget.initialData!['id']);
      } else {
        await supabase.from(table).insert(payload);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e, st) {
      debugPrint('Error saving resource: $e\n$st');
      if (mounted) setState(() => _error = 'Failed to save: $e');
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.initialData != null ? 'Edit Resource' : 'Add Extra Resource', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Define the cost and production impact of this resource.', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate400)),
              const SizedBox(height: 24),
              
              Text('Target Service', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
              const SizedBox(height: 8),
              _buildServiceDropdown(),
              const SizedBox(height: 16),
  
              Text('Resource Type', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
              const SizedBox(height: 8),
              _buildDropdown(
                value: _selectedType,
                items: _types,
                onChanged: (val) {
                  if (val != null) {
                    setState(() { _selectedType = val; _selectedCatalogItemId = null; });
                    _loadCatalogData();
                  }
                },
              ),
              const SizedBox(height: 24),
              
              if (_selectedType == 'Machinery') ...[
                Text('USAGE TYPE', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate400, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildDropdown(
                  value: _isPrincipal ? 'Principal' : 'Support',
                  items: ['Principal', 'Support'],
                  onChanged: (val) {
                    setState(() {
                      _isPrincipal = val == 'Principal';
                      if (_isPrincipal) _parentMachineryId = null;
                    });
                    _calculateCost();
                  },
                ),
                const SizedBox(height: 24),
              ],
  
              Text('SELECT FROM CATALOG', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate400, letterSpacing: 1)),
              const SizedBox(height: 8),
              _isLoadingCatalogs ? const LinearProgressIndicator(color: AppTheme.primaryGreen) : 
                _error != null 
                  ? Text(_error!, style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.errorRed, fontWeight: FontWeight.w600))
                  : _buildCatalogDropdown(),
              
              if (!_isPrincipal && _selectedType == 'Machinery') ...[
                const SizedBox(height: 24),
                Text('LINK TO PRIMARY MACHINE (OPTIONAL)', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate400, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildParentMachineryDropdown(),
              ],
              const SizedBox(height: 24),
  
              if (_selectedCatalogItemId != null) ...[
                _buildCostConfigPanel(),
                const SizedBox(height: 16),
                if (_isPrincipal && _selectedType == 'Machinery' && _newEstimatedDuration > 0)
                  _buildTimelineImpactPanel(),
                const SizedBox(height: 24),
              ],
  
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOTAL ESTIMATED EXTRA COST', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen, letterSpacing: 1)),
                        Text('\$${_costController.text}', style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                      ],
                    ),
                    Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primaryGreen.withOpacity(0.5), size: 32),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withOpacity(0.3))),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: GoogleFonts.manrope(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600))),
                  ]),
                ),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel', style: GoogleFonts.manrope(color: AppTheme.slate400, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveResource,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(widget.initialData != null ? 'Update Resource' : 'Add Resource', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF334155))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, isExpanded: true, dropdownColor: const Color(0xFF1E293B), style: GoogleFonts.manrope(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.arrow_drop_down, color: AppTheme.slate400), items: items.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(), onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildServiceDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF334155))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedServiceId, isExpanded: true, hint: Text('Select Service...', style: GoogleFonts.manrope(color: AppTheme.slate500, fontSize: 14)),
          dropdownColor: const Color(0xFF1E293B), style: GoogleFonts.manrope(color: Colors.white, fontSize: 14), icon: const Icon(Icons.layers_outlined, color: AppTheme.primaryGreen, size: 18),
          items: _projectServices.map((s) => DropdownMenuItem(value: s['id'].toString(), child: Text('${s['name']} (${s['unit_of_measure'] ?? 'und'})'))).toList(),
          onChanged: (val) { if (val != null) _onServiceSelected(val); },
        ),
      ),
    );
  }

  Widget _buildCatalogDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF334155))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCatalogItemId, isExpanded: true, hint: Text('Select Item...', style: GoogleFonts.manrope(color: AppTheme.slate500, fontSize: 14)),
          dropdownColor: const Color(0xFF1E293B), style: GoogleFonts.manrope(color: Colors.white, fontSize: 14), icon: const Icon(Icons.search, color: AppTheme.slate400, size: 18),
          items: _catalogItems.map((item) => DropdownMenuItem(value: item['id'].toString(), child: Text(item['description'] ?? item['name'] ?? 'Unknown'))).toList(),
          onChanged: (val) { if (val != null) _onResourceSelected(val); },
        ),
      ),
    );
  }

  Widget _buildParentMachineryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF334155))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _parentMachineryId, isExpanded: true, hint: Text('None (No link)', style: GoogleFonts.manrope(color: AppTheme.slate500, fontSize: 14)),
          dropdownColor: const Color(0xFF1E293B), style: GoogleFonts.manrope(color: Colors.white, fontSize: 14),
          items: [const DropdownMenuItem<String>(value: null, child: Text('None (No link)')), ..._projectMachinery.map((m) => DropdownMenuItem(value: m['id'].toString(), child: Text(m['machinery_name'] ?? 'Unknown Machine')))],
          onChanged: (val) { setState(() => _parentMachineryId = val); },
        ),
      ),
    );
  }

  Widget _buildCostConfigPanel() {
    final unit = (_selectedService?['unit_of_measure'] ?? _selectedService?['unit'] ?? 'CY').toString().toUpperCase();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF334155))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: _buildTextField(_selectedType == 'Machinery' ? 'Monthly Rent (\$)' : 'Daily Rate (\$)', _selectedType == 'Machinery' ? _monthlyRentController : _rentController)), 
            const SizedBox(width: 12), 
            Expanded(child: _buildTextField('Quantity', _quantityController, isInt: true))
          ]),
          if (_selectedType == 'Machinery') ...[
            const SizedBox(height: 8),
            // Show converted Daily Rent
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(6)),
              child: Row(
                children: [
                  Icon(Icons.event_note, size: 12, color: AppTheme.slate400),
                  const SizedBox(width: 8),
                  Text('Daily Rent (calculated): \$${_rentController.text}', style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate400)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(children: [Expanded(child: _buildTextField('Days', _daysController, isInt: true)), const SizedBox(width: 12), Expanded(child: _buildTextField('Transport (\$)', _transportController))]),
          if (_selectedType == 'Machinery') ...[
            const SizedBox(height: 12),
            Row(children: [Expanded(child: _buildTextField('Fuel GPH', _fuelGphController)), const SizedBox(width: 12), Expanded(child: _buildTextField('Hours/Day', _hoursPerDayController))]),
            const SizedBox(height: 16),
            // Production fields differ by unit type
            if (_isLinearBased || _isAcresBased) ...[
              Text('PRODUCTION CAPACITY', style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.slate500, letterSpacing: 1)),
              const SizedBox(height: 8),
              _buildTextField('Performance (${_isLinearBased ? "LF" : "AC"}/day)', _performanceController),
            ] else ...[
              // CY and SQFT → trips × capacity
              Text('PRODUCTION CAPACITY  (auto-calculated: trips × capacity)', style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.slate500, letterSpacing: 1)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _buildTextField('Trips / Day', _tripsController)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField('Capacity (CY)', _capacityController)),
              ]),
              const SizedBox(height: 8),
              // Read-only display of computed CY/day
              Builder(builder: (_) {
                final trips = double.tryParse(_tripsController.text) ?? 0;
                final cap   = double.tryParse(_capacityController.text) ?? 0;
                final qty   = int.tryParse(_quantityController.text) ?? 1;
                final cyDay = trips * cap * qty;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                  child: Row(children: [
                    const Icon(Icons.bolt, size: 14, color: AppTheme.primaryGreen),
                    const SizedBox(width: 8),
                    Text('This machine: ${cyDay.toStringAsFixed(0)} CY/day', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
                    const Spacer(),
                    if (_originalFleetDailyProduction > 0)
                      Text('Fleet was: ${_originalFleetDailyProduction.toStringAsFixed(0)} CY/day', style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate500)),
                  ]),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isInt = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate500, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller, keyboardType: TextInputType.number, style: GoogleFonts.manrope(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.all(12), filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.primaryGreen))),
          onChanged: (val) {
            if (val.startsWith('0') && val.length > 1 && val[1] != '.') {
              final clean = val.substring(1);
              controller.value = TextEditingValue(
                text: clean,
                selection: TextSelection.collapsed(offset: clean.length),
              );
            }
            _calculateCost();
          },
        ),
      ],
    );
  }

  Widget _buildTimelineImpactPanel() {
    final incrementalDaysSaved = _currentBaselineDuration - _newEstimatedDuration;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed_outlined, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'TIMELINE OPTIMIZATION (CUMULATIVE)',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.orange,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // LEVEL 1: Original Quote Duration
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1. Original Quote Duration', style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 12)),
              Text('${_originalDuration.toStringAsFixed(1)} days', style: GoogleFonts.manrope(color: const Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFF1E293B), thickness: 1),
          const SizedBox(height: 8),

          // LEVEL 2: Current Baseline
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('2. Current Baseline Duration', style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 12)),
                  Text(
                    '${_currentBaselineDuration.toStringAsFixed(1)} days',
                    style: GoogleFonts.manrope(
                      color: _currentBaselineDuration < _originalDuration ? Colors.amber : const Color(0xFFCBD5E1),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (_otherUnplannedAdditions.isNotEmpty) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withOpacity(0.04)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 10, color: AppTheme.slate500),
                            const SizedBox(width: 6),
                            Text(
                              'Includes ${_otherUnplannedAdditions.length} previous extra resource(s):',
                              style: GoogleFonts.manrope(color: AppTheme.slate500, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ..._otherUnplannedAdditions.map((m) {
                          final meta = m['calculation_metadata'] as Map<String, dynamic>?;
                          final saved = (meta?['days_saved'] as num?)?.toDouble() ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(top: 2, left: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.subdirectory_arrow_right, size: 8, color: AppTheme.slate600),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    m['machinery_name'] ?? 'Unknown Machine',
                                    style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 10),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '-${saved.toStringAsFixed(1)} days',
                                  style: GoogleFonts.manrope(color: Colors.amber.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFF1E293B), thickness: 1),
          const SizedBox(height: 8),

          // LEVEL 3: New Projected
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('3. New Projected Duration', style: GoogleFonts.manrope(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: Text(
                  '${_newEstimatedDuration.toStringAsFixed(1)} days',
                  style: GoogleFonts.manrope(color: AppTheme.primaryGreen, fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          
          if (incrementalDaysSaved > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_circle_down_outlined, size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Text('This machine savings (incremental):', style: GoogleFonts.manrope(color: const Color(0xFFCBD5E1), fontSize: 11)),
                        ],
                      ),
                      Text(
                        '-${incrementalDaysSaved.toStringAsFixed(1)} days',
                        style: GoogleFonts.manrope(color: const Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.savings_outlined, size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Text('Estimated compression savings:', style: GoogleFonts.manrope(color: const Color(0xFFCBD5E1), fontSize: 11)),
                        ],
                      ),
                      Text(
                        '\$${_compressionSavings.toStringAsFixed(2)}',
                        style: GoogleFonts.manrope(color: const Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
