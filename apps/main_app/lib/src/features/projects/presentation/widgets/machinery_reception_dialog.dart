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
  final _hourMeterController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCondition = 'operational';
  String _selectedOwnership = 'owned';
  final List<PlatformFile> _selectedFiles = [];
  final List<String> _existingPhotos = []; // Keep track of old photos in edit mode
  bool _isLoading = false;
  bool _isSaving = false;

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
          _hourMeterController.text = (data['hour_meter_start']?.toString()) ?? '';
          _notesController.text = data['observations'] ?? '';
          _selectedCondition = data['condition_status'] ?? 'operational';
          _selectedOwnership = data['ownership_type'] ?? 'owned';
          
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
    _hourMeterController.dispose();
    _notesController.dispose();
    super.dispose();
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
      final inspectorName = user?.userMetadata?['name'] ?? 'Unknown Inspector';

      // 1. Upload Photos
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
        'hour_meter_start': double.tryParse(_hourMeterController.text.trim()) ?? 0,
        'condition_status': _selectedCondition,
        'observations': _notesController.text.trim(),
        'evidence_photos': photoUrls,
        'brand_model': widget.machineryName,
        'ownership_type': _selectedOwnership,
      };

      if (widget.inspectionId != null) {
        // Update existing record
        await supabase.from('machinery_inspections').update(payload).eq('id', widget.inspectionId!);
      } else {
        // Insert new record
        await supabase.from('machinery_inspections').insert(payload);

        // 3. Update Received Quantity only on new insert
        final currentMachinery = await supabase
            .from('project_machinery')
            .select('received_quantity')
            .eq('id', widget.projectMachineryId)
            .single();
            
        final currentQty = (currentMachinery['received_quantity'] as num?)?.toInt() ?? 0;
        
        await supabase.from('project_machinery').update({
          'received_quantity': currentQty + 1,
        }).eq('id', widget.projectMachineryId);
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 600,
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
                        Text(widget.inspectionId != null ? 'Edit Reception' : 'Machine Reception', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
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
                              label: 'Hour Meter',
                              controller: _hourMeterController,
                              icon: Icons.timer_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
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
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      Text('Evidence Photos (Required)', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                      const SizedBox(height: 8),
                      
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
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.slate200, style: BorderStyle.solid),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, color: AppTheme.slate400),
                                  SizedBox(height: 4),
                                  Text('Add', style: TextStyle(fontSize: 11, color: AppTheme.slate500)),
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
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
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
              borderSide: const BorderSide(color: AppTheme.primaryGreen),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
