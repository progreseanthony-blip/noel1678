import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:intl/intl.dart';
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

  // Form Controllers
  final _topsoilCtrl = TextEditingController(text: '0');
  final _compactedCtrl = TextEditingController(text: '0');
  final _swellFactorCtrl = TextEditingController(text: '0.15');
  DateTime _startDate = DateTime.now();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _estimationId;

  List<Map<String, dynamic>> _machineryCatalog = [];
  List<Map<String, dynamic>> _selectedResources = [];

  Map<String, dynamic>? _calculationResult;
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
    for (final res in _selectedResources) {
      if (res['qtyCtrl'] is TextEditingController) (res['qtyCtrl'] as TextEditingController).dispose();
      if (res['tripsCtrl'] is TextEditingController) (res['tripsCtrl'] as TextEditingController).dispose();
      if (res['capCtrl'] is TextEditingController) (res['capCtrl'] as TextEditingController).dispose();
      if (res['perDayCtrl'] is TextEditingController) (res['perDayCtrl'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final catalog = await ref.read(catalogsServiceProvider).getMachinery();
      _machineryCatalog = catalog;

      final serviceId = widget.service['id'];
      final persistentData = widget.service['estimationData'] as Map<String, dynamic>?;

      if (persistentData != null) {
        // Load from temporary local data (unsaved wizard state)
        _topsoilCtrl.text = persistentData['topsoil_volume']?.toString() ?? '0';
        _compactedCtrl.text = persistentData['compacted_volume']?.toString() ?? '0';
        _swellFactorCtrl.text = persistentData['swell_factor']?.toString() ?? '0.15';
        _startDate = persistentData['start_date'] ?? DateTime.now();
        
        final resList = persistentData['resources'] as List?;
        if (resList != null) {
           _selectedResources = resList.map((r) => {
              ...Map<String, dynamic>.from(r),
              'photo_url': r['photo_url'] ?? _machineryCatalog.firstWhere((m) => m['id'] == r['machine_id'], orElse: () => {})['photo_url'],
              'machinery_type': r['machinery_type'] ?? _machineryCatalog.firstWhere((m) => m['id'] == r['machine_id'], orElse: () => {})['machinery_type'] ?? 'hauling',
              'qtyCtrl': TextEditingController(text: r['quantity']?.toString() ?? '1'),
              'tripsCtrl': TextEditingController(text: r['trips_per_day']?.toString() ?? '60'),
              'capCtrl': TextEditingController(text: r['capacity_per_trip']?.toString() ?? '1'),
              'perDayCtrl': TextEditingController(text: ((r['trips_per_day'] as num? ?? 60) * (r['capacity_per_trip'] as num? ?? 1)).toStringAsFixed(0)),
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
          _startDate = DateTime.parse(estimation['start_date']);

          final resources = await ref.read(quotesServiceProvider).getResourcesForEstimation(_estimationId!);
          _selectedResources = resources.map((r) => {
            'machine_id': r['machine_id'],
            'machine_name': r['machinery']?['description'] ?? 'Unknown',
            'photo_url': r['machinery']?['photo_url'],
            'quantity': (r['quantity'] as num).toDouble(),
            'trips_per_day': (r['trips_per_day'] as num).toDouble(),
            'capacity_per_trip': (r['capacity_per_trip'] as num).toDouble(),
            'machinery_type': r['machinery_type'] ?? r['machinery']?['machinery_type'] ?? 'hauling',
            'qtyCtrl': TextEditingController(text: r['quantity']?.toString() ?? '1'),
            'tripsCtrl': TextEditingController(text: r['trips_per_day']?.toString() ?? '60'),
            'capCtrl': TextEditingController(text: r['capacity_per_trip']?.toString() ?? '30'),
            'perDayCtrl': TextEditingController(text: ((r['trips_per_day'] as num? ?? 60) * (r['capacity_per_trip'] as num? ?? 30)).toStringAsFixed(0)),
          }).toList();
        } else {
           // New estimation but DB service
           _compactedCtrl.text = widget.service['quantity']?.toString() ?? '0';
           if (_machineryCatalog.isNotEmpty) _addResource(_machineryCatalog.first);
        }
      } else {
        // Entirely new service in wizard
        _compactedCtrl.text = widget.service['quantity']?.toString() ?? '0';
        if (_machineryCatalog.isNotEmpty) {
          _addResource(_machineryCatalog.first);
        }
      }

      _runCalculation();
    } catch (e) {
      debugPrint('Error loading estimation: $e');
    }
    setState(() => _isLoading = false);
  }

  void _addResource(Map<String, dynamic> machine) {
    setState(() {
      final qty = 1.0;
      final trips = (machine['trips_per_day'] as num?)?.toDouble() ?? 60.0;
      final capacity = (machine['capacity_yards'] as num?)?.toDouble() ?? 30.0;
      
      _selectedResources.add({
        'machine_id': machine['id'],
        'machine_name': machine['description'],
        'photo_url': machine['photo_url'],
        'quantity': qty,
        'trips_per_day': trips,
        'capacity_per_trip': capacity,
        'machinery_type': machine['machinery_type'] ?? 'hauling',
        'qtyCtrl': TextEditingController(text: qty.toString()),
        'tripsCtrl': TextEditingController(text: trips.toString()),
        'capCtrl': TextEditingController(text: capacity.toString()),
        'perDayCtrl': TextEditingController(text: (trips * capacity).toStringAsFixed(0)),
      });
      _runCalculation();
    });
  }

  void _runCalculation() {
    if (_topsoilCtrl.text.isEmpty || _compactedCtrl.text.isEmpty) return;

    final result = EstimationCalculator.calculate(
      topsoilVolume: double.tryParse(_topsoilCtrl.text) ?? 0,
      compactedVolume: double.tryParse(_compactedCtrl.text) ?? 0,
      swellFactor: double.tryParse(_swellFactorCtrl.text) ?? 0.15,
      startDate: _startDate,
      resources: _selectedResources.map((r) => {
        'quantity': r['quantity'],
        'trips_per_day': r['trips_per_day'],
        'capacity_per_trip': r['capacity_per_trip'],
        'machine_name': r['machine_name'],
        'machinery_type': r['machinery_type'],
      }).toList(),
    );

    setState(() {
      _calculationResult = result;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final topVal = double.tryParse(_topsoilCtrl.text) ?? 0;
    final compVal = double.tryParse(_compactedCtrl.text) ?? 0;
    final swellVal = double.tryParse(_swellFactorCtrl.text) ?? 0.15;

    if (widget.service['id'] == null) {
      // Local application for unsaved services
      if (mounted) {
        Navigator.pop(context, {
          'applied': true,
          'total_cy_loose': compVal, // User specifically asked to sync compacted volume to Qty
          'calculated_loose': _calculationResult?['totalCYLoose'] ?? 0,
          'working_days': _calculationResult?['workingDays'] ?? 0,
          'end_date': _calculationResult?['endDate'],
          'resources': _selectedResources.map((r) => {
             ...r,
             'qtyCtrl': null, 'tripsCtrl': null, 'capCtrl': null, 'perDayCtrl': null // Strip controllers for storage
          }).toList(),
          'topsoil_volume': topVal,
          'compacted_volume': compVal,
          'swell_factor': swellVal,
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
        'total_cy_loose': _calculationResult?['totalCYLoose'] ?? 0,
        'start_date': _startDate.toIso8601String(),
        'end_date': (_calculationResult?['endDate'] as DateTime?)?.toIso8601String(),
        'total_working_days': _calculationResult?['workingDays'] ?? 0,
      };

      final savedEstimation = await ref.read(quotesServiceProvider).upsertEstimation(estimationData);
      await ref.read(quotesServiceProvider).saveResources(savedEstimation['id'], _selectedResources);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estimation saved successfully'), backgroundColor: AppTheme.primaryGreen),
        );
        Navigator.pop(context, {
          'applied': true,
          'total_cy_loose': compVal, // Sync compacted volume to Qty
          'calculated_loose': _calculationResult?['totalCYLoose'] ?? 0,
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        width: 1600, // Widened for 3 columns and calendar
        height: 850,
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
                  Expanded(
                    child: _showCalendar ? _buildCalendarView() : _buildThreeColumnLayout(),
                  ),
                  _buildFooter(),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
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
                Text('Estimation & Production Planning', style: GoogleFonts.manrope(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                Text('Service: ${widget.service['name']}', style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 13)),
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

  Widget _buildThreeColumnLayout() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Column 1: Initial Volume & Settings (Flex 5 - approx 50% of original)
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _inputLabel('Factors'),
                    const SizedBox(height: 12),
                    _textField(_topsoilCtrl, 'Topsoil', Icons.layers_outlined),
                    const SizedBox(height: 8),
                    _textField(_compactedCtrl, 'Compacted', Icons.compress_outlined),
                    const SizedBox(height: 8),
                    _textField(_swellFactorCtrl, 'Swell %', Icons.expand_outlined),
                    const Divider(height: 32),
                    _inputLabel('Schedule'),
                    const SizedBox(height: 12),
                    _datePicker(),
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 32),
            // Column 2: Resources (Flex 8 - approx 80% of original)
            Expanded(
              flex: 8,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _inputLabel('Resources'),
                    const SizedBox(height: 8),
                    ..._selectedResources.asMap().entries.map((e) => _resourceItem(e.key, e.value)),
                    const SizedBox(height: 8),
                    _addResourceButton(),
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 32),
            // Column 3: Summary Cards (Flex 12 - remains wide)
            Expanded(
              flex: 12,
              child: _buildCalculationSummary(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationSummary() {
    if (_calculationResult == null) return const Center(child: Text('Enter data to calculate'));

    final totalCY = (_calculationResult!['totalCYLoose'] as num).toDouble();
    final workingDays = _calculationResult!['workingDays'] as int;
    final endDate = _calculationResult!['endDate'] as DateTime;
    
    final calendarDays = endDate.difference(_startDate).inDays;
    final months = calendarDays / 30.44;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputLabel('Calculation Results'),
        const SizedBox(height: 12),
        // Cards in a Row to keep them "all at the top"
        Row(
          children: [
            Expanded(
              child: _resultCard(
                'Total Loose',
                totalCY.toStringAsFixed(0),
                'CY with swell',
                Icons.dashboard_customize_outlined,
                AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _resultCard(
                'Completion',
                DateFormat('MMM dd').format(endDate),
                'Estimated end',
                Icons.event_available_outlined,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _resultCardExtended(
          'Project Duration',
          '$workingDays Working Days',
          'Calendar: $calendarDays d | Months: ${months.toStringAsFixed(1)}',
          Icons.timer_outlined,
          Colors.orange,
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.1)),
          ),
          child: Text(
            'Sat: 50% production | Sun/Hol: Non-working',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(fontSize: 10, color: AppTheme.slate700, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _resultCard(String title, String value, String sub, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Icon(icon, color: color, size: 16)),
              const Spacer(),
              Text(title, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate500)),
            ],
          ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Icon(icon, color: color, size: 16)),
              const Spacer(),
              Text(title, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate500)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
          const SizedBox(height: 6),
          Text(subContent, style: GoogleFonts.manrope(fontSize: 10, color: AppTheme.slate500, height: 1.2, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _inputLabel(String text) {
    return Text(text.toUpperCase(), style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppTheme.slate500));
  }

  Widget _textField(TextEditingController ctrl, String label, IconData icon) {
    return TextFormField(
      controller: ctrl,
      onTap: () => ctrl.selection = TextSelection(baseOffset: 0, extentOffset: ctrl.text.length),
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

  Widget _resourceItem(int index, Map<String, dynamic> res) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.slate50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.slate200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (res['machine_id'] != null) ...[
                 Builder(builder: (context) {
                    final item = _machineryCatalog.firstWhere((mx) => mx['id'] == res['machine_id'], orElse: () => {});
                    final photoUrl = item['photo_url'] as String?;
                    if (photoUrl == null || photoUrl.isEmpty) return const SizedBox.shrink();
                    return Container(
                      width: 45, height: 32,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white,
                        border: Border.all(color: AppTheme.slate200),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.settings, size: 16, color: AppTheme.slate400)),
                    );
                 }),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(res['machine_name'], style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                    _typeBadge(res['machinery_type'] ?? 'hauling'),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() { _selectedResources.removeAt(index); _runCalculation(); }),
                icon: const Icon(Icons.remove_circle_outline, color: AppTheme.errorRed, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
               _miniInput('QTY', (val) {
                res['quantity'] = double.tryParse(val) ?? 1.0;
                 _runCalculation();
              }, res['qtyCtrl']),
              if (res['machinery_type'] == 'hauling') ...[
                const SizedBox(width: 8),
                _miniInput('TRIPS/D', (val) {
                  final tripsVal = double.tryParse(val) ?? 60.0;
                  res['trips_per_day'] = tripsVal;
                  final capVal = double.tryParse((res['capCtrl'] as TextEditingController).text) ?? 0;
                  (res['perDayCtrl'] as TextEditingController).text = (tripsVal * capVal).toStringAsFixed(0);
                  _runCalculation();
                }, res['tripsCtrl']),
                const SizedBox(width: 8),
                _miniInput('CAP (CY)', (val) {
                  final capVal = double.tryParse(val) ?? 30.0;
                  res['capacity_per_trip'] = capVal;
                  final tripsVal = double.tryParse((res['tripsCtrl'] as TextEditingController).text) ?? 0;
                  (res['perDayCtrl'] as TextEditingController).text = (tripsVal * capVal).toStringAsFixed(0);
                  _runCalculation();
                }, res['capCtrl']),
              ],
              if (res['machinery_type'] != 'support') ...[
                 const SizedBox(width: 8),
                 _miniInput(res['machinery_type'] == 'production' ? 'CY/DAY' : 'CY/D (UNIT)', (val) {
                    // Update capacity_per_trip effectively so (trips * cap) = total
                    final totalVal = double.tryParse(val) ?? 0;
                    if (res['machinery_type'] == 'production') {
                      res['trips_per_day'] = 1.0; // Fixed at 1 trip
                      res['capacity_per_trip'] = totalVal;
                      (res['tripsCtrl'] as TextEditingController).text = '1';
                      (res['capCtrl'] as TextEditingController).text = totalVal.toStringAsFixed(2);
                    } else {
                      final tripsVal = double.tryParse((res['tripsCtrl'] as TextEditingController).text) ?? 60.0;
                      if (tripsVal > 0) {
                        final newCap = totalVal / tripsVal;
                        res['capacity_per_trip'] = newCap;
                        (res['capCtrl'] as TextEditingController).text = newCap.toStringAsFixed(2);
                      }
                    }
                    _runCalculation();
                 }, res['perDayCtrl']),
              ],
            ],
          ),
        ],
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

  Widget _addResourceButton() {
    return InkWell(
      onTap: () async {
        final result = await showDialog<List<Map<String, dynamic>>>(
          context: context,
          builder: (context) => MachinerySelectionDialog(
            serviceId: widget.service['id']?.toString() ?? widget.service['catalog_service_id']?.toString() ?? '',
          ),
        );
        if (result != null) {
          for (final m in result) {
            _addResource(m);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 16, color: AppTheme.primaryGreen),
              SizedBox(width: 8),
              Text('ADD MACHINE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ScheduleCalendarView(
        dailySchedule: List<Map<String, dynamic>>.from(_calculationResult?['dailySchedule'] ?? []),
        resources: _selectedResources,
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppTheme.slate200))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _footerButton('Cancel', Colors.white, AppTheme.slate500, () => Navigator.pop(context), border: true),
          const SizedBox(width: 12),
          _footerButton(_isSaving ? 'Saving...' : 'Save Estimation', AppTheme.primaryGreen, Colors.white, _save),
        ],
      ),
    );
  }

  Widget _typeBadge(String type) {
    Color color = AppTheme.primaryGreen;
    String label = 'HAULING';
    IconData icon = Icons.local_shipping_outlined;

    if (type == 'production') {
      color = Colors.blue;
      label = 'PRODUCTION';
      icon = Icons.precision_manufacturing_outlined;
    } else if (type == 'support') {
      color = AppTheme.slate500;
      label = 'SUPPORT';
      icon = Icons.commute_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _footerButton(String label, Color bg, Color text, VoidCallback onTap, {bool border = false}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: text,
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
