import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import 'package:intl/intl.dart';

class BaselineImpactSection extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> lines;
  final Map<String, List<Map<String, dynamic>>> initialPlans;
  final void Function(Map<String, List<Map<String, dynamic>>>) onPlansChanged;
  final void Function(int lineIndex) onReestimate;
  final void Function(int lineIndex, Map<String, dynamic> updatedLine)?
      onLineUpdated;

  const BaselineImpactSection({
    super.key,
    required this.lines,
    this.initialPlans = const {},
    required this.onPlansChanged,
    required this.onReestimate,
    this.onLineUpdated,
  });

  static String planKey(Map<String, dynamic> line) {
    return line['service_name'] as String? ?? line.hashCode.toString();
  }

  @override
  ConsumerState<BaselineImpactSection> createState() =>
      _BaselineImpactSectionState();
}

class _BaselineImpactSectionState
    extends ConsumerState<BaselineImpactSection> {
  final _plans = <String, List<Map<String, dynamic>>>{};
  final _fmt = NumberFormat('#,##0.00', 'en_US');
  final _ohCtls = <String, TextEditingController>{};
  final _profitCtls = <String, TextEditingController>{};

  List<Map<String, dynamic>> _catalogMachinery = [];
  List<Map<String, dynamic>> _catalogLaborRoles = [];
  List<Map<String, dynamic>> _catalogMaterials = [];
  List<Map<String, dynamic>> _catalogInstruments = [];
  bool _loadingCatalogs = true;

  @override
  void initState() {
    super.initState();
    _loadCatalogs();
    _syncPlans();
  }

  @override
  void didUpdateWidget(BaselineImpactSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPlans();
  }

  @override
  void dispose() {
    for (final c in _ohCtls.values) {
      c.dispose();
    }
    for (final c in _profitCtls.values) {
      c.dispose();
    }
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

  void _syncPlans() {
    for (final line in widget.lines) {
      final key = BaselineImpactSection.planKey(line);
      if (widget.initialPlans.containsKey(key)) {
        _plans[key] =
            List<Map<String, dynamic>>.from(widget.initialPlans[key]!);
      } else {
        _plans.putIfAbsent(key, () => []);
      }
      final meta = line['estimation_metadata'] as Map<String, dynamic>? ?? {};
      _ohCtls.putIfAbsent(
          key, () => TextEditingController(text: (meta['overhead_percentage'] as num?)?.toString() ?? '10'));
      _profitCtls.putIfAbsent(
          key, () => TextEditingController(text: (meta['profit_percentage'] as num?)?.toString() ?? '5'));
    }
    _plans.removeWhere(
        (k, _) => !widget.lines.any((l) => BaselineImpactSection.planKey(l) == k));
    for (final k in _plans.keys.toList()) {
      if (!widget.lines.any((l) => BaselineImpactSection.planKey(l) == k)) {
        _ohCtls[k]?.dispose();
        _ohCtls.remove(k);
        _profitCtls[k]?.dispose();
        _profitCtls.remove(k);
      }
    }
  }

  void _notify() {
    widget.onPlansChanged(Map.from(_plans));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lines.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, size: 20, color: Colors.indigo.shade600),
              const SizedBox(width: 8),
              Text(
                'Baseline Impact (Resource Plans)',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.indigo.shade800,
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message:
                    'Define how project resources are adjusted when this CO is approved',
                child: Icon(Icons.info_outline,
                    size: 16, color: Colors.indigo.shade300),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.lines.asMap().entries.map((e) =>
              _buildLineSection(e.key, e.value, BaselineImpactSection.planKey(e.value))),
        ],
      ),
    );
  }

  Widget _buildLineSection(int index, Map<String, dynamic> line, String key) {
    final lineType = line['line_type'] as String? ?? '';
    final serviceName = line['service_name'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.indigo.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  serviceName,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _colorForType(lineType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  lineType.replaceAll('_', ' '),
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _colorForType(lineType).withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (lineType == 'existing_service')
            _buildProportionalControls(key, line)
          else if (lineType == 'new_service')
            _loadingCatalogs
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _buildNewServiceEditor(index, key, line)
          else if (lineType == 'deduction')
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.info, size: 14, color: Colors.amber.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Existing resources will be flagged for deduction upon approval',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppTheme.slate600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _colorForType(String lineType) {
    switch (lineType) {
      case 'existing_service':
        return Colors.blue;
      case 'new_service':
        return Colors.green;
      case 'deduction':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  // ── Existing Service: Proportional Controls ──

  Widget _buildProportionalControls(String key, Map<String, dynamic> line) {
    final plans = _plans[key] ?? [];
    final existingPlan = plans.isNotEmpty ? plans.first : null;
    final factor =
        (existingPlan?['proportional_factor'] as num?)?.toDouble() ?? 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Proportional Adjustment Factor',
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.slate600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 100,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.slate200),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${factor}x',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.indigo,
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: factor.clamp(0.0, 5.0),
                min: 0,
                max: 5,
                divisions: 20,
                activeColor: Colors.indigo,
                label: '${factor}x',
                onChanged: (v) {
                  setState(() {
                    _plans[key] = [
                      {
                        'resource_type': 'labor',
                        'proportional_factor': v,
                      }
                    ];
                  });
                  _notify();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tip: 1.0x = same as current, 1.5x = 50% more, 0.5x = half',
          style: GoogleFonts.manrope(
            fontSize: 11,
            color: AppTheme.slate400,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: ['labor', 'machinery', 'material', 'instrument'].map((t) {
            final selected = _plans[key]?.any((p) =>
                    p['resource_type'] == t &&
                    p['proportional_factor'] != null) ??
                false;
            return FilterChip(
              label: Text(
                t[0].toUpperCase() + t.substring(1),
                style: GoogleFonts.manrope(fontSize: 11),
              ),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  _plans[key] ??= [];
                  if (v) {
                    _plans[key]!.add({
                      'resource_type': t,
                      'proportional_factor': factor,
                    });
                  } else {
                    _plans[key]!.removeWhere(
                        (p) => p['resource_type'] == t);
                  }
                  if (_plans[key]!.isEmpty) _plans.remove(key);
                });
                _notify();
              },
              selectedColor: Colors.indigo.withOpacity(0.15),
              checkmarkColor: Colors.indigo,
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── New Service: Full Resource Editor ──

  Widget _buildNewServiceEditor(
      int lineIndex, String key, Map<String, dynamic> line) {
    final plans = _plans[key] ?? [];
    final meta = line['estimation_metadata'] as Map<String, dynamic>? ?? {};
    final workingDays = (meta['working_days'] as num?)?.toInt() ?? 0;

    final ohCtrl = _ohCtls[key] ?? TextEditingController(text: '10');
    final profitCtrl = _profitCtls[key] ?? TextEditingController(text: '5');

    final machinery = plans.where((p) => p['resource_type'] == 'machinery').toList();
    final labors = plans.where((p) => p['resource_type'] == 'labor').toList();
    final materials = plans.where((p) => p['resource_type'] == 'material').toList();
    final instruments = plans.where((p) => p['resource_type'] == 'instrument').toList();

    final subtotal = _computeSubtotal(plans);
    final oh = double.tryParse(ohCtrl.text) ?? 0;
    final profit = double.tryParse(profitCtrl.text) ?? 0;
    final ohAmount = subtotal * (oh / 100);
    final profitAmount = (subtotal + ohAmount) * (profit / 100);
    final totalSale = subtotal + ohAmount + profitAmount;
    final qty = (line['quantity_change'] as num?)?.toDouble() ?? 1;
    final unitPrice = qty > 0 ? totalSale / qty.toDouble() : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // OH / Profit / Working Days
        Row(
          children: [
            SizedBox(
              width: 80,
              child: TextField(
                controller: ohCtrl,
                decoration: const InputDecoration(
                  labelText: 'OH %',
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  setState(() {});
                  _updateLineMeta(lineIndex, key);
                },
                style: GoogleFonts.manrope(fontSize: 12),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: TextField(
                controller: profitCtrl,
                decoration: const InputDecoration(
                  labelText: 'Profit %',
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  setState(() {});
                  _updateLineMeta(lineIndex, key);
                },
                style: GoogleFonts.manrope(fontSize: 12),
              ),
            ),
            if (workingDays > 0) ...[
              const SizedBox(width: 16),
              Icon(Icons.calendar_today, size: 14, color: AppTheme.slate500),
              const SizedBox(width: 4),
              Text(
                '$workingDays working days',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.slate600,
                ),
              ),
            ],
            const Spacer(),
            SizedBox(
              height: 28,
              child: OutlinedButton.icon(
                onPressed: () => widget.onReestimate(lineIndex),
                icon: const Icon(Icons.edit, size: 14),
                label: Text(
                  'Edit Estimation',
                  style: GoogleFonts.manrope(
                      fontSize: 11, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  foregroundColor: Colors.indigo,
                  side: BorderSide(color: Colors.indigo.withOpacity(0.3)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Machinery section
        _resourceSection(
          title: 'Machinery',
          icon: Icons.precision_manufacturing,
          color: Colors.amber,
          plans: machinery,
          totalLabel: (p) => _fmt.format(_machineryCost(p)),
          onAdd: () => _addMachinery(key),
          onEdit: (i, p) => _editMachinery(key, i, p),
          onRemove: (i, p) => _removePlan(key, i, p),
          emptyLabel: 'No machinery added',

          // Detail builder for machinery row
          detailBuilder: (p) => _buildMachineryDetail(p),
        ),
        const SizedBox(height: 8),

        // Labor section
        _resourceSection(
          title: 'Labor',
          icon: Icons.people,
          color: Colors.teal,
          plans: labors,
          totalLabel: (p) => _fmt.format(_laborCost(p)),
          onAdd: () => _addLabor(key),
          onEdit: (i, p) => _editLabor(key, i, p),
          onRemove: (i, p) => _removePlan(key, i, p),
          emptyLabel: 'No labor added',
          detailBuilder: (p) => _buildLaborDetail(p),
        ),
        const SizedBox(height: 8),

        // Materials section
        _resourceSection(
          title: 'Materials',
          icon: Icons.inventory_2,
          color: Colors.blue,
          plans: materials,
          totalLabel: (p) => _fmt.format(_materialCost(p)),
          onAdd: () => _addMaterial(key),
          onEdit: (i, p) => _editMaterial(key, i, p),
          onRemove: (i, p) => _removePlan(key, i, p),
          emptyLabel: 'No materials added',
          detailBuilder: (p) => _buildMaterialDetail(p),
        ),
        const SizedBox(height: 8),

        // Equipment / Instruments section
        _resourceSection(
          title: 'Equipment / Tools',
          icon: Icons.handyman,
          color: Colors.purple,
          plans: instruments,
          totalLabel: (p) => _fmt.format(_instrumentCost(p)),
          onAdd: () => _addInstrument(key),
          onEdit: (i, p) => _editInstrument(key, i, p),
          onRemove: (i, p) => _removePlan(key, i, p),
          emptyLabel: 'No equipment added',
          detailBuilder: (p) => _buildInstrumentDetail(p),
        ),
        const SizedBox(height: 16),

        // Subtotal summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.slate50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.slate200),
          ),
          child: Column(
            children: [
              _summaryRow('Subtotal', subtotal, AppTheme.slate700),
              _summaryRow('Overhead ($oh%)', ohAmount, AppTheme.slate600),
              _summaryRow('Profit ($profit%)', profitAmount, AppTheme.slate600),
              const Divider(height: 16),
              _summaryRow('Total Sale', totalSale, AppTheme.primaryGreen, bold: true),
              _summaryRow(
                'Unit Price',
                unitPrice,
                Colors.indigo,
                bold: true,
                large: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _updateLineMeta(int lineIndex, String key) {
    if (lineIndex < 0 || lineIndex >= widget.lines.length) return;
    final line = Map<String, dynamic>.from(widget.lines[lineIndex]);
    final meta = Map<String, dynamic>.from(
        line['estimation_metadata'] as Map<String, dynamic>? ?? {});
    meta['overhead_percentage'] = double.tryParse(_ohCtls[key]?.text ?? '') ?? 0;
    meta['profit_percentage'] = double.tryParse(_profitCtls[key]?.text ?? '') ?? 0;
    line['estimation_metadata'] = meta;
    widget.onLineUpdated?.call(lineIndex, line);
  }

  // ── Cost computation helpers ──

  double _computeSubtotal(List<Map<String, dynamic>> plans) {
    var total = 0.0;
    for (final p in plans) {
      final type = p['resource_type'] as String? ?? '';
      switch (type) {
        case 'machinery':
          total += _machineryCost(p);
          break;
        case 'labor':
          total += _laborCost(p);
          break;
        case 'material':
          total += _materialCost(p);
          break;
        case 'instrument':
          total += _instrumentCost(p);
          break;
      }
    }
    return total;
  }

  double _machineryCost(Map<String, dynamic> p) {
    final qty = (p['quantity'] as num?)?.toDouble() ?? 1;
    final rent = (p['monthly_rent_cost'] as num?)?.toDouble() ?? 0;
    final months = (p['months_to_use'] as num?)?.toDouble() ?? 1;
    final gph = (p['fuel_gph'] as num?)?.toDouble() ?? 0;
    final fuelP = (p['fuel_price'] as num?)?.toDouble() ?? 0;
    final delivery = (p['delivery_cost'] as num?)?.toDouble() ?? 0;
    return rent * months * qty + gph * 220 * months * fuelP * qty + delivery;
  }

  double _laborCost(Map<String, dynamic> p) {
    final emp = (p['employees_quantity'] as num?)?.toDouble() ?? 1;
    final rate = (p['hourly_rate'] as num?)?.toDouble() ?? 0;
    final perDiem = (p['per_diem'] as num?)?.toDouble() ?? 0;
    final months = (p['months_to_work'] as num?)?.toDouble() ?? 1;
    return rate * 220 * months * emp + perDiem * 30 * months * emp;
  }

  double _materialCost(Map<String, dynamic> p) {
    final qty = (p['quantity'] as num?)?.toDouble() ?? 0;
    final cost = (p['unit_cost'] as num?)?.toDouble() ?? 0;
    return qty * cost;
  }

  double _instrumentCost(Map<String, dynamic> p) {
    final qty = (p['quantity'] as num?)?.toDouble() ?? 1;
    final days = (p['days'] as num?)?.toDouble() ?? 1;
    final price = (p['unit_price'] as num?)?.toDouble() ?? 0;
    return qty * days * price;
  }

  // ── Resource Section reusable widget ──

  Widget _resourceSection({
    required String title,
    required IconData icon,
    required MaterialColor color,
    required List<Map<String, dynamic>> plans,
    required String Function(Map<String, dynamic>) totalLabel,
    required VoidCallback onAdd,
    required void Function(int, Map<String, dynamic>) onEdit,
    required void Function(int, Map<String, dynamic>) onRemove,
    required String emptyLabel,
    required Widget Function(Map<String, dynamic>) detailBuilder,
  }) {
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color.shade600),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color.shade800,
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${_fmt.format(plans.fold(0.0, (s, p) => s + (double.tryParse(totalLabel(p).replaceAll('\$', '').replaceAll(',', '')) ?? 0)))}',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color.shade700,
                  ),
                ),
              ],
            ),
          ),
          if (plans.isEmpty)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                emptyLabel,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: AppTheme.slate400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...plans.asMap().entries.map((e) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: AppTheme.slate200)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: detailBuilder(e.value)),
                      IconButton(
                        icon: const Icon(Icons.edit,
                            size: 15, color: AppTheme.slate500),
                        onPressed: () => onEdit(e.key, e.value),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 15, color: AppTheme.errorRed),
                        onPressed: () => onRemove(e.key, e.value),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                )),
          Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 15),
                label: Text(
                  'Add $title',
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

  Widget _summaryRow(String label, double value, Color color,
      {bool bold = false, bool large = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
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
      ),
    );
  }

  // ── Detail builders ──

  Widget _buildMachineryDetail(Map<String, dynamic> p) {
    final isPrimary = p['is_principal'] == true;
    final qty = (p['quantity'] as num?)?.toDouble() ?? 1;
    final rent = (p['monthly_rent_cost'] as num?)?.toDouble() ?? 0;
    final months = (p['months_to_use'] as num?)?.toDouble() ?? 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${p['resource_name'] ?? ''}${isPrimary ? ' (PRIMARY)' : ' (SUPPORT)'}',
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'Qty: $qty | Rent: \$${_fmt.format(rent)}/mo x $months mo',
          style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate500),
        ),
      ],
    );
  }

  Widget _buildLaborDetail(Map<String, dynamic> p) {
    final emp = (p['employees_quantity'] as num?)?.toDouble() ?? 1;
    final rate = (p['hourly_rate'] as num?)?.toDouble() ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p['resource_name'] as String? ?? '',
          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        Text(
          'Emp: $emp | Rate: \$${_fmt.format(rate)}/hr',
          style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate500),
        ),
      ],
    );
  }

  Widget _buildMaterialDetail(Map<String, dynamic> p) {
    final qty = (p['quantity'] as num?)?.toDouble() ?? 0;
    final cost = (p['unit_cost'] as num?)?.toDouble() ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p['resource_name'] as String? ?? '',
          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        Text(
          'Qty: ${_fmt.format(qty)} ${p['unit'] ?? ''} × \$${_fmt.format(cost)}/${p['unit'] ?? ''}',
          style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate500),
        ),
      ],
    );
  }

  Widget _buildInstrumentDetail(Map<String, dynamic> p) {
    final qty = (p['quantity'] as num?)?.toDouble() ?? 1;
    final days = (p['days'] as num?)?.toDouble() ?? 1;
    final price = (p['unit_price'] as num?)?.toDouble() ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p['resource_name'] as String? ?? '',
          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        Text(
          'Qty: $qty × $days d @ \$${_fmt.format(price)}/d',
          style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate500),
        ),
      ],
    );
  }

  // ── Add resource dialogs ──

  void _addMachinery(String key) async {
    final result = await _showCatalogSelector(
      title: 'Add Machinery',
      items: _catalogMachinery,
      displayNameKey: 'description',
      subtitleKey: (item) {
        final rent =
            (item['monthly_rent_cost'] as num?)?.toDouble() ?? 0;
        return '\$${_fmt.format(rent)}/mo';
      },
      selectedBuilder: (item) => <String, dynamic>{
        'resource_type': 'machinery',
        'resource_name': item['description'] ?? 'Machinery',
        'quantity': 1,
        'is_principal': false,
        'parent_resource_name': null,
        'catalog_id': item['id'] as String?,
        'monthly_rent_cost':
            (item['monthly_rent_cost'] as num?)?.toDouble() ?? 0,
        'delivery_cost': null,
        'fuel_gph': (item['fuel_gallons'] as num?)?.toDouble() ?? 0,
        'fuel_price': null,
        'months_to_use': null,
      },
    );
    if (result != null && mounted) {
      setState(() {
        _plans.putIfAbsent(key, () => []);
        _plans[key]!.add(result);
      });
      _notify();
    }
  }

  void _addLabor(String key) async {
    final result = await _showCatalogSelector(
      title: 'Add Labor',
      items: _catalogLaborRoles,
      displayNameKey: 'description',
      subtitleKey: (item) {
        final rate =
            (item['hourly_rate'] as num?)?.toDouble() ?? 0;
        return '\$${_fmt.format(rate)}/hr';
      },
      selectedBuilder: (item) => <String, dynamic>{
        'resource_type': 'labor',
        'resource_name':
            item['description'] ?? item['role_name'] ?? 'Labor',
        'quantity': 1,
        'catalog_id': item['id'] as String?,
        'hourly_rate': (item['hourly_rate'] as num?)?.toDouble() ?? 0,
        'per_diem': null,
        'employees_quantity': 1,
        'months_to_work': null,
      },
    );
    if (result != null && mounted) {
      setState(() {
        _plans.putIfAbsent(key, () => []);
        _plans[key]!.add(result);
      });
      _notify();
    }
  }

  void _addMaterial(String key) async {
    final result = await _showCatalogSelector(
      title: 'Add Material',
      items: _catalogMaterials,
      displayNameKey: 'description',
      subtitleKey: (item) {
        final price =
            (item['unit_price'] as num?)?.toDouble() ?? 0;
        final unit = item['unit'] ?? item['unit_name'] ?? '';
        return '\$${_fmt.format(price)}/$unit';
      },
      selectedBuilder: (item) => <String, dynamic>{
        'resource_type': 'material',
        'resource_name': item['description'] ?? 'Material',
        'quantity': 1,
        'unit': item['unit'] ?? item['unit_name'] ?? 'und',
        'unit_cost': (item['unit_price'] as num?)?.toDouble() ?? 0,
        'catalog_id': item['id'] as String?,
      },
    );
    if (result != null && mounted) {
      setState(() {
        _plans.putIfAbsent(key, () => []);
        _plans[key]!.add(result);
      });
      _notify();
    }
  }

  void _addInstrument(String key) async {
    final result = await _showCatalogSelector(
      title: 'Add Equipment / Tool',
      items: _catalogInstruments,
      displayNameKey: 'description',
      subtitleKey: (item) {
        final price =
            (item['unit_price'] as num?)?.toDouble() ?? 0;
        return '\$${_fmt.format(price)}/d';
      },
      selectedBuilder: (item) => <String, dynamic>{
        'resource_type': 'instrument',
        'resource_name': item['description'] ?? 'Equipment',
        'quantity': 1,
        'days': 1,
        'unit_price': (item['unit_price'] as num?)?.toDouble() ?? 0,
        'catalog_id': item['id'] as String?,
      },
    );
    if (result != null && mounted) {
      setState(() {
        _plans.putIfAbsent(key, () => []);
        _plans[key]!.add(result);
      });
      _notify();
    }
  }

  Future<Map<String, dynamic>?> _showCatalogSelector({
    required String title,
    required List<Map<String, dynamic>> items,
    required String displayNameKey,
    required String Function(Map<String, dynamic>) subtitleKey,
    required Map<String, dynamic> Function(Map<String, dynamic>) selectedBuilder,
  }) async {
    final result = await showSafeDialog<Map<String, dynamic>>(
      context: context,
      fullscreenOnMobile: true,
      builder: (ctx) => _CatalogSelectorDialog(
        title: title,
        items: items,
        displayNameKey: displayNameKey,
        subtitleKey: subtitleKey,
        selectedBuilder: selectedBuilder,
      ),
    );
    return result;
  }

  // ── Edit resource dialogs ──

  void _editMachinery(
      String key, int idx, Map<String, dynamic> plan) async {
    final result = await _editMachineryDialog(context, plan);
    if (result != null && mounted) {
      setState(() {
        final fullIdx = _plans[key]?.indexWhere(
            (p) =>
                p['resource_type'] == 'machinery' &&
                p['catalog_id'] == plan['catalog_id'] &&
                p['resource_name'] == plan['resource_name']);
        if (fullIdx != null && fullIdx >= 0) {
          _plans[key]![fullIdx] = result;
        }
      });
      _notify();
    }
  }

  void _editLabor(String key, int idx, Map<String, dynamic> plan) async {
    final result = await _editLaborDialog(context, plan);
    if (result != null && mounted) {
      setState(() {
        final fullIdx = _plans[key]?.indexWhere(
            (p) =>
                p['resource_type'] == 'labor' &&
                p['catalog_id'] == plan['catalog_id'] &&
                p['resource_name'] == plan['resource_name']);
        if (fullIdx != null && fullIdx >= 0) {
          _plans[key]![fullIdx] = result;
        }
      });
      _notify();
    }
  }

  void _editMaterial(String key, int idx, Map<String, dynamic> plan) async {
    final result = await _editSimpleDialog(
      context,
      'Edit Material',
      plan,
      fields: ['quantity', 'unit_cost', 'unit'],
    );
    if (result != null && mounted) {
      setState(() {
        final fullIdx = _plans[key]?.indexWhere(
            (p) =>
                p['resource_type'] == 'material' &&
                p['catalog_id'] == plan['catalog_id'] &&
                p['resource_name'] == plan['resource_name']);
        if (fullIdx != null && fullIdx >= 0) {
          _plans[key]![fullIdx] = result;
        }
      });
      _notify();
    }
  }

  void _editInstrument(String key, int idx, Map<String, dynamic> plan) async {
    final result = await _editSimpleDialog(
      context,
      'Edit Equipment',
      plan,
      fields: ['quantity', 'days', 'unit_price'],
    );
    if (result != null && mounted) {
      setState(() {
        final fullIdx = _plans[key]?.indexWhere(
            (p) =>
                p['resource_type'] == 'instrument' &&
                p['catalog_id'] == plan['catalog_id'] &&
                p['resource_name'] == plan['resource_name']);
        if (fullIdx != null && fullIdx >= 0) {
          _plans[key]![fullIdx] = result;
        }
      });
      _notify();
    }
  }

  void _removePlan(String key, int idx, Map<String, dynamic> plan) {
    setState(() {
      final fullIdx = _plans[key]?.indexWhere(
          (p) =>
              p['resource_type'] == plan['resource_type'] &&
              p['catalog_id'] == plan['catalog_id'] &&
              p['resource_name'] == plan['resource_name']);
      if (fullIdx != null && fullIdx >= 0) {
        _plans[key]?.removeAt(fullIdx);
        if (_plans[key]?.isEmpty ?? false) _plans.remove(key);
      }
    });
    _notify();
  }

  String _costText(Map<String, dynamic> data, String key, {String fallback = ''}) {
    final v = data[key];
    if (v == null) return fallback;
    final n = v as num;
    return n == 0 ? fallback : n.toString();
  }

  // ── Machinery edit dialog ──

  Future<Map<String, dynamic>?> _editMachineryDialog(
      BuildContext ctx, Map<String, dynamic> existing) async {
    final qtyCtrl = TextEditingController(
      text: _costText(existing, 'quantity', fallback: '1'),
    );
    final rentCtrl = TextEditingController(
      text: _costText(existing, 'monthly_rent_cost'),
    );
    final monthsCtrl = TextEditingController(
      text: _costText(existing, 'months_to_use', fallback: '1'),
    );
    final deliveryCtrl = TextEditingController(
      text: _costText(existing, 'delivery_cost'),
    );
    final fuelPriceCtrl = TextEditingController(
      text: _costText(existing, 'fuel_price'),
    );
    final fuelGphCtrl = TextEditingController(
      text: _costText(existing, 'fuel_gph'),
    );

    return showSafeDialog<Map<String, dynamic>>(
      context: context,
      fullscreenOnMobile: true,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          existing['resource_name'] as String? ?? 'Machinery',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rentCtrl,
                decoration:
                    const InputDecoration(labelText: 'Monthly Rent (\$)'),
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
                controller: deliveryCtrl,
                decoration:
                    const InputDecoration(labelText: 'Delivery Cost (\$)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fuelPriceCtrl,
                decoration:
                    const InputDecoration(labelText: 'Fuel Price (\$/gal)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fuelGphCtrl,
                decoration:
                    const InputDecoration(labelText: 'Fuel Consumption (gal/hr)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: Text('Cancel',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dCtx).pop({
                ...existing,
                'quantity': double.tryParse(qtyCtrl.text) ?? 1,
                'monthly_rent_cost': double.tryParse(rentCtrl.text) ?? 0,
                'months_to_use': double.tryParse(monthsCtrl.text) ?? 1,
                'delivery_cost': double.tryParse(deliveryCtrl.text) ?? 0,
                'fuel_price': double.tryParse(fuelPriceCtrl.text) ?? 0,
                'fuel_gph': double.tryParse(fuelGphCtrl.text) ?? 0,
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── Labor edit dialog ──

  Future<Map<String, dynamic>?> _editLaborDialog(
      BuildContext ctx, Map<String, dynamic> existing) async {
    final empCtrl = TextEditingController(
      text: _costText(existing, 'employees_quantity', fallback: '1'),
    );
    final rateCtrl = TextEditingController(
      text: _costText(existing, 'hourly_rate'),
    );
    final monthsCtrl = TextEditingController(
      text: _costText(existing, 'months_to_work', fallback: '1'),
    );
    final perDiemCtrl = TextEditingController(
      text: _costText(existing, 'per_diem'),
    );

    return showSafeDialog<Map<String, dynamic>>(
      context: context,
      fullscreenOnMobile: true,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          existing['resource_name'] as String? ?? 'Labor',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: empCtrl,
                decoration: const InputDecoration(labelText: 'Employees'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rateCtrl,
                decoration: const InputDecoration(labelText: 'Hourly Rate (\$)'),
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
                controller: perDiemCtrl,
                decoration: const InputDecoration(labelText: 'Per Diem (\$)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: Text('Cancel',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dCtx).pop({
                ...existing,
                'employees_quantity': double.tryParse(empCtrl.text) ?? 1,
                'hourly_rate': double.tryParse(rateCtrl.text) ?? 0,
                'months_to_work': double.tryParse(monthsCtrl.text) ?? 1,
                'per_diem': double.tryParse(perDiemCtrl.text) ?? 0,
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── Simple field edit dialog (materials, instruments) ──

  Future<Map<String, dynamic>?> _editSimpleDialog(
    BuildContext ctx,
    String title,
    Map<String, dynamic> existing, {
    required List<String> fields,
  }) async {
    final ctls = <String, TextEditingController>{};
    for (final f in fields) {
      final v = existing[f];
      ctls[f] = TextEditingController(
        text: v is String
            ? (v.isEmpty ? '' : v)
            : _costText(existing, f),
      );
    }

    return showSafeDialog<Map<String, dynamic>>(
      context: context,
      fullscreenOnMobile: true,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          existing['resource_name'] as String? ?? title,
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: fields.map((f) {
            var label = f.replaceAll('_', ' ');
            if (f == 'unit_cost') label = 'Unit Cost (\$)';
            if (f == 'unit_price') label = 'Daily Rate (\$)';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: ctls[f],
                decoration: InputDecoration(
                    labelText: label[0].toUpperCase() + label.substring(1)),
                keyboardType: TextInputType.number,
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: Text('Cancel',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              final updated = Map<String, dynamic>.from(existing);
              for (final f in fields) {
                updated[f] = double.tryParse(ctls[f]!.text) ?? 0;
              }
              Navigator.of(dCtx).pop(updated);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ── Catalog Selector Dialog ──

class _CatalogSelectorDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final String displayNameKey;
  final String Function(Map<String, dynamic>) subtitleKey;
  final Map<String, dynamic> Function(Map<String, dynamic>) selectedBuilder;

  const _CatalogSelectorDialog({
    required this.title,
    required this.items,
    required this.displayNameKey,
    required this.subtitleKey,
    required this.selectedBuilder,
  });

  @override
  State<_CatalogSelectorDialog> createState() =>
      _CatalogSelectorDialogState();
}

class _CatalogSelectorDialogState extends State<_CatalogSelectorDialog> {
  String _searchQuery = '';

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return widget.items;
    final q = _searchQuery.toLowerCase();
    return widget.items.where((item) {
      final name =
          (item[widget.displayNameKey] as String? ?? '').toLowerCase();
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
                        style:
                            GoogleFonts.manrope(color: AppTheme.slate500),
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
                          onTap: () =>
                              Navigator.of(context).pop(widget.selectedBuilder(item)),
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
