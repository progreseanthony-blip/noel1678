import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';

class StepMaterials extends StatefulWidget {
  final List<Map<String, dynamic>> plannedMaterials;
  final List<Map<String, dynamic>> materialUsage;
  final bool isReadOnly;
  final ValueChanged<List<Map<String, dynamic>>> onUsageChanged;

  const StepMaterials({
    super.key,
    required this.plannedMaterials,
    required this.materialUsage,
    required this.isReadOnly,
    required this.onUsageChanged,
  });

  @override
  State<StepMaterials> createState() => _StepMaterialsState();
}

class _StepMaterialsState extends State<StepMaterials> {
  List<Map<String, dynamic>> _entries = [];
  String? _serviceFilter;
  final Map<String, TextEditingController> _ctrls = {};

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _entries = widget.materialUsage.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  @override
  void didUpdateWidget(StepMaterials oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.materialUsage != widget.materialUsage) {
      _entries = widget.materialUsage.map((m) => Map<String, dynamic>.from(m)).toList();
    }
  }

  void _emit() => widget.onUsageChanged(List<Map<String, dynamic>>.from(_entries));

  bool _isAdded(String pmId) =>
      _entries.any((e) => e['project_material_id'] == pmId);
  int _entryIdx(String pmId) =>
      _entries.indexWhere((e) => e['project_material_id'] == pmId);

  void _addEntry(Map<String, dynamic> pm) {
    setState(() {
      _entries.add({
        'project_material_id': pm['id'],
        'material_id': pm['material_id'],
        'quantity_used': 0,
        'area_installed': null,
        'unit': pm['materials']?['unit'] ?? pm['unit_name'] ?? 'units',
        'notes': '',
        '_name': pm['material_name'] ?? pm['materials']?['description'] ?? 'Material',
      });
    });
    _emit();
  }

  void _removeEntry(int index) {
    setState(() => _entries.removeAt(index));
    _emit();
  }

  void _updateEntry(int index, String key, dynamic value) {
    setState(() => _entries[index][key] = value);
    _emit();
  }

  List<Map<String, dynamic>> _filteredMaterials() {
    if (_serviceFilter == null) return widget.plannedMaterials;
    return widget.plannedMaterials.where((pm) {
      final svc = pm['quote_services']?['name'] as String?;
      return svc == _serviceFilter;
    }).toList();
  }

  List<String> _allServices() {
    final names = <String>{};
    for (final pm in widget.plannedMaterials) {
      final n = pm['quote_services']?['name'] as String?;
      if (n != null) names.add(n);
    }
    return names.toList()..sort();
  }

  Map<String?, List<Map<String, dynamic>>> _groupByService(List<Map<String, dynamic>> list) {
    final map = <String?, List<Map<String, dynamic>>>{};
    for (final pm in list) {
      final svc = pm['quote_services']?['name'] as String? ?? 'Unassigned';
      map.putIfAbsent(svc, () => []).add(pm);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMaterials();
    final grouped = _groupByService(filtered);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildServiceFilter(),
      const SizedBox(height: 12),
      if (filtered.isEmpty)
        _emptyState('No materials planned for this project')
      else
        ...grouped.entries.map((svc) => _buildServiceGroup(svc.key ?? 'Unassigned', svc.value)),
    ]);
  }

  Widget _buildServiceFilter() {
    final services = _allServices();
    if (services.isEmpty) return const SizedBox.shrink();
    return Row(children: [
      Text('Service:', style: _t(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate500)),
      const SizedBox(width: 12),
      SizedBox(width: 260, child: DropdownButtonFormField<String>(
        value: _serviceFilter,
        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        hint: Text('All Services', style: _t(fontSize: 13)),
        items: [
          DropdownMenuItem<String>(value: null, child: Text('All Services', style: _t(fontSize: 13))),
          ...services.map((s) => DropdownMenuItem(value: s, child: Text(s, style: _t(fontSize: 13)))),
        ],
        onChanged: (v) => setState(() => _serviceFilter = v),
      )),
    ]);
  }

  Widget _buildServiceGroup(String svcName, List<Map<String, dynamic>> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: AppTheme.slate200.withAlpha(120), borderRadius: BorderRadius.circular(6)),
        child: Text(svcName, style: _t(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.slate700)),
      ),
      const SizedBox(height: 6),
      ...items.map((pm) => _buildMaterialCard(pm)),
    ]);
  }

  Widget _buildMaterialCard(Map<String, dynamic> pm) {
    final pmId = pm['id'] as String;
    final matName = pm['material_name'] ?? pm['materials']?['description'] ?? 'Material';
    final unit = pm['materials']?['unit'] ?? pm['unit_name'] ?? 'units';
    final expected = pm['expected_quantity'] ?? 0;
    final isAdded = _isAdded(pmId);
    final entryIdx = isAdded ? _entryIdx(pmId) : -1;
    final entry = isAdded ? _entries[entryIdx] : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: AppTheme.slate200)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        initiallyExpanded: isAdded,
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isAdded ? AppTheme.primaryGreen.withAlpha(25) : AppTheme.slate200,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(isAdded ? Icons.check_circle : Icons.inventory, size: 16, color: isAdded ? AppTheme.primaryGreen : AppTheme.slate500),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(matName, style: _t(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate900)),
          Text('Expected: $expected $unit', style: _t(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.slate500)),
        ]),
        children: [
          if (!isAdded)
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Row(children: [
                Expanded(child: Text('Not registered today', style: _t(fontSize: 11, color: AppTheme.slate400))),
                if (!widget.isReadOnly)
                  TextButton.icon(
                    onPressed: () => _addEntry(pm),
                    icon: const Icon(Icons.add, size: 14),
                    label: Text('Add', style: _t(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  ),
              ]),
            )
          else
            _buildUsageForm(entryIdx, entry!, unit),
        ],
      ),
    );
  }

  Widget _buildUsageForm(int index, Map<String, dynamic> entry, String unit) {
    return Padding(
      padding: const EdgeInsets.only(left: 44),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppTheme.primaryGreen.withAlpha(10), borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!widget.isReadOnly) ...[
            Row(children: [
              Expanded(child: _numField(index, 'quantity_used', 'Qty Used ($unit)', entry['quantity_used']?.toString() ?? '', (v) => _updateEntry(index, 'quantity_used', v))),
              const SizedBox(width: 10),
              Expanded(child: _numField(index, 'area_installed', 'Area Installed', entry['area_installed']?.toString() ?? '', (v) => _updateEntry(index, 'area_installed', v))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Spacer(),
              IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorRed), onPressed: () => _removeEntry(index), tooltip: 'Remove'),
            ]),
          ] else ...[
            Row(children: [
              _roField('Qty Used', '${entry['quantity_used'] ?? '-'} $unit'),
              const SizedBox(width: 16),
              _roField('Area', entry['area_installed']?.toString() ?? '-'),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _numField(int idx, String field, String label, String initial, ValueChanged<double> onChanged) {
    final key = '${idx}_$field';
    if (!_ctrls.containsKey(key)) {
      final isZero = initial.isEmpty || initial == '0' || initial == '0.0';
      _ctrls[key] = TextEditingController(text: isZero ? '' : initial);
    }
    return TextField(
      controller: _ctrls[key],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.slate200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.slate200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.primaryGreen.withAlpha(150), width: 2)),
        fillColor: AppTheme.slate50,
        filled: true,
      ),
      onChanged: (v) {
        final d = double.tryParse(v) ?? 0;
        onChanged(d);
      },
    );
  }

  Widget _roField(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: _t(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.slate400)),
      Text(value, style: _t(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.slate900)),
    ]);
  }

  Widget _emptyState(String text) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: AppTheme.slate50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.slate200)),
      child: Column(children: [
        Icon(Icons.inventory_outlined, size: 40, color: AppTheme.slate400),
        const SizedBox(height: 8),
        Text(text, style: _t(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.slate500)),
      ]),
    );
  }

  TextStyle _t({double? fontSize, FontWeight? fontWeight, Color? color}) {
    return GoogleFonts.manrope(fontSize: fontSize, fontWeight: fontWeight, color: color);
  }
}
