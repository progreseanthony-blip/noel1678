import 'dart:ui';
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

  bool get _isEditing => widget.serviceToEdit != null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final data = {
        'description': _descriptionController.text.trim(),
        'unit': _unitController.text.trim(),
      };

      if (_isEditing) {
        await ref.read(catalogsServiceProvider).updateService(widget.serviceToEdit!['id'], data);
      } else {
        await ref.read(catalogsServiceProvider).createService(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Service updated successfully' : 'Service added successfully', style: GoogleFonts.manrope(color: Colors.white)),
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
          constraints: const BoxConstraints(maxWidth: 500),
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
                          label: 'Service Description',
                          hint: 'e.g. Earth Moving, Site Preparation',
                          icon: Icons.design_services_outlined,
                          controller: _descriptionController,
                        ),
                        const SizedBox(height: 24),
                        _buildTextInput(
                          label: 'Measurement Unit',
                          hint: 'e.g. m3, und, hr, lot',
                          icon: Icons.straighten_outlined,
                          controller: _unitController,
                        ),
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
                  Text(_isEditing ? 'Edit Service' : 'Add Service', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
                  Text('Define the service and its unit of measurement', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500)),
                ],
              ),
            ],
          ),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppTheme.slate400)),
        ],
      ),
    );
  }

  Widget _buildTextInput({required String label, required String hint, required IconData icon, required TextEditingController controller}) {
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
          validator: (value) => value == null || value.trim().isEmpty ? 'Required field' : null,
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
            onPressed: _isSaving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_isEditing ? 'Save Changes' : 'Add Service', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
