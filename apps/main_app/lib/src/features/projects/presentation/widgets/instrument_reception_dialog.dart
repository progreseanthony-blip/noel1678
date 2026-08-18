import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_ui_components/noel_ui_components.dart';

class InstrumentReceptionDialog extends StatefulWidget {
  final String projectId;
  final String projectInstrumentId;
  final String instrumentName;
  final String serviceName;
  final String? inspectionId; // Optional for Edit mode

  const InstrumentReceptionDialog({
    super.key,
    required this.projectId,
    required this.projectInstrumentId,
    required this.instrumentName,
    required this.serviceName,
    this.inspectionId,
  });

  @override
  State<InstrumentReceptionDialog> createState() => _InstrumentReceptionDialogState();
}

class _InstrumentReceptionDialogState extends State<InstrumentReceptionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _serialController = TextEditingController();
  final _notesController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  String _selectedCondition = 'operational';
  String _selectedOwnership = 'owned';
  DateTime _receptionDate = DateTime.now();
  final List<PlatformFile> _selectedFiles = [];
  final List<String> _existingPhotos = []; // Keep track of old photos in edit mode
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
          .from('instrument_inspections')
          .select()
          .eq('id', widget.inspectionId!)
          .single();
      
      if (mounted) {
        setState(() {
          _serialController.text = data['internal_code'] ?? '';
          _notesController.text = data['observations'] ?? '';
          _quantityController.text = (data['quantity_received']?.toString()) ?? '1';
          _selectedCondition = data['condition_status'] ?? 'operational';
          _selectedOwnership = data['ownership_type'] ?? 'owned';
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
    _notesController.dispose();
    _quantityController.dispose();
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
          colorScheme: ColorScheme.light(primary: Colors.purple),
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
        setState(() {
          _selectedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting images: $e')),
        );
      }
    }
  }

  void _removeExistingPhoto(int index) {
    setState(() {
      _existingPhotos.removeAt(index);
    });
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

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
      final user = supabase.auth.currentUser;

      // 1. Upload Photos
      final List<String> photoUrls = List.from(_existingPhotos);
      for (final file in _selectedFiles) {
        if (file.bytes == null) continue;
        
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(' ', '_')}';
        final filePath = '${widget.projectId}/instruments/${widget.projectInstrumentId}/$fileName';

        await supabase.storage.from('machinery_evidence').uploadBinary(
          filePath,
          file.bytes!,
          fileOptions: FileOptions(contentType: 'image/${file.extension ?? 'jpeg'}'),
        );

        final publicUrl = supabase.storage.from('machinery_evidence').getPublicUrl(filePath);
        photoUrls.add(publicUrl);
      }

      final payload = {
        'project_instrument_id': widget.projectInstrumentId,
        'received_by': user?.id,
        'internal_code': _serialController.text.trim(),
        'condition_status': _selectedCondition,
        'observations': _notesController.text.trim(),
        'evidence_photos': photoUrls,
        'brand_model': widget.instrumentName,
        'ownership_type': _selectedOwnership,
        'reception_date': _receptionDate.toIso8601String().split('T')[0],
        'quantity_received': int.tryParse(_quantityController.text.trim()) ?? 1,
      };

      if (widget.inspectionId != null) {
        // Update existing record
        await supabase.from('instrument_inspections').update(payload).eq('id', widget.inspectionId!);
      } else {
        // Insert new record
        await supabase.from('instrument_inspections').insert(payload);

        // 3. Update Received Quantity on new insert
        final qty = int.tryParse(_quantityController.text.trim()) ?? 1;
        final currentInstrument = await supabase
            .from('project_instruments')
            .select('received_quantity')
            .eq('id', widget.projectInstrumentId)
            .single();
            
        final currentQty = (currentInstrument['received_quantity'] as num?)?.toDouble() ?? 0.0;
        
        await supabase.from('project_instruments').update({
          'received_quantity': currentQty + qty,
        }).eq('id', widget.projectInstrumentId);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving reception: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveDialogShell(
      title: widget.inspectionId != null ? 'Edit Instrument Reception' : 'Instrument Reception',
      subtitle: widget.instrumentName,
      icon: Icons.handyman_outlined,
      isEditMode: widget.inspectionId != null,
      maxWidth: 600,
      bodyPadding: const EdgeInsets.all(24),
      onClose: () => Navigator.of(context).pop(),
      body: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      widget.serviceName,
                      style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.purple),
                    ),
                  ),
                        // Reception Date
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
                              const Icon(Icons.calendar_today_outlined, color: Colors.purple, size: 18),
                              const SizedBox(width: 12),
                              Text(
                                '${_receptionDate.month.toString().padLeft(2,'0')}/${_receptionDate.day.toString().padLeft(2,'0')}/${_receptionDate.year}',
                                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.slate900),
                              ),
                              const Spacer(),
                              Text('Tap to change', style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate400)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                          child: _buildTextField(
                            label: 'Serial Number / Internal Code',
                            controller: _serialController,
                            icon: Icons.tag,
                            required: true,
                            validator: DialogValidators.required(),
                          ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                          child: _buildTextField(
                            label: 'Quantity',
                            controller: _quantityController,
                            icon: Icons.numbers,
                            keyboardType: TextInputType.number,
                            required: true,
                            validator: DialogValidators.requiredPositive(),
                          ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Condition', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(border: Border.all(color: AppTheme.slate200), borderRadius: BorderRadius.circular(10)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedCondition,
                                      isExpanded: true,
                                      items: const [
                                        DropdownMenuItem(value: 'excellent', child: Text('Excellent (Like New)')),
                                        DropdownMenuItem(value: 'operational', child: Text('Good (Operational)')),
                                        DropdownMenuItem(value: 'needs_maintenance', child: Text('Fair (Needs maintenance)')),
                                        DropdownMenuItem(value: 'damaged', child: Text('Poor (Damaged)')),
                                      ],
                                      onChanged: (val) { if (val != null) setState(() => _selectedCondition = val); },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ownership', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(border: Border.all(color: AppTheme.slate200), borderRadius: BorderRadius.circular(10)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedOwnership,
                                      isExpanded: true,
                                      items: const [
                                        DropdownMenuItem(value: 'owned', child: Text('Owned')),
                                        DropdownMenuItem(value: 'rented', child: Text('Rented')),
                                      ],
                                      onChanged: (val) { if (val != null) setState(() => _selectedOwnership = val); },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        label: 'Observations / Notes',
                        controller: _notesController,
                        icon: Icons.notes,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
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
                          child: Text('Please add at least one photo to continue', style: GoogleFonts.manrope(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600)),
                        ),
                      const SizedBox(height: 12),
                      
                      // Photos Grid
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ..._existingPhotos.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final url = entry.value;
                            return Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.slate200),
                                image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                              ),
                              child: Align(
                                alignment: Alignment.topRight,
                                child: GestureDetector(
                                  onTap: () => _removeExistingPhoto(idx),
                                  child: Container(
                                    margin: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            );
                          }),
                          ..._selectedFiles.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final file = entry.value;
                            return Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.slate200),
                                image: file.bytes != null 
                                  ? DecorationImage(image: MemoryImage(file.bytes!), fit: BoxFit.cover) 
                                  : null,
                              ),
                              child: Align(
                                alignment: Alignment.topRight,
                                child: GestureDetector(
                                  onTap: () => _removeFile(idx),
                                  child: Container(
                                    margin: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            );
                          }),
                          GestureDetector(
                            onTap: _pickFiles,
                            child: Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _showPhotoError && _selectedFiles.isEmpty ? Colors.orange : Colors.purple.withOpacity(0.3), 
                                  style: BorderStyle.solid,
                                  width: 2,
                                ),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, color: Colors.purple),
                                  SizedBox(height: 4),
                                  Text('Add Photo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
],
                  ),
                ),
              footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Spacer(),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate700),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _isSaving ? null : _saveReception,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: _isSaving ? AppTheme.slate400 : Colors.purple,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSaving)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    else
                      const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _isSaving ? 'Saving...' : (widget.inspectionId != null ? 'Update Record' : 'Confirm Reception'),
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (required)
          RequiredLabel(label: label)
        else
          Text(label, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.manrope(fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: maxLines == 1 ? Icon(icon, color: AppTheme.slate400, size: 20) : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.slate200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.slate200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.purple),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
