import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:google_fonts/google_fonts.dart';

class MaterialDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? materialToEdit;
  const MaterialDialog({super.key, this.materialToEdit});

  @override
  ConsumerState<MaterialDialog> createState() => _MaterialDialogState();
}

class _MaterialDialogState extends ConsumerState<MaterialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _unitController = TextEditingController();
  Set<String> _selectedServiceIds = {};
  List<Map<String, dynamic>> _allServices = [];
  bool _isLoadingServices = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchServices();
    if (widget.materialToEdit != null) {
      final m = widget.materialToEdit!;
      _descriptionController.text = m['description'] ?? '';
      _unitController.text = m['unit'] ?? '';
      final ids = m['associated_service_ids'] as List?;
      if (ids != null) _selectedServiceIds = Set<String>.from(ids.map((id) => id.toString()));
    }
  }

  Future<void> _fetchServices() async {
    setState(() => _isLoadingServices = true);
    try {
      final services = await ref.read(catalogsServiceProvider).getServices();
      setState(() => _allServices = services);
    } catch (e) {
      debugPrint('***** Error fetching services: $e');
    } finally {
      if (mounted) setState(() => _isLoadingServices = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.materialToEdit != null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final data = {
        'description': _descriptionController.text.trim(),
        'unit': _unitController.text.trim(),
        'associated_service_ids': _selectedServiceIds.toList(),
      };

      if (_isEditing) {
        await ref.read(catalogsServiceProvider).updateMaterial(widget.materialToEdit!['id'], data);
      } else {
        await ref.read(catalogsServiceProvider).createMaterial(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Material updated successfully' : 'Material added successfully', style: GoogleFonts.manrope(color: Colors.white)),
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
                          label: 'Material Description',
                          hint: 'e.g. Concrete, Gravel, Rebar',
                          icon: Icons.inventory_2_outlined,
                          controller: _descriptionController,
                        ),
                        const SizedBox(height: 24),
                        _buildTextInput(
                          label: 'Unit of Measure',
                          hint: 'e.g. CY, Tons, Lbs',
                          icon: Icons.straighten_outlined,
                          controller: _unitController,
                        ),
                        const SizedBox(height: 24),
                        _buildServiceSelector(),
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
                  Text(_isEditing ? 'Edit Material' : 'Add Material', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
                  Text('Define the item and associate it with services', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500)),
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
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2)),
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'Required field' : null,
        ),
      ],
    );
  }

  Widget _buildServiceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Associated Services', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
            if (_selectedServiceIds.isNotEmpty)
               Text('${_selectedServiceIds.length} selected', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen)),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingServices)
          const Center(child: CircularProgressIndicator())
        else
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppTheme.slate50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _allServices.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.slate200),
              itemBuilder: (context, index) {
                final svc = _allServices[index];
                final id = svc['id'].toString();
                final isSelected = _selectedServiceIds.contains(id);
                return CheckboxListTile(
                  value: isSelected,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(svc['description'] ?? '', style: GoogleFonts.manrope(fontSize: 13, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, color: isSelected ? AppTheme.slate900 : AppTheme.slate500)),
                  activeColor: AppTheme.primaryGreen,
                  checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) _selectedServiceIds.add(id);
                      else _selectedServiceIds.remove(id);
                    });
                  },
                );
              },
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
                : Text(_isEditing ? 'Save Changes' : 'Add Material', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
