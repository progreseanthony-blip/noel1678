import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';

class IncidentFormPage extends ConsumerStatefulWidget {
  final String projectId;
  final String? dailyReportId;

  const IncidentFormPage({super.key, required this.projectId, this.dailyReportId});

  @override
  ConsumerState<IncidentFormPage> createState() => _IncidentFormPageState();
}

class _IncidentFormPageState extends ConsumerState<IncidentFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _isLoadingResources = true;

  List<Map<String, dynamic>> _categories = [];

  String? _selectedCategoryId;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'medium';
  DateTime _startedAt = DateTime.now();
  final _actualExpensesCtrl = TextEditingController();

  final List<Map<String, dynamic>> _affectedItems = [];

  List<Map<String, dynamic>> _projectMaterials = [];
  List<Map<String, dynamic>> _projectMachinery = [];
  List<Map<String, dynamic>> _projectLabor = [];
  List<Map<String, dynamic>> _projectInstruments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final service = ref.read(incidentsServiceProvider);
      _categories = await service.getCategories();

      final client = Supabase.instance.client;
      final materials = await client
          .from('project_materials')
          .select('id, material_name, unit_name, expected_quantity, received_quantity')
          .eq('project_id', widget.projectId);
      final machinery = await client
          .from('project_machinery')
          .select('id, machinery_name, expected_quantity, received_quantity')
          .eq('project_id', widget.projectId);
      final labor = await client
          .from('project_labor')
          .select('id, role_name, expected_employees, active_employees')
          .eq('project_id', widget.projectId);
      final instruments = await client
          .from('project_instruments')
          .select('id, instrument_name, expected_quantity, received_quantity')
          .eq('project_id', widget.projectId);

      if (mounted) {
        setState(() {
          _projectMaterials = List<Map<String, dynamic>>.from(materials ?? []);
          _projectMachinery = List<Map<String, dynamic>>.from(machinery ?? []);
          _projectLabor = List<Map<String, dynamic>>.from(labor ?? []);
          _projectInstruments = List<Map<String, dynamic>>.from(instruments ?? []);
          _isLoadingResources = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingResources = false);
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startedAt,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startedAt),
    );
    if (time == null) return;
    setState(() {
      _startedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _addResourceItem() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _AddResourceDialog(
        materials: _projectMaterials,
        machinery: _projectMachinery,
        labor: _projectLabor,
        instruments: _projectInstruments,
      ),
    );
    if (result != null) {
      setState(() => _affectedItems.add(result));
    }
  }

  void _removeResourceItem(int index) {
    setState(() => _affectedItems.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(incidentsServiceProvider);
      final userId = Supabase.instance.client.auth.currentUser?.id;

      final incident = await service.create({
        'project_id': widget.projectId,
        if (widget.dailyReportId != null) 'daily_report_id': widget.dailyReportId,
        'category_id': _selectedCategoryId,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'priority': _priority,
        'reported_by': userId,
        'started_at': _startedAt.toUtc().toIso8601String(),
        'actual_expenses': double.tryParse(_actualExpensesCtrl.text) ?? 0,
      });

      for (final item in _affectedItems) {
        await service.addAffectedItem(incident['id'], item);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident reported successfully'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _actualExpensesCtrl.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Report Incident', style: TextStyle(fontSize: 16)),
      ),
      body: _isLoadingResources
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Basic Information', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    items: _categories.map((c) => DropdownMenuItem(
                      value: c['id'] as String,
                      child: Text(c['name'] as String? ?? ''),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedCategoryId = v),
                    decoration: const InputDecoration(labelText: 'Category *', border: OutlineInputBorder()),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder(), hintText: 'Brief description of the incident'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), hintText: 'Detailed explanation...'),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _priority,
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(value: 'critical', child: Text('Critical')),
                    ],
                    onChanged: (v) => setState(() => _priority = v!),
                    decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),

                  InkWell(
                    onTap: _pickDateTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date & Time *', border: OutlineInputBorder()),
                      child: Row(children: [
                        const Icon(Icons.access_time, size: 18, color: AppTheme.slate500),
                        const SizedBox(width: 8),
                        Text(_formatDateTime(_startedAt), style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate900)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _actualExpensesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Actual Expenses (\$)',
                      hintText: 'Money spent on repairs, replacements...',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(children: [
                    Text('Affected Resources', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.slate900)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addResourceItem,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                    ),
                  ]),
                  const SizedBox(height: 8),

                  if (_affectedItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.slate50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.slate200, style: BorderStyle.solid),
                      ),
                      child: Center(
                        child: Text('No resources affected. Tap "Add" to select project resources.',
                            style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 13)),
                      ),
                    )
                  else
                    ..._affectedItems.asMap().entries.map((entry) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(Icons.inventory_2, color: AppTheme.slate500),
                        title: Text(entry.value['resource_name'] as String? ?? '', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text('${entry.value['affected_type']} - ${entry.value['quantity_affected']} ${entry.value['unit'] ?? ''}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 18, color: AppTheme.errorRed),
                          onPressed: () => _removeResourceItem(entry.key),
                        ),
                      ),
                    )),

                  const SizedBox(height: 32),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                      label: Text(_isSubmitting ? 'Submitting...' : 'Report Incident'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.errorRed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _AddResourceDialog extends StatefulWidget {
  final List<Map<String, dynamic>> materials;
  final List<Map<String, dynamic>> machinery;
  final List<Map<String, dynamic>> labor;
  final List<Map<String, dynamic>> instruments;

  const _AddResourceDialog({
    required this.materials,
    required this.machinery,
    required this.labor,
    required this.instruments,
  });

  @override
  State<_AddResourceDialog> createState() => _AddResourceDialogState();
}

class _AddResourceDialogState extends State<_AddResourceDialog> {
  String _selectedType = 'material';
  String? _selectedResourceId;
  double _quantity = 1;
  String _unit = '';
  double _repairCost = 0;

  List<Map<String, dynamic>> get _currentList {
    switch (_selectedType) {
      case 'material': return widget.materials;
      case 'machinery': return widget.machinery;
      case 'labor': return widget.labor;
      case 'instrument': return widget.instruments;
      default: return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Affected Resource'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: const [
                  DropdownMenuItem(value: 'material', child: Text('Material')),
                  DropdownMenuItem(value: 'machinery', child: Text('Machinery')),
                  DropdownMenuItem(value: 'labor', child: Text('Labor/Personnel')),
                  DropdownMenuItem(value: 'instrument', child: Text('Instrument')),
                ],
                onChanged: (v) => setState(() {
                  _selectedType = v!;
                  _selectedResourceId = null;
                }),
                decoration: const InputDecoration(labelText: 'Resource Type', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedResourceId,
                items: _currentList.map((r) {
                  final name = r['material_name'] ?? r['machinery_name'] ?? r['role_name'] ?? r['instrument_name'] ?? '';
                  return DropdownMenuItem(value: r['id'] as String, child: Text(name as String, style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedResourceId = v;
                    final selected = _currentList.cast<Map<String, dynamic>?>().firstWhere((r) => r?['id'] == v, orElse: () => null);
                    if (selected != null) {
                      _unit = selected['unit_name'] as String? ?? selected['unit'] as String? ?? '';
                    }
                  });
                },
                decoration: const InputDecoration(labelText: 'Resource', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: '1',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity Affected', border: OutlineInputBorder()),
                onChanged: (v) => _quantity = double.tryParse(v) ?? 1,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _unit,
                decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder(), hintText: 'm³, units, hours...'),
                onChanged: (v) => _unit = v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: '0',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Repair Cost (\$)', border: OutlineInputBorder(), hintText: 'Estimated cost to fix/replace'),
                onChanged: (v) => _repairCost = double.tryParse(v) ?? 0,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _selectedResourceId == null ? null : () {
            final selected = _currentList.cast<Map<String, dynamic>?>().firstWhere((r) => r?['id'] == _selectedResourceId, orElse: () => null);
            final name = selected?['material_name'] ?? selected?['machinery_name'] ?? selected?['role_name'] ?? selected?['instrument_name'] ?? '';
            Navigator.pop(context, {
              'affected_type': _selectedType,
              if (_selectedType == 'material') 'project_material_id': _selectedResourceId,
              if (_selectedType == 'machinery') 'project_machinery_id': _selectedResourceId,
              if (_selectedType == 'labor') 'project_labor_id': _selectedResourceId,
              if (_selectedType == 'instrument') 'project_instrument_id': _selectedResourceId,
              'resource_name': name,
              'quantity_affected': _quantity,
              'unit': _unit,
              'estimated_cost': _repairCost,
            });
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
