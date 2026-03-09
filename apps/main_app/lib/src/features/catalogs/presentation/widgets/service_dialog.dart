import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? serviceToEdit;
  const ServiceDialog({super.key, this.serviceToEdit});

  @override
  ConsumerState<ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends ConsumerState<ServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _unitController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.serviceToEdit != null) {
      _descriptionController.text = widget.serviceToEdit!['description'] ?? '';
      _unitController.text = widget.serviceToEdit!['unit'] ?? '';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final data = {
        'description': _descriptionController.text.trim(),
        'unit': _unitController.text.trim(),
      };

      if (widget.serviceToEdit != null) {
        await ref.read(catalogsServiceProvider).updateService(widget.serviceToEdit!['id'], data);
      } else {
        await ref.read(catalogsServiceProvider).createService(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.serviceToEdit != null ? 'Edit Service' : 'Add Service', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Service Description', hintText: 'e.g. Earth Moving'),
              validator: (v) => v == null || v.isEmpty ? 'Description is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _unitController,
              decoration: const InputDecoration(labelText: 'Measurement Unit', hintText: 'e.g. m3, und, hr'),
              validator: (v) => v == null || v.isEmpty ? 'Unit is required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('SAVE'),
        ),
      ],
    );
  }
}
