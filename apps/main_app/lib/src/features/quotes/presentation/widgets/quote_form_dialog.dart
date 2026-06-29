import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import 'package:intl/intl.dart';
import 'package:noel_app/src/features/catalogs/presentation/widgets/service_dialog.dart';
import 'package:noel_app/src/features/catalogs/presentation/widgets/machinery_dialog.dart';
import 'package:noel_app/src/features/catalogs/presentation/widgets/labor_role_dialog.dart';
import 'package:noel_app/src/features/customers/presentation/widgets/customer_form_dialog.dart';
import 'service_estimation_dialog.dart';
import 'machinery_selection_dialog.dart';

// ══════════════════════════════════════════════════════════════
//  DATA MODELS (local, in-memory for the wizard)
// ══════════════════════════════════════════════════════════════

class MachineryEntry {
  String machineName;
  double monthsToUse;
  double monthlyRentCost;
  double quantity;
  double gallonsPerHour;
  double gallonCost;
  double deliveryCost;
  bool isPrimaryMover;
  String? parentMachineName;

  MachineryEntry({
    this.machineName = '',
    this.monthsToUse = 0,
    this.monthlyRentCost = 0,
    this.quantity = 1,
    this.gallonsPerHour = 0,
    this.gallonCost = 0,
    this.deliveryCost = 0,
    this.isPrimaryMover = true,
    this.parentMachineName,
  });

  double get ratePerHour => monthlyRentCost / 160;
  double get hoursWorkedPerMonth => monthsToUse * quantity * 220;
  double get totalRent => ratePerHour * hoursWorkedPerMonth;
  double get totalGallons => hoursWorkedPerMonth * gallonsPerHour;
  double get totalGallonsCost => totalGallons * gallonCost;
  double get deliveryTotal => deliveryCost * quantity;
  double get totalGeneral => totalRent + totalGallonsCost + deliveryTotal;
}

class LaborEntry {
  String roleName;
  double monthsToWork;
  double employeesQuantity;
  double hourlyRate;
  double perDiem;

  LaborEntry({
    this.roleName = '',
    this.monthsToWork = 0,
    this.employeesQuantity = 1,
    this.hourlyRate = 0,
    this.perDiem = 0,
  });

  double get hoursPerMonth => monthsToWork * 220 * employeesQuantity;
  double get totalPay => hoursPerMonth * hourlyRate;
  double get totalPerDiem => hoursPerMonth * perDiem;
  double get totalFinal => totalPay + totalPerDiem;
}

class MaterialEntry {
  String materialName;
  String unit;
  double quantity;
  double unitPrice;
  String? catalogId;

  MaterialEntry({
    this.materialName = '',
    this.unit = 'und',
    this.quantity = 0,
    this.unitPrice = 0,
    this.catalogId,
  });

  double get total => quantity * unitPrice;
}

class InstrumentEntry {
  String instrumentName;
  double quantity;
  double days;
  double unitPrice;
  String? catalogId;
  String? notes;
  String? photoUrl;

  InstrumentEntry({
    this.instrumentName = '',
    this.quantity = 1,
    this.days = 1,
    this.unitPrice = 0,
    this.catalogId,
    this.notes,
    this.photoUrl,
  });

  double get total => quantity * days * unitPrice;
}

class ServiceEntry {
  String? dbId;
  String name;
  String unitOfMeasure;
  double quantity;
  double overheadPercentage;
  double profitPercentage;
  double directCost;
  double targetPrice;
  bool isStaffingRole;
  List<MachineryEntry> machineries;
  List<LaborEntry> labors;
  List<MaterialEntry> materials;
  List<InstrumentEntry> instruments;

  Map<String, dynamic>? estimationData;
  String? catalogId;

  ServiceEntry({
    this.name = '',
    this.unitOfMeasure = 'und',
    this.quantity = 1,
    this.overheadPercentage = 0,
    this.profitPercentage = 0,
    this.directCost = 0,
    this.targetPrice = 0,
    this.isStaffingRole = false,
    List<MachineryEntry>? machineries,
    List<LaborEntry>? labors,
    List<MaterialEntry>? materials,
    List<InstrumentEntry>? instruments,
    this.estimationData,
    this.catalogId,
  }) : machineries = machineries ?? [],
       labors = labors ?? [],
       materials = materials ?? [],
       instruments = instruments ?? [];

  double get totalMachinery => machineries.fold(0.0, (s, m) => s + m.totalRent);
  double get totalGasoline =>
      machineries.fold(0.0, (s, m) => s + m.totalGallonsCost);
  double get totalDelivery =>
      machineries.fold(0.0, (s, m) => s + m.deliveryTotal);
  double get totalLabor => labors.fold(0.0, (s, l) => s + l.totalPay);
  double get totalPerDiem => labors.fold(0.0, (s, l) => s + l.totalPerDiem);
  double get totalMaterials => materials.fold(0.0, (s, m) => s + m.total);
  double get totalInstruments => instruments.fold(0.0, (s, i) => s + i.total);
  double get subTotal {
    if (unitOfMeasure.toLowerCase() == 'ls' || isStaffingRole) {
      return quantity * directCost;
    }
    return totalMachinery +
        totalGasoline +
        totalDelivery +
        totalLabor +
        totalPerDiem +
        totalMaterials +
        totalInstruments;
  }
  double get overheadAmount => subTotal * (overheadPercentage / 100);
  double get totalPlusOverhead => subTotal + overheadAmount;
  double get profitAmount => totalPlusOverhead * (profitPercentage / 100);
  double get totalSaleV2 => totalPlusOverhead + profitAmount;
  double get unitPrice => quantity > 0 ? totalSaleV2 / quantity : 0;

  double get priceGap => targetPrice - totalSaleV2;
  double get priceGapPercent =>
      targetPrice > 0 ? (targetPrice - totalSaleV2).abs() / targetPrice * 100 : 0;
  String get gapStatus => targetPrice <= 0
      ? 'none'
      : priceGapPercent < 2
          ? 'green'
          : priceGapPercent < 10
              ? 'yellow'
              : 'red';
}

// ══════════════════════════════════════════════════════════════
//  MAIN DIALOG
// ══════════════════════════════════════════════════════════════

class QuoteFormDialog extends StatefulWidget {
  final Map<String, dynamic>? quoteToEdit;
  const QuoteFormDialog({super.key, this.quoteToEdit});
  @override
  State<QuoteFormDialog> createState() => _QuoteFormDialogState();
}

class _QuoteFormDialogState extends State<QuoteFormDialog> {
  int _currentStep = 0;
  bool _isSaving = false;
  bool _isLoadingData = false;

  // Step 0 - Quote Info
  late TextEditingController _titleController;
  late TextEditingController _clientController;
  DateTime _quoteDate = DateTime.now();
  String _selectedStatus = 'draft';
  String _quoteType = 'standard';
  String? _selectedClientAddress;

  // Catalogs for step 1+
  List<Map<String, dynamic>> _catalogServices = [];
  List<Map<String, dynamic>> _catalogMachinery = [];
  List<Map<String, dynamic>> _catalogLaborRoles = [];
  List<Map<String, dynamic>> _catalogMaterials = [];
  List<Map<String, dynamic>> _catalogInstruments = [];
  List<Map<String, dynamic>> _catalogCustomers = [];

  // Step 1+ - Services
  List<ServiceEntry> _services = [];
  int _activeServiceIndex = 0;

  final _currencyFormat = NumberFormat('#,##0.00', 'en_US');

  bool get _isEditing => widget.quoteToEdit != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.quoteToEdit?['title'] ?? '',
    );
    _clientController = TextEditingController(
      text: widget.quoteToEdit?['client_name'] ?? '',
    );
    if (widget.quoteToEdit?['quote_date'] != null) {
      _quoteDate =
          DateTime.tryParse(widget.quoteToEdit!['quote_date']) ??
          DateTime.now();
    }
    _selectedStatus = widget.quoteToEdit?['status'] ?? 'draft';
    _quoteType = widget.quoteToEdit?['quote_type'] ?? 'standard';
    _selectedClientAddress = widget.quoteToEdit?['client_address'];

    _loadCatalogs();
    if (_isEditing) {
      _loadExistingData();
    } else {
      _services.add(ServiceEntry(name: _quoteType == 'staffing' ? 'Role 1' : 'Service 1', unitOfMeasure: _quoteType == 'staffing' ? 'hr' : 'und', isStaffingRole: _quoteType == 'staffing'));
    }
  }

  void _syncMachineryFromEstimation(
    ServiceEntry svc,
    Map<String, dynamic> result,
  ) {
    // 1. Calculate duration in months (using the same logic as the result card)
    final start = result['start_date'] as DateTime;
    final end = result['end_date'] as DateTime;
    final calendarDays = end.difference(start).inDays + 1;
    final months = double.parse((calendarDays / 30.44).toStringAsFixed(1));

    // 2. Fetch resources from estimation result
    final resources = result['resources'] as List;
    if (resources.isEmpty) return;

    // 3. Clear existing machineries if they were default/empty
    if (svc.machineries.isEmpty ||
        (svc.machineries.length == 1 &&
            svc.machineries[0].machineName.isEmpty)) {
      svc.machineries.clear();
    }

    final newMachineries = <MachineryEntry>[];
    final oldMachineries = List<MachineryEntry>.from(svc.machineries);

    for (final res in resources) {
      final machineId = res['machine_id'];
      final machineName = res['machine_name'] ?? '';
      final isPrimary = res['is_primary_mover'] as bool? ?? true;

      String? parentName;
      if (res['parent_resource_id'] != null) {
        final pRes = resources.firstWhere(
          (r) => r['id'] == res['parent_resource_id'],
          orElse: () => <String, dynamic>{},
        );
        parentName = pRes['machine_name'];
      }

      // Find in oldMachineries
      int matchIdx = oldMachineries.indexWhere(
        (m) =>
            m.machineName == machineName &&
            m.isPrimaryMover == isPrimary &&
            m.parentMachineName == parentName,
      );
      if (matchIdx < 0) {
        matchIdx = oldMachineries.indexWhere(
          (m) => m.machineName == machineName,
        );
      }

      if (matchIdx >= 0) {
        final m = oldMachineries[matchIdx];
        oldMachineries.removeAt(matchIdx); // claim it
        m.monthsToUse = months;
        m.quantity = (res['quantity'] as num).toDouble();
        m.isPrimaryMover = isPrimary;
        m.parentMachineName = parentName;
        newMachineries.add(m);
      } else {
        // Find in catalog for default costs
        final catalogItem = _catalogMachinery.firstWhere(
          (m) => m['id'] == machineId || m['description'] == machineName,
          orElse: () => <String, dynamic>{},
        );

        newMachineries.add(
          MachineryEntry(
            machineName: machineName,
            monthsToUse: months,
            quantity: (res['quantity'] as num).toDouble(),
            // Defaults or catalog values
            monthlyRentCost:
                (catalogItem['monthly_rent_cost'] as num?)?.toDouble() ?? 0,
            gallonsPerHour:
                (catalogItem['fuel_gallons'] as num?)?.toDouble() ?? 0,
            gallonCost:
                (catalogItem['gallon_cost'] as num?)?.toDouble() ?? 5.25,
            deliveryCost:
                (catalogItem['delivery_cost'] as num?)?.toDouble() ?? 0,
            isPrimaryMover: isPrimary,
            parentMachineName: parentName,
          ),
        );
      }
    }

    // Replace current machineries with the new reconstructed list
    svc.machineries.clear();
    svc.machineries.addAll(newMachineries);

    // Sort to keep hierarchy: Primary followed by its supports
    final sortedList = <MachineryEntry>[];
    final primaries = svc.machineries.where((m) => m.isPrimaryMover).toList();
    for (var p in primaries) {
      sortedList.add(p);
      sortedList.addAll(
        svc.machineries.where(
          (m) => !m.isPrimaryMover && m.parentMachineName == p.machineName,
        ),
      );
    }
    // Append any unassigned supports
    sortedList.addAll(
      svc.machineries.where(
        (m) =>
            !m.isPrimaryMover &&
            !primaries.any((p) => p.machineName == m.parentMachineName),
      ),
    );

    svc.machineries.clear();
    svc.machineries.addAll(sortedList);

    // --- 4. Sync Labor (Operators) ---
    final List<LaborEntry> autoLabors = [];
    for (final res in resources) {
      final roleId = res['operator_role_id'];
      if (roleId != null) {
        // Look up the role in catalog
        final role = _catalogLaborRoles.firstWhere(
          (r) => r['id'].toString() == roleId.toString(),
          orElse: () => <String, dynamic>{},
        );

        if (role.isNotEmpty) {
          final roleName = role['description'] ?? '';
          final qty = (res['quantity'] as num).toDouble();

          int existingIdx = autoLabors.indexWhere(
            (l) => l.roleName == roleName,
          );
          if (existingIdx >= 0) {
            autoLabors[existingIdx].employeesQuantity += qty;
            if (months > autoLabors[existingIdx].monthsToWork) {
              autoLabors[existingIdx].monthsToWork = months;
            }
          } else {
            autoLabors.add(
              LaborEntry(
                roleName: roleName,
                monthsToWork: months,
                employeesQuantity: qty,
                hourlyRate: (role['hourly_rate'] as num?)?.toDouble() ?? 0,
                perDiem: (role['per_diem'] as num?)?.toDouble() ?? 0,
              ),
            );
          }
        }
      }
    }

    // Merge with manual labors (keeping roles that are NOT auto-generated to avoid deleting manual entries like 'Helper')
    final finalLabors = <LaborEntry>[];
    finalLabors.addAll(autoLabors);

    for (final existing in svc.labors) {
      // If this manual labor role is NOT one of the machine operators, preserve it
      if (!autoLabors.any((l) => l.roleName == existing.roleName)) {
        finalLabors.add(existing);
      }
    }

    svc.labors.clear();
    svc.labors.addAll(finalLabors);

    setState(() {});
  }

  void _syncMaterialsFromEstimation(
    ServiceEntry svc,
    Map<String, dynamic> result,
  ) {
    final estMaterials = result['materials'] as List?;
    if (estMaterials == null || estMaterials.isEmpty) return;

    // Clear if it's the default empty state
    if (svc.materials.isEmpty ||
        (svc.materials.length == 1 && svc.materials[0].materialName.isEmpty)) {
      svc.materials.clear();
    }

    for (final em in estMaterials) {
      final String? catId = em['material_id']?.toString();
      final String name = em['material_name'] ?? '';

      // Look for existing to update or add new
      final existingIdx = svc.materials.indexWhere(
        (m) => m.catalogId == catId || m.materialName == name,
      );

      if (existingIdx != -1) {
        svc.materials[existingIdx].quantity = (em['quantity'] as num)
            .toDouble();
        svc.materials[existingIdx].unitPrice = (em['unit_price'] as num)
            .toDouble();
        svc.materials[existingIdx].unit = em['unit'] ?? 'und';
      } else {
        svc.materials.add(
          MaterialEntry(
            catalogId: catId,
            materialName: name,
            quantity: (em['quantity'] as num).toDouble(),
            unitPrice: (em['unit_price'] as num).toDouble(),
            unit: em['unit'] ?? 'und',
          ),
        );
      }
    }
    setState(() {});
  }

  void _syncInstrumentsFromEstimation(
    ServiceEntry svc,
    Map<String, dynamic> result,
  ) {
    final estInstruments = result['instruments'] as List?;
    if (estInstruments == null || estInstruments.isEmpty) return;

    // We replace instruments to match the estimation dialog's state exactly
    svc.instruments.clear();
    for (final ei in estInstruments) {
      svc.instruments.add(
        InstrumentEntry(
          catalogId: ei['instrument_id']?.toString(),
          instrumentName: ei['instrument_name'] ?? '',
          quantity: (ei['quantity'] as num).toDouble(),
          days: (ei['days'] as num?)?.toDouble() ?? 1.0,
          unitPrice: (ei['unit_price'] as num).toDouble(),
          notes: ei['notes'],
        ),
      );
    }
    setState(() {});
  }

  Future<void> _loadCatalogs() async {
    try {
      final supabase = Supabase.instance.client;
      final svcs = await supabase
          .from('services')
          .select()
          .order('description');
      final mach = await supabase
          .from('machinery')
          .select()
          .order('description');
      final labr = await supabase
          .from('labor_roles')
          .select()
          .order('description');
      final matr = await supabase
          .from('materials')
          .select()
          .order('description');
      final inst = await supabase
          .from('logistics_equipment')
          .select()
          .order('description');
      final cust = await supabase
          .from('customers')
          .select()
          .order('name');

      if (mounted) {
        setState(() {
          _catalogServices = List<Map<String, dynamic>>.from(svcs ?? []);
          _catalogMachinery = List<Map<String, dynamic>>.from(mach ?? []);
          _catalogLaborRoles = List<Map<String, dynamic>>.from(labr ?? []);
          _catalogMaterials = List<Map<String, dynamic>>.from(matr ?? []);
          _catalogInstruments = List<Map<String, dynamic>>.from(inst ?? []);
          _catalogCustomers = List<Map<String, dynamic>>.from(cust ?? []).map((c) => {
            ...c,
            'description': c['name'],
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading catalogs: $e');
    }
  }

  Future<void> _loadExistingData() async {
    setState(() => _isLoadingData = true);
    try {
      final supabase = Supabase.instance.client;
      final quoteId = widget.quoteToEdit!['id'];

      // Load services for this quote
      final responseServices = await supabase
          .from('quote_services')
          .select()
          .eq('quote_id', quoteId)
          .order('created_at');

      final servicesData = List<Map<String, dynamic>>.from(
        responseServices ?? [],
      );
      final loadedServices = <ServiceEntry>[];

      for (final svcData in servicesData) {
        final svcId = svcData['id'];

        // Load estimation for this service
        final responseEst = await supabase
            .from('quote_service_estimations')
            .select()
            .eq('quote_service_id', svcId)
            .maybeSingle();

        Map<String, dynamic>? estimationData;
        if (responseEst != null) {
          final estId = responseEst['id'];
          final responseRes = await supabase
              .from('quote_service_estimation_resources')
              .select(
                '*, machinery(description, capacity, default_trips_per_day, photo_url, machinery_type)',
              )
              .eq('estimation_id', estId);

          final resources = (responseRes as List)
              .map(
                (r) => {
                  'id': r['id'],
                  'is_primary_mover': r['is_primary_mover'] ?? true,
                  'parent_resource_id': r['parent_resource_id'],
                  'machine_id': r['machine_id'],
                  'machine_name': r['machinery']?['description'] ?? 'Unknown',
                  'photo_url': r['machinery']?['photo_url'],
                  'machinery_type':
                      r['machinery']?['machinery_type'] ?? 'hauling',
                  'quantity': (r['quantity'] as num).toDouble(),
                  'trips_per_day': (r['trips_per_day'] as num).toDouble(),
                  'capacity_per_trip': (r['capacity_per_trip'] as num)
                      .toDouble(),
                  'performance_per_day':
                      (r['performance_per_day'] as num?)?.toDouble() ?? 0.0,
                },
              )
              .toList();

          // Load materials for this service specifically for the estimation context if any
          final responseEstMat = await supabase
              .from('quote_service_materials')
              .select('*, materials(description, unit, yield_factor)')
              .eq('quote_service_id', svcId);

          final estMaterials = (responseEstMat as List)
              .map(
                (m) => {
                  'material_id': m['material_id'],
                  'material_name': m['material_name'],
                  'quantity': (m['quantity'] as num).toDouble(),
                  'unit_price': (m['unit_price'] as num).toDouble(),
                  'unit': m['unit_name'],
                },
              )
              .toList();

          estimationData = {
            'id': estId,
            'topsoil_volume': (responseEst['topsoil_volume'] as num).toDouble(),
            'compacted_volume': (responseEst['compacted_volume'] as num)
                .toDouble(),
            'swell_factor': (responseEst['swell_factor'] as num).toDouble(),
            'thickness_inches':
                (responseEst['thickness_inches'] as num?)?.toDouble() ?? 0.0,
            'gravel_thickness_inches':
                (responseEst['gravel_thickness_inches'] as num?)?.toDouble() ?? 0.0,
            'trench_width_inches':
                (responseEst['trench_width_inches'] as num?)?.toDouble() ?? 0.0,
            'trench_depth_inches':
                (responseEst['trench_depth_inches'] as num?)?.toDouble() ?? 0.0,
            'total_cy_loose': (responseEst['total_cy_loose'] as num).toDouble(),
            'working_days': (responseEst['total_working_days'] as num).toInt(),
            'start_date': DateTime.parse(responseEst['start_date']),
            'end_date': responseEst['end_date'] != null
                ? DateTime.parse(responseEst['end_date'])
                : null,
            'resources': resources,
            'materials': estMaterials,
          };
        }

        // Load machineries for this service
        final responseMach = await supabase
            .from('quote_service_machineries')
            .select()
            .eq('quote_service_id', svcId);

        final machData = List<Map<String, dynamic>>.from(responseMach ?? []);

        final machineries = machData
            .map<MachineryEntry>(
              (m) => MachineryEntry(
                machineName: m['machine_name'] ?? '',
                monthsToUse: (m['months_to_use'] as num?)?.toDouble() ?? 0,
                monthlyRentCost:
                    (m['monthly_rent_cost'] as num?)?.toDouble() ?? 0,
                quantity: (m['quantity'] as num?)?.toDouble() ?? 1,
                gallonsPerHour:
                    (m['gallons_per_hour'] as num?)?.toDouble() ?? 0,
                gallonCost: (m['gallon_cost'] as num?)?.toDouble() ?? 0,
                deliveryCost: (m['delivery_cost'] as num?)?.toDouble() ?? 0,
                isPrimaryMover: m['is_primary_mover'] as bool? ?? true,
                parentMachineName: m['parent_machine_name'] as String?,
              ),
            )
            .toList();

        // Load labors for this service
        final responseLabor = await supabase
            .from('quote_service_labors')
            .select()
            .eq('quote_service_id', svcId);

        final laborData = List<Map<String, dynamic>>.from(responseLabor ?? []);

        final labors = laborData
            .map<LaborEntry>(
              (l) => LaborEntry(
                roleName: l['role_name'] ?? '',
                monthsToWork: (l['months_to_work'] as num?)?.toDouble() ?? 0,
                employeesQuantity:
                    (l['employees_quantity'] as num?)?.toDouble() ?? 1,
                hourlyRate: (l['hourly_rate'] as num?)?.toDouble() ?? 0,
                perDiem: (l['per_diem'] as num?)?.toDouble() ?? 0,
              ),
            )
            .toList();

        // Load materials for this service
        final responseMat = await supabase
            .from('quote_service_materials')
            .select()
            .eq('quote_service_id', svcId);

        final matData = List<Map<String, dynamic>>.from(responseMat ?? []);
        final materials = matData
            .map<MaterialEntry>(
              (m) => MaterialEntry(
                materialName: m['material_name'] ?? '',
                quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
                unitPrice: (m['unit_price'] as num?)?.toDouble() ?? 0,
                unit: m['unit_name'] ?? 'und',
                catalogId: m['material_id']?.toString(),
              ),
            )
            .toList();

        // Load instruments for this service
        final responseInst = await supabase
            .from('quote_service_instruments')
            .select()
            .eq('quote_service_id', svcId);

        final instData = List<Map<String, dynamic>>.from(responseInst ?? []);
        final instruments = instData
            .map<InstrumentEntry>(
              (i) => InstrumentEntry(
                instrumentName: i['instrument_name'] ?? '',
                quantity: (i['quantity'] as num?)?.toDouble() ?? 1,
                unitPrice: (i['unit_price'] as num?)?.toDouble() ?? 0,
                days: (i['days'] as num?)?.toDouble() ?? 1,
                catalogId: i['instrument_id']?.toString(),
                notes: i['notes'],
              ),
            )
            .toList();

        loadedServices.add(
          ServiceEntry(
            name: svcData['name'] ?? '',
            unitOfMeasure: svcData['unit_of_measure'] ?? 'und',
            quantity: (svcData['quantity'] as num?)?.toDouble() ?? 1,
            overheadPercentage:
                (svcData['overhead_percentage'] as num?)?.toDouble() ?? 0,
            profitPercentage:
                (svcData['profit_percentage'] as num?)?.toDouble() ?? 0,
            directCost: (svcData['direct_cost'] as num?)?.toDouble() ?? 0,
            targetPrice: (svcData['target_price'] as num?)?.toDouble() ?? 0,
            isStaffingRole: _quoteType == 'staffing',
            machineries: machineries,  // _loadExistingData
            labors: labors,
            materials: materials,
            instruments: instruments,
            estimationData: estimationData,
            catalogId: svcData['service_id']
                ?.toString(), // Map it if it exists in DB, otherwise we match by name below
          )..dbId = svcId,
        );
      }

      // Fallback: If catalogId is null (e.g. old data), try to match by name
      for (final s in loadedServices) {
        if (s.catalogId == null) {
          final cat = _catalogServices.firstWhere(
            (c) => c['description'] == s.name,
            orElse: () => {},
          );
          if (cat.isNotEmpty) s.catalogId = cat['id']?.toString();
        }
      }

      setState(() {
        _services = loadedServices.isEmpty
            ? [ServiceEntry(name: 'Service 1')]
            : loadedServices;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _services = [ServiceEntry(name: 'Service 1')];
        _isLoadingData = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading data: $e',
              style: GoogleFonts.manrope(),
            ),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _clientController.dispose();
    super.dispose();
  }

  // ── Save to Supabase ──
  Future<void> _persistQuote({required bool closeDialog}) async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter an estimate title',
            style: GoogleFonts.manrope(),
          ),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      setState(() => _currentStep = 0);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final supabase = Supabase.instance.client;
      String quoteId;

      double totalAmount = 0;
      for (final svc in _services) {
        totalAmount += svc.totalSaleV2;
      }

      if (_isEditing) {
        await supabase
            .from('quotes')
            .update({
              'title': _titleController.text.trim(),
              'client_name': _clientController.text.trim(),
              'client_address': _selectedClientAddress,
              'total_amount': totalAmount,
              'quote_date': _quoteDate.toIso8601String().split('T')[0],
              'status': _selectedStatus,
              'quote_type': _quoteType,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', widget.quoteToEdit!['id']);
        quoteId = widget.quoteToEdit!['id'];
      } else {
        final result = await supabase
            .from('quotes')
            .insert({
              'title': _titleController.text.trim(),
              'client_name': _clientController.text.trim(),
              'client_address': _selectedClientAddress,
              'total_amount': totalAmount,
              'quote_date': _quoteDate.toIso8601String().split('T')[0],
              'status': _selectedStatus,
              'quote_type': _quoteType,
            })
            .select()
            .single();
        quoteId = result['id'];
      }

      // Insert or update services, machineries, labors
      for (final svc in _services) {
        final String svcId;
        if (svc.dbId != null) {
          svcId = svc.dbId!;
          await supabase
              .from('quote_services')
              .update({
                'name': svc.name,
                'unit_of_measure': svc.unitOfMeasure,
                'quantity': svc.quantity,
                'overhead_percentage': svc.overheadPercentage,
                'profit_percentage': svc.profitPercentage,
                'direct_cost': svc.totalSaleV2,
                'target_price': svc.targetPrice,
              })
              .eq('id', svcId);

          // Delete old resource children to re-insert
          await supabase.from('quote_service_machineries').delete().eq('quote_service_id', svcId);
          await supabase.from('quote_service_labors').delete().eq('quote_service_id', svcId);
          await supabase.from('quote_service_materials').delete().eq('quote_service_id', svcId);
          await supabase.from('quote_service_instruments').delete().eq('quote_service_id', svcId);
          await supabase.from('quote_service_estimations').delete().eq('quote_service_id', svcId);
        } else {
          final svcResult = await supabase
              .from('quote_services')
              .insert({
                'quote_id': quoteId,
                'name': svc.name,
                'unit_of_measure': svc.unitOfMeasure,
                'quantity': svc.quantity,
                'overhead_percentage': svc.overheadPercentage,
                'profit_percentage': svc.profitPercentage,
                'direct_cost': svc.totalSaleV2,
                'target_price': svc.targetPrice,
              })
              .select()
              .single();
          svcId = svcResult['id'];
        }

        for (final m in svc.machineries) {
          await supabase.from('quote_service_machineries').insert({
            'quote_service_id': svcId,
            'machine_name': m.machineName,
            'months_to_use': m.monthsToUse,
            'monthly_rent_cost': m.monthlyRentCost,
            'quantity': m.quantity,
            'gallons_per_hour': m.gallonsPerHour,
            'gallon_cost': m.gallonCost,
            'delivery_cost': m.deliveryCost,
            'is_primary_mover': m.isPrimaryMover,
            'parent_machine_name': m.parentMachineName,
          });
        }

        for (final l in svc.labors) {
          await supabase.from('quote_service_labors').insert({
            'quote_service_id': svcId,
            'role_name': l.roleName,
            'months_to_work': l.monthsToWork,
            'employees_quantity': l.employeesQuantity,
            'hourly_rate': l.hourlyRate,
            'per_diem': l.perDiem,
          });
        }

        for (final m in svc.materials) {
          await supabase.from('quote_service_materials').insert({
            'quote_service_id': svcId,
            'material_id': m.catalogId,
            'material_name': m.materialName,
            'quantity': m.quantity,
            'unit_price': m.unitPrice,
            'unit_name': m.unit,
          });
        }

        for (final i in svc.instruments) {
          await supabase.from('quote_service_instruments').insert({
            'quote_service_id': svcId,
            'instrument_id': i.catalogId,
            'instrument_name': i.instrumentName,
            'quantity': i.quantity,
            'days': i.days,
            'unit_price': i.unitPrice,
            'notes': i.notes,
          });
        }

        // Save estimation data if exists
        if (svc.estimationData != null) {
          final est = svc.estimationData!;
          final estResult = await supabase
              .from('quote_service_estimations')
              .insert({
                'quote_service_id': svcId,
                'topsoil_volume': est['topsoil_volume'] ?? 0,
                'compacted_volume': est['compacted_volume'] ?? 0,
                'swell_factor': est['swell_factor'] ?? 0.15,
                'thickness_inches': est['thickness_inches'] ?? 0,
                'total_cy_loose': est['total_cy_loose'] ?? 0,
                'start_date': (est['start_date'] is String)
                    ? est['start_date']
                    : (est['start_date'] as DateTime).toIso8601String(),
                'end_date': est['end_date'] != null
                    ? ((est['end_date'] is String)
                          ? est['end_date']
                          : (est['end_date'] as DateTime).toIso8601String())
                    : null,
                'total_working_days': est['working_days'] ?? 0,
              })
              .select()
              .single();

          final estId = estResult['id'];
          final resources = est['resources'] as List?;
          if (resources != null && resources.isNotEmpty) {
            // Phase 1: primaries
            final primaries = resources
                .where((r) => (r['is_primary_mover'] as bool? ?? true) == true)
                .toList();
            final supports = resources
                .where((r) => (r['is_primary_mover'] as bool? ?? true) == false)
                .toList();
            final Map<String, String> localToDbId = {};
            for (final r in primaries) {
              final localId = r['id']?.toString();
              final inserted = await supabase
                  .from('quote_service_estimation_resources')
                  .insert({
                    'estimation_id': estId,
                    'machine_id': r['machine_id'],
                    'quantity': r['quantity'] ?? 1,
                    'trips_per_day': r['trips_per_day'] ?? 60,
                    'capacity_per_trip': r['capacity_per_trip'] ?? 30,
                    'performance_per_day': r['performance_per_day'] ?? 0,
                    'is_primary_mover': true,
                    'parent_resource_id': null,
                  })
                  .select()
                  .single();
              if (localId != null)
                localToDbId[localId] = inserted['id'] as String;
            }
            // Phase 2: supports
            if (supports.isNotEmpty) {
              await supabase
                  .from('quote_service_estimation_resources')
                  .insert(
                    supports.map((r) {
                      final lp = r['parent_resource_id']?.toString();
                      return {
                        'estimation_id': estId,
                        'machine_id': r['machine_id'],
                        'quantity': r['quantity'] ?? 1,
                        'trips_per_day': 0,
                        'capacity_per_trip': 0,
                        'performance_per_day': r['performance_per_day'] ?? 0,
                        'is_primary_mover': false,
                        'parent_resource_id': lp != null
                            ? localToDbId[lp]
                            : null,
                      };
                    }).toList(),
                  );
            }
          }

          // Save materials from estimation to service materials if needed
          final estimationMaterials = est['materials'] as List?;
          if (estimationMaterials != null && estimationMaterials.isNotEmpty) {
            for (final em in estimationMaterials) {
              // Only add if not already in svc.materials by catalogId
              if (!svc.materials.any(
                (m) => m.catalogId?.toString() == em['material_id']?.toString(),
              )) {
                svc.materials.add(
                  MaterialEntry(
                    catalogId: em['material_id']?.toString(),
                    materialName: em['material_name'] ?? '',
                    quantity: (em['quantity'] as num?)?.toDouble() ?? 0,
                    unitPrice: (em['unit_price'] as num?)?.toDouble() ?? 0,
                    unit: em['unit'] ?? 'und',
                  ),
                );
              }
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              closeDialog
                  ? (_isEditing ? 'Estimation updated!' : 'Estimation created!')
                  : 'Draft saved!',
              style: GoogleFonts.manrope(color: Colors.white),
            ),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        if (closeDialog) {
          Navigator.of(context).pop(true);
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: 900,
            maxHeight: MediaQuery.of(context).size.height * 0.95,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildWizardHeader(),
              _buildStepIndicator(),
              Expanded(
                child: _isLoadingData
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen,
                          strokeWidth: 3,
                        ),
                      )
                    : _buildCurrentStepContent(),
              ),
              _buildWizardFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Wizard Header ──
  Widget _buildWizardHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isEditing ? Icons.edit_outlined : Icons.request_quote_outlined,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit Estimate' : 'Create New Estimate',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.slate900,
                  ),
                ),
                Text(
                  _stepSubtitle(),
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppTheme.slate500,
                  ),
                ),
              ],
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(
                Icons.close,
                color: AppTheme.slate400,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _stepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Step 1 of 6 — Basic Information';
      case 1:
        return 'Step 2 of 6 — Services & Machinery';
      case 2:
        return 'Step 3 of 6 — Labor & Workforce';
      case 3:
        return 'Step 4 of 6 — Project Materials';
      case 4:
        return 'Step 5 of 6 — Instruments & Tools';
      case 5:
        return 'Step 6 de 6 — Summary & Profit';
      default:
        return '';
    }
  }

  // ── Step Indicator ──
  Widget _buildStepIndicator() {
    final bool allServicesAreLS = _services.isNotEmpty && _services.every((s) => s.unitOfMeasure.toLowerCase() == 'ls' || s.isStaffingRole);
    final steps = ['Info', 'Machinery', 'Labor', 'Materials', 'Tools', 'Summary'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone
                          ? AppTheme.primaryGreen
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                GestureDetector(
                  onTap: () {
                    if (allServicesAreLS && i >= 1 && i <= 4) return;
                    setState(() => _currentStep = i);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? AppTheme.primaryGreen
                          : isDone
                          ? AppTheme.primaryGreen.withOpacity(0.15)
                          : const Color(0xFFE2E8F0),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(
                              Icons.check,
                              color: AppTheme.primaryGreen,
                              size: 16,
                            )
                          : Text(
                              '${i + 1}',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isActive
                                    ? Colors.white
                                    : AppTheme.slate500,
                              ),
                            ),
                    ),
                  ),
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone
                          ? AppTheme.primaryGreen
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Template Copy ──
  Future<void> _showQuoteTemplatePicker() async {
    final supabase = Supabase.instance.client;
    List<Map<String, dynamic>> quotes;
    try {
      final response = await supabase
          .from('quotes')
          .select('id, title, client_name, quote_date, total_amount, status, quote_type')
          .order('created_at', ascending: false)
          .limit(100);
      quotes = List<Map<String, dynamic>>.from(response ?? []);
    } catch (_) {
      quotes = [];
    }
    if (!mounted) return;

    final searchCtrl = TextEditingController();
    String query = '';

    final result = await showSafeDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Copy from Existing Estimate', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800)),
          content: SizedBox(
            width: 600,
            height: 480,
            child: Column(
              children: [
                TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by title or client...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { searchCtrl.clear(); setDialogState(() => query = ''); })
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  onChanged: (v) => setDialogState(() => query = v.toLowerCase().trim()),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: quotes.isEmpty
                      ? Center(child: Text('No existing estimates found', style: GoogleFonts.manrope(color: AppTheme.slate400)))
                      : ListView.separated(
                          itemCount: quotes.where((q) {
                            if (query.isEmpty) return true;
                            return (q['title'] ?? '').toString().toLowerCase().contains(query) ||
                                (q['client_name'] ?? '').toString().toLowerCase().contains(query);
                          }).length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final filtered = quotes.where((q) {
                              if (query.isEmpty) return true;
                              return (q['title'] ?? '').toString().toLowerCase().contains(query) ||
                                  (q['client_name'] ?? '').toString().toLowerCase().contains(query);
                            }).toList();
                            final q = filtered[index];
                            final title = q['title'] ?? 'Untitled';
                            final client = q['client_name'] ?? '—';
                            final date = q['quote_date'] as String?;
                            final dateFormatted = date != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(date)) : '—';
                            final amount = (q['total_amount'] as num?)?.toDouble() ?? 0;
                            final type = q['quote_type'] ?? 'standard';
                            final typeLabel = type == 'staffing' ? 'Labor Supply' : 'Standard';
                            final f = NumberFormat('#,##0');

                            return ListTile(
                              dense: true,
                              leading: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: type == 'staffing' ? Colors.amber.withAlpha(20) : AppTheme.primaryGreen.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  type == 'staffing' ? Icons.people_outline : Icons.engineering_outlined,
                                  color: type == 'staffing' ? Colors.amber : AppTheme.primaryGreen,
                                  size: 20,
                                ),
                              ),
                              title: Text(title, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$client · $dateFormatted · $typeLabel', style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate500)),
                                  if (amount > 0) Text('\$ ${f.format(amount)}', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.slate900)),
                                ],
                              ),
                              trailing: TextButton(
                                onPressed: () => Navigator.pop(ctx, q),
                                child: Text('Copy', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: AppTheme.slate500))),
          ],
        ),
      ),
    );

    searchCtrl.dispose();
    if (result != null && mounted) {
      await _populateFromTemplate(result['id'] as String);
    }
  }

  Future<void> _populateFromTemplate(String quoteId) async {
    setState(() => _isLoadingData = true);
    try {
      final supabase = Supabase.instance.client;
      final quotesService = QuotesService(supabase);
      final full = await quotesService.getFullQuoteForTemplate(quoteId);
      if (full == null || !mounted) { setState(() => _isLoadingData = false); return; }

      final type = full['quote_type'] ?? 'standard';
      _quoteType = type == 'staffing' ? 'staffing' : 'standard';
      _titleController.text = '';
      _clientController.text = '';
      _quoteDate = DateTime.now();
      _selectedStatus = 'draft';
      _selectedClientAddress = null;

      final servicesList = full['services'] as List? ?? [];
      final loadedServices = <ServiceEntry>[];
      for (final svc in servicesList) {
        final svcData = svc as Map<String, dynamic>;

        final machList = svcData['machineries'] as List? ?? [];
        final machineries = machList.map<MachineryEntry>((m) => MachineryEntry(
          machineName: m['machine_name'] ?? '',
          monthsToUse: (m['months_to_use'] as num?)?.toDouble() ?? 0,
          monthlyRentCost: (m['monthly_rent_cost'] as num?)?.toDouble() ?? 0,
          quantity: (m['quantity'] as num?)?.toDouble() ?? 1,
          gallonsPerHour: (m['gallons_per_hour'] as num?)?.toDouble() ?? 0,
          gallonCost: (m['gallon_cost'] as num?)?.toDouble() ?? 0,
          deliveryCost: (m['delivery_cost'] as num?)?.toDouble() ?? 0,
          isPrimaryMover: m['is_primary_mover'] as bool? ?? true,
          parentMachineName: m['parent_machine_name'] as String?,
        )).toList();

        final laborList = svcData['labors'] as List? ?? [];
        final labors = laborList.map<LaborEntry>((l) => LaborEntry(
          roleName: l['role_name'] ?? '',
          monthsToWork: (l['months_to_work'] as num?)?.toDouble() ?? 0,
          employeesQuantity: (l['employees_quantity'] as num?)?.toDouble() ?? 1,
          hourlyRate: (l['hourly_rate'] as num?)?.toDouble() ?? 0,
          perDiem: (l['per_diem'] as num?)?.toDouble() ?? 0,
        )).toList();

        final matList = svcData['materials'] as List? ?? [];
        final materials = matList.map<MaterialEntry>((m) => MaterialEntry(
          materialName: m['material_name'] ?? '',
          quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
          unitPrice: (m['unit_price'] as num?)?.toDouble() ?? 0,
          unit: m['unit_name'] ?? 'und',
          catalogId: m['material_id']?.toString(),
        )).toList();

        final instList = svcData['instruments'] as List? ?? [];
        final instruments = instList.map<InstrumentEntry>((i) => InstrumentEntry(
          instrumentName: i['instrument_name'] ?? '',
          quantity: (i['quantity'] as num?)?.toDouble() ?? 1,
          unitPrice: (i['unit_price'] as num?)?.toDouble() ?? 0,
          days: (i['days'] as num?)?.toDouble() ?? 1,
          catalogId: i['instrument_id']?.toString(),
          notes: i['notes'],
        )).toList();

        final est = svcData['estimation'] as Map<String, dynamic>?;
        final estResources = svcData['estimation_resources'] as List? ?? [];
        Map<String, dynamic>? estimationData;
        if (est != null) {
          estimationData = {
            'id': null,
            'topsoil_volume': est['topsoil_volume'],
            'compacted_volume': est['compacted_volume'],
            'swell_factor': est['swell_factor'],
            'total_cy_loose': est['total_cy_loose'],
            'start_date': est['start_date'] != null ? DateTime.parse(est['start_date'].toString()) : DateTime.now(),
            'end_date': est['end_date'] != null ? DateTime.parse(est['end_date'].toString()) : null,
            'total_working_days': est['total_working_days'],
            'working_days': est['total_working_days'],
            'workingDays': est['total_working_days'],
            'thickness_inches': est['thickness_inches'],
            'gravel_thickness_inches': est['gravel_thickness_inches'],
            'trench_width_inches': est['trench_width_inches'],
            'trench_depth_inches': est['trench_depth_inches'],
            'calculated_loose': est['total_cy_loose'],
            'resources': estResources,
            'materials': matList,
          };
        }

        String? catalogId = svcData['service_id']?.toString();

        loadedServices.add(ServiceEntry(
          name: svcData['name'] ?? '',
          unitOfMeasure: svcData['unit_of_measure'] ?? 'und',
          quantity: (svcData['quantity'] as num?)?.toDouble() ?? 1,
          overheadPercentage: (svcData['overhead_percentage'] as num?)?.toDouble() ?? 0,
          profitPercentage: (svcData['profit_percentage'] as num?)?.toDouble() ?? 0,
          directCost: (svcData['direct_cost'] as num?)?.toDouble() ?? 0,
          targetPrice: (svcData['target_price'] as num?)?.toDouble() ?? 0,
          isStaffingRole: _quoteType == 'staffing',
          machineries: machineries,  // _populateFromTemplate
          labors: labors,
          materials: materials,
          instruments: instruments,
          estimationData: estimationData,
          catalogId: catalogId,
        ));
      }

      for (final s in loadedServices) {
        if (s.catalogId == null) {
          final cat = _catalogServices.firstWhere(
            (c) => c['description'] == s.name,
            orElse: () => {},
          );
          if (cat.isNotEmpty) s.catalogId = cat['id']?.toString();
        }
      }

      setState(() {
        _services = loadedServices.isEmpty
            ? [ServiceEntry(name: 'Service 1')]
            : loadedServices;
        if (_services.isNotEmpty) _activeServiceIndex = 0;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _services = [ServiceEntry(name: 'Service 1')];
        _isLoadingData = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading template: $e', style: GoogleFonts.manrope()), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  Widget _buildTemplateBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _showQuoteTemplatePicker,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withAlpha(10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primaryGreen.withAlpha(30)),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppTheme.primaryGreen.withAlpha(20), shape: BoxShape.circle),
                child: const Icon(Icons.file_copy_outlined, color: AppTheme.primaryGreen, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Copy from existing estimate', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
                    Text('Start with a proven quote configuration — services, resources and prices', style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate500)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.primaryGreen),
            ],
          ),
        ),
      ),
    );
  }

  // ── Target Price Gap ──

  Widget _buildTargetPriceMini(ServiceEntry svc) {
    final gap = svc.priceGap;
    final pct = svc.priceGapPercent;
    final color = svc.gapStatus == 'green'
        ? AppTheme.primaryGreen
        : svc.gapStatus == 'yellow'
            ? Colors.orange
            : AppTheme.errorRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            gap <= 0 ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12, color: color,
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${_currencyFormat.format(gap.abs())}',
                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: color),
              ),
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLevers(ServiceEntry svc) {
    if (svc.targetPrice <= 0 || svc.gapStatus == 'green') return const SizedBox.shrink();

    final gap = svc.priceGap;
    final suggestions = <_LeverSuggestion>[];

    if (svc.profitAmount > 0) {
      final newProfit = (((svc.profitAmount + gap) / svc.totalPlusOverhead) * 100)
          .clamp(5.0, 35.0);
      suggestions.add(_LeverSuggestion(
        label: 'Profit \u2192 ${newProfit.toStringAsFixed(1)}%',
        icon: Icons.trending_down,
        action: () => setState(() => svc.profitPercentage = newProfit),
      ));
    }

    if (svc.overheadAmount > 0 && suggestions.length < 2) {
      final newOH = (((svc.overheadAmount + gap) / svc.subTotal) * 100)
          .clamp(5.0, 25.0);
      suggestions.add(_LeverSuggestion(
        label: 'OH \u2192 ${newOH.toStringAsFixed(1)}%',
        icon: Icons.trending_down,
        action: () => setState(() => svc.overheadPercentage = newOH),
      ));
    }

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Quick fix:', style: GoogleFonts.manrope(fontSize: 10, color: AppTheme.slate400)),
          const SizedBox(width: 6),
          ...suggestions.map((s) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: s.action,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.withAlpha(40)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(s.icon, size: 12, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(s.label, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.orange)),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  // ── Step Content ──
  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep0Info();
      case 1:
        return _buildStep1Machinery();
      case 2:
        return _buildStep2Labor();
      case 3:
        return _buildStep3Materials();
      case 4:
        return _buildStep4Instruments();
      case 5:
        return _buildStep5Summary();
      default:
        return const SizedBox.shrink();
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  STEP 0: BASIC INFO
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep0Info() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isEditing) _buildTemplateBanner(),
          _sectionTitle('Estimate Details'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _labeledField(
                  'Quote Type',
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _quoteType = 'standard';
                                if (!_isEditing && _services.length == 1 && _services.first.name.startsWith('Role')) {
                                  _services.first.name = 'Service 1';
                                  _services.first.unitOfMeasure = 'und';
                                  _services.first.isStaffingRole = false;
                                }
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: _quoteType == 'standard' ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                              ),
                              alignment: Alignment.center,
                              child: Text('Standard Project', style: GoogleFonts.manrope(fontSize: 13, fontWeight: _quoteType == 'standard' ? FontWeight.w700 : FontWeight.w500, color: _quoteType == 'standard' ? AppTheme.primaryGreen : AppTheme.slate600)),
                            ),
                          ),
                        ),
                        Container(width: 1, color: const Color(0xFFE2E8F0)),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _quoteType = 'staffing';
                                if (!_isEditing && _services.length == 1 && _services.first.name.startsWith('Service')) {
                                  _services.first.name = 'Role 1';
                                  _services.first.unitOfMeasure = 'hr';
                                  _services.first.isStaffingRole = true;
                                }
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: _quoteType == 'staffing' ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                              ),
                              alignment: Alignment.center,
                              child: Text('Labor Supply', style: GoogleFonts.manrope(fontSize: 13, fontWeight: _quoteType == 'staffing' ? FontWeight.w700 : FontWeight.w500, color: _quoteType == 'staffing' ? AppTheme.primaryGreen : AppTheme.slate600)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _labeledField(
                  'Estimate Title',
                  TextFormField(
                    controller: _titleController,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppTheme.slate900,
                    ),
                    decoration: _inputDeco(
                      'e.g. Golf Course Renovation Phase 1',
                      Icons.description_outlined,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SearchableCatalogDropdown(
                  label: 'Client / Customer',
                  items: _catalogCustomers,
                  initialValue: _clientController.text,
                  onSelected: (val, item) {
                    _clientController.text = val;
                    _selectedClientAddress = item?['address'];
                  },
                  onAddNew: () => _openCatalogItemAdd('customers'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _labeledField(
                  'Estimate Date',
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _quoteDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _quoteDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: AppTheme.slate400,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('MMM dd, yyyy').format(_quoteDate),
                            style: GoogleFonts.manrope(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _labeledField(
            'Status',
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: _inputDeco(null, Icons.flag_outlined),
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppTheme.slate900,
              ),
              items: ['draft', 'sent', 'accepted', 'rejected']
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s[0].toUpperCase() + s.substring(1)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedStatus = v);
              },
            ),
          ),
          const SizedBox(height: 28),
          _sectionTitle(_quoteType == 'staffing' ? 'Labor Roles' : 'Services'),
          const SizedBox(height: 12),
          ..._services.asMap().entries.map(
            (e) => _buildServiceChip(e.key, e.value),
          ),
          const SizedBox(height: 12),
          _addButton(_quoteType == 'staffing' ? 'Add Role' : 'Add Service', () {
            setState(() {
              _services.add(
                ServiceEntry(name: _quoteType == 'staffing' ? 'Role ${_services.length + 1}' : 'Service ${_services.length + 1}', unitOfMeasure: _quoteType == 'staffing' ? 'hr' : 'und', isStaffingRole: _quoteType == 'staffing'),
              );
            });
          }),
        ],
      ),
    );
  }

  Widget _buildServiceChip(int serviceIndex, ServiceEntry svc) {
    final bool isSelected = _activeServiceIndex == serviceIndex;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Listener(
        onPointerDown: (_) {
          // Absolute capture of the touch event before it reaches children
          if (_activeServiceIndex != serviceIndex) {
            FocusScope.of(context).unfocus();
            setState(() => _activeServiceIndex = serviceIndex);
            print('Raw selection triggered for: $serviceIndex');
          }
        },
        behavior: HitTestBehavior.opaque,
        child: GestureDetector(
          onDoubleTap: () {
            setState(() {
              _activeServiceIndex = serviceIndex;
              _currentStep = 1;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryGreen.withOpacity(0.12)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryGreen
                    : const Color(0xFFE2E8F0),
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Selection Indicator
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : AppTheme.slate200,
                      width: isSelected ? 6 : 2,
                    ),
                    color: isSelected ? Colors.white : Colors.transparent,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // ── Left: Role/Service + Unit + Qty + UnitCost + Subtotal ──
                          SizedBox(
                            width: 160,
                            child: GestureDetector(
                              onTapDown: (_) => setState(
                                () => _activeServiceIndex = serviceIndex,
                              ),
                              child: _SearchableCatalogDropdown(
                                label: _quoteType == 'staffing' ? 'Role name' : 'Service name',
                                items: _quoteType == 'staffing' ? _catalogLaborRoles : _catalogServices,
                                excludeItems: _services
                                    .map((s) => s.name)
                                    .where((n) => n != svc.name)
                                    .toList(),
                                initialValue: svc.name,
                                onSelected: (val, item) {
                                  setState(() {
                                    _activeServiceIndex = serviceIndex;
                                    svc.name = val;
                                    if (item != null) {
                                      svc.catalogId = item['id']?.toString();
                                      if (item['unit'] != null) {
                                        svc.unitOfMeasure = item['unit'];
                                      }
                                      if (_quoteType == 'staffing' && item['hourly_rate'] != null) {
                                        svc.directCost = (item['hourly_rate'] as num).toDouble();
  }
}
                              });
                                },
                                onAddNew: () => _openCatalogItemAdd(_quoteType == 'staffing' ? 'labor' : 'services'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _miniField(
                            'Unit',
                            svc.unitOfMeasure,
                            48,
                            (v) => setState(() {
                              _activeServiceIndex = serviceIndex;
                              svc.unitOfMeasure = v;
                            }),
                            key: ValueKey('unit_${serviceIndex}_${svc.name}'),
                            onTap: () => setState(
                              () => _activeServiceIndex = serviceIndex,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _miniNumField(
                            'Qty',
                            svc.quantity,
                            80,
                            (v) => setState(() {
                              _activeServiceIndex = serviceIndex;
                              svc.quantity = v;
                            }),
                            onTap: () => setState(
                              () => _activeServiceIndex = serviceIndex,
                            ),
                          ),
                          if (svc.unitOfMeasure.toLowerCase() == 'ls' || svc.isStaffingRole) ...[
                            const SizedBox(width: 10),
                            _miniNumField(
                              'Unit Cost (\$)',
                              svc.directCost,
                              90,
                              (v) => setState(() {
                                _activeServiceIndex = serviceIndex;
                                svc.directCost = v;
                              }),
                              onTap: () => setState(
                                () => _activeServiceIndex = serviceIndex,
                              ),
                            ),
                          ],
                          if (svc.isStaffingRole) ...[
                            const SizedBox(width: 10),
                            _calcChip(
                              'Subtotal',
                              svc.quantity * svc.directCost,
                            ),
                          ],
                          // ── Spacer pushes OH% and Profit% to the right ──
                          const Spacer(),
                          _miniNumField(
                            'OH%',
                            svc.overheadPercentage,
                            48,
                            (v) => setState(() {
                              _activeServiceIndex = serviceIndex;
                              svc.overheadPercentage = v;
                            }),
                            onTap: () => setState(
                              () => _activeServiceIndex = serviceIndex,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _miniNumField(
                            'Profit%',
                            svc.profitPercentage,
                            52,
                            (v) => setState(() {
                              _activeServiceIndex = serviceIndex;
                              svc.profitPercentage = v;
                            }),
                            onTap: () => setState(
                              () => _activeServiceIndex = serviceIndex,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _miniNumField(
                            'Target \$',
                            svc.targetPrice,
                            70,
                            (v) => setState(() {
                              _activeServiceIndex = serviceIndex;
                              svc.targetPrice = v;
                            }),
                            onTap: () => setState(
                              () => _activeServiceIndex = serviceIndex,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Work Projection Button (only for non-LS/non-staffing)
                          if (svc.unitOfMeasure.toLowerCase() != 'ls' && !svc.isStaffingRole) ...[
                            const SizedBox(width: 10),
                            Tooltip(
                              message: 'Work Projection',
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onDoubleTap: () {},
                                  onTapDown: (_) => setState(
                                    () => _activeServiceIndex = serviceIndex,
                                  ),
                                  onTap: () async {
                                    final result = await showSafeDialog(
                                      context: context,
                                      builder: (_) => ServiceEstimationDialog(
                                        service: {
                                          'id': null,
                                          'catalog_service_id': svc.catalogId,
                                          'name': svc.name,
                                          'quantity': svc.quantity,
                                          'unit': svc.unitOfMeasure,
                                          'estimationData': svc.estimationData,
                                        },
                                      ),
                                    );

                                    if (result != null &&
                                        result is Map &&
                                        result['applied'] == true) {
                                      setState(() {
                                        svc.quantity =
                                            (result['total_cy_loose'] as num)
                                                .toDouble();
                                        svc.estimationData =
                                            Map<String, dynamic>.from(
                                              result as Map,
                                            );
                                        _syncMachineryFromEstimation(
                                          svc,
                                          result as Map<String, dynamic>,
                                        );
                                        _syncMaterialsFromEstimation(
                                          svc,
                                          result as Map<String, dynamic>,
                                        );
                                        _syncInstrumentsFromEstimation(
                                          svc,
                                          result as Map<String, dynamic>,
                                        );
                                      });
                                    }
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 2),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.primaryGreen.withOpacity(0.3),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.analytics_outlined,
                                      color: AppTheme.primaryGreen,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],

                        ],
                      ),
                      if (svc.targetPrice > 0) ...[
                        const SizedBox(height: 6),
                        Row(children: [
                          _buildTargetPriceMini(svc),
                          const SizedBox(width: 8),
                          _buildQuickLevers(svc),
                        ]),
                      ],
                      if (svc.estimationData != null) ...[
                        const SizedBox(height: 12),
                        _buildEstimationSummaryBoxes(svc),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Total: \$${_currencyFormat.format(svc.totalSaleV2)}  |  Unit Price: \$${_currencyFormat.format(svc.unitPrice)}',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_services.length > 1) ...[
                  const SizedBox(width: 8),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onDoubleTap: () {}, // Prevent parent navigation bubbling
                      onTap: () {
                        setState(() {
                          _services.removeAt(serviceIndex);
                          if (_activeServiceIndex >= _services.length)
                            _activeServiceIndex = _services.length - 1;
                        });
                      },
                      child: const Icon(
                        Icons.delete_outline,
                        color: AppTheme.slate400,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  STEP 1: MACHINERY
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep1Machinery() {
    if (_services.isEmpty)
      return Center(
        child: Text(
          'Add a service first',
          style: GoogleFonts.manrope(color: AppTheme.slate500),
        ),
      );
    final svc = _services[_activeServiceIndex.clamp(0, _services.length - 1)];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildServiceTabs(),
          const SizedBox(height: 20),
          Row(
            children: [
              _sectionTitle('Machinery for "${svc.name}"'),
              const Spacer(),
              _buildEstimationSummaryBoxes(svc),
            ],
          ),
          const SizedBox(height: 16),
          if (svc.machineries.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Text(
                  'No machinery added yet. Click below to add one.',
                  style: GoogleFonts.manrope(color: AppTheme.slate500),
                ),
              ),
            )
          else
            ...svc.machineries.asMap().entries.map(
              (e) => _buildMachineryCard(svc, e.key, e.value),
            ),
          const SizedBox(height: 16),
          _addButton('Add Machinery', () {
            setState(() => svc.machineries.add(MachineryEntry()));
          }),
          const SizedBox(height: 20),
          _buildMachinerySummary(svc),
        ],
      ),
    );
  }

  Widget _buildMachineryCard(ServiceEntry svc, int index, MachineryEntry m) {
    return Container(
      key: ValueKey(m),
      margin: EdgeInsets.only(left: m.isPrimaryMover ? 0 : 40, bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: m.isPrimaryMover
            ? Colors.white
            : AppTheme.slate50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: m.isPrimaryMover
                ? const Color(0xFFE2E8F0)
                : AppTheme.slate200,
            width: m.isPrimaryMover ? 1 : 4,
          ),
          top: const BorderSide(color: Color(0xFFE2E8F0)),
          right: const BorderSide(color: Color(0xFFE2E8F0)),
          bottom: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (m.machineName != '' &&
                  _catalogMachinery.any(
                    (mx) => mx['description'] == m.machineName,
                  )) ...[
                Builder(
                  builder: (context) {
                    final item = _catalogMachinery.firstWhere(
                      (mx) => mx['description'] == m.machineName,
                    );
                    final String? photoUrl = item['photo_url'];

                    return Container(
                      width: 50,
                      height: 40,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.slate50,
                        border: Border.all(color: AppTheme.slate200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: (photoUrl != null && photoUrl.isNotEmpty)
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                color: AppTheme.slate50,
                                child: const Icon(
                                  Icons.precision_manufacturing,
                                  size: 20,
                                  color: AppTheme.slate400,
                                ),
                              ),
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                            )
                          : Container(
                              color: AppTheme.slate50,
                              child: const Icon(
                                Icons.precision_manufacturing,
                                size: 20,
                                color: AppTheme.slate400,
                              ),
                            ),
                    );
                  },
                ),
              ],
              Text(
                'Machine ${index + 1}',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.slate900,
                ),
              ),
              const SizedBox(width: 8),
              if (m.isPrimaryMover)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF11D411).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 10,
                        color: Color(0xFF11D411),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'PRIMARY',
                        style: GoogleFonts.manrope(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF11D411),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.slate200.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.build_circle,
                        size: 10,
                        color: AppTheme.slate600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'SUPPORT',
                        style: GoogleFonts.manrope(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.slate600,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => svc.machineries.removeAt(index)),
                  child: const Icon(
                    Icons.close,
                    color: AppTheme.slate400,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 1: Name, Months, Monthly Rent, Qty
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SearchableCatalogDropdown(
                label: 'Machine Name',
                width: 180,
                items: _catalogMachinery,
                excludeItems: const [],
                initialValue: m.machineName,
                onSelected: (val, item) {
                  setState(() {
                    m.machineName = val;
                    if (item != null) {
                      // Pull fuel consumption from catalog
                      if (item['fuel_gallons'] != null) {
                        m.gallonsPerHour = (item['fuel_gallons'] as num)
                            .toDouble();
                      }
                      // Pull monthly rent if it exists in catalog (field name sync)
                      if (item['monthly_rent_cost'] != null) {
                        m.monthlyRentCost = (item['monthly_rent_cost'] as num)
                            .toDouble();
                      } else if (item['monthly_rent'] != null) {
                        m.monthlyRentCost = (item['monthly_rent'] as num)
                            .toDouble();
                      }

                      // Default gasoline cost if not set
                      if (m.gallonCost == 0) m.gallonCost = 5.25;
                    }
                  });
                },
                onAddNew: () => _openCatalogItemAdd('machinery'),
              ),
              _fieldCard(
                'Months',
                m.monthsToUse,
                70,
                onNum: (v) => setState(() => m.monthsToUse = v),
              ),
              _fieldCard(
                'Monthly Rent \$',
                m.monthlyRentCost,
                100,
                onNum: (v) => setState(() => m.monthlyRentCost = v),
              ),
              _fieldCard(
                'Qty',
                m.quantity,
                50,
                onNum: (v) => setState(() => m.quantity = v),
              ),
              _fieldCard(
                'Gal/Hour',
                m.gallonsPerHour,
                70,
                onNum: (v) => setState(() => m.gallonsPerHour = v),
              ),
              _fieldCard(
                'Gal Cost \$',
                m.gallonCost,
                80,
                onNum: (v) => setState(() => m.gallonCost = v),
              ),
              _fieldCard(
                'Delivery \$',
                m.deliveryCost,
                80,
                onNum: (v) => setState(() => m.deliveryCost = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _calcChip('Rate/Hr', m.ratePerHour),
                _calcChip('Hours/Mo', m.hoursWorkedPerMonth, isCurrency: false),
                _calcChip('Total Rent', m.totalRent),
                _calcChip('Total Gal', m.totalGallons, isCurrency: false),
                _calcChip('Delivery Total', m.deliveryTotal),
                _calcChip('Gas Cost', m.totalGallonsCost),
                _calcChip('TOTAL', m.totalGeneral, highlight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMachinerySummary(ServiceEntry svc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Machinery Summary',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.slate900,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total Rent: \$${_currencyFormat.format(svc.totalMachinery)}',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.slate700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Total Delivery: \$${_currencyFormat.format(svc.totalDelivery)}',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.slate700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Total Gas: \$${_currencyFormat.format(svc.totalGasoline)}',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.slate700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Combined: \$${_currencyFormat.format(svc.totalMachinery + svc.totalGasoline + svc.totalDelivery)}',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  STEP 2: LABOR
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep2Labor() {
    if (_services.isEmpty)
      return Center(
        child: Text(
          'Add a service first',
          style: GoogleFonts.manrope(color: AppTheme.slate500),
        ),
      );
    final svc = _services[_activeServiceIndex.clamp(0, _services.length - 1)];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildServiceTabs(),
          const SizedBox(height: 20),
          Row(
            children: [
              _sectionTitle('Labor for "${svc.name}"'),
              const Spacer(),
              _buildEstimationSummaryBoxes(svc),
            ],
          ),
          const SizedBox(height: 16),
          if (svc.labors.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Text(
                  'No labor added yet. Click below to add one.',
                  style: GoogleFonts.manrope(color: AppTheme.slate500),
                ),
              ),
            )
          else
            ...svc.labors.asMap().entries.map(
              (e) => _buildLaborCard(svc, e.key, e.value),
            ),
          const SizedBox(height: 16),
          _addButton('Add Labor', () {
            double initialMonths = 0;
            if (svc.estimationData != null) {
              final start = svc.estimationData!['start_date'] as DateTime?;
              final end = svc.estimationData!['end_date'] as DateTime?;
              if (start != null && end != null) {
                final diff = end.difference(start).inDays;
                initialMonths = double.parse((diff / 30.44).toStringAsFixed(1));
              }
            }
            setState(
              () => svc.labors.add(LaborEntry(monthsToWork: initialMonths)),
            );
          }),
          const SizedBox(height: 20),
          _buildLaborSummary(svc),
        ],
      ),
    );
  }

  Widget _buildLaborCard(ServiceEntry svc, int index, LaborEntry l) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Labor ${index + 1}',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.slate900,
                ),
              ),
              const Spacer(),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => svc.labors.removeAt(index)),
                  child: const Icon(
                    Icons.close,
                    color: AppTheme.slate400,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SearchableCatalogDropdown(
                label: 'Role/Position',
                width: 180,
                items: _catalogLaborRoles,
                excludeItems: const [],
                initialValue: l.roleName,
                onSelected: (val, item) {
                  setState(() {
                    l.roleName = val;
                    if (item != null && item['hourly_rate'] != null) {
                      l.hourlyRate = (item['hourly_rate'] as num).toDouble();
                    }
                  });
                },
                onAddNew: () => _openCatalogItemAdd('labor'),
              ),
              _fieldCard(
                'Months',
                l.monthsToWork,
                80,
                onNum: (v) => setState(() => l.monthsToWork = v),
              ),
              _fieldCard(
                'Employees',
                l.employeesQuantity,
                80,
                onNum: (v) => setState(() => l.employeesQuantity = v),
              ),
              _fieldCard(
                'Hourly Rate \$',
                l.hourlyRate,
                100,
                onNum: (v) => setState(() => l.hourlyRate = v),
                key: ValueKey('rate_${index}_${l.roleName}'),
              ),
              _fieldCard(
                'Per Diem \$',
                l.perDiem,
                100,
                onNum: (v) => setState(() => l.perDiem = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _calcChip('Hours/Mo', l.hoursPerMonth, isCurrency: false),
                _calcChip('Total Pay', l.totalPay),
                _calcChip('Total PerDiem', l.totalPerDiem),
                _calcChip('TOTAL', l.totalFinal, highlight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaborSummary(ServiceEntry svc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Labor Summary',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.slate900,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total Pay: \$${_currencyFormat.format(svc.totalLabor)}',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.slate700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Total PerDiem: \$${_currencyFormat.format(svc.totalPerDiem)}',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.slate700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Combined: \$${_currencyFormat.format(svc.totalLabor + svc.totalPerDiem)}',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  STEP 3: MATERIALS
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep3Materials() {
    if (_services.isEmpty)
      return Center(
        child: Text(
          'Add a service first',
          style: GoogleFonts.manrope(color: AppTheme.slate500),
        ),
      );
    final svc = _services[_activeServiceIndex.clamp(0, _services.length - 1)];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildServiceTabs(),
          const SizedBox(height: 20),
          _sectionTitle('Materials & Project Supplies'),
          const SizedBox(height: 16),
          if (svc.materials.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Text(
                  'No materials added yet. Estimation values will appear here or click below to manually add.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(color: AppTheme.slate500),
                ),
              ),
            )
          else
            ...svc.materials.asMap().entries.map(
              (e) => _buildMaterialCard(svc, e.key, e.value),
            ),
          const SizedBox(height: 16),
          _addButton('Add Material', () {
            setState(() => svc.materials.add(MaterialEntry()));
          }),
          const SizedBox(height: 20),
          _buildMaterialSummary(svc),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(ServiceEntry svc, int index, MaterialEntry m) {
    return Container(
      key: ValueKey(m),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Material ${index + 1}',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.slate900,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => svc.materials.removeAt(index)),
                child: const Icon(
                  Icons.close,
                  color: AppTheme.slate400,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SearchableCatalogDropdown(
                label: 'Name / Description',
                width: 200,
                items: _catalogMaterials,
                initialValue: m.materialName,
                onSelected: (val, item) {
                  setState(() {
                    m.materialName = val;
                    if (item != null) {
                      m.unit = item['unit'] ?? 'und';
                      m.catalogId = item['id']?.toString();

                      // Smart Auto-calculation based on estimation data
                      if (svc.estimationData != null) {
                        final data = svc.estimationData!;
                        final yieldFactor =
                            (item['yield_factor'] as num?)?.toDouble() ?? 1.0;

                        // Keys from ServiceEstimationDialog:
                        // 'calculated_loose' -> CY Loose
                        // 'compacted_volume' -> CY Compacted or SQFT Area
                        final volLoose = (data['calculated_loose'] as num?)
                            ?.toDouble();
                        final volComp = (data['compacted_volume'] as num?)
                            ?.toDouble();

                        double? metric;
                        final unitL = m.unit.toLowerCase();

                        if (unitL.contains('ft') || unitL.contains('sq')) {
                          // For Area (SQFT), use compacted_volume (which stores Area if the service is area-based)
                          metric = volComp;
                        } else {
                          // For Volume (CY/TON), prefer Loose Volume as it's what's typically bought
                          metric = volLoose ?? volComp;
                        }

                        if (metric != null && metric > 0) {
                          m.quantity = double.parse(
                            (metric * yieldFactor).toStringAsFixed(2),
                          );
                        }
                      }
                    }
                  });
                },
                onAddNew: () => _openCatalogItemAdd('materials'),
              ),
              _fieldCard(
                'Quantity',
                m.quantity,
                80,
                onNum: (v) => setState(() => m.quantity = v),
              ),
              _fieldCard(
                'Unit',
                0,
                80,
                initialText: m.unit,
                onText: (v) => setState(() => m.unit = v),
              ),
              _fieldCard(
                'Unit Price \$',
                m.unitPrice,
                100,
                onNum: (v) => setState(() => m.unitPrice = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Spacer(),
                Text(
                  'TOTAL: ',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate500,
                  ),
                ),
                Text(
                  '\$${_currencyFormat.format(m.total)}',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialSummary(ServiceEntry svc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Materials Summary',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.slate900,
            ),
          ),
          Text(
            'Total: \$${_currencyFormat.format(svc.totalMaterials)}',
            style: GoogleFonts.manrope(
              fontSize: 15,
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  STEP 4: SUMMARY
  // ══════════════════════════════════════════════════════════════

  Widget _buildTargetPriceSummary() {
    final svcs = _services.where((s) => s.targetPrice > 0).toList();
    if (svcs.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Target Price Summary', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.2),
              4: FlexColumnWidth(0.8),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
                children: [
                  _thCell('Service'),
                  _thCell('Target'),
                  _thCell('Current'),
                  _thCell('Gap'),
                  _thCell(''),
                ],
              ),
              ...svcs.map((svc) {
                final gap = svc.priceGap;
                final color = svc.gapStatus == 'green'
                    ? AppTheme.primaryGreen
                    : svc.gapStatus == 'yellow'
                        ? Colors.orange
                        : AppTheme.errorRed;
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(svc.name, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.slate900)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('\$${_currencyFormat.format(svc.targetPrice)}', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('\$${_currencyFormat.format(svc.totalSaleV2)}', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate600)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        gap <= 0 ? '-\$${_currencyFormat.format(gap.abs())}' : '+\$${_currencyFormat.format(gap.abs())}',
                        style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: color),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
          const Divider(height: 24),
          Builder(builder: (_) {
            final totalTarget = svcs.fold<double>(0, (s, svc) => s + svc.targetPrice);
            final totalCurrent = svcs.fold<double>(0, (s, svc) => s + svc.totalSaleV2);
            final totalGap = totalTarget - totalCurrent;
            final tColor = totalGap.abs() / (totalTarget > 0 ? totalTarget : 1) < 0.02
                ? AppTheme.primaryGreen
                : totalGap.abs() / (totalTarget > 0 ? totalTarget : 1) < 0.1
                    ? Colors.orange
                    : AppTheme.errorRed;
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Total: ', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                Text('\$${_currencyFormat.format(totalTarget)} target  /  \$${_currencyFormat.format(totalCurrent)} current', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.slate600)),
                const SizedBox(width: 16),
                Text(totalGap <= 0 ? '-\$${_currencyFormat.format(totalGap.abs())}' : '+\$${_currencyFormat.format(totalGap.abs())}', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: tColor)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _thCell(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate400)),
  );

  Widget _buildStep5Summary() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Estimate: ${_titleController.text}'),
          const SizedBox(height: 20),
          ..._services.asMap().entries.map(
            (e) => _buildServiceSummaryCard(e.key, e.value),
          ),
          if (_services.any((s) => s.targetPrice > 0)) ...[
            const SizedBox(height: 20),
            _buildTargetPriceSummary(),
          ],
          const SizedBox(height: 20),
          _buildGrandTotal(),
        ],
      ),
    );
  }

  Widget _buildServiceSummaryCard(int index, ServiceEntry svc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${svc.name}  (${svc.quantity} ${svc.unitOfMeasure})',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.slate900,
            ),
          ),
          const SizedBox(height: 16),
          if (svc.unitOfMeasure.toLowerCase() == 'ls' || svc.isStaffingRole) ...[
            _summaryRow('Direct Cost', svc.directCost),
          ] else ...[
            _summaryRow('Total Machinery', svc.totalMachinery),
            _summaryRow('Total Delivery', svc.totalDelivery),
            _summaryRow('Total Gasoline', svc.totalGasoline),
            _summaryRow('Total Labor', svc.totalLabor),
            _summaryRow('Total PerDiem', svc.totalPerDiem),
            _summaryRow(
              'Total Materials',
              svc.totalMaterials,
              highlight: svc.totalMaterials > 0,
            ),
            _summaryRow(
              'Total Instruments',
              svc.totalInstruments,
              highlight: svc.totalInstruments > 0,
            ),
          ],
          const Divider(height: 24),
          _summaryRow('Sub Total', svc.subTotal, bold: true),
          _summaryRow(
            'Overhead (${svc.overheadPercentage}%)',
            svc.overheadAmount,
          ),
          _summaryRow('Total + Overhead', svc.totalPlusOverhead),
          _summaryRow('Profit (${svc.profitPercentage}%)', svc.profitAmount),
          const Divider(height: 24),
          _summaryRow(
            'Sale Total (V2)',
            svc.totalSaleV2,
            bold: true,
            highlight: true,
          ),
          _summaryRow('Unit Price', svc.unitPrice),
        ],
      ),
    );
  }

  Widget _buildGrandTotal() {
    final grandTotal = _services.fold(0.0, (s, svc) => s + svc.totalSaleV2);
    final totalOverhead = _services.fold(0.0, (s, svc) => s + svc.overheadAmount);
    final totalProfit = _services.fold(0.0, (s, svc) => s + svc.profitAmount);
    final totalSubTotal = _services.fold(0.0, (s, svc) => s + svc.subTotal);

    final overheadPct = totalSubTotal > 0 ? (totalOverhead / totalSubTotal) * 100 : 0.0;
    final profitPct = totalSubTotal > 0 ? (totalProfit / totalSubTotal) * 100 : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GRAND TOTAL',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.slate900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sub Total: \$${_currencyFormat.format(totalSubTotal)}',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate700,
                  ),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 12,
                  children: [
                    Text(
                      'Overhead: \$${_currencyFormat.format(totalOverhead)} (${overheadPct.toStringAsFixed(1)}%)',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.slate500,
                      ),
                    ),
                    Text(
                      'Profit: \$${_currencyFormat.format(totalProfit)} (${profitPct.toStringAsFixed(1)}%)',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.slate500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '\$${_currencyFormat.format(grandTotal)}',
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Instruments() {
    if (_services.isEmpty)
      return Center(
        child: Text(
          'Add a service first',
          style: GoogleFonts.manrope(color: AppTheme.slate500),
        ),
      );
    final svc = _services[_activeServiceIndex.clamp(0, _services.length - 1)];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildServiceTabs(),
          const SizedBox(height: 20),
          _sectionTitle('Instruments & Special Tools'),
          const SizedBox(height: 16),
          if (svc.instruments.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Text(
                  'No instruments added yet. Estimation values will appear here or click below to manually add.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(color: AppTheme.slate500),
                ),
              ),
            )
          else
            ...svc.instruments.asMap().entries.map(
              (e) => _buildInstrumentCard(svc, e.key, e.value),
            ),
          const SizedBox(height: 16),
          _addButton('Add Instrument', () {
            _showInstrumentSelector(svc);
          }, icon: Icons.playlist_add),
          const SizedBox(height: 20),
          _buildInstrumentSummary(svc),
        ],
      ),
    );
  }

  Widget _buildInstrumentCard(ServiceEntry svc, int index, InstrumentEntry inst) {
    return Container(
      key: ValueKey(inst),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (inst.instrumentName != '' &&
                  _catalogInstruments.any(
                    (ix) => ix['description'] == inst.instrumentName,
                  )) ...[
                Builder(
                  builder: (context) {
                    final item = _catalogInstruments.firstWhere(
                      (ix) => ix['description'] == inst.instrumentName,
                    );
                    final String? photoUrl = item['photo_url'];

                    return Container(
                      width: 50,
                      height: 40,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.slate50,
                        border: Border.all(color: AppTheme.slate200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: (photoUrl != null && photoUrl.isNotEmpty)
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                color: AppTheme.slate50,
                                child: const Icon(
                                  Icons.construction,
                                  size: 20,
                                  color: AppTheme.slate400,
                                ),
                              ),
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            )
                          : const Icon(
                              Icons.construction,
                              size: 20,
                              color: AppTheme.slate400,
                            ),
                    );
                  },
                ),
              ],
              Text(
                'Tool / Instrument ${index + 1}',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.slate900,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => svc.instruments.removeAt(index)),
                child: const Icon(
                  Icons.close,
                  color: AppTheme.slate400,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SearchableCatalogDropdown(
                label: 'Tool Name',
                width: 200,
                items: _catalogInstruments,
                initialValue: inst.instrumentName,
                onSelected: (val, item) {
                  setState(() {
                    inst.instrumentName = val;
                    if (item != null) {
                      inst.catalogId = item['id']?.toString();
                    }
                  });
                },
                onAddNew: () => _openCatalogItemAdd('instruments'),
              ),
              _fieldCard(
                'Qty',
                inst.quantity,
                70,
                onNum: (v) => setState(() => inst.quantity = v),
              ),
              _fieldCard(
                'Days',
                inst.days,
                70,
                onNum: (v) => setState(() => inst.days = v),
              ),
              _fieldCard(
                'Price/Day',
                inst.unitPrice,
                100,
                onNum: (v) => setState(() => inst.unitPrice = v),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '\$${_currencyFormat.format(inst.total)}',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstrumentSummary(ServiceEntry svc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Instruments for ${svc.name}',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              color: AppTheme.slate700,
            ),
          ),
          Text(
            _currencyFormat.format(svc.totalInstruments),
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    double value, {
    bool bold = false,
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: AppTheme.slate700,
            ),
          ),
          Text(
            '\$${_currencyFormat.format(value)}',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? AppTheme.primaryGreen : AppTheme.slate900,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  SERVICE TABS (used in Step 1 and 2)
  // ══════════════════════════════════════════════════════════════
  Widget _buildServiceTabs() {
    final nonLSServices = _services.asMap().entries.where((e) => e.value.unitOfMeasure.toLowerCase() != 'ls' && !e.value.isStaffingRole).toList();

    if (nonLSServices.isEmpty) return const SizedBox.shrink();

    // Ensure active index is valid for tabs
    if (_activeServiceIndex >= _services.length || _services[_activeServiceIndex].unitOfMeasure.toLowerCase() == 'ls' || _services[_activeServiceIndex].isStaffingRole) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _activeServiceIndex = nonLSServices.first.key;
          });
        }
      });
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: nonLSServices.map((e) {
          final isActive = e.key == _activeServiceIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _activeServiceIndex = e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primaryGreen : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: isActive
                        ? null
                        : Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    e.value.name.isEmpty
                        ? 'Service ${e.key + 1}'
                        : e.value.name,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : AppTheme.slate700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  WIZARD FOOTER
  // ══════════════════════════════════════════════════════════════
  Widget _buildWizardFooter() {
    final bool allServicesAreLS = _services.isNotEmpty && _services.every((s) => s.unitOfMeasure.toLowerCase() == 'ls' || s.isStaffingRole);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            _footerBtn(
              'Back',
              Icons.arrow_back,
              false,
              () => setState(() {
                if (_currentStep == 5 && allServicesAreLS) {
                  _currentStep = 0;
                } else {
                  _currentStep--;
                }
              }),
            )
          else
            const SizedBox.shrink(),
          Row(
            children: [
              _footerBtn(
                'Cancel',
                null,
                false,
                () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 12),
              if (_currentStep < 5) ...[
                _footerBtn(
                  _isSaving ? 'Saving...' : 'Save Draft',
                  Icons.save_outlined,
                  false,
                  _isSaving ? null : () => _persistQuote(closeDialog: false),
                ),
                const SizedBox(width: 12),
                _footerBtn(
                  'Next',
                  Icons.arrow_forward,
                  true,
                  () => setState(() {
                    if (_currentStep == 0 && allServicesAreLS) {
                      _currentStep = 5;
                    } else {
                      _currentStep++;
                    }
                  }),
                ),
              ]
              else
                _footerBtn(
                  _isSaving ? 'Saving...' : (_isEditing ? 'Save Estimate' : 'Create Estimate'),
                  Icons.check,
                  true,
                  _isSaving ? null : () => _persistQuote(closeDialog: true),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerBtn(
    String label,
    IconData? icon,
    bool primary,
    VoidCallback? onTap,
  ) {
    return MouseRegion(
      cursor: onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: primary
                ? (onTap != null ? AppTheme.primaryGreen : AppTheme.slate400)
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: primary ? null : Border.all(color: const Color(0xFFCBD5E1)),
            boxShadow: primary
                ? [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null && !label.startsWith('Back')) ...[
                // nothing
              ],
              if (label == 'Back') ...[
                Icon(icon, size: 16, color: AppTheme.slate700),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primary ? Colors.white : AppTheme.slate700,
                ),
              ),
              if (icon != null && label != 'Back') ...[
                const SizedBox(width: 6),
                Icon(
                  icon,
                  size: 16,
                  color: primary ? Colors.white : AppTheme.slate700,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  REUSABLE WIDGETS
  // ══════════════════════════════════════════════════════════════
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppTheme.slate900,
      ),
    );
  }

  Widget _buildEstimationSummaryBoxes(ServiceEntry svc) {
    if (svc.estimationData == null) return const SizedBox.shrink();

    final data = svc.estimationData!;
    final startDate = data['start_date'] as DateTime?;
    final endDate = data['end_date'] as DateTime?;
    final workingDays = data['working_days'] ?? 0;

    String period = '-';
    String months = '0';
    String calendarDays = '0';

    if (startDate != null && endDate != null) {
      period =
          '${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd').format(endDate)}';
      final diff = endDate.difference(startDate).inDays;
      calendarDays = diff.toString();
      months = (diff / 30.44).toStringAsFixed(1);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _estBox('Period', period),
        _estBox('Months', months),
        _estBox('Production Days', workingDays.toString()),
        _estBox('Total Days', calendarDays),
      ],
    );
  }

  Widget _estBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.slate900,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showInstrumentSelector(ServiceEntry svc) async {
    final result = await showSafeDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (context) => MachinerySelectionDialog(
        serviceId: svc.catalogId ?? '',
        isInstrument: true,
      ),
    );

    if (result == null || result.isEmpty) return;

    // Get default days from production
    double defaultDays = 1.0;
    if (svc.estimationData != null) {
      final wDays = svc.estimationData!['workingDays'] ?? 
                    svc.estimationData!['working_days'] ?? 
                    svc.estimationData!['total_working_days'];
      defaultDays = (wDays as num?)?.toDouble() ?? 1.0;
      if (defaultDays <= 0) defaultDays = 1.0;
    }

    setState(() {
      for (final i in result) {
        svc.instruments.add(InstrumentEntry(
          instrumentName: i['instrument_name'] ?? i['description'] ?? 'Untitled',
          catalogId: i['instrument_id']?.toString() ?? i['id']?.toString(),
          unitPrice: (i['unit_price'] as num?)?.toDouble() ?? (i['daily_rate'] as num?)?.toDouble() ?? 0.0,
          photoUrl: i['photo_url'],
          days: defaultDays,
        ));
      }
    });
  }

  Widget _labeledField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.slate700,
          ),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }

  InputDecoration _inputDeco(String? hint, [IconData? icon]) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 13),
      prefixIcon: icon != null
          ? Icon(icon, color: AppTheme.slate400, size: 18)
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 2),
      ),
    );
  }

  Widget _addButton(String label, VoidCallback onTap, {IconData icon = Icons.add}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.primaryGreen,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppTheme.primaryGreen, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldCard(
    String label,
    double? value,
    double width, {
    String? initialText,
    Function(double)? onNum,
    Function(String)? onText,
    Key? key,
  }) {
    final val = onText != null
        ? initialText!
        : (value != null ? value.toString() : '');
    return SizedBox(
      key: key,
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate500,
            ),
          ),
          const SizedBox(height: 4),
          _AutoSelectField(
            initialValue: val,
            onChanged: (v) {
              if (onNum != null) onNum(double.tryParse(v) ?? 0);
              if (onText != null) onText(v);
            },
            keyboardType: onNum != null
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            inputFormatters: onNum != null
                ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
                : null,
          ),
        ],
      ),
    );
  }

  Widget _miniField(
    String label,
    String value,
    double width,
    Function(String) onChange, {
    Key? key,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      key: key,
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate500,
            ),
          ),
          SizedBox(
            height: 28,
            child: _MiniAutoSelectField(
              initialValue: value,
              onChanged: onChange,
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniNumField(
    String label,
    double value,
    double width,
    Function(double) onChange, {
    Key? key,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      key: key,
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate500,
            ),
          ),
          SizedBox(
            height: 28,
            child: _MiniAutoSelectField(
              initialValue: value != 0 ? value.toString() : '',
              isNumeric: true,
              onChanged: (v) => onChange(double.tryParse(v) ?? 0),
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _calcChip(
    String label,
    double value, {
    bool highlight = false,
    bool isCurrency = true,
  }) {
    final displayText = isCurrency
        ? '\$${_currencyFormat.format(value)}'
        : NumberFormat('#,##0.00').format(value);
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate500,
            ),
          ),
          SizedBox(
            height: 28,
            child: TextFormField(
              readOnly: true,
              initialValue: displayText,
              key: ValueKey(displayText),
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                color: highlight ? AppTheme.primaryGreen : AppTheme.slate700,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                filled: true,
                fillColor:
                    highlight
                        ? AppTheme.primaryGreen.withOpacity(0.06)
                        : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color:
                        highlight
                            ? AppTheme.primaryGreen.withOpacity(0.3)
                            : const Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color:
                        highlight
                            ? AppTheme.primaryGreen.withOpacity(0.3)
                            : const Color(0xFFE2E8F0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color:
                        highlight
                            ? AppTheme.primaryGreen
                            : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCatalogItemAdd(String type) {
    Widget? dialog;
    if (type == 'services') dialog = ServiceDialog();
    if (type == 'machinery') dialog = MachineryDialog();
    if (type == 'labor') dialog = LaborRoleDialog();
    if (type == 'customers') dialog = const CustomerFormDialog();
    if (type == 'materials' || type == 'instruments') dialog = MachineryDialog();

    if (dialog != null) {
      showSafeDialog(
        context: context,
        builder: (context) => dialog!,
      ).then((success) {
        if (success == true) _loadCatalogs();
      });
    }
  }
}

class _SearchableCatalogDropdown extends StatelessWidget {
  final String label;
  final List<Map<String, dynamic>> items;
  final List<String> excludeItems;
  final String initialValue;
  final Function(String, Map<String, dynamic>?) onSelected;
  final VoidCallback onAddNew;
  final double? width;

  const _SearchableCatalogDropdown({
    required this.label,
    required this.items,
    this.excludeItems = const [],
    required this.initialValue,
    required this.onSelected,
    required this.onAddNew,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate500,
            ),
          ),
          const SizedBox(height: 4),
          Autocomplete<Map<String, dynamic>>(
            initialValue: TextEditingValue(text: initialValue),
            displayStringForOption: (option) => option['description'] ?? '',
            optionsBuilder: (textEditingValue) {
              final available = items.where(
                (i) => !excludeItems.contains(i['description']),
              );
              final t = textEditingValue.text.toLowerCase();
              if (t.isEmpty ||
                  t.startsWith('service') ||
                  t.startsWith('machine') ||
                  t.startsWith('role')) {
                return available;
              }
              return available
                  .where(
                    (i) =>
                        i['description'].toString().toLowerCase().contains(t),
                  )
                  .toList();
            },
            onSelected: (option) => onSelected(option['description'], option),
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppTheme.slate900,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search or type...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(
                          color: Color(0xFF1D4ED8),
                          width: 1.5,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: AppTheme.slate400,
                        ),
                        onPressed: () {
                          final current = controller.text;
                          controller.text = '';
                          controller.text = current;
                          focusNode.requestFocus();
                        },
                      ),
                    ),
                    onChanged: (v) => onSelected(v, null),
                  );
                },
            optionsViewBuilder: (context, onSelectedInternal, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(10),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 260,
                      maxHeight: 260,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppTheme.slate200),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children: [
                          ...options.map((option) {
                            final photoUrl = option['photo_url'] as String?;
                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              leading: label.toLowerCase().contains('machine')
                                  ? Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: AppTheme.slate50,
                                        border: Border.all(color: AppTheme.slate200),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: (photoUrl != null && photoUrl.isNotEmpty)
                                          ? Image.network(photoUrl, fit: BoxFit.cover)
                                          : const Center(
                                              child: Icon(Icons.precision_manufacturing, size: 18, color: AppTheme.slate400),
                                            ),
                                    )
                                  : null,
                              title: Text(
                                option['description'] ?? '',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.slate900,
                                ),
                              ),
                              subtitle: option['hourly_rate'] != null
                                  ? Text(
                                      '\$${option['hourly_rate']}/hr',
                                      style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate500),
                                    )
                                  : (option['unit'] != null
                                      ? Text(
                                          'Unit: ${option['unit']}',
                                          style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate500),
                                        )
                                      : null),
                              hoverColor: AppTheme.primaryGreen.withOpacity(0.05),
                              onTap: () => onSelectedInternal(option),
                            );
                          }).toList(),
                          const Divider(height: 1),
                          InkWell(
                            onTap: () => onAddNew(),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              color: AppTheme.primaryGreen.withOpacity(0.05),
                              child: Row(
                                children: [
                                  const Icon(Icons.add_circle_outline, size: 16, color: AppTheme.primaryGreen),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add New to Catalog',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MiniAutoSelectField extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;
  final VoidCallback? onTap;
  final bool isNumeric;

  const _MiniAutoSelectField({
    required this.initialValue,
    required this.onChanged,
    this.onTap,
    this.isNumeric = false,
  });

  @override
  State<_MiniAutoSelectField> createState() => _MiniAutoSelectFieldState();
}

class _MiniAutoSelectFieldState extends State<_MiniAutoSelectField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      }
    });
  }

  @override
  void didUpdateWidget(_MiniAutoSelectField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      keyboardType: widget.isNumeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: widget.isNumeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
          : null,
      style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate900),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 1.5),
        ),
      ),
      onTap: () {
        if (widget.onTap != null) widget.onTap!();
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      },
    );
  }
}

class _AutoSelectField extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _AutoSelectField({
    required this.initialValue,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  State<_AutoSelectField> createState() => _AutoSelectFieldState();
}

class _AutoSelectFieldState extends State<_AutoSelectField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      }
    });
  }

  @override
  void didUpdateWidget(_AutoSelectField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate900),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 1.5),
        ),
      ),
      onTap: () {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      },
      onChanged: widget.onChanged,
    );
  }
}

class _LeverSuggestion {
  final String label;
  final IconData icon;
  final VoidCallback action;
  const _LeverSuggestion({required this.label, required this.icon, required this.action});
}

