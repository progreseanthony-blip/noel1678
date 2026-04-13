import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:intl/intl.dart';
import 'package:noel_app/src/features/catalogs/presentation/widgets/service_dialog.dart';
import 'package:noel_app/src/features/catalogs/presentation/widgets/machinery_dialog.dart';
import 'package:noel_app/src/features/catalogs/presentation/widgets/labor_role_dialog.dart';
import 'service_estimation_dialog.dart';

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

class ServiceEntry {
  String name;
  String unitOfMeasure;
  double quantity;
  double overheadPercentage;
  double profitPercentage;
  List<MachineryEntry> machineries;
  List<LaborEntry> labors;
  List<MaterialEntry> materials;

  Map<String, dynamic>? estimationData;
  String? catalogId;

  ServiceEntry({
    this.name = '',
    this.unitOfMeasure = 'und',
    this.quantity = 1,
    this.overheadPercentage = 0,
    this.profitPercentage = 0,
    List<MachineryEntry>? machineries,
    List<LaborEntry>? labors,
    List<MaterialEntry>? materials,
    this.estimationData,
    this.catalogId,
  })  : machineries = machineries ?? [],
        labors = labors ?? [],
        materials = materials ?? [];

  double get totalMachinery => machineries.fold(0.0, (s, m) => s + m.totalRent);
  double get totalGasoline => machineries.fold(0.0, (s, m) => s + m.totalGallonsCost);
  double get totalDelivery => machineries.fold(0.0, (s, m) => s + m.deliveryTotal);
  double get totalLabor => labors.fold(0.0, (s, l) => s + l.totalPay);
  double get totalPerDiem => labors.fold(0.0, (s, l) => s + l.totalPerDiem);
  double get totalMaterials => materials.fold(0.0, (s, m) => s + m.total);
  double get subTotal => totalMachinery + totalGasoline + totalDelivery + totalLabor + totalPerDiem + totalMaterials;
  double get overheadAmount => subTotal * (overheadPercentage / 100);
  double get totalPlusOverhead => subTotal + overheadAmount;
  double get profitAmount => totalPlusOverhead * (profitPercentage / 100);
  double get totalSaleV2 => totalPlusOverhead + profitAmount;
  double get unitPrice => quantity > 0 ? totalSaleV2 / quantity : 0;
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

  // Catalogs for step 1+
  List<Map<String, dynamic>> _catalogServices = [];
  List<Map<String, dynamic>> _catalogMachinery = [];
  List<Map<String, dynamic>> _catalogLaborRoles = [];
  List<Map<String, dynamic>> _catalogMaterials = [];

  // Step 1+ - Services
  List<ServiceEntry> _services = [];
  int _activeServiceIndex = 0;

  final _currencyFormat = NumberFormat('#,##0.00', 'en_US');

  bool get _isEditing => widget.quoteToEdit != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.quoteToEdit?['title'] ?? '');
    _clientController = TextEditingController(text: widget.quoteToEdit?['client_name'] ?? '');
    if (widget.quoteToEdit?['quote_date'] != null) {
      _quoteDate = DateTime.tryParse(widget.quoteToEdit!['quote_date']) ?? DateTime.now();
    }
    _selectedStatus = widget.quoteToEdit?['status'] ?? 'draft';

    _loadCatalogs();
    if (_isEditing) {
      _loadExistingData();
    } else {
      _services.add(ServiceEntry(name: 'Service 1'));
    }
  }

  void _syncMachineryFromEstimation(ServiceEntry svc, Map<String, dynamic> result) {
    // 1. Calculate duration in months (using the same logic as the result card)
    final start = result['start_date'] as DateTime;
    final end = result['end_date'] as DateTime;
    final calendarDays = end.difference(start).inDays + 1;
    final months = double.parse((calendarDays / 30.44).toStringAsFixed(1));

    // 2. Fetch resources from estimation result
    final resources = result['resources'] as List;
    if (resources.isEmpty) return;

    // 3. Clear existing machineries if they were default/empty
    if (svc.machineries.isEmpty || (svc.machineries.length == 1 && svc.machineries[0].machineName.isEmpty)) {
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
        final pRes = resources.firstWhere((r) => r['id'] == res['parent_resource_id'], orElse: () => <String, dynamic>{});
        parentName = pRes['machine_name'];
      }
      
      // Find in oldMachineries
      int matchIdx = oldMachineries.indexWhere((m) => m.machineName == machineName && m.isPrimaryMover == isPrimary && m.parentMachineName == parentName);
      if (matchIdx < 0) {
        matchIdx = oldMachineries.indexWhere((m) => m.machineName == machineName);
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
          orElse: () => <String,dynamic>{}
        );

        newMachineries.add(MachineryEntry(
          machineName: machineName,
          monthsToUse: months,
          quantity: (res['quantity'] as num).toDouble(),
          // Defaults or catalog values
          monthlyRentCost: (catalogItem['monthly_rent_cost'] as num?)?.toDouble() ?? 0,
          gallonsPerHour: (catalogItem['fuel_gallons'] as num?)?.toDouble() ?? 0,
          gallonCost: (catalogItem['gallon_cost'] as num?)?.toDouble() ?? 5.25,
          deliveryCost: (catalogItem['delivery_cost'] as num?)?.toDouble() ?? 0,
          isPrimaryMover: isPrimary,
          parentMachineName: parentName,
        ));
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
      sortedList.addAll(svc.machineries.where((m) => !m.isPrimaryMover && m.parentMachineName == p.machineName));
    }
    // Append any unassigned supports
    sortedList.addAll(svc.machineries.where((m) => !m.isPrimaryMover && !primaries.any((p) => p.machineName == m.parentMachineName)));
    
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
           orElse: () => <String, dynamic>{}
         );
         
         if (role.isNotEmpty) {
           final roleName = role['description'] ?? '';
           final qty = (res['quantity'] as num).toDouble();
           
           int existingIdx = autoLabors.indexWhere((l) => l.roleName == roleName);
           if (existingIdx >= 0) {
              autoLabors[existingIdx].employeesQuantity += qty;
              if (months > autoLabors[existingIdx].monthsToWork) {
                 autoLabors[existingIdx].monthsToWork = months;
              }
           } else {
              autoLabors.add(LaborEntry(
                roleName: roleName,
                monthsToWork: months,
                employeesQuantity: qty,
                hourlyRate: (role['hourly_rate'] as num?)?.toDouble() ?? 0,
                perDiem: (role['per_diem'] as num?)?.toDouble() ?? 0,
              ));
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

  void _syncMaterialsFromEstimation(ServiceEntry svc, Map<String, dynamic> result) {
    final estMaterials = result['materials'] as List?;
    if (estMaterials == null || estMaterials.isEmpty) return;

    // Clear if it's the default empty state
    if (svc.materials.isEmpty || (svc.materials.length == 1 && svc.materials[0].materialName.isEmpty)) {
      svc.materials.clear();
    }

    for (final em in estMaterials) {
      final String? catId = em['material_id']?.toString();
      final String name = em['material_name'] ?? '';
      
      // Look for existing to update or add new
      final existingIdx = svc.materials.indexWhere((m) => m.catalogId == catId || m.materialName == name);
      
      if (existingIdx != -1) {
        svc.materials[existingIdx].quantity = (em['quantity'] as num).toDouble();
        svc.materials[existingIdx].unitPrice = (em['unit_price'] as num).toDouble();
        svc.materials[existingIdx].unit = em['unit'] ?? 'und';
      } else {
        svc.materials.add(MaterialEntry(
          catalogId: catId,
          materialName: name,
          quantity: (em['quantity'] as num).toDouble(),
          unitPrice: (em['unit_price'] as num).toDouble(),
          unit: em['unit'] ?? 'und',
        ));
      }
    }
    setState(() {});
  }

  Future<void> _loadCatalogs() async {
    try {
      final supabase = Supabase.instance.client;
      final svcs = await supabase.from('services').select().order('description');
      final mach = await supabase.from('machinery').select().order('description');
      final labr = await supabase.from('labor_roles').select().order('description');
      final matr = await supabase.from('materials').select().order('description');
      
      if (mounted) {
        setState(() {
          _catalogServices = List<Map<String, dynamic>>.from(svcs ?? []);
          _catalogMachinery = List<Map<String, dynamic>>.from(mach ?? []);
          _catalogLaborRoles = List<Map<String, dynamic>>.from(labr ?? []);
          _catalogMaterials = List<Map<String, dynamic>>.from(matr ?? []);
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
      
      final servicesData = List<Map<String, dynamic>>.from(responseServices ?? []);
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
              .select('*, machinery(description, capacity, default_trips_per_day, photo_url, machinery_type)')
              .eq('estimation_id', estId);

          final resources = (responseRes as List).map((r) => {
            'id': r['id'],
            'is_primary_mover': r['is_primary_mover'] ?? true,
            'parent_resource_id': r['parent_resource_id'],
            'machine_id': r['machine_id'],
            'machine_name': r['machinery']?['description'] ?? 'Unknown',
            'photo_url': r['machinery']?['photo_url'],
            'machinery_type': r['machinery']?['machinery_type'] ?? 'hauling',
            'quantity': (r['quantity'] as num).toDouble(),
            'trips_per_day': (r['trips_per_day'] as num).toDouble(),
            'capacity_per_trip': (r['capacity_per_trip'] as num).toDouble(),
            'performance_per_day': (r['performance_per_day'] as num?)?.toDouble() ?? 0.0,
          }).toList();

          // Load materials for this service specifically for the estimation context if any
          final responseEstMat = await supabase
              .from('quote_service_materials')
              .select('*, materials(description, unit, yield_factor)')
              .eq('quote_service_id', svcId);
          
          final estMaterials = (responseEstMat as List).map((m) => {
            'material_id': m['material_id'],
            'material_name': m['material_name'],
            'quantity': (m['quantity'] as num).toDouble(),
            'unit_price': (m['unit_price'] as num).toDouble(),
            'unit': m['unit_name'],
          }).toList();

          estimationData = {
            'id': estId,
            'topsoil_volume': (responseEst['topsoil_volume'] as num).toDouble(),
            'compacted_volume': (responseEst['compacted_volume'] as num).toDouble(),
            'swell_factor': (responseEst['swell_factor'] as num).toDouble(),
            'thickness_inches': (responseEst['thickness_inches'] as num?)?.toDouble() ?? 0.0,
            'total_cy_loose': (responseEst['total_cy_loose'] as num).toDouble(),
            'working_days': (responseEst['total_working_days'] as num).toInt(),
            'start_date': DateTime.parse(responseEst['start_date']),
            'end_date': responseEst['end_date'] != null ? DateTime.parse(responseEst['end_date']) : null,
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

        final machineries = machData.map<MachineryEntry>((m) => MachineryEntry(
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

        // Load labors for this service
        final responseLabor = await supabase
            .from('quote_service_labors')
            .select()
            .eq('quote_service_id', svcId);
        
        final laborData = List<Map<String, dynamic>>.from(responseLabor ?? []);

        final labors = laborData.map<LaborEntry>((l) => LaborEntry(
          roleName: l['role_name'] ?? '',
          monthsToWork: (l['months_to_work'] as num?)?.toDouble() ?? 0,
          employeesQuantity: (l['employees_quantity'] as num?)?.toDouble() ?? 1,
          hourlyRate: (l['hourly_rate'] as num?)?.toDouble() ?? 0,
          perDiem: (l['per_diem'] as num?)?.toDouble() ?? 0,
        )).toList();

        // Load materials for this service
        final responseMat = await supabase
            .from('quote_service_materials')
            .select()
            .eq('quote_service_id', svcId);
        
        final matData = List<Map<String, dynamic>>.from(responseMat ?? []);
        final materials = matData.map<MaterialEntry>((m) => MaterialEntry(
          materialName: m['material_name'] ?? '',
          quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
          unitPrice: (m['unit_price'] as num?)?.toDouble() ?? 0,
          unit: m['unit_name'] ?? 'und', // Or unit_measure if that's the col
          catalogId: m['material_id']?.toString(),
        )).toList();


        loadedServices.add(ServiceEntry(
          name: svcData['name'] ?? '',
          unitOfMeasure: svcData['unit_of_measure'] ?? 'und',
          quantity: (svcData['quantity'] as num?)?.toDouble() ?? 1,
          overheadPercentage: (svcData['overhead_percentage'] as num?)?.toDouble() ?? 0,
          profitPercentage: (svcData['profit_percentage'] as num?)?.toDouble() ?? 0,
          machineries: machineries,
          labors: labors,
          materials: materials,
          estimationData: estimationData,
          catalogId: svcData['service_id']?.toString(), // Map it if it exists in DB, otherwise we match by name below
        ));
      }

      // Fallback: If catalogId is null (e.g. old data), try to match by name
      for (final s in loadedServices) {
        if (s.catalogId == null) {
          final cat = _catalogServices.firstWhere((c) => c['description'] == s.name, orElse: () => {});
          if (cat.isNotEmpty) s.catalogId = cat['id']?.toString();
        }
      }

      setState(() {
        _services = loadedServices.isEmpty ? [ServiceEntry(name: 'Service 1')] : loadedServices;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _services = [ServiceEntry(name: 'Service 1')];
        _isLoadingData = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e', style: GoogleFonts.manrope()), backgroundColor: AppTheme.errorRed),
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
  Future<void> _saveQuote() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a quote title', style: GoogleFonts.manrope()), backgroundColor: AppTheme.errorRed),
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
        await supabase.from('quotes').update({
          'title': _titleController.text.trim(),
          'client_name': _clientController.text.trim(),
          'total_amount': totalAmount,
          'quote_date': _quoteDate.toIso8601String().split('T')[0],
          'status': _selectedStatus,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', widget.quoteToEdit!['id']);
        quoteId = widget.quoteToEdit!['id'];

        // Delete old children to re-insert
        await supabase.from('quote_services').delete().eq('quote_id', quoteId);
      } else {
        final result = await supabase.from('quotes').insert({
          'title': _titleController.text.trim(),
          'client_name': _clientController.text.trim(),
          'total_amount': totalAmount,
          'quote_date': _quoteDate.toIso8601String().split('T')[0],
          'status': _selectedStatus,
        }).select().single();
        quoteId = result['id'];
      }

      // Insert services, machineries, labors
      for (final svc in _services) {
        final svcResult = await supabase.from('quote_services').insert({
          'quote_id': quoteId,
          'name': svc.name,
          'unit_of_measure': svc.unitOfMeasure,
          'quantity': svc.quantity,
          'overhead_percentage': svc.overheadPercentage,
          'profit_percentage': svc.profitPercentage,
        }).select().single();
        final svcId = svcResult['id'];

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

        // Save estimation data if exists
        if (svc.estimationData != null) {
          final est = svc.estimationData!;
          final estResult = await supabase.from('quote_service_estimations').insert({
            'quote_service_id': svcId,
            'topsoil_volume': est['topsoil_volume'] ?? 0,
            'compacted_volume': est['compacted_volume'] ?? 0,
            'swell_factor': est['swell_factor'] ?? 0.15,
            'thickness_inches': est['thickness_inches'] ?? 0,
            'total_cy_loose': est['total_cy_loose'] ?? 0,
            'start_date': (est['start_date'] is String) ? est['start_date'] : (est['start_date'] as DateTime).toIso8601String(),
            'end_date': est['end_date'] != null ? ((est['end_date'] is String) ? est['end_date'] : (est['end_date'] as DateTime).toIso8601String()) : null,
            'total_working_days': est['working_days'] ?? 0,
          }).select().single();

          final estId = estResult['id'];
          final resources = est['resources'] as List?;
          if (resources != null && resources.isNotEmpty) {
            // Phase 1: primaries
            final primaries = resources.where((r) => (r['is_primary_mover'] as bool? ?? true) == true).toList();
            final supports  = resources.where((r) => (r['is_primary_mover'] as bool? ?? true) == false).toList();
            final Map<String, String> localToDbId = {};
            for (final r in primaries) {
              final localId = r['id']?.toString();
              final inserted = await supabase.from('quote_service_estimation_resources').insert({
                'estimation_id': estId,
                'machine_id': r['machine_id'],
                'quantity': r['quantity'] ?? 1,
                'trips_per_day': r['trips_per_day'] ?? 60,
                'capacity_per_trip': r['capacity_per_trip'] ?? 30,
                'performance_per_day': r['performance_per_day'] ?? 0,
                'is_primary_mover': true,
                'parent_resource_id': null,
              }).select().single();
              if (localId != null) localToDbId[localId] = inserted['id'] as String;
            }
            // Phase 2: supports
            if (supports.isNotEmpty) {
              await supabase.from('quote_service_estimation_resources').insert(
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
                    'parent_resource_id': lp != null ? localToDbId[lp] : null,
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
              if (!svc.materials.any((m) => m.catalogId?.toString() == em['material_id']?.toString())) {
                svc.materials.add(MaterialEntry(
                  catalogId: em['material_id']?.toString(),
                  materialName: em['material_name'] ?? '',
                  quantity: (em['quantity'] as num?)?.toDouble() ?? 0,
                  unitPrice: (em['unit_price'] as num?)?.toDouble() ?? 0,
                  unit: em['unit'] ?? 'und',
                ));
              }
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Quote updated!' : 'Quote created!', style: GoogleFonts.manrope(color: Colors.white)),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.manrope()), backgroundColor: AppTheme.errorRed),
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: Column(
            children: [
              _buildWizardHeader(),
              _buildStepIndicator(),
              Expanded(child: _isLoadingData
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen, strokeWidth: 3))
                : _buildCurrentStepContent()),
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
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(_isEditing ? Icons.edit_outlined : Icons.request_quote_outlined, color: AppTheme.primaryGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isEditing ? 'Edit Quote' : 'Create New Quote', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
                Text(_stepSubtitle(), style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500)),
              ],
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.close, color: AppTheme.slate400, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  String _stepSubtitle() {
    switch (_currentStep) {
      case 0: return 'Step 1 of 5 — Basic Information';
      case 1: return 'Step 2 of 5 — Services & Machinery';
      case 2: return 'Step 3 of 5 — Labor & Workforce';
      case 3: return 'Step 4 of 5 — Project Materials';
      case 4: return 'Step 5 de 5 — Summary & Profit';
      default: return '';
    }
  }

  // ── Step Indicator ──
  Widget _buildStepIndicator() {
    final steps = ['Info', 'Machinery', 'Labor', 'Materials', 'Summary'];
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
                if (i > 0) Expanded(child: Container(height: 2, color: isDone ? AppTheme.primaryGreen : const Color(0xFFE2E8F0))),
                GestureDetector(
                  onTap: () => setState(() => _currentStep = i),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? AppTheme.primaryGreen : isDone ? AppTheme.primaryGreen.withOpacity(0.15) : const Color(0xFFE2E8F0),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, color: AppTheme.primaryGreen, size: 16)
                          : Text('${i + 1}', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: isActive ? Colors.white : AppTheme.slate500)),
                    ),
                  ),
                ),
                if (i < steps.length - 1) Expanded(child: Container(height: 2, color: isDone ? AppTheme.primaryGreen : const Color(0xFFE2E8F0))),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Step Content ──
  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0: return _buildStep0Info();
      case 1: return _buildStep1Machinery();
      case 2: return _buildStep2Labor();
      case 3: return _buildStep3Materials();
      case 4: return _buildStep4Summary();
      default: return const SizedBox.shrink();
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
          _sectionTitle('Quote Details'),
          const SizedBox(height: 16),
          _labeledField('Quote Title', TextFormField(
            controller: _titleController,
            style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate900),
            decoration: _inputDeco('e.g. Golf Course Renovation Phase 1', Icons.description_outlined),
          )),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _labeledField('Client / Customer', TextFormField(
                  controller: _clientController,
                  style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate900),
                  decoration: _inputDeco('Client name', Icons.person_outline),
                )),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _labeledField('Quote Date', InkWell(
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 18, color: AppTheme.slate400),
                        const SizedBox(width: 10),
                        Text(DateFormat('MMM dd, yyyy').format(_quoteDate), style: GoogleFonts.manrope(fontSize: 14)),
                      ],
                    ),
                  ),
                )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _labeledField('Status', DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: _inputDeco(null, Icons.flag_outlined),
            style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate900),
            items: ['draft', 'sent', 'accepted', 'rejected'].map((s) => DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1)))).toList(),
            onChanged: (v) { if (v != null) setState(() => _selectedStatus = v); },
          )),
          const SizedBox(height: 28),
          _sectionTitle('Services'),
          const SizedBox(height: 12),
          ..._services.asMap().entries.map((e) => _buildServiceChip(e.key, e.value)),
          const SizedBox(height: 12),
          _addButton('Add Service', () {
            setState(() {
              _services.add(ServiceEntry(name: 'Service ${_services.length + 1}'));
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
              color: isSelected ? AppTheme.primaryGreen.withOpacity(0.12) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryGreen : const Color(0xFFE2E8F0),
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                )
              ] : [
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
                    color: isSelected ? AppTheme.primaryGreen : AppTheme.slate200,
                    width: isSelected ? 6 : 2,
                  ),
                  color: isSelected ? Colors.white : Colors.transparent,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      SizedBox(
                        width: 200,
                        child: GestureDetector(
                          onTapDown: (_) => setState(() => _activeServiceIndex = serviceIndex),
                          child: _SearchableCatalogDropdown(
                            label: 'Service name',
                            items: _catalogServices,
                            excludeItems: _services.map((s) => s.name).where((n) => n != svc.name).toList(),
                            initialValue: svc.name,
                            onSelected: (val, item) {
                              setState(() {
                                _activeServiceIndex = serviceIndex; // Auto-select on interact
                                svc.name = val;
                                if (item != null) {
                                  svc.catalogId = item['id']?.toString();
                                  if (item['unit'] != null) {
                                    svc.unitOfMeasure = item['unit'];
                                  }
                                }
                              });
                            },
                            onAddNew: () => _openCatalogItemAdd('services'),
                          ),
                        ),
                      ),
                      _miniField('Unit', svc.unitOfMeasure, 60, (v) => setState(() { _activeServiceIndex = serviceIndex; svc.unitOfMeasure = v; }), key: ValueKey('unit_${serviceIndex}_${svc.name}'), onTap: () => setState(() => _activeServiceIndex = serviceIndex)),
                      _miniNumField('Qty', svc.quantity, 85, (v) => setState(() { _activeServiceIndex = serviceIndex; svc.quantity = v; }), onTap: () => setState(() => _activeServiceIndex = serviceIndex)),
                      _miniNumField('OH%', svc.overheadPercentage, 55, (v) => setState(() { _activeServiceIndex = serviceIndex; svc.overheadPercentage = v; }), onTap: () => setState(() => _activeServiceIndex = serviceIndex)),
                      _miniNumField('Profit%', svc.profitPercentage, 60, (v) => setState(() { _activeServiceIndex = serviceIndex; svc.profitPercentage = v; }), onTap: () => setState(() => _activeServiceIndex = serviceIndex)),
                      // Estimation Button
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onDoubleTap: () {}, // Prevent bubbling
                          onTapDown: (_) => setState(() => _activeServiceIndex = serviceIndex),
                          onTap: () async {
                            final result = await showDialog(
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

                            if (result != null && result is Map && result['applied'] == true) {
                              setState(() {
                                svc.quantity = (result['total_cy_loose'] as num).toDouble();
                                svc.estimationData = Map<String, dynamic>.from(result as Map); 
                                _syncMachineryFromEstimation(svc, result as Map<String, dynamic>);
                                _syncMaterialsFromEstimation(svc, result as Map<String, dynamic>);
                              });
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 2),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                            ),
                            child: const Icon(Icons.analytics_outlined, color: AppTheme.primaryGreen, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (svc.estimationData != null) ...[
                    const SizedBox(height: 12),
                    _buildEstimationSummaryBoxes(svc),
                  ],
                  const SizedBox(height: 4),
                  Text('Total: \$${_currencyFormat.format(svc.totalSaleV2)}  |  Unit Price: \$${_currencyFormat.format(svc.unitPrice)}',
                    style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.w700)),
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
                    if (_activeServiceIndex >= _services.length) _activeServiceIndex = _services.length - 1;
                  });
                },
                child: const Icon(Icons.delete_outline, color: AppTheme.slate400, size: 18),
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
    if (_services.isEmpty) return Center(child: Text('Add a service first', style: GoogleFonts.manrope(color: AppTheme.slate500)));
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
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Center(child: Text('No machinery added yet. Click below to add one.', style: GoogleFonts.manrope(color: AppTheme.slate500))),
            )
          else
            ...svc.machineries.asMap().entries.map((e) => _buildMachineryCard(svc, e.key, e.value)),
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
        color: m.isPrimaryMover ? Colors.white : AppTheme.slate50.withOpacity(0.5), 
        borderRadius: BorderRadius.circular(12),
        border: Border(
           left: BorderSide(color: m.isPrimaryMover ? const Color(0xFFE2E8F0) : AppTheme.slate200, width: m.isPrimaryMover ? 1 : 4),
           top: const BorderSide(color: Color(0xFFE2E8F0)),
           right: const BorderSide(color: Color(0xFFE2E8F0)),
           bottom: const BorderSide(color: Color(0xFFE2E8F0)),
        )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (m.machineName != '' && _catalogMachinery.any((mx) => mx['description'] == m.machineName)) ...[
                 Builder(builder: (context) {
                    final item = _catalogMachinery.firstWhere((mx) => mx['description'] == m.machineName);
                    final String? photoUrl = item['photo_url'];
                    
                    return Container(
                      width: 50, height: 40,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.slate50,
                        border: Border.all(color: AppTheme.slate200),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: (photoUrl != null && photoUrl.isNotEmpty)
                        ? Image.network(
                            photoUrl, 
                            fit: BoxFit.cover, 
                            errorBuilder: (c, e, s) => Container(
                              color: AppTheme.slate50,
                              child: const Icon(Icons.precision_manufacturing, size: 20, color: AppTheme.slate400),
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: AppTheme.slate50,
                            child: const Icon(Icons.precision_manufacturing, size: 20, color: AppTheme.slate400),
                          ),
                    );
                 }),
              ],
              Text('Machine ${index + 1}', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
              const SizedBox(width: 8),
              if (m.isPrimaryMover)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF11D411).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Row(children: [
                    const Icon(Icons.star, size: 10, color: Color(0xFF11D411)),
                    const SizedBox(width: 4),
                    Text('PRIMARY', style: GoogleFonts.manrope(fontSize: 8, fontWeight: FontWeight.w800, color: const Color(0xFF11D411))),
                  ]),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.slate200.withOpacity(0.5), borderRadius: BorderRadius.circular(4)),
                  child: Row(children: [
                    const Icon(Icons.build_circle, size: 10, color: AppTheme.slate600),
                    const SizedBox(width: 4),
                    Text('SUPPORT', style: GoogleFonts.manrope(fontSize: 8, fontWeight: FontWeight.w800, color: AppTheme.slate600)),
                  ]),
                ),
              const Spacer(),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => svc.machineries.removeAt(index)),
                  child: const Icon(Icons.close, color: AppTheme.slate400, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 1: Name, Months, Monthly Rent, Qty
          Wrap(
            spacing: 12, runSpacing: 12,
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
                        m.gallonsPerHour = (item['fuel_gallons'] as num).toDouble();
                      }
                      // Pull monthly rent if it exists in catalog (field name sync)
                      if (item['monthly_rent_cost'] != null) {
                        m.monthlyRentCost = (item['monthly_rent_cost'] as num).toDouble();
                      } else if (item['monthly_rent'] != null) {
                        m.monthlyRentCost = (item['monthly_rent'] as num).toDouble();
                      }
                      
                      // Default gasoline cost if not set
                      if (m.gallonCost == 0) m.gallonCost = 5.25;
                    }
                  });
                },
                onAddNew: () => _openCatalogItemAdd('machinery'),
              ),
              _fieldCard('Months', m.monthsToUse, 70, onNum: (v) => setState(() => m.monthsToUse = v)),
              _fieldCard('Monthly Rent \$', m.monthlyRentCost, 100, onNum: (v) => setState(() => m.monthlyRentCost = v)),
              _fieldCard('Qty', m.quantity, 50, onNum: (v) => setState(() => m.quantity = v)),
              _fieldCard('Gal/Hour', m.gallonsPerHour, 70, onNum: (v) => setState(() => m.gallonsPerHour = v)),
              _fieldCard('Gal Cost \$', m.gallonCost, 80, onNum: (v) => setState(() => m.gallonCost = v)),
              _fieldCard('Delivery \$', m.deliveryCost, 80, onNum: (v) => setState(() => m.deliveryCost = v)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
            child: Wrap(
              spacing: 16, runSpacing: 8,
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
          Text('Machinery Summary', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Total Rent: \$${_currencyFormat.format(svc.totalMachinery)}', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate700, fontWeight: FontWeight.w600)),
              Text('Total Delivery: \$${_currencyFormat.format(svc.totalDelivery)}', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate700, fontWeight: FontWeight.w600)),
              Text('Total Gas: \$${_currencyFormat.format(svc.totalGasoline)}', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate700, fontWeight: FontWeight.w600)),
              Text('Combined: \$${_currencyFormat.format(svc.totalMachinery + svc.totalGasoline + svc.totalDelivery)}', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.primaryGreen, fontWeight: FontWeight.w800)),
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
    if (_services.isEmpty) return Center(child: Text('Add a service first', style: GoogleFonts.manrope(color: AppTheme.slate500)));
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
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Center(child: Text('No labor added yet. Click below to add one.', style: GoogleFonts.manrope(color: AppTheme.slate500))),
            )
          else
            ...svc.labors.asMap().entries.map((e) => _buildLaborCard(svc, e.key, e.value)),
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
            setState(() => svc.labors.add(LaborEntry(monthsToWork: initialMonths)));
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
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Labor ${index + 1}', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
              const Spacer(),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => svc.labors.removeAt(index)),
                  child: const Icon(Icons.close, color: AppTheme.slate400, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12, runSpacing: 12,
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
              _fieldCard('Months', l.monthsToWork, 80, onNum: (v) => setState(() => l.monthsToWork = v)),
              _fieldCard('Employees', l.employeesQuantity, 80, onNum: (v) => setState(() => l.employeesQuantity = v)),
              _fieldCard('Hourly Rate \$', l.hourlyRate, 100, onNum: (v) => setState(() => l.hourlyRate = v), key: ValueKey('rate_${index}_${l.roleName}')),
              _fieldCard('Per Diem \$', l.perDiem, 100, onNum: (v) => setState(() => l.perDiem = v)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
            child: Wrap(
              spacing: 16, runSpacing: 8,
              children: [
                _calcChip('Hours/Mo', l.hoursPerMonth),
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
          Text('Labor Summary', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Total Pay: \$${_currencyFormat.format(svc.totalLabor)}', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate700, fontWeight: FontWeight.w600)),
              Text('Total PerDiem: \$${_currencyFormat.format(svc.totalPerDiem)}', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate700, fontWeight: FontWeight.w600)),
              Text('Combined: \$${_currencyFormat.format(svc.totalLabor + svc.totalPerDiem)}', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.primaryGreen, fontWeight: FontWeight.w800)),
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
    final svc = _services[_activeServiceIndex];
    return Padding(
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
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Center(child: Text('No materials added yet. Estimation values will appear here or click below to manually add.', textAlign: TextAlign.center, style: GoogleFonts.manrope(color: AppTheme.slate500))),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: svc.materials.length,
                itemBuilder: (ctx, idx) => _buildMaterialCard(svc, idx, svc.materials[idx]),
              ),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Material ${index + 1}', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => svc.materials.removeAt(index)),
                child: const Icon(Icons.close, color: AppTheme.slate400, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: [
              _SearchableCatalogDropdown(
                label: 'Name / Description', width: 200,
                items: _catalogMaterials,
                initialValue: m.materialName,
                onSelected: (val, item) {
                  setState(() {
                    m.materialName = val;
                    if (item != null) {
                      m.unit = item['unit'] ?? 'und';
                      m.catalogId = item['id']?.toString();
                    }
                  });
                },
                onAddNew: () => _openCatalogItemAdd('materials'),
              ),
              _fieldCard('Quantity', m.quantity, 80, onNum: (v) => setState(() => m.quantity = v)),
              _fieldCard('Unit', 0, 80, initialText: m.unit, onText: (v) => setState(() => m.unit = v)),
              _fieldCard('Unit Price \$', m.unitPrice, 100, onNum: (v) => setState(() => m.unitPrice = v)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Spacer(),
                Text('TOTAL: ', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate500)),
                Text('\$${_currencyFormat.format(m.total)}', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen)),
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
      decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Materials Summary', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
          Text('Total: \$${_currencyFormat.format(svc.totalMaterials)}', style: GoogleFonts.manrope(fontSize: 15, color: AppTheme.primaryGreen, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  STEP 4: SUMMARY
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep4Summary() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Quote: ${_titleController.text}'),
          const SizedBox(height: 20),
          ..._services.asMap().entries.map((e) => _buildServiceSummaryCard(e.key, e.value)),
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
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${svc.name}  (${svc.quantity} ${svc.unitOfMeasure})', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
          const SizedBox(height: 16),
          _summaryRow('Total Machinery', svc.totalMachinery),
          _summaryRow('Total Delivery', svc.totalDelivery),
          _summaryRow('Total Gasoline', svc.totalGasoline),
          _summaryRow('Total Labor', svc.totalLabor),
          _summaryRow('Total PerDiem', svc.totalPerDiem),
          _summaryRow('Total Materials', svc.totalMaterials, highlight: svc.totalMaterials > 0),
          const Divider(height: 24),
          _summaryRow('Sub Total', svc.subTotal, bold: true),
          _summaryRow('Overhead (${svc.overheadPercentage}%)', svc.overheadAmount),
          _summaryRow('Total + Overhead', svc.totalPlusOverhead),
          _summaryRow('Profit (${svc.profitPercentage}%)', svc.profitAmount),
          const Divider(height: 24),
          _summaryRow('Sale Total (V2)', svc.totalSaleV2, bold: true, highlight: true),
          _summaryRow('Unit Price', svc.unitPrice),
        ],
      ),
    );
  }

  Widget _buildGrandTotal() {
    final grandTotal = _services.fold(0.0, (s, svc) => s + svc.totalSaleV2);
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
          Text('GRAND TOTAL', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
          Text('\$${_currencyFormat.format(grandTotal)}', style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.manrope(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: AppTheme.slate700)),
          Text('\$${_currencyFormat.format(value)}', style: GoogleFonts.manrope(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: highlight ? AppTheme.primaryGreen : AppTheme.slate900)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  SERVICE TABS (used in Step 1 and 2)
  // ══════════════════════════════════════════════════════════════
  Widget _buildServiceTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _services.asMap().entries.map((e) {
          final isActive = e.key == _activeServiceIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _activeServiceIndex = e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primaryGreen : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: isActive ? null : Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    e.value.name.isEmpty ? 'Service ${e.key + 1}' : e.value.name,
                    style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: isActive ? Colors.white : AppTheme.slate700),
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
            _footerBtn('Back', Icons.arrow_back, false, () => setState(() => _currentStep--))
          else
            const SizedBox.shrink(),
          Row(
            children: [
              _footerBtn('Cancel', null, false, () => Navigator.of(context).pop()),
              const SizedBox(width: 12),
              if (_currentStep < 4)
                _footerBtn('Next', Icons.arrow_forward, true, () => setState(() => _currentStep++))
              else
                _footerBtn(_isSaving ? 'Saving...' : 'Save Quote', Icons.check, true, _isSaving ? null : _saveQuote),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerBtn(String label, IconData? icon, bool primary, VoidCallback? onTap) {
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: primary ? (onTap != null ? AppTheme.primaryGreen : AppTheme.slate400) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: primary ? null : Border.all(color: const Color(0xFFCBD5E1)),
            boxShadow: primary ? [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))] : null,
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
              Text(label, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: primary ? Colors.white : AppTheme.slate700)),
              if (icon != null && label != 'Back') ...[
                const SizedBox(width: 6),
                Icon(icon, size: 16, color: primary ? Colors.white : AppTheme.slate700),
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
    return Text(title, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.slate900));
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
      period = '${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd').format(endDate)}';
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
          Text(label, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.slate500)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
        ],
      ),
    );
  }


  Widget _labeledField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
        const SizedBox(height: 6),
        field,
      ],
    );
  }

  InputDecoration _inputDeco(String? hint, [IconData? icon]) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 13),
      prefixIcon: icon != null ? Icon(icon, color: AppTheme.slate400, size: 18) : null,
      filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 2)),
    );
  }

  Widget _addButton(String label, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primaryGreen, style: BorderStyle.solid),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, color: AppTheme.primaryGreen, size: 18),
              const SizedBox(width: 6),
              Text(label, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldCard(String label, double? value, double width, {String? initialText, Function(double)? onNum, Function(String)? onText, Key? key}) {
    final val = onText != null ? initialText! : (value != null ? value.toString() : '');
    return SizedBox(
      key: key,
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.slate500)),
          const SizedBox(height: 4),
          _AutoSelectField(
            initialValue: val,
            onChanged: (v) {
              if (onNum != null) onNum(double.tryParse(v) ?? 0);
              if (onText != null) onText(v);
            },
            keyboardType: onNum != null ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            inputFormatters: onNum != null ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))] : null,
          ),
        ],
      ),
    );
  }

  Widget _miniField(String label, String value, double width, Function(String) onChange, {Key? key, VoidCallback? onTap}) {
    return SizedBox(
      key: key,
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.slate500)),
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

  Widget _miniNumField(String label, double value, double width, Function(double) onChange, {Key? key, VoidCallback? onTap}) {
    return SizedBox(
      key: key,
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.slate500)),
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

  Widget _calcChip(String label, double value, {bool highlight = false, bool isCurrency = true}) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.slate400)),
        Text(
          isCurrency ? '\$${_currencyFormat.format(value)}' : NumberFormat('#,##0.00').format(value),
          style: GoogleFonts.manrope(fontSize: 12, fontWeight: highlight ? FontWeight.w800 : FontWeight.w600, color: highlight ? AppTheme.primaryGreen : AppTheme.slate900),
        ),
      ],
    );
  }

  // ═══════════════════════════════
  // QUICK ADD METHODS
  // ═══════════════════════════════
  void _openCatalogItemAdd(String type) {
    Widget? dialog;
    if (type == 'services') dialog = ServiceDialog();
    if (type == 'machinery') dialog = MachineryDialog();
    if (type == 'labor') dialog = LaborRoleDialog();
    // if (type == 'materials') dialog = MaterialDialog(); // Assume we might add later or use generic
    
    if (dialog != null) {
      showDialog(context: context, builder: (context) => dialog!)
        .then((success) { if (success == true) _loadCatalogs(); });
    }
  }
}

// ══════════════════════════════════════════════════════════════
//  SEARCHABLE DROPDOWN COMPONENT
// ══════════════════════════════════════════════════════════════

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
          Text(label, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.slate500)),
          const SizedBox(height: 4),
          Autocomplete<Map<String, dynamic>>(
            initialValue: TextEditingValue(text: initialValue),
            displayStringForOption: (option) => option['description'] ?? '',
            optionsBuilder: (textEditingValue) {
              final available = items.where((i) => !excludeItems.contains(i['description']));
              
              final t = textEditingValue.text.toLowerCase();
              // If empty or a default placeholder, show all available
              if (t.isEmpty || t.startsWith('service') || t.startsWith('machine') || t.startsWith('role')) {
                return available;
              }
              
              return available.where((i) => i['description'].toString().toLowerCase().contains(t)).toList();
            },
            onSelected: (option) => onSelected(option['description'], option),
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate900),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search or type...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 1.5)),
                  suffixIcon: const Icon(Icons.search, size: 16, color: AppTheme.slate400),
                ),
                onChanged: (v) => onSelected(v, null),
                onTap: () {
                  final t = controller.text.toLowerCase();
                  if (t.startsWith('service') || t.startsWith('machine') || t.startsWith('role')) {
                    controller.clear();
                    onSelected('', null);
                  }
                },
              );
            },
            optionsViewBuilder: (context, onSelectedInternal, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 400,
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppTheme.slate200),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (options.isNotEmpty)
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                              final photoUrl = option['photo_url'] as String?;
                              
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                leading: label.toLowerCase().contains('machine') 
                                  ? Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8), 
                                        color: AppTheme.slate50, 
                                        border: Border.all(color: AppTheme.slate200),
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
                                        ],
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: (photoUrl != null && photoUrl.isNotEmpty)
                                        ? Image.network(
                                            photoUrl, 
                                            fit: BoxFit.cover, 
                                            errorBuilder: (c, e, s) => const Center(child: Icon(Icons.precision_manufacturing, size: 22, color: AppTheme.slate400)),
                                            loadingBuilder: (context, child, progress) {
                                              if (progress == null) return child;
                                              return const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)));
                                            },
                                          )
                                        : const Center(child: Icon(Icons.precision_manufacturing, size: 22, color: AppTheme.slate400)),
                                    )
                                  : null,
                                title: Text(option['description'] ?? '', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate900)),
                                subtitle: option['hourly_rate'] != null 
                                  ? Text('\$${option['hourly_rate']}/hr', style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate500))
                                  : (option['unit'] != null ? Text('Unit: ${option['unit']}', style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate500)) : null),
                                hoverColor: AppTheme.primaryGreen.withOpacity(0.05),
                                onTap: () => onSelectedInternal(option),
                              );
                              },
                            ),
                          ),
                        const Divider(height: 1),
                        InkWell(
                          onTap: () {
                            onAddNew();
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            color: AppTheme.primaryGreen.withOpacity(0.05),
                            child: Row(
                              children: [
                                const Icon(Icons.add_circle_outline, size: 18, color: AppTheme.primaryGreen),
                                const SizedBox(width: 8),
                                Text('Add New to Catalog', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
                              ],
                            ),
                          ),
                        ),
                      ],
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
        _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
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
      onTap: widget.onTap,
      keyboardType: widget.isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      inputFormatters: widget.isNumeric ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))] : null,
      style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate900),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 1.5)),
      ),
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
        _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 1.5)),
      ),
      onChanged: widget.onChanged,
    );
  }
}
