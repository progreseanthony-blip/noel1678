import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import 'package:intl/intl.dart';

class NewServiceEstimationDialog extends ConsumerStatefulWidget {
  final String serviceName;
  final String unitOfMeasure;
  final String? catalogServiceId;
  final String projectId;

  const NewServiceEstimationDialog({
    super.key,
    required this.serviceName,
    required this.unitOfMeasure,
    this.catalogServiceId,
    required this.projectId,
  });

  static Future<Map<String, dynamic>?> open({
    required BuildContext context,
    required WidgetRef ref,
    required String projectId,
    required String serviceName,
    required String unitOfMeasure,
    String? catalogServiceId,
  }) {
    return showSafeDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => NewServiceEstimationDialog(
        projectId: projectId,
        serviceName: serviceName,
        unitOfMeasure: unitOfMeasure,
        catalogServiceId: catalogServiceId,
      ),
    );
  }

  @override
  ConsumerState<NewServiceEstimationDialog> createState() =>
      _NewServiceEstimationDialogState();
}

class _NewServiceEstimationDialogState
    extends ConsumerState<NewServiceEstimationDialog> {
  final _qtyCtrl = TextEditingController(text: '1');
  final _ohCtrl = TextEditingController(text: '10');
  final _profitCtrl = TextEditingController(text: '5');
  final _fmt = NumberFormat('#,##0.00', 'en_US');

  var _resources = <Map<String, dynamic>>[];
  var _loadingCatalogs = true;
  List<Map<String, dynamic>> _catalogMachinery = [];
  List<Map<String, dynamic>> _catalogLaborRoles = [];
  List<Map<String, dynamic>> _catalogMaterials = [];
  List<Map<String, dynamic>> _catalogInstruments = [];

  @override
  void initState() {
    super.initState();
    _loadCatalogs();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _ohCtrl.dispose();
    _profitCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCatalogs() async {
    try {
      final svc = ref.read(catalogsServiceProvider);
      final results = await Future.wait([
        svc.getMachinery(),
        svc.getLaborRoles(),
        svc.getMaterials(),
        svc.getLogisticsEquipment(),
      ]);
      if (mounted) {
        setState(() {
          _catalogMachinery = results[0];
          _catalogLaborRoles = results[1];
          _catalogMaterials = results[2];
          _catalogInstruments = results[3];
          _loadingCatalogs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCatalogs = false);
    }
  }

  double get _subtotal {
    var total = 0.0;
    for (final r in _resources) {
      final type = r['resource_type'] as String? ?? '';
      final qty = (r['quantity'] as num?)?.toDouble() ?? 1;
      switch (type) {
        case 'labor':
          final rate = (r['hourly_rate'] as num?)?.toDouble() ?? 0;
          final months = (r['months_to_work'] as num?)?.toDouble() ?? 1;
          final employees = (r['employees_quantity'] as num?)?.toDouble() ?? 1;
          total += rate * 220 * months * employees; // 220 hrs/month
          total += (r['per_diem'] as num?)?.toDouble() ?? 0 * months * employees;
          break;
        case 'machinery':
          final monthlyRent = (r['monthly_rent_cost'] as num?)?.toDouble() ?? 0;
          final months = (r['months_to_use'] as num?)?.toDouble() ?? 1;
          final machQty = (r['quantity'] as num?)?.toDouble() ?? 1;
          final gph = (r['gallons_per_hour'] as num?)?.toDouble() ?? 0;
          final fuelPrice = (r['fuel_price'] as num?)?.toDouble() ?? 0;
          total += monthlyRent * months * machQty;
          total += gph * 220 * months * fuelPrice; // fuel cost
          total += (r['delivery_cost'] as num?)?.toDouble() ?? 0;
          break;
        case 'material':
          final unitPrice = (r['unit_price'] as num?)?.toDouble() ?? 0;
          total += qty * unitPrice;
          break;
        case 'instrument':
          final unitPrice = (r['unit_price'] as num?)?.toDouble() ?? 0;
          final days = (r['days'] as num?)?.toDouble() ?? 1;
          total += qty * unitPrice * days;
          break;
      }
    }
    return total;
  }

  double get _overheadAmount {
    final oh = double.tryParse(_ohCtrl.text) ?? 0;
    return _subtotal * (oh / 100);
  }

  double get _profitAmount {
    final prof = double.tryParse(_profitCtrl.text) ?? 0;
    return (_subtotal + _overheadAmount) * (prof / 100);
  }

  double get _totalSale => _subtotal + _overheadAmount + _profitAmount;

  double get _unitPrice {
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    return qty > 0 ? _totalSale / qty : 0;
  }

  Future<void> _addResource(String type) async {
    switch (type) {
      case 'labor':
        final result = await _showLaborSelector();
        if (result != null) setState(() => _resources.add(result));
        break;
      case 'machinery':
        final result = await _showMachinerySelector();
        if (result != null) setState(() => _resources.add(result));
        break;
      case 'material':
        final result = await _showMaterialSelector();
        if (result != null) setState(() => _resources.add(result));
        break;
      case 'instrument':
        final result = await _showInstrumentSelector();
        if (result != null) setState(() => _resources.add(result));
        break;
    }
  }

  Future<Map<String, dynamic>?> _showLaborSelector() async {
    return showSafeDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _CatalogSelectorDialog(
        title: 'Select Labor Role',
        items: _catalogLaborRoles,
        displayNameKey: 'description',
        subtitleKey: (item) {
          final rate = (item['hourly_rate'] as num?)?.toDouble() ?? 0;
          return '\$${_fmt.format(rate)}/hr';
        },
        selectedBuilder: (item) => <String, dynamic>{
          'resource_type': 'labor',
          'resource_name': item['description'] ?? item['role_name'] ?? 'Labor',
          'role_name': item['role_name'] ?? item['description'] ?? 'Labor',
          'hourly_rate': (item['hourly_rate'] as num?)?.toDouble() ?? 0,
          'employees_quantity': 1,
          'months_to_work': 1,
          'per_diem': 0,
          'quantity': 1,
        },
        editBuilder: (existing) => _showResourceEditor(
          ctx,
          'labor',
          existing,
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _showMachinerySelector() async {
    return showSafeDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _CatalogSelectorDialog(
        title: 'Select Machinery',
        items: _catalogMachinery,
        displayNameKey: 'description',
        subtitleKey: (item) {
          final rent = (item['monthly_rent_cost'] as num?)?.toDouble() ?? 0;
          return '\$${_fmt.format(rent)}/mo';
        },
        selectedBuilder: (item) => <String, dynamic>{
          'resource_type': 'machinery',
          'resource_name': item['description'] ?? 'Machinery',
          'monthly_rent_cost':
              (item['monthly_rent_cost'] as num?)?.toDouble() ?? 0,
          'months_to_use': 1,
          'quantity': 1,
          'gallons_per_hour': (item['gallons_per_hour'] as num?)?.toDouble() ?? 0,
          'fuel_price': 0,
          'delivery_cost': 0,
          'catalog_id': item['id'] as String?,
        },
        editBuilder: (existing) => _showResourceEditor(
          ctx,
          'machinery',
          existing,
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _showMaterialSelector() async {
    return showSafeDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _CatalogSelectorDialog(
        title: 'Select Material',
        items: _catalogMaterials,
        displayNameKey: 'description',
        subtitleKey: (item) {
          final price = (item['unit_price'] as num?)?.toDouble() ?? 0;
          final unit = item['unit'] ?? item['unit_name'] ?? '';
          return '\$${_fmt.format(price)}/$unit';
        },
        selectedBuilder: (item) => <String, dynamic>{
          'resource_type': 'material',
          'resource_name': item['description'] ?? 'Material',
          'unit': item['unit'] ?? item['unit_name'] ?? 'und',
          'unit_price': (item['unit_price'] as num?)?.toDouble() ?? 0,
          'quantity': 1,
          'catalog_id': item['id'] as String?,
        },
        editBuilder: (existing) => _showResourceEditor(
          ctx,
          'material',
          existing,
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _showInstrumentSelector() async {
    return showSafeDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _CatalogSelectorDialog(
        title: 'Select Equipment',
        items: _catalogInstruments,
        displayNameKey: 'description',
        subtitleKey: (item) {
          final price = (item['unit_price'] as num?)?.toDouble() ?? 0;
          final unit = item['unit'] ?? '';
          return '\$${_fmt.format(price)}/$unit';
        },
        selectedBuilder: (item) => <String, dynamic>{
          'resource_type': 'instrument',
          'resource_name': item['description'] ?? 'Equipment',
          'unit_price': (item['unit_price'] as num?)?.toDouble() ?? 0,
          'quantity': 1,
          'days': 1,
          'catalog_id': item['id'] as String?,
        },
        editBuilder: (existing) => _showResourceEditor(
          ctx,
          'instrument',
          existing,
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _showResourceEditor(
    BuildContext dialogContext,
    String type,
    Map<String, dynamic> existing,
  ) async {
    final qtyCtrl = TextEditingController(
      text: (existing['quantity'] as num?)?.toString() ?? '1',
    );

    List<Widget> extraFields = [];
    switch (type) {
      case 'labor':
        final empCtrl = TextEditingController(
          text:
              (existing['employees_quantity'] as num?)?.toString() ?? '1',
        );
        final monthsCtrl = TextEditingController(
          text: (existing['months_to_work'] as num?)?.toString() ?? '1',
        );
        extraFields = [
          const SizedBox(height: 12),
          TextField(
            controller: empCtrl,
            decoration: const InputDecoration(labelText: 'Employees'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: monthsCtrl,
            decoration: const InputDecoration(labelText: 'Months'),
            keyboardType: TextInputType.number,
          ),
        ];
        return showSafeDialog<Map<String, dynamic>>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              existing['resource_name'] as String? ?? '',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
                ...extraFields,
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop({
                    ...existing,
                    'quantity': double.tryParse(qtyCtrl.text) ?? 1,
                    'employees_quantity':
                        double.tryParse(empCtrl.text) ?? 1,
                    'months_to_work':
                        double.tryParse(monthsCtrl.text) ?? 1,
                  });
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      case 'machinery':
        final monthsCtrl = TextEditingController(
          text: (existing['months_to_use'] as num?)?.toString() ?? '1',
        );
        final fuelCtrl = TextEditingController(
          text: (existing['fuel_price'] as num?)?.toString() ?? '0',
        );
        return showSafeDialog<Map<String, dynamic>>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              existing['resource_name'] as String? ?? '',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: monthsCtrl,
                  decoration: const InputDecoration(labelText: 'Months'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fuelCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Fuel Price (\$/gal)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop({
                    ...existing,
                    'quantity': double.tryParse(qtyCtrl.text) ?? 1,
                    'months_to_use':
                        double.tryParse(monthsCtrl.text) ?? 1,
                    'fuel_price': double.tryParse(fuelCtrl.text) ?? 0,
                  });
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      case 'material':
      case 'instrument':
        final priceCtrl = TextEditingController(
          text: (existing['unit_price'] as num?)?.toString() ?? '0',
        );
        List<Widget> extra = [];
        if (type == 'instrument') {
          final daysCtrl = TextEditingController(
            text: (existing['days'] as num?)?.toString() ?? '1',
          );
          extra = [
            const SizedBox(height: 12),
            TextField(
              controller: daysCtrl,
              decoration: const InputDecoration(labelText: 'Days'),
              keyboardType: TextInputType.number,
            ),
          ];
          return showSafeDialog<Map<String, dynamic>>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(
                existing['resource_name'] as String? ?? '',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: qtyCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Unit Price (\$)'),
                    keyboardType: TextInputType.number,
                  ),
                  ...extra,
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop({
                      ...existing,
                      'quantity': double.tryParse(qtyCtrl.text) ?? 1,
                      'unit_price':
                          double.tryParse(priceCtrl.text) ?? 0,
                      if (type == 'instrument')
                        'days': double.tryParse(
                                (extra.isNotEmpty
                                    ? (extra.last as TextField)
                                        .controller
                                        ?.text
                                    : null) ??
                                    '1') ??
                            1,
                    });
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          );
        }
        return showSafeDialog<Map<String, dynamic>>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              existing['resource_name'] as String? ?? '',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Unit Price (\$)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop({
                    ...existing,
                    'quantity': double.tryParse(qtyCtrl.text) ?? 1,
                    'unit_price': double.tryParse(priceCtrl.text) ?? 0,
                  });
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(color: Colors.indigo.withOpacity(0.15)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.build, size: 22, color: Colors.indigo.shade600),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Estimate New Service',
                      style: GoogleFonts.manrope(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.indigo.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: _loadingCatalogs
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Service info
                          Text(
                            widget.serviceName,
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Unit: ${widget.unitOfMeasure}',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppTheme.slate500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Quantity + OH + Profit
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _qtyCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Quantity',
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _ohCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'OH %',
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _profitCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Profit %',
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Resource sections
                          Text(
                            'Resources',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.slate700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildResourceSection(
                            type: 'labor',
                            icon: Icons.people,
                            label: 'Labor',
                            color: Colors.teal,
                          ),
                          const SizedBox(height: 8),
                          _buildResourceSection(
                            type: 'machinery',
                            icon: Icons.precision_manufacturing,
                            label: 'Machinery',
                            color: Colors.amber,
                          ),
                          const SizedBox(height: 8),
                          _buildResourceSection(
                            type: 'material',
                            icon: Icons.inventory_2,
                            label: 'Materials',
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 8),
                          _buildResourceSection(
                            type: 'instrument',
                            icon: Icons.handyman,
                            label: 'Equipment',
                            color: Colors.purple,
                          ),
                          const SizedBox(height: 24),
                          // Summary
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.slate50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.slate200),
                            ),
                            child: Column(
                              children: [
                                _summaryRow(
                                  'Subtotal',
                                  _subtotal,
                                  AppTheme.slate700,
                                ),
                                const SizedBox(height: 4),
                                _summaryRow(
                                  'Overhead (${_ohCtrl.text}%)',
                                  _overheadAmount,
                                  AppTheme.slate600,
                                ),
                                const SizedBox(height: 4),
                                _summaryRow(
                                  'Profit (${_profitCtrl.text}%)',
                                  _profitAmount,
                                  AppTheme.slate600,
                                ),
                                const Divider(height: 20),
                                _summaryRow(
                                  'Total Sale',
                                  _totalSale,
                                  AppTheme.primaryGreen,
                                  bold: true,
                                ),
                                const SizedBox(height: 4),
                                _summaryRow(
                                  'Unit Price',
                                  _unitPrice,
                                  Colors.indigo,
                                  bold: true,
                                  large: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.slate200),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop({
                        'service_name': widget.serviceName,
                        'unit_of_measure': widget.unitOfMeasure,
                        'catalog_service_id': widget.catalogServiceId,
                        'line_type': 'new_service',
                        'quantity_change':
                            double.tryParse(_qtyCtrl.text) ?? 1,
                        'unit_price': _unitPrice,
                        'resource_plans': _resources,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Add to CO',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceSection({
    required String type,
    required IconData icon,
    required String label,
    required MaterialColor color,
  }) {
    final items = _resources
        .where((r) => r['resource_type'] == type)
        .toList();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color.shade600),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color.shade800,
                  ),
                ),
                const Spacer(),
                Text(
                  '${items.length} item(s)',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppTheme.slate500,
                  ),
                ),
              ],
            ),
          ),
          if (items.isNotEmpty)
            ...items.asMap().entries.map((e) => _resourceTile(type, e.key, e.value)),
          Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _addResource(type),
                icon: const Icon(Icons.add, size: 15),
                label: Text(
                  'Add $label',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color.shade600,
                  side: BorderSide(color: color.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resourceTile(String type, int idx, Map<String, dynamic> r) {
    String detail;
    switch (type) {
      case 'labor':
        detail =
            '\$${_fmt.format((r['hourly_rate'] as num?)?.toDouble() ?? 0)}/hr x ${r['employees_quantity']} emp x ${r['months_to_work']} mo';
        break;
      case 'machinery':
        detail =
            '\$${_fmt.format((r['monthly_rent_cost'] as num?)?.toDouble() ?? 0)}/mo x ${r['quantity']} x ${r['months_to_use']} mo';
        break;
      case 'material':
        detail =
            '\$${_fmt.format((r['unit_price'] as num?)?.toDouble() ?? 0)}/${r['unit'] ?? 'und'} x ${r['quantity']}';
        break;
      case 'instrument':
        detail =
            '\$${_fmt.format((r['unit_price'] as num?)?.toDouble() ?? 0)}/d x ${r['quantity']} x ${r['days']}d';
        break;
      default:
        detail = '';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.slate200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r['resource_name'] as String? ?? '',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  detail,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppTheme.slate500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 15, color: AppTheme.slate500),
            onPressed: () async {
              final updated = await _showResourceEditor(context, type, r);
              if (updated != null) {
                setState(() => _resources[idx] = updated);
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          IconButton(
            icon:
                const Icon(Icons.close, size: 15, color: AppTheme.errorRed),
            onPressed: () => setState(() => _resources.removeAt(idx)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    double value,
    Color color, {
    bool bold = false,
    bool large = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: large ? 14 : 12,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          '\$${_fmt.format(value)}',
          style: GoogleFonts.manrope(
            fontSize: large ? 16 : 12,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Reusable catalog selector dialog with inline editing option
class _CatalogSelectorDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final String displayNameKey;
  final String Function(Map<String, dynamic>) subtitleKey;
  final Map<String, dynamic> Function(Map<String, dynamic>) selectedBuilder;
  final Future<Map<String, dynamic>?> Function(Map<String, dynamic>)?
      editBuilder;

  const _CatalogSelectorDialog({
    required this.title,
    required this.items,
    required this.displayNameKey,
    required this.subtitleKey,
    required this.selectedBuilder,
    this.editBuilder,
  });

  @override
  State<_CatalogSelectorDialog> createState() => _CatalogSelectorDialogState();
}

class _CatalogSelectorDialogState extends State<_CatalogSelectorDialog> {
  String _searchQuery = '';

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return widget.items;
    final q = _searchQuery.toLowerCase();
    return widget.items.where((item) {
      final name = (item[widget.displayNameKey] as String? ?? '').toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.title,
        style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.manrope(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No items found',
                        style: GoogleFonts.manrope(color: AppTheme.slate500),
                      ),
                    )
                  : ListView(
                      children: _filtered.map((item) {
                        final name =
                            item[widget.displayNameKey] as String? ?? '';
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
                            widget.subtitleKey(item),
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: AppTheme.slate500,
                            ),
                          ),
                          onTap: () async {
                            final result = widget.selectedBuilder(item);
                            if (widget.editBuilder != null) {
                              final edited =
                                  await widget.editBuilder!.call(result);
                              if (edited != null && context.mounted) {
                                Navigator.of(context).pop(edited);
                              }
                            } else {
                              Navigator.of(context).pop(result);
                            }
                          },
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
