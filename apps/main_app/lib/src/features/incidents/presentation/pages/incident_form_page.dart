import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import '../../../../shared/widgets/completed_project_banner.dart';
import 'package:uuid/uuid.dart';

class IncidentFormPage extends ConsumerStatefulWidget {
  final String projectId;
  final String? dailyReportId;
  final String? incidentId;

  const IncidentFormPage({super.key, required this.projectId, this.dailyReportId, this.incidentId});

  @override
  ConsumerState<IncidentFormPage> createState() => _IncidentFormPageState();
}

class _IncidentFormPageState extends ConsumerState<IncidentFormPage> {
  bool _isCompleted = false;
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();
  bool _isSubmitting = false;
  bool _isLoadingResources = true;
  bool _isUploading = false;

  List<String> _evidencePhotos = [];
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

      if (widget.incidentId != null) {
        final incident = await service.getById(widget.incidentId!);
        _selectedCategoryId = incident['category_id']?.toString();
        _titleCtrl.text = incident['title'] ?? '';
        _descCtrl.text = incident['description'] ?? '';
        _priority = incident['priority'] ?? 'medium';
        _actualExpensesCtrl.text = (incident['actual_expenses'] as num?)?.toString() ?? '';
        final sd = incident['started_at'];
        _startedAt = sd != null ? DateTime.parse(sd.toString()).toLocal() : DateTime.now();
        final items = incident['incident_affected_items'] as List? ?? [];
        _affectedItems.addAll(List<Map<String, dynamic>>.from(items.map((i) => Map<String, dynamic>.from(i))));
        final photos = incident['evidence_photos'] as List? ?? [];
        _evidencePhotos = List<String>.from(photos.map((p) => p.toString()));
      }

      final client = Supabase.instance.client;
      final materials = await client
          .from('project_materials')
          .select('id, material_name, unit_name, expected_quantity, received_quantity, quote_service_materials(unit_price)')
          .eq('project_id', widget.projectId);
      final machinery = await client
          .from('project_machinery')
          .select('id, machinery_name, expected_quantity, received_quantity, quote_service_machineries(monthly_rent_cost)')
          .eq('project_id', widget.projectId);
      final labor = await client
          .from('project_labor')
          .select('id, role_name, expected_employees, active_employees, quote_service_labors(hourly_rate)')
          .eq('project_id', widget.projectId);
      final instruments = await client
          .from('project_instruments')
          .select('id, instrument_name, expected_quantity, received_quantity, quote_service_instruments(unit_price)')
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
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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
    final result = await showSafeDialog<Map<String, dynamic>>(
      context: context,
      fullscreenOnMobile: true,
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

  Future<void> _editResourceItem(int index) async {
    final item = _affectedItems[index];
    final type = item['affected_type'] as String? ?? 'material';
    final initialResourceId = type == 'material' ? item['project_material_id']?.toString()
        : type == 'machinery' ? item['project_machinery_id']?.toString()
        : type == 'labor' ? item['project_labor_id']?.toString()
        : item['project_instrument_id']?.toString();
    final result = await showSafeDialog<Map<String, dynamic>>(
      context: context,
      fullscreenOnMobile: true,
      builder: (ctx) => _AddResourceDialog(
        materials: _projectMaterials,
        machinery: _projectMachinery,
        labor: _projectLabor,
        instruments: _projectInstruments,
        editMode: true,
        initialType: type,
        initialResourceId: initialResourceId,
        initialQuantity: (item['quantity_affected'] as num?)?.toDouble() ?? 1,
        initialUnit: item['unit'] as String? ?? '',
        initialHourlyRate: (item['hourly_cost_rate'] as num?)?.toDouble() ?? 0,
        initialDailyRate: (item['daily_rate'] as num?)?.toDouble() ?? 0,
        initialDaysAffected: (item['days_affected'] as num?)?.toDouble() ?? 0,
      ),
    );
    if (result != null) {
      setState(() => _affectedItems[index] = result);
    }
  }

  void _removeResourceItem(int index) {
    setState(() => _affectedItems.removeAt(index));
  }

  void _removePhoto(int index) {
    setState(() => _evidencePhotos.removeAt(index));
  }

  Future<void> _pickPhotos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;

    setState(() => _isUploading = true);
    try {
      for (final file in result.files) {
        if (file.bytes == null) continue;
        final ext = file.extension ?? 'jpg';
        final path = '${widget.projectId}/${_uuid.v4()}.$ext';
        await Supabase.instance.client.storage
            .from('incident-photos')
            .uploadBinary(path, file.bytes!);
        final url = Supabase.instance.client.storage
            .from('incident-photos')
            .getPublicUrl(path);
        _evidencePhotos.add(url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
    if (mounted) setState(() => _isUploading = false);
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

      final data = {
        'project_id': widget.projectId,
        if (widget.dailyReportId != null) 'daily_report_id': widget.dailyReportId,
        'category_id': _selectedCategoryId,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'priority': _priority,
        'reported_by': userId,
        'started_at': _startedAt.toUtc().toIso8601String(),
        'actual_expenses': double.tryParse(_actualExpensesCtrl.text) ?? 0,
        'evidence_photos': _evidencePhotos,
      };

      if (widget.incidentId != null) {
        await service.update(widget.incidentId!, data);
        await service.deleteAllAffectedItems(widget.incidentId!);
        for (final item in _affectedItems) {
          await service.addAffectedItem(widget.incidentId!, item);
        }
      } else {
        final incident = await service.create(data);
        for (final item in _affectedItems) {
          await service.addAffectedItem(incident['id'], item);
        }
      }

      if (mounted) {
        final msg = widget.incidentId != null ? 'Incident updated successfully' : 'Incident reported successfully';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
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
        title: Text(widget.incidentId != null ? 'Edit Incident' : 'Report Incident', style: const TextStyle(fontSize: 16)),
      ),
      body: _isLoadingResources
          ? const Center(child: CircularProgressIndicator())
          : CompletedProjectBanner(
              projectId: widget.projectId,
              isCompletedCallback: (completed) {
                if (completed != _isCompleted) setState(() => _isCompleted = completed);
              },
              child: Form(
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
                    ..._affectedItems.asMap().entries.map((entry) {
                      final rate = entry.value['hourly_cost_rate'] ?? 0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(Icons.inventory_2, color: AppTheme.slate500),
                          title: Text(entry.value['resource_name'] as String? ?? '', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Text('${entry.value['affected_type']} - ${(rate as num).toStringAsFixed(0)} \$/hr'),
                          onTap: () => _editResourceItem(entry.key),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 18, color: AppTheme.errorRed),
                            onPressed: () => _removeResourceItem(entry.key),
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 24),
                  Row(children: [
                    Text('Evidence Photos', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.slate900)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _isUploading ? null : _pickPhotos,
                      icon: _isUploading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.add_a_photo, size: 18),
                      label: Text(_isUploading ? 'Uploading...' : 'Add Photos'),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  if (_evidencePhotos.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.slate50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.slate200),
                      ),
                      child: Center(
                        child: Text('No photos added. Tap "Add Photos" to attach evidence.',
                            style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 13)),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _evidencePhotos.asMap().entries.map((entry) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                entry.value,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80, height: 80,
                                  color: AppTheme.slate200,
                                  child: const Icon(Icons.broken_image, color: AppTheme.slate400),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0, right: 0,
                              child: GestureDetector(
                                onTap: () => _removePhoto(entry.key),
                                child: Container(
                                  width: 20, height: 20,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.errorRed,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _isCompleted || _isSubmitting ? null : _submit,
                      icon: _isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                      label: Text(_isSubmitting ? 'Saving...' : (widget.incidentId != null ? 'Update Incident' : 'Report Incident')),
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
            ),
    );
  }
}

class _AddResourceDialog extends StatefulWidget {
  final List<Map<String, dynamic>> materials;
  final List<Map<String, dynamic>> machinery;
  final List<Map<String, dynamic>> labor;
  final List<Map<String, dynamic>> instruments;
  final bool editMode;
  final String initialType;
  final double initialQuantity;
  final String initialUnit;
  final double initialHourlyRate;
  final double initialDailyRate;
  final double initialDaysAffected;
  final String? initialResourceId;

  const _AddResourceDialog({
    required this.materials,
    required this.machinery,
    required this.labor,
    required this.instruments,
    this.editMode = false,
    this.initialType = 'material',
    this.initialQuantity = 1,
    this.initialUnit = '',
    this.initialHourlyRate = 0,
    this.initialDailyRate = 0,
    this.initialDaysAffected = 0,
    this.initialResourceId,
  });

  @override
  State<_AddResourceDialog> createState() => _AddResourceDialogState();
}

class _AddResourceDialogState extends State<_AddResourceDialog> {
  late String _selectedType;
  String? _selectedResourceId;
  late double _quantity;
  late final TextEditingController _unitCtrl;
  late double _hourlyCostRate;
  late double _dailyRate;
  late double _daysAffected;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _dailyRateCtrl;
  late final TextEditingController _daysCtrl;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.editMode ? widget.initialType : 'material';
    _selectedResourceId = widget.editMode ? widget.initialResourceId : null;
    _quantity = widget.initialQuantity;
    _unitCtrl = TextEditingController(text: widget.initialUnit);
    _hourlyCostRate = widget.initialHourlyRate;
    _dailyRate = widget.initialDailyRate;
    _daysAffected = widget.initialDaysAffected;
    _rateCtrl = TextEditingController(text: widget.initialHourlyRate > 0 ? widget.initialHourlyRate.toStringAsFixed(0) : '0');
    _dailyRateCtrl = TextEditingController(text: widget.initialDailyRate > 0 ? widget.initialDailyRate.toStringAsFixed(0) : '0');
    _daysCtrl = TextEditingController(text: widget.initialDaysAffected > 0 ? widget.initialDaysAffected.toStringAsFixed(0) : '0');
  }

  List<Map<String, dynamic>> get _currentList {
    switch (_selectedType) {
      case 'material': return widget.materials;
      case 'machinery': return widget.machinery;
      case 'labor': return widget.labor;
      case 'instrument': return widget.instruments;
      default: return [];
    }
  }

  double _suggestedRate(Map<String, dynamic>? resource) {
    if (resource == null) return 0;
    switch (_selectedType) {
      case 'machinery':
        final qsm = resource['quote_service_machineries'];
        final monthly = qsm is Map ? (qsm['monthly_rent_cost'] as num?)?.toDouble() ?? 0 : 0;
        _dailyRate = monthly > 0 ? monthly / 30 : 0;
        _dailyRateCtrl.text = _dailyRate > 0 ? _dailyRate.toStringAsFixed(0) : '0';
        return monthly > 0 ? monthly / 160 : 0;
      case 'labor':
        final qsl = resource['quote_service_labors'];
        return qsl is Map ? (qsl['hourly_rate'] as num?)?.toDouble() ?? 0 : 0;
      case 'instrument':
        final qsi = resource['quote_service_instruments'];
        final price = qsi is Map ? (qsi['unit_price'] as num?)?.toDouble() ?? 0 : 0;
        return price > 0 ? price / 8 : 0;
      case 'material':
      default:
        return 0;
    }
  }

  @override
  void dispose() {
    _rateCtrl.dispose();
    _dailyRateCtrl.dispose();
    _daysCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveDialogShell(
      title: widget.editMode ? 'Edit Affected Resource' : 'Add Affected Resource',
      maxWidth: 480,
      onClose: () => Navigator.of(context).pop(),
      body: Column(
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
            onChanged: widget.editMode ? null : (v) => setState(() {
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
                  _unitCtrl.text = selected['unit_name'] as String? 
                      ?? (_selectedType == 'machinery' ? 'hrs' 
                      : _selectedType == 'labor' ? 'workers'
                      : _selectedType == 'instrument' ? 'days'
                      : '');
                  _hourlyCostRate = _suggestedRate(selected);
                  _rateCtrl.text = _hourlyCostRate > 0 ? _hourlyCostRate.toStringAsFixed(0) : '0';
                }
              });
            },
            decoration: const InputDecoration(labelText: 'Resource', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: widget.editMode ? widget.initialQuantity.toString() : '1',
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantity Affected', border: OutlineInputBorder()),
            onChanged: (v) => _quantity = double.tryParse(v) ?? 1,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _unitCtrl,
            decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder(), hintText: 'm³, units, hours...'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _rateCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Hourly Cost Rate (\$/hr)',
              hintText: 'Cost per hour of downtime',
              border: OutlineInputBorder(),
              prefixText: '\$ ',
            ),
            onChanged: (v) => _hourlyCostRate = double.tryParse(v) ?? 0,
          ),
          if (_selectedType == 'machinery') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _dailyRateCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Daily Rent Rate (\$/day)',
                hintText: 'Auto-calculated from monthly rent / 30',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              onChanged: (v) => _dailyRate = double.tryParse(v) ?? 0,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _daysCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Days Affected',
                hintText: 'Number of calendar days machine was unavailable',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _daysAffected = double.tryParse(v) ?? 0,
            ),
          ],
        ],
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          const SizedBox(width: 8),
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
                'unit': _unitCtrl.text,
                'hourly_cost_rate': _hourlyCostRate,
                if (_selectedType == 'machinery') 'daily_rate': _dailyRate,
                if (_selectedType == 'machinery') 'days_affected': _daysAffected,
              });
            },
            child: Text(widget.editMode ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }
}
