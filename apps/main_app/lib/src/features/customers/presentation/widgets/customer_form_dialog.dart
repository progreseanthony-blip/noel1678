import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class CustomerFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? customerToEdit;

  const CustomerFormDialog({super.key, this.customerToEdit});

  @override
  ConsumerState<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends ConsumerState<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _einController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  bool _isSaving = false;

  final _einFormatter = MaskTextInputFormatter(
    mask: '##-#######',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final _phoneFormatter = MaskTextInputFormatter(
    mask: '(###) ###-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customerToEdit?['name'] ?? '');
    _einController = TextEditingController(text: widget.customerToEdit?['ein'] ?? '');
    _addressController = TextEditingController(text: widget.customerToEdit?['address'] ?? '');
    _phoneController = TextEditingController(text: widget.customerToEdit?['phone'] ?? '');
    _emailController = TextEditingController(text: widget.customerToEdit?['email'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _einController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'ein': _einController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
      };

      if (widget.customerToEdit != null) {
        await ref.read(customersServiceProvider).updateCustomer(widget.customerToEdit!['id'], data);
      } else {
        await ref.read(customersServiceProvider).createCustomer(data);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving customer: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.customerToEdit != null ? 'Edit Customer' : 'New Customer',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.slate900,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppTheme.slate400),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildField('Full Name', _nameController, Icons.person_outline, isRequired: true),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('EIN', _einController, Icons.badge_outlined, formatters: [_einFormatter], hint: '00-0000000')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('Phone', _phoneController, Icons.phone_outlined, formatters: [_phoneFormatter], hint: '(000) 000-0000')),
                ],
              ),
              const SizedBox(height: 16),
              _buildField('Email Address', _emailController, Icons.email_outlined, isEmail: true),
              const SizedBox(height: 16),
              _buildField('Physical Address', _addressController, Icons.location_on_outlined, maxLines: 2),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppTheme.slate500)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A)))
                        : Text('Save Customer', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, 
      {bool isRequired = false, bool isEmail = false, List<MaskTextInputFormatter>? formatters, int maxLines = 1, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.slate600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          inputFormatters: formatters,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: AppTheme.slate400),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.slate200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.slate200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return 'This field is required';
            }
            if (isEmail && value != null && value.isNotEmpty) {
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Enter a valid email';
              }
            }
            return null;
          },
        ),
      ],
    );
  }
}
