import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_ui_components/noel_ui_components.dart';

class BaselineImpactSection extends StatefulWidget {
  final List<Map<String, dynamic>> lines;
  final void Function(Map<String, List<Map<String, dynamic>>>) onPlansChanged;

  const BaselineImpactSection({
    super.key,
    required this.lines,
    required this.onPlansChanged,
  });

  @override
  State<BaselineImpactSection> createState() => _BaselineImpactSectionState();
}

class _BaselineImpactSectionState extends State<BaselineImpactSection> {
  final _plans = <String, List<Map<String, dynamic>>>{};

  @override
  void initState() {
    super.initState();
    _syncPlans();
  }

  @override
  void didUpdateWidget(BaselineImpactSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPlans();
  }

  void _syncPlans() {
    for (final line in widget.lines) {
      final key = _lineKey(line);
      _plans.putIfAbsent(key, () => []);
    }
    _plans.removeWhere((k, _) =>
        !widget.lines.any((l) => _lineKey(l) == k));
  }

  String _lineKey(Map<String, dynamic> line) {
    return line['service_name'] as String? ?? line.hashCode.toString();
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
              _buildLineSection(e.key, e.value, _lineKey(e.value))),
        ],
      ),
    );
  }

  Widget _buildLineSection(int index, Map<String, dynamic> line, String key) {
    final lineType = line['line_type'] as String? ?? '';
    final serviceName = line['service_name'] as String? ?? '';
    final plans = _plans[key] ?? [];

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
            _buildExplicitResources(key, plans)
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

  Widget _buildProportionalControls(String key, Map<String, dynamic> line) {
    final plans = _plans[key] ?? [];
    // Find the first plan that has a proportional_factor
    final existingPlan = plans.isNotEmpty ? plans.first : null;
    final factor = (existingPlan?['proportional_factor'] as num?)?.toDouble() ?? 1.0;

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
                        'proportional_factor': v.roundToDouble(),
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
        // Show resource type toggles
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: ['labor', 'machinery', 'material', 'instrument'].map((t) {
            final selected = _plans[key]?.any((p) =>
                    p['resource_type'] == t && p['proportional_factor'] != null) ??
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

  Widget _buildExplicitResources(
      String key, List<Map<String, dynamic>> plans) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...plans.asMap().entries.map((e) => _resourceRow(key, e.key, e.value)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _addResource(key),
            icon: const Icon(Icons.add, size: 16),
            label: Text(
              'Add Resource',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.indigo,
              side: BorderSide(color: Colors.indigo.withOpacity(0.3)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _resourceRow(String key, int idx, Map<String, dynamic> plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.slate50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan['resource_name'] ?? 'Resource',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Type: ${plan['resource_type']} | Qty: ${plan['quantity']}',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppTheme.slate500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 16, color: AppTheme.slate500),
            onPressed: () => _editResource(key, idx, plan),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppTheme.errorRed),
            onPressed: () {
              setState(() {
                _plans[key]?.removeAt(idx);
                if (_plans[key]?.isEmpty ?? false) _plans.remove(key);
              });
              _notify();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Future<void> _addResource(String key) async {
    final result = await _showResourceEditor(context);
    if (result != null && mounted) {
      setState(() {
        _plans.putIfAbsent(key, () => []);
        _plans[key]!.add(result);
      });
      _notify();
    }
  }

  Future<void> _editResource(
      String key, int idx, Map<String, dynamic> plan) async {
    final result = await _showResourceEditor(context, existing: plan);
    if (result != null && mounted) {
      setState(() {
        _plans[key]![idx] = result;
      });
      _notify();
    }
  }

  Future<Map<String, dynamic>?> _showResourceEditor(
    BuildContext context, {
    Map<String, dynamic>? existing,
  }) async {
    final nameCtrl = TextEditingController(
      text: existing?['resource_name'] as String? ?? '',
    );
    final qtyCtrl = TextEditingController(
      text: existing?['quantity']?.toString() ?? '1',
    );
    String type = existing?['resource_type'] as String? ?? 'labor';

    final availableTypes = ['labor', 'machinery', 'material', 'instrument'];

    return showSafeDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          existing != null ? 'Edit Resource' : 'Add Resource',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Resource Type'),
                items: availableTypes
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(
                            t[0].toUpperCase() + t.substring(1),
                            style: GoogleFonts.manrope(),
                          ),
                        ))
                    .toList(),
                onChanged: (v) => type = v ?? type,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Resource Name'),
                style: GoogleFonts.manrope(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                style: GoogleFonts.manrope(),
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
              Navigator.of(ctx).pop({
                'resource_type': type,
                'resource_name': nameCtrl.text.trim().isEmpty
                    ? 'Additional ${type[0].toUpperCase()}${type.substring(1)}'
                    : nameCtrl.text.trim(),
                'quantity': double.tryParse(qtyCtrl.text) ?? 1,
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
