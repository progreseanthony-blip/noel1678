import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class MachineryDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? machineryToEdit;
  const MachineryDialog({super.key, this.machineryToEdit});

  @override
  ConsumerState<MachineryDialog> createState() => _MachineryDialogState();
}

class _MachineryDialogState extends ConsumerState<MachineryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();
  final _tripsController = TextEditingController(text: '60');
  bool _isSaving = false;
  Uint8List? _pickedFileBytes;
  String? _pickedFileName;
  String? _currentImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.machineryToEdit != null) {
      _descriptionController.text = widget.machineryToEdit!['description'] ?? '';
      _currentImageUrl = widget.machineryToEdit!['photo_url'];
      _capacityController.text = widget.machineryToEdit!['capacity'] ?? '';
      _tripsController.text = widget.machineryToEdit!['default_trips_per_day']?.toString() ?? '60';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _capacityController.dispose();
    _tripsController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.machineryToEdit != null;

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.first.bytes != null) {
        setState(() {
          _pickedFileBytes = result.files.first.bytes;
          _pickedFileName = result.files.first.name;
        });
      }
    } catch (e) {
      debugPrint('***** File picker error: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_pickedFileBytes == null) return _currentImageUrl;

    setState(() => _isUploading = true);
    try {
      final cleanName = _pickedFileName!.replaceAll(RegExp(r'[^a-zA-Z0-9.\-_]'), '_');
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$cleanName';
      
      final storage = ref.read(supabaseClientProvider).storage;
      
      await storage.from('equipment').uploadBinary(
        fileName,
        _pickedFileBytes!,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      return storage.from('equipment').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('***** Upload error: $e');
      rethrow;
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final imageUrl = await _uploadImage();
      
      final data = {
        'description': _descriptionController.text.trim(),
        'photo_url': imageUrl,
        'capacity': _capacityController.text.trim(),
        'default_trips_per_day': double.tryParse(_tripsController.text) ?? 60,
      };
      
      if (_isEditing) {
        await ref.read(catalogsServiceProvider).updateMachinery(widget.machineryToEdit!['id'], data);
      } else {
        await ref.read(catalogsServiceProvider).createMachinery(data);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Equipment updated success' : 'Equipment added success', style: GoogleFonts.manrope(color: Colors.white)),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', style: GoogleFonts.manrope()), backgroundColor: AppTheme.errorRed));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 550),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTextInput(
                          label: 'Equipment Description',
                          hint: 'e.g. Excavator 320D, JD 950 L',
                          icon: Icons.precision_manufacturing_outlined,
                          controller: _descriptionController,
                        ),
                        const SizedBox(height: 24),
                        _buildTextInput(
                          label: 'Capacity',
                          hint: 'e.g. 1.2 m3, 30 tons',
                          icon: Icons.fitness_center_outlined,
                          controller: _capacityController,
                        ),
                        const SizedBox(height: 24),
                        _buildTextInput(
                          label: 'Estimated Trips per Day',
                          hint: 'e.g. 60, 80',
                          icon: Icons.repeat_on_outlined,
                          controller: _tripsController,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 24),
                        _buildImagePicker(),
                      ],
                    ),
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
                child: Center(child: Icon(_isEditing ? Icons.edit_outlined : Icons.add_circle_outline, color: AppTheme.primaryGreen, size: 20)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_isEditing ? 'Edit Equipment' : 'Add Equipment', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
                  Text('Registration of machinery and heavy equipment', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500)),
                ],
              ),
            ],
          ),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppTheme.slate400)),
        ],
      ),
    );
  }

  Widget _buildTextInput({required String label, required String hint, required IconData icon, required TextEditingController controller, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate900),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.manrope(color: AppTheme.slate400),
            prefixIcon: Icon(icon, color: AppTheme.slate400, size: 20),
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 2)),
          ),
          keyboardType: keyboardType,
          validator: (value) => value == null || value.trim().isEmpty ? 'Required field' : null,
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Equipment Image', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isUploading ? null : _pickImage,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.slate50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.slate200, style: BorderStyle.solid),
            ),
            child: _pickedFileBytes != null
                ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_pickedFileBytes!, fit: BoxFit.cover))
                : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12), 
                        child: Image.network(
                          _currentImageUrl!, 
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image_outlined, size: 40, color: AppTheme.slate400),
                              const SizedBox(height: 8),
                              Text('Image Failed to Load', style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 12)),
                            ],
                          ),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined, size: 40, color: AppTheme.slate400),
                          const SizedBox(height: 12),
                          Text('Upload Equipment Photo', style: GoogleFonts.manrope(color: AppTheme.slate500, fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('Supported: JPG, PNG', style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 11)),
                        ],
                      )),
          ),
        ),
        if (_pickedFileBytes != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() { _pickedFileBytes = null; _pickedFileName = null; }),
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: Text('Remove selection', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: const BoxDecoration(color: Color(0xFFF8FAFC), border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppTheme.slate700)),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: (_isSaving || _isUploading) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: (_isSaving || _isUploading)
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_isEditing ? 'Save Changes' : 'Add Equipment', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
