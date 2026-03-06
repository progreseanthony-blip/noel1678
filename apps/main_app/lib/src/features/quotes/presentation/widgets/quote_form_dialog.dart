import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:intl/intl.dart';

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

  MachineryEntry({
    this.machineName = '',
    this.monthsToUse = 0,
    this.monthlyRentCost = 0,
    this.quantity = 1,
    this.gallonsPerHour = 0,
    this.gallonCost = 0,
  });

  double get ratePerHour => monthlyRentCost / 160;
  double get hoursWorkedPerMonth => monthsToUse * quantity * 220;
  double get totalRent => ratePerHour * hoursWorkedPerMonth;
  double get totalGallons => hoursWorkedPerMonth * gallonsPerHour;
  double get totalGallonsCost => totalGallons * gallonCost;
  double get totalGeneral => totalRent + totalGallonsCost;
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

class ServiceEntry {
  String name;
  String unitOfMeasure;
  double quantity;
  double overheadPercentage;
  double profitPercentage;
  List<MachineryEntry> machineries;
  List<LaborEntry> labors;

  ServiceEntry({
    this.name = '',
    this.unitOfMeasure = 'und',
    this.quantity = 1,
    this.overheadPercentage = 0,
    this.profitPercentage = 0,
    List<MachineryEntry>? machineries,
    List<LaborEntry>? labors,
  })  : machineries = machineries ?? [],
        labors = labors ?? [];

  double get totalMachinery => machineries.fold(0.0, (s, m) => s + m.totalRent);
  double get totalGasoline => machineries.fold(0.0, (s, m) => s + m.totalGallonsCost);
  double get totalLabor => labors.fold(0.0, (s, l) => s + l.totalPay);
  double get totalPerDiem => labors.fold(0.0, (s, l) => s + l.totalPerDiem);
  double get subTotal => totalMachinery + totalGasoline + totalLabor + totalPerDiem;
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
  String _selectedStatus = 'draft';

  // Step 1+ - Services
  List<ServiceEntry> _services = [];
  int _activeServiceIndex = 0;

  final _currencyFormat = NumberFormat('#,##0.00', 'en_US');

  bool get _isEditing => widget.quoteToEdit != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.quoteToEdit?['title'] ?? '');
    _selectedStatus = widget.quoteToEdit?['status'] ?? 'draft';

    if (_isEditing) {
      _loadExistingData();
    } else {
      _services.add(ServiceEntry(name: 'Service 1'));
    }
  }

  Future<void> _loadExistingData() async {
    setState(() => _isLoadingData = true);
    try {
      final supabase = Supabase.instance.client;
      final quoteId = widget.quoteToEdit!['id'];

      // Load services for this quote
      final servicesData = await supabase
          .from('quote_services')
          .select()
          .eq('quote_id', quoteId)
          .order('created_at');

      final loadedServices = <ServiceEntry>[];

      for (final svcData in servicesData) {
        final svcId = svcData['id'];

        // Load machineries for this service
        final machData = await supabase
            .from('quote_service_machineries')
            .select()
            .eq('quote_service_id', svcId);

        final machineries = machData.map<MachineryEntry>((m) => MachineryEntry(
          machineName: m['machine_name'] ?? '',
          monthsToUse: (m['months_to_use'] as num?)?.toDouble() ?? 0,
          monthlyRentCost: (m['monthly_rent_cost'] as num?)?.toDouble() ?? 0,
          quantity: (m['quantity'] as num?)?.toDouble() ?? 1,
          gallonsPerHour: (m['gallons_per_hour'] as num?)?.toDouble() ?? 0,
          gallonCost: (m['gallon_cost'] as num?)?.toDouble() ?? 0,
        )).toList();

        // Load labors for this service
        final laborData = await supabase
            .from('quote_service_labors')
            .select()
            .eq('quote_service_id', svcId);

        final labors = laborData.map<LaborEntry>((l) => LaborEntry(
          roleName: '',
          monthsToWork: (l['months_to_work'] as num?)?.toDouble() ?? 0,
          employeesQuantity: (l['employees_quantity'] as num?)?.toDouble() ?? 1,
          hourlyRate: (l['hourly_rate'] as num?)?.toDouble() ?? 0,
          perDiem: (l['per_diem'] as num?)?.toDouble() ?? 0,
        )).toList();

        loadedServices.add(ServiceEntry(
          name: svcData['name'] ?? '',
          unitOfMeasure: svcData['unit_of_measure'] ?? 'und',
          quantity: (svcData['quantity'] as num?)?.toDouble() ?? 1,
          overheadPercentage: (svcData['overhead_percentage'] as num?)?.toDouble() ?? 0,
          profitPercentage: (svcData['profit_percentage'] as num?)?.toDouble() ?? 0,
          machineries: machineries,
          labors: labors,
        ));
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

      if (_isEditing) {
        await supabase.from('quotes').update({
          'title': _titleController.text.trim(),
          'status': _selectedStatus,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', widget.quoteToEdit!['id']);
        quoteId = widget.quoteToEdit!['id'];

        // Delete old children to re-insert
        await supabase.from('quote_services').delete().eq('quote_id', quoteId);
      } else {
        final result = await supabase.from('quotes').insert({
          'title': _titleController.text.trim(),
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
          });
        }

        for (final l in svc.labors) {
          await supabase.from('quote_service_labors').insert({
            'quote_service_id': svcId,
            'months_to_work': l.monthsToWork,
            'employees_quantity': l.employeesQuantity,
            'hourly_rate': l.hourlyRate,
            'per_diem': l.perDiem,
          });
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
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10))],
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
            decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
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
      case 0: return 'Step 1 of 4 — Basic Information';
      case 1: return 'Step 2 of 4 — Services & Machinery';
      case 2: return 'Step 3 of 4 — Labor & Workforce';
      case 3: return 'Step 4 of 4 — Summary & Profit';
      default: return '';
    }
  }

  // ── Step Indicator ──
  Widget _buildStepIndicator() {
    final steps = ['Info', 'Machinery', 'Labor', 'Summary'];
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
                      color: isActive ? AppTheme.primaryGreen : isDone ? AppTheme.primaryGreen.withValues(alpha: 0.15) : const Color(0xFFE2E8F0),
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
      case 3: return _buildStep3Summary();
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
          const SizedBox(height: 20),
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

  Widget _buildServiceChip(int index, ServiceEntry svc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _activeServiceIndex == index ? AppTheme.primaryGreen.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _activeServiceIndex == index ? AppTheme.primaryGreen : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeServiceIndex = index),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 200,
                        child: TextFormField(
                          initialValue: svc.name,
                          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate900),
                          decoration: InputDecoration(hintText: 'Service name', border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                          onChanged: (v) => svc.name = v,
                        ),
                      ),
                      const Spacer(),
                      _miniField('Unit', svc.unitOfMeasure, 60, (v) => setState(() => svc.unitOfMeasure = v)),
                      const SizedBox(width: 8),
                      _miniNumField('Qty', svc.quantity, 60, (v) => setState(() => svc.quantity = v)),
                      const SizedBox(width: 8),
                      _miniNumField('OH%', svc.overheadPercentage, 55, (v) => setState(() => svc.overheadPercentage = v)),
                      const SizedBox(width: 8),
                      _miniNumField('Profit%', svc.profitPercentage, 60, (v) => setState(() => svc.profitPercentage = v)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Total: \$${_currencyFormat.format(svc.totalSaleV2)}  |  Unit Price: \$${_currencyFormat.format(svc.unitPrice)}',
                    style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          if (_services.length > 1) ...[
            const SizedBox(width: 8),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _services.removeAt(index);
                    if (_activeServiceIndex >= _services.length) _activeServiceIndex = _services.length - 1;
                  });
                },
                child: const Icon(Icons.delete_outline, color: AppTheme.slate400, size: 18),
              ),
            ),
          ],
        ],
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
          _sectionTitle('Machinery for "${svc.name}"'),
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
              Text('Machine ${index + 1}', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
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
              _fieldCard('Machine Name', null, 180, initialText: m.machineName, onText: (v) => setState(() => m.machineName = v)),
              _fieldCard('Months', m.monthsToUse, 80, onNum: (v) => setState(() => m.monthsToUse = v)),
              _fieldCard('Monthly Rent \$', m.monthlyRentCost, 110, onNum: (v) => setState(() => m.monthlyRentCost = v)),
              _fieldCard('Qty', m.quantity, 60, onNum: (v) => setState(() => m.quantity = v)),
              _fieldCard('Gal/Hour', m.gallonsPerHour, 80, onNum: (v) => setState(() => m.gallonsPerHour = v)),
              _fieldCard('Gal Cost \$', m.gallonCost, 90, onNum: (v) => setState(() => m.gallonCost = v)),
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
                _calcChip('Hours/Mo', m.hoursWorkedPerMonth),
                _calcChip('Total Rent', m.totalRent),
                _calcChip('Total Gal', m.totalGallons),
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
        color: AppTheme.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Machinery Summary', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Total Rent: \$${_currencyFormat.format(svc.totalMachinery)}', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate700, fontWeight: FontWeight.w600)),
              Text('Total Gas: \$${_currencyFormat.format(svc.totalGasoline)}', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate700, fontWeight: FontWeight.w600)),
              Text('Combined: \$${_currencyFormat.format(svc.totalMachinery + svc.totalGasoline)}', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.primaryGreen, fontWeight: FontWeight.w800)),
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
          _sectionTitle('Labor for "${svc.name}"'),
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
            setState(() => svc.labors.add(LaborEntry()));
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
              _fieldCard('Role/Position', null, 180, initialText: l.roleName, onText: (v) => setState(() => l.roleName = v)),
              _fieldCard('Months', l.monthsToWork, 80, onNum: (v) => setState(() => l.monthsToWork = v)),
              _fieldCard('Employees', l.employeesQuantity, 80, onNum: (v) => setState(() => l.employeesQuantity = v)),
              _fieldCard('Hourly Rate \$', l.hourlyRate, 100, onNum: (v) => setState(() => l.hourlyRate = v)),
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
        color: AppTheme.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
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
  //  STEP 3: SUMMARY
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep3Summary() {
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
          _summaryRow('Total Gasoline', svc.totalGasoline),
          _summaryRow('Total Labor', svc.totalLabor),
          _summaryRow('Total PerDiem', svc.totalPerDiem),
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
        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
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
              if (_currentStep < 3)
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
            boxShadow: primary ? [BoxShadow(color: AppTheme.primaryGreen.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))] : null,
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

  Widget _fieldCard(String label, double? value, double width, {String? initialText, Function(double)? onNum, Function(String)? onText}) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.slate500)),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: onText != null ? initialText : (value != null && value != 0 ? value.toString() : ''),
            keyboardType: onNum != null ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            inputFormatters: onNum != null ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))] : null,
            style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate900),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 1.5)),
            ),
            onChanged: (v) {
              if (onNum != null) onNum(double.tryParse(v) ?? 0);
              if (onText != null) onText(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _miniField(String label, String value, double width, Function(String) onChange) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.slate400)),
          SizedBox(
            height: 28,
            child: TextFormField(
              initialValue: value,
              style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate900),
              decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFE2E8F0)))),
              onChanged: onChange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniNumField(String label, double value, double width, Function(double) onChange) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.slate400)),
          SizedBox(
            height: 28,
            child: TextFormField(
              initialValue: value != 0 ? value.toString() : '',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate900),
              decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFE2E8F0)))),
              onChanged: (v) => onChange(double.tryParse(v) ?? 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _calcChip(String label, double value, {bool highlight = false}) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.slate400)),
        Text(
          '\$${_currencyFormat.format(value)}',
          style: GoogleFonts.manrope(fontSize: 12, fontWeight: highlight ? FontWeight.w800 : FontWeight.w600, color: highlight ? AppTheme.primaryGreen : AppTheme.slate900),
        ),
      ],
    );
  }
}
