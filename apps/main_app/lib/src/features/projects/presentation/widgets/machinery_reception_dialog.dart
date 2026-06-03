import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';

class MachineryReceptionDialog extends StatefulWidget {
  final String projectId;
  final String projectMachineryId;
  final String machineryName;
  final String serviceName;
  final String? inspectionId; // Optional for Edit mode

  const MachineryReceptionDialog({
    super.key,
    required this.projectId,
    required this.projectMachineryId,
    required this.machineryName,
    required this.serviceName,
    this.inspectionId,
  });

  @override
  State<MachineryReceptionDialog> createState() => _MachineryReceptionDialogState();
}

class _MachineryReceptionDialogState extends State<MachineryReceptionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _serialController = TextEditingController();
  final _internalIdController = TextEditingController();
  final _hourMeterController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCondition = 'operational';
  String _selectedOwnership = 'owned';
  String _odometerUnit = 'hours'; // 'hours' or 'miles'
  DateTime _receptionDate = DateTime.now();
  final List<PlatformFile> _selectedFiles = [];
  final List<String> _existingPhotos = [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _showPhotoError = false;

  @override
  void initState() {
    super.initState();
    if (widget.inspectionId != null) {
      _loadExistingData();
    }
  }

  Future<void> _loadExistingData() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('machinery_inspections')
          .select()
          .eq('id', widget.inspectionId!)
          .single();

      if (mounted) {
        setState(() {
          _serialController.text = data['internal_code'] ?? '';
          _internalIdController.text = data['internal_id'] ?? '';
          _hourMeterController.text = (data['hour_meter_start']?.toString()) ?? '';
          _notesController.text = data['observations'] ?? '';
          _selectedCondition = data['condition_status'] ?? 'operational';
          _selectedOwnership = data['ownership_type'] ?? 'owned';
          _odometerUnit = data['odometer_unit'] ?? 'hours';
          if (data['reception_date'] != null) {
            _receptionDate = DateTime.tryParse(data['reception_date']) ?? DateTime.now();
          }
          final photos = data['evidence_photos'] as List?;
          if (photos != null) {
            _existingPhotos.addAll(photos.map((e) => e.toString()));
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading inspection: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _serialController.dispose();
    _internalIdController.dispose();
    _hourMeterController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receptionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _receptionDate = picked);
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (result != null) {
        setState(() => _selectedFiles.addAll(result.files));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting images: $e')),
        );
      }
    }
  }

  void _removeExistingPhoto(int index) => setState(() => _existingPhotos.removeAt(index));
  void _removeFile(int index) => setState(() => _selectedFiles.removeAt(index));

  Future<void> _saveReception() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFiles.isEmpty && _existingPhotos.isEmpty) {
      setState(() => _showPhotoError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one evidence photo is required.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final supabase = Supabase.instance.client;

    try {
      if (widget.projectMachineryId.isEmpty) {
        throw 'Invalid machinery ID';
      }
      // Overbooking conflict check
      final inspectionId = widget.inspectionId;
      final hasInspectionId = inspectionId != null && inspectionId.isNotEmpty;
      final baseQuery = supabase
          .from('machinery_inspections')
          .select('id, brand_model, project_machinery(project_id, projects(title))')
          .eq('internal_code', _serialController.text.trim())
          .is_('returned_at', null);
      final filteredQuery = hasInspectionId
          ? baseQuery.neq('id', inspectionId!)
          : baseQuery;
      final results = await filteredQuery.limit(1);
      final activeInspection = results.isEmpty ? null : results.first;

      if (activeInspection != null) {
        final otherProjectName = activeInspection['project_machinery']?['projects']?['title'] ?? 'another project';
        
        final proceed = await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withOpacity(0.6),
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                Text('Overbooking Alert', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'Machine with serial/plate "${_serialController.text.trim()}" is currently active on "$otherProjectName".\n\n'
              'Do you want to automatically transfer it (releasing it from "$otherProjectName" and assigning it here)?',
              style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate700),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: GoogleFonts.manrope(color: AppTheme.slate500, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text('Transfer Machine', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (proceed != true) {
          setState(() => _isSaving = false);
          return;
        }

        // De-mobilize from previous assignment
        await supabase
            .from('machinery_inspections')
            .update({
              'returned_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', activeInspection['id']);
      }

      final user = supabase.auth.currentUser;

      // Upload Photos
      final List<String> photoUrls = List.from(_existingPhotos);
      for (final file in _selectedFiles) {
        if (file.bytes == null) continue;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(' ', '_')}';
        final filePath = '${widget.projectId}/${widget.projectMachineryId}/$fileName';
        await supabase.storage.from('machinery_evidence').uploadBinary(
          filePath,
          file.bytes!,
          fileOptions: FileOptions(contentType: 'image/${file.extension ?? 'jpeg'}'),
        );
        final publicUrl = supabase.storage.from('machinery_evidence').getPublicUrl(filePath);
        photoUrls.add(publicUrl);
      }

      final payload = {
        'project_machinery_id': widget.projectMachineryId,
        'received_by': user?.id,
        'internal_code': _serialController.text.trim(),
        'internal_id': _internalIdController.text.trim(),
        'hour_meter_start': double.tryParse(_hourMeterController.text.trim()) ?? 0,
        'odometer_unit': _odometerUnit,
        'reception_date': _receptionDate.toIso8601String().split('T')[0],
        'condition_status': _selectedCondition,
        'observations': _notesController.text.trim(),
        'evidence_photos': photoUrls,
        'brand_model': widget.machineryName,
        'ownership_type': _selectedOwnership,
      };

      if (widget.inspectionId != null) {
        await supabase.from('machinery_inspections').update(payload).eq('id', widget.inspectionId!);
      } else {
        await supabase.from('machinery_inspections').insert(payload);
        final currentQty = await supabase
            .from('project_machinery')
            .select('received_quantity')
            .eq('id', widget.projectMachineryId)
            .maybeSingle()
            .then((row) => (row?['received_quantity'] as num?)?.toInt() ?? 0);
        await supabase.from('project_machinery').update({
          'received_quantity': currentQty + 1,
        }).eq('id', widget.projectMachineryId);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving reception: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${_receptionDate.month.toString().padLeft(2, '0')}/${_receptionDate.day.toString().padLeft(2, '0')}/${_receptionDate.year}';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 620,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fact_check_outlined, color: AppTheme.primaryGreen),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.inspectionId != null ? 'Edit Reception' : 'Machine Reception',
                          style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                        ),
                        Text(widget.machineryName, style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate500)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            widget.serviceName,
                            style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppTheme.slate400),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: _isLoading
                  ? const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Reception Date ───────────────────────────────
                            Text('Reception Date', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.slate200),
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, color: AppTheme.primaryGreen, size: 18),
                                    const SizedBox(width: 12),
                                    Text(formattedDate, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.slate900)),
                                    const Spacer(),
                                    Text('Tap to change', style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate400)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Serial + Internal ID ─────────────────────────
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    label: 'Serial Number / PIN',
                                    controller: _serialController,
                                    icon: Icons.tag,
                                    validator: (v) => v!.isEmpty ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    label: 'Internal Code (ID)',
                                    controller: _internalIdController,
                                    icon: Icons.qr_code,
                                    hint: 'e.g. SCR-001',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ── Odometer ─────────────────────────────────────
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    label: _odometerUnit == 'hours' ? 'Hour Meter (hrs)' : 'Odometer (mi)',
                                    controller: _hourMeterController,
                                    icon: _odometerUnit == 'hours' ? Icons.timer_outlined : Icons.speed,
                                    keyboardType: TextInputType.number,
                                    validator: (v) => v!.isEmpty ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Odometer Unit Toggle
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Odometer Type', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppTheme.slate200),
                                        ),
                                        child: Row(
                                          children: [
                                            _buildOdometerToggle('Hours', Icons.timer_outlined, 'hours'),
                                            _buildOdometerToggle('Miles', Icons.speed, 'miles'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ── Condition + Ownership ────────────────────────
                            Row(
                              children: [
                                Expanded(child: _buildDropdown(
                                  label: 'Condition',
                                  value: _selectedCondition,
                                  items: const [
                                    DropdownMenuItem(value: 'excellent', child: Text('Excellent (Like New)')),
                                    DropdownMenuItem(value: 'operational', child: Text('Good (Operational)')),
                                    DropdownMenuItem(value: 'needs_maintenance', child: Text('Fair (Needs maintenance)')),
                                    DropdownMenuItem(value: 'damaged', child: Text('Poor (Damaged)')),
                                  ],
                                  onChanged: (v) { if (v != null) setState(() => _selectedCondition = v); },
                                )),
                                const SizedBox(width: 16),
                                Expanded(child: _buildDropdown(
                                  label: 'Ownership',
                                  value: _selectedOwnership,
                                  items: const [
                                    DropdownMenuItem(value: 'owned', child: Text('Owned')),
                                    DropdownMenuItem(value: 'rented', child: Text('Rented')),
                                  ],
                                  onChanged: (v) { if (v != null) setState(() => _selectedOwnership = v); },
                                )),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ── Notes ────────────────────────────────────────
                            _buildTextField(
                              label: 'Observations / Notes',
                              controller: _notesController,
                              icon: Icons.notes,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 24),

                            // ── Evidence Photos ──────────────────────────────
                            Row(
                              children: [
                                Text('Evidence Photos', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                  child: Text('REQUIRED', style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.orange)),
                                ),
                              ],
                            ),
                            if (_showPhotoError && _selectedFiles.isEmpty && _existingPhotos.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text('Please add at least one photo to continue',
                                    style: GoogleFonts.manrope(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600)),
                              ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                ..._existingPhotos.asMap().entries.map((entry) => _buildPhotoThumb(
                                      networkUrl: entry.value,
                                      onRemove: () => _removeExistingPhoto(entry.key),
                                    )),
                                ..._selectedFiles.asMap().entries.map((entry) => _buildPhotoThumb(
                                      bytes: entry.value.bytes,
                                      onRemove: () => _removeFile(entry.key),
                                    )),
                                GestureDetector(
                                  onTap: _pickFiles,
                                  child: Container(
                                    width: 80, height: 80,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _showPhotoError && _selectedFiles.isEmpty ? Colors.orange : AppTheme.primaryGreen.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo, color: AppTheme.primaryGreen),
                                        SizedBox(height: 4),
                                        Text('Add Photo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: AppTheme.slate500)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveReception,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                    label: Text(
                      _isSaving ? 'Saving...' : (widget.inspectionId != null ? 'Update Record' : 'Confirm Reception'),
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white),
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

  Widget _buildOdometerToggle(String label, IconData icon, String value) {
    final isSelected = _odometerUnit == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _odometerUnit = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.white : AppTheme.slate500),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppTheme.slate500,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoThumb({String? networkUrl, Uint8List? bytes, required VoidCallback onRemove}) {
    return Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.slate200),
        image: networkUrl != null
            ? DecorationImage(image: NetworkImage(networkUrl), fit: BoxFit.cover)
            : (bytes != null ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover) : null),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
            child: const Icon(Icons.close, size: 14, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(border: Border.all(color: AppTheme.slate200), borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(value: value, isExpanded: true, items: items, onChanged: onChanged),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.manrope(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.manrope(color: AppTheme.slate400),
            prefixIcon: maxLines == 1 ? Icon(icon, color: AppTheme.slate400, size: 20) : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.slate200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.slate200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryGreen)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
