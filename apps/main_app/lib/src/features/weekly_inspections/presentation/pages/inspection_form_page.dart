import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_data/noel_data.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../../../../shared/widgets/top_header.dart';

class InspectionFormPage extends StatefulWidget {
  final String projectId;
  final String? inspectionId;
  const InspectionFormPage({super.key, required this.projectId, this.inspectionId});

  @override
  State<InspectionFormPage> createState() => _InspectionFormPageState();
}

class _InspectionFormPageState extends State<InspectionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();

  DateTime _selectedDate = DateTime.now();
  String _method = 'drone';
  String? _inspectorId;
  final _notesController = TextEditingController();
  final _evidenceFiles = <Map<String, String>>[];
  final _pendingEvidenceFiles = <Map<String, dynamic>>[];

  List<Map<String, dynamic>> _projectServices = [];
  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, TextEditingController> _detailNotesControllers = {};

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String? _error;
  String? _editingStatus;
  Map<String, dynamic>? _project;

  @override
  void initState() {
    super.initState();
    _inspectorId = Supabase.instance.client.auth.currentUser?.id;
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final c in _quantityControllers.values) {
      c.dispose();
    }
    for (final c in _detailNotesControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final supabase = Supabase.instance.client;
      final service = InspectionService(supabase);
      _isEditing = widget.inspectionId != null;

      final project = await supabase
          .from('projects')
          .select('id, title')
          .eq('id', widget.projectId)
          .maybeSingle();

      final services =
          await service.getProjectServicesForInspection(widget.projectId);

      for (final svc in services) {
        final id = svc['id'] as String;
        _quantityControllers[id] = TextEditingController();
        _detailNotesControllers[id] = TextEditingController();
      }

      if (_isEditing) {
        final inspection = await service.getInspectionById(widget.inspectionId!);
        final details = await service.getInspectionDetails(widget.inspectionId!);

        _selectedDate = DateTime.tryParse(inspection['inspection_date']?.toString() ?? '') ?? DateTime.now();
        _method = inspection['method']?.toString() ?? 'drone';
        _inspectorId = inspection['inspector_id']?.toString();
        _notesController.text = inspection['general_notes']?.toString() ?? '';
        _editingStatus = inspection['status']?.toString();

        final existingEvidence = List<Map<String, String>>.from(
            (inspection['evidence_files'] as List?)?.map((e) => Map<String, String>.from(e as Map)) ?? []);
        _evidenceFiles.addAll(existingEvidence);

        for (final detail in details) {
          final qsId = detail['quote_service_id']?.toString();
          if (qsId != null && _quantityControllers.containsKey(qsId)) {
            _quantityControllers[qsId]?.text = (detail['measured_quantity'] as num?)?.toDouble()?.toString() ?? '';
            _detailNotesControllers[qsId]?.text = detail['notes']?.toString() ?? '';
          }
        }
      }

      if (mounted) {
        setState(() {
          _project = project;
          _projectServices = services;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _addEvidence() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (final file in result.files) {
          if (file.bytes != null) {
            setState(() {
              _pendingEvidenceFiles.add({
                'bytes': file.bytes,
                'fileName': file.name,
                'description': file.name,
              });
            });
          }
        }
      }
    } catch (e) {
      debugPrint('File picker error: $e');
    }
  }

  Future<List<Map<String, String>>> _uploadPendingFiles() async {
    final uploaded = <Map<String, String>>[];
    final storage = Supabase.instance.client.storage;

    for (final file in _pendingEvidenceFiles) {
      final bytes = file['bytes'] as List<int>?;
      if (bytes == null) continue;

      final cleanName = (file['fileName'] as String)
          .replaceAll(RegExp(r'[^a-zA-Z0-9.\-_]'), '_');
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$cleanName';

      await storage.from('equipment').uploadBinary(
            fileName,
            Uint8List.fromList(bytes),
            fileOptions:
                const FileOptions(cacheControl: '3600', upsert: false),
          );

      final publicUrl = storage.from('equipment').getPublicUrl(fileName);

      uploaded.add({
        'url': publicUrl,
        'description': file['description'] as String? ?? '',
        'type': 'photo',
      });
    }

    return uploaded;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    bool hasAnyQuantity = false;
    for (final svc in _projectServices) {
      final id = svc['id'] as String;
      final qty = double.tryParse(_quantityControllers[id]?.text ?? '');
      if (qty != null && qty > 0) {
        hasAnyQuantity = true;
        break;
      }
    }

    if (!hasAnyQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please enter at least one measured quantity for a service.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final service = InspectionService(supabase);

      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      final uploadedFiles = await _uploadPendingFiles();
      final allEvidence = [..._evidenceFiles, ...uploadedFiles];

      final inspectionData = {
        'project_id': widget.projectId,
        'inspection_date': dateStr,
        'inspector_id': _inspectorId,
        'method': _method,
        'general_notes': _notesController.text.trim(),
        'evidence_files': allEvidence,
      };

      String inspectionId;
      if (_isEditing) {
        inspectionId = widget.inspectionId!;
        await service.updateInspection(inspectionId, inspectionData);

        final existingDetails = await service.getInspectionDetails(inspectionId);
        for (final detail in existingDetails) {
          await service.deleteInspectionDetail(detail['id'] as String);
        }
      } else {
        final inspection = await service.createInspection({
          ...inspectionData,
          'status': 'draft',
        });
        inspectionId = inspection['id'] as String;
      }

      for (final svc in _projectServices) {
        final id = svc['id'] as String;
        final qty =
            double.tryParse(_quantityControllers[id]?.text ?? '') ?? 0;
        if (qty > 0) {
          final totalPlanned =
              (svc['quantity'] as num?)?.toDouble() ?? 0;
          await service.addInspectionDetail({
            'inspection_id': inspectionId,
            'quote_service_id': id,
            'measured_quantity': qty,
            'unit': svc['unit_of_measure'],
            'total_planned_quantity': totalPlanned,
            'notes': _detailNotesControllers[id]?.text.trim() ?? '',
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Draft updated successfully.'
                : 'Draft saved successfully.'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving inspection: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userName = currentUser?.userMetadata?['name'] ?? 'Admin User';
    final userEmail = currentUser?.email ?? '';
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      key: _mobileScaffoldKey,
      backgroundColor: const Color(0xFF0F172A),
      drawer: isMobile
          ? Drawer(
              backgroundColor: const Color(0xFF0F172A),
              child: Sidebar(
                userName: userName,
                userEmail: userEmail,
                currentPath:
                    '/projects/${widget.projectId}/weekly-inspections/new',
                onLogout: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) context.go('/signin');
                },
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            Sidebar(
              userName: userName,
              userEmail: userEmail,
              currentPath:
                  '/projects/${widget.projectId}/weekly-inspections/new',
              onLogout: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/signin');
              },
            ),
          Expanded(
            child: Column(
              children: [
                if (!isMobile)
                  TopHeader(
                    userName: userName,
                    breadcrumbs: [
                      'Operations',
                      'Projects',
                      _project?['title'] ?? 'Project',
                      'Weekly Inspections',
                      'New'
                    ],
                  ),
                if (isMobile) _buildMobileHeader(),
                Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primaryGreen))
                        : _error != null
                            ? _buildError()
                            : _buildForm(isMobile)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      color: const Color(0xFF1E293B),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _mobileScaffoldKey.currentState?.openDrawer(),
            child: const Icon(Icons.menu, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            _isEditing ? 'Edit Inspection' : 'New Inspection',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildForm(bool isMobile) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back,
                      size: 16, color: AppTheme.slate400),
                  const SizedBox(width: 6),
                  Text(
                    'Back to List',
                    style: GoogleFonts.manrope(
                      color: AppTheme.slate400,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isEditing ? 'Edit Weekly Inspection' : 'New Weekly Inspection',
              style: GoogleFonts.manrope(
                fontSize: isMobile ? 24 : 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              _project?['title'] ?? '',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.slate400,
              ),
            ),
            const SizedBox(height: 24),

            // General Info Card
            _buildSectionCard(
              title: 'Inspection Details',
              icon: Icons.info_outline,
              children: [
                const SizedBox(height: 12),
                _buildDatePicker(),
                const SizedBox(height: 16),
                _buildMethodDropdown(),
                const SizedBox(height: 16),
                _buildNotesField(),
              ],
            ),
            const SizedBox(height: 16),

            // Evidence Card
            _buildSectionCard(
              title: 'Evidence Files',
              icon: Icons.photo_library_outlined,
              children: [
                const SizedBox(height: 8),
                if (_pendingEvidenceFiles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${_pendingEvidenceFiles.length} file(s) selected — will upload on save',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._evidenceFiles.map((e) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                e['url'] ?? '',
                                width: 100,
                                height: 75,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 100,
                                  height: 75,
                                  color: AppTheme.slate700,
                                  child: const Icon(Icons.image, color: AppTheme.slate500, size: 24),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => setState(() => _evidenceFiles.remove(e)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        )),
                    ..._pendingEvidenceFiles.asMap().entries.map((entry) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                Uint8List.fromList(entry.value['bytes'] as List<int>),
                                width: 100,
                                height: 75,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 100,
                                  height: 75,
                                  color: AppTheme.slate700,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.image_outlined, color: Colors.orange, size: 24),
                                      const SizedBox(height: 2),
                                      Text(
                                        entry.value['fileName'] ?? '',
                                        style: GoogleFonts.manrope(fontSize: 8, color: Colors.orange),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _pendingEvidenceFiles.removeAt(entry.key)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        )),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _addEvidence,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(
                    'Add Evidence File',
                    style: GoogleFonts.manrope(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    side:
                        const BorderSide(color: AppTheme.primaryGreen),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Service Measurements Card
            _buildSectionCard(
              title: 'Service Measurements',
              icon: Icons.straighten,
              children: [
                const SizedBox(height: 12),
                if (_projectServices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No services found for this project.',
                      style: GoogleFonts.manrope(
                        color: AppTheme.slate400,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  ...(_projectServices.map((svc) =>
                      _buildServiceMeasurement(svc))),
              ],
            ),
            const SizedBox(height: 32),

            // Save button
            Center(
              child: SizedBox(
                width: isMobile ? double.infinity : 320,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : _isEditing
                            ? 'Update Draft'
                            : 'Save as Draft',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    return Row(
      children: [
        Text(
          'Date:',
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: AppTheme.slate200,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(
              dateStr,
              style: GoogleFonts.manrope(fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: AppTheme.slate600),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodDropdown() {
    return Row(
      children: [
        Text(
          'Method:',
          style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate200),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _method,
            dropdownColor: Colors.white,
            style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate900),
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              contentPadding:
                  EdgeInsets.fromLTRB(16, 30, 16, 12),
              labelStyle: TextStyle(color: Color(0xFF475569), fontSize: 13),
              hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              floatingLabelStyle: TextStyle(color: Color(0xFF475569), fontSize: 11),
            ),
            items: const [
              DropdownMenuItem(value: 'drone', child: Text('Drone', style: TextStyle(color: Color(0xFF0F172A)))),
              DropdownMenuItem(value: 'gps', child: Text('GPS', style: TextStyle(color: Color(0xFF0F172A)))),
              DropdownMenuItem(
                  value: 'total_station', child: Text('Total Station', style: TextStyle(color: Color(0xFF0F172A)))),
              DropdownMenuItem(value: 'other', child: Text('Other', style: TextStyle(color: Color(0xFF0F172A)))),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _method = v);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      decoration: const InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: 'General Notes',
        hintText: 'Observations, weather conditions, etc.',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: EdgeInsets.fromLTRB(16, 32, 16, 12),
        labelStyle: TextStyle(color: Color(0xFF475569), fontSize: 13),
        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        floatingLabelStyle: TextStyle(color: Color(0xFF475569), fontSize: 11),
      ),
      style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate900),
    );
  }

  Widget _buildServiceMeasurement(Map<String, dynamic> svc) {
    final id = svc['id'] as String;
    final name = svc['name'] ?? 'Unknown';
    final unit = svc['unit_of_measure'] ?? 'CY';
    final plannedQty = (svc['quantity'] as num?)?.toDouble() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.construction, size: 14, color: AppTheme.slate400),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.slate200,
                  ),
                ),
              ),
              Text(
                'Planned: ${plannedQty.toStringAsFixed(1)} $unit',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: AppTheme.slate500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _quantityControllers[id],
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelText: 'Measured Quantity ($unit)',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.fromLTRB(14, 30, 14, 12),
                    labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 12),
                    floatingLabelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 11),
                  ),
                  style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate900),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _detailNotesControllers[id],
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.fromLTRB(14, 30, 14, 12),
                    labelStyle: TextStyle(color: Color(0xFF475569), fontSize: 12),
                    floatingLabelStyle: TextStyle(color: Color(0xFF475569), fontSize: 11),
                  ),
                  style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate900),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
