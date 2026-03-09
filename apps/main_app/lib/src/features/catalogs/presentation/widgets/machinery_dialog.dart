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
  final _photoUrlController = TextEditingController();
  final _capacityController = TextEditingController();
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
    }
  }

  Future<void> _pickImage() async {
    debugPrint('***** Picking image...');
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null) {
        debugPrint('***** File picked: ${result.files.first.name}');
        if (result.files.first.bytes != null) {
          setState(() {
            _pickedFileBytes = result.files.first.bytes;
            _pickedFileName = result.files.first.name;
          });
        }
      }
    } catch (e) {
      debugPrint('***** File picker error: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_pickedFileBytes == null) {
      debugPrint('***** No new image picked, returning current: $_currentImageUrl');
      return _currentImageUrl;
    }

    setState(() => _isUploading = true);
    try {
      // Sanitize filename: replace spaces with underscores and remove non-alphanumeric chars (except dots)
      final cleanName = _pickedFileName!.replaceAll(RegExp(r'[^a-zA-Z0-9.\-_]'), '_');
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$cleanName';
      
      debugPrint('***** Uploading image: $fileName (${_pickedFileBytes!.length} bytes)');
      final storage = ref.read(supabaseClientProvider).storage;
      
      await storage.from('equipment').uploadBinary(
        fileName,
        _pickedFileBytes!,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final publicUrl = storage.from('equipment').getPublicUrl(fileName);
      debugPrint('***** Upload success! Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('***** Upload error: $e');
      rethrow; // Let _save handle and show it
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _photoUrlController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final imageUrl = await _uploadImage();
      
      final data = {
        'description': _descriptionController.text.trim(),
        'photo_url': imageUrl,
        'capacity': _capacityController.text.trim(),
      };
      
      debugPrint('***** Invoking catalogsServiceProvider with data: $data');
      if (widget.machineryToEdit != null) {
        await ref.read(catalogsServiceProvider).updateMachinery(widget.machineryToEdit!['id'], data);
      } else {
        await ref.read(catalogsServiceProvider).createMachinery(data);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully!'), backgroundColor: AppTheme.primaryGreen));
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('***** Save error details: $e');
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.machineryToEdit != null ? 'Edit Equipment' : 'Add Equipment', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Equipment Description', hintText: 'e.g. Excavator 320D'),
                validator: (v) => v == null || v.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(labelText: 'Capacity', hintText: 'e.g. 1.2 m3'),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Equipment Image', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.slate700)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _isUploading ? null : _pickImage,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.slate50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.slate200),
                      ),
                      child: _pickedFileBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(_pickedFileBytes!, fit: BoxFit.cover),
                            )
                          : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(_currentImageUrl!, fit: BoxFit.cover),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_a_photo_outlined, size: 32, color: AppTheme.slate400),
                                    const SizedBox(height: 8),
                                    Text('Select from device', style: GoogleFonts.manrope(color: AppTheme.slate500, fontSize: 13)),
                                  ],
                                )),
                    ),
                  ),
                  if (_pickedFileBytes != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton.icon(
                        onPressed: () => setState(() {
                          _pickedFileBytes = null;
                          _pickedFileName = null;
                        }),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Remove selection'),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        ElevatedButton(
          onPressed: (_isSaving || _isUploading) ? null : _save,
          child: (_isSaving || _isUploading)
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('SAVE'),
        ),
      ],
    );
  }
}
