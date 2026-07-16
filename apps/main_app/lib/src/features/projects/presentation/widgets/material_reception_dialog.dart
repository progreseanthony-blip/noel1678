import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class MaterialReceptionDialog extends StatefulWidget {
  final String projectId;
  final String projectMaterialId;
  final String materialName;
  final String serviceName;
  final String unitName;
  final num expectedQuantity;
  final num currentReceived;
  final String? receptionId; // Optional for Edit mode

  const MaterialReceptionDialog({
    super.key,
    required this.projectId,
    required this.projectMaterialId,
    required this.materialName,
    required this.serviceName,
    required this.unitName,
    required this.expectedQuantity,
    required this.currentReceived,
    this.receptionId,
  });

  @override
  State<MaterialReceptionDialog> createState() => _MaterialReceptionDialogState();
}

class _MaterialReceptionDialogState extends State<MaterialReceptionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceController = TextEditingController();
  final _providerController = TextEditingController();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCondition = 'good';
  final List<PlatformFile> _selectedFiles = [];
  final List<String> _existingPhotos = [];
  DateTime _receptionDate = DateTime.now();
  bool _isLoading = false;
  bool _isSaving = false;
  bool _showPhotoError = false;

  @override
  void initState() {
    super.initState();
    // Default quantity to remaining expected quantity if new
    if (widget.receptionId == null) {
      final remaining = widget.expectedQuantity - widget.currentReceived;
      if (remaining > 0) {
        _quantityController.text = remaining.toString();
      }
    } else {
      _loadExistingData();
    }
  }

  Future<void> _loadExistingData() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('material_receptions')
          .select()
          .eq('id', widget.receptionId!)
          .single();
      
      if (mounted) {
        setState(() {
          _invoiceController.text = data['invoice_number'] ?? '';
          _providerController.text = data['provider_name'] ?? '';
          _quantityController.text = (data['quantity_received']?.toString()) ?? '';
          _notesController.text = data['observations'] ?? '';
          _selectedCondition = data['condition_status'] ?? 'good';
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
      debugPrint('Error loading reception: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _providerController.dispose();
    _quantityController.dispose();
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

    final qty = double.tryParse(_quantityController.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid quantity.'),
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
        final filePath = '${widget.projectId}/${widget.projectMaterialId}/$fileName';

        await supabase.storage.from('machinery_evidence').uploadBinary(
          filePath,
          file.bytes!,
          fileOptions: FileOptions(contentType: 'image/${file.extension ?? 'jpeg'}'),
        );

        final publicUrl = supabase.storage.from('machinery_evidence').getPublicUrl(filePath);
        photoUrls.add(publicUrl);
      }

      final payload = {
        'project_material_id': widget.projectMaterialId,
        'received_by': user?.id,
        'invoice_number': _invoiceController.text.trim(),
        'provider_name': _providerController.text.trim(),
        'quantity_received': qty,
        'condition_status': _selectedCondition,
        'observations': _notesController.text.trim(),
        'evidence_photos': photoUrls,
        'reception_date': _receptionDate.toIso8601String().split('T')[0],
      };

      if (widget.receptionId != null) {
        // Fetch old qty to adjust total
        final oldData = await supabase.from('material_receptions').select('quantity_received').eq('id', widget.receptionId!).single();
        final oldQty = (oldData['quantity_received'] as num?)?.toDouble() ?? 0.0;
        
        await supabase.from('material_receptions').update(payload).eq('id', widget.receptionId!);
        
        // Adjust total received_quantity in project_materials
        final diff = qty - oldQty;
        if (diff != 0) {
           final currentMat = await supabase.from('project_materials').select('received_quantity').eq('id', widget.projectMaterialId).single();
           final currentTotal = (currentMat['received_quantity'] as num?)?.toDouble() ?? 0.0;
           await supabase.from('project_materials').update({'received_quantity': currentTotal + diff}).eq('id', widget.projectMaterialId);
        }

      } else {
        await supabase.from('material_receptions').insert(payload);

        // Update Total Received Quantity
        final currentMat = await supabase.from('project_materials').select('received_quantity').eq('id', widget.projectMaterialId).single();
        final currentQty = (currentMat['received_quantity'] as num?)?.toDouble() ?? 0.0;
        
        await supabase.from('project_materials').update({
          'received_quantity': currentQty + qty,
        }).eq('id', widget.projectMaterialId);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving reception: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 600,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Center(
                            child: Icon(Icons.inventory_2_outlined, color: AppTheme.primaryGreen, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.receptionId != null ? 'Edit Material Reception' : 'Material Reception',
                              style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                            ),
                            const SizedBox(height: 4),
                            Text(widget.materialName, style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate500, height: 1.0)),
                            const SizedBox(height: 4),
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
                      ],
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.close, color: AppTheme.slate400, size: 24),
                      ),
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
                              const Icon(Icons.calendar_today_outlined, color: AppTheme.primaryGreen, size: 18),
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
                            child: _buildTextField(
                              label: 'Quantity Received (${widget.unitName})',
                              controller: _quantityController,
                              icon: Icons.numbers,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              label: 'Invoice / Ticket #',
                              controller: _invoiceController,
                              icon: Icons.receipt_long,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Provider Name',
                              controller: _providerController,
                              icon: Icons.local_shipping,
                            ),
                          ),
                          const SizedBox(width: 16),
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
                                        DropdownMenuItem(value: 'good', child: Text('Good')),
                                        DropdownMenuItem(value: 'damaged', child: Text('Damaged')),
                                        DropdownMenuItem(value: 'incomplete', child: Text('Incomplete')),
                                      ],
                                      onChanged: (val) { if (val != null) setState(() => _selectedCondition = val); },
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
                        required: false,
                      ),
                      const SizedBox(height: 24),
                     
                       // Evidence Photos
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
                                   color: _showPhotoError && _selectedFiles.isEmpty && _existingPhotos.isEmpty
                                       ? Colors.orange
                                       : AppTheme.primaryGreen.withOpacity(0.3),
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
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          color: _isSaving ? AppTheme.slate400 : AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withOpacity(0.2),
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
                              _isSaving ? 'Saving...' : (widget.receptionId != null ? 'Update Record' : 'Confirm Reception'),
                              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = true,
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
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate900),
          decoration: InputDecoration(
            hintText: maxLines > 1 ? '' : null,
            prefixIcon: maxLines == 1 ? Icon(icon, color: AppTheme.slate400, size: 20) : null,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 16 : 0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.slate200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.slate200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryGreen)),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: required ? DialogValidators.required() : null,
        ),
      ],
    );
  }
}
