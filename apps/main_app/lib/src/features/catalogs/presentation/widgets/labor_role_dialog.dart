import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:google_fonts/google_fonts.dart';

class LaborRoleDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? roleToEdit;
  const LaborRoleDialog({super.key, this.roleToEdit});

  @override
  ConsumerState<LaborRoleDialog> createState() => _LaborRoleDialogState();
}

class _LaborRoleDialogState extends ConsumerState<LaborRoleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _rateController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.roleToEdit != null) {
      _descriptionController.text = widget.roleToEdit!['description'] ?? '';
      _rateController.text = widget.roleToEdit!['hourly_rate']?.toString() ?? '0';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final data = {
        'description': _descriptionController.text.trim(),
        'hourly_rate': double.tryParse(_rateController.text) ?? 0,
      };

      if (widget.roleToEdit != null) {
        await ref.read(catalogsServiceProvider).updateLaborRole(widget.roleToEdit!['id'], data);
      } else {
        await ref.read(catalogsServiceProvider).createLaborRole(data);
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
      title: Text(widget.roleToEdit != null ? 'Edit Labor Role' : 'Add Labor Role', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Role Description', hintText: 'e.g. Foreman'),
              validator: (v) => v == null || v.isEmpty ? 'Description is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _rateController,
              decoration: const InputDecoration(labelText: 'Hourly Rate', prefixText: '\$'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => v == null || v.isEmpty ? 'Rate is required' : null,
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
