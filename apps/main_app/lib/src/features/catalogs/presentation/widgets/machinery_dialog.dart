import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
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
  final _capacityController = TextEditingController(); // General capacity text
  final _capacityYardsController = TextEditingController(); // Numeric for calculation
  final _tripsController = TextEditingController(text: '60');
  final _fuelController = TextEditingController();
  String _machineryType = 'hauling'; // hauling, production, support
  Set<String> _selectedServiceIds = {};
  String? _selectedOperatorRoleId;
  List<Map<String, dynamic>> _allServices = [];
  List<Map<String, dynamic>> _laborRoles = [];
  bool _isLoadingServices = false;
  bool _isLoadingRoles = false;
  bool _isSaving = false;
  Uint8List? _pickedFileBytes;
  String? _pickedFileName;
  String? _currentImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchServices();
    _fetchLaborRoles();
    if (widget.machineryToEdit != null) {
      final m = widget.machineryToEdit!;
      _descriptionController.text = m['description'] ?? '';
      _currentImageUrl = m['photo_url'];
      _capacityController.text = m['capacity'] ?? '';
      _capacityYardsController.text = m['capacity_yards']?.toString() ?? '';
      _tripsController.text = m['trips_per_day']?.toString() ?? '60';
      _fuelController.text = m['fuel_gallons']?.toString() ?? '';
      
      _machineryType = m['machinery_type'] ?? 'hauling';
      
      final ids = m['associated_service_ids'] as List?;
      if (ids != null) _selectedServiceIds = Set<String>.from(ids.map((id) => id.toString()));
      
      _selectedOperatorRoleId = m['operator_role_id']?.toString();
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

  Future<void> _fetchLaborRoles() async {
    setState(() => _isLoadingRoles = true);
    try {
      final roles = await ref.read(catalogsServiceProvider).getLaborRoles();
      setState(() => _laborRoles = roles);
    } catch (e) {
      debugPrint('***** Error fetching labor roles: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRoles = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _capacityController.dispose();
    _capacityYardsController.dispose();
    _tripsController.dispose();
    _fuelController.dispose();
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
      
      final capYards = double.tryParse(_capacityYardsController.text) ?? 0;
      final trips = double.tryParse(_tripsController.text) ?? 0;
      
      final data = {
        'description': _descriptionController.text.trim(),
        'photo_url': imageUrl,
        'capacity': _capacityController.text.trim(),
        'capacity_yards': capYards,
        'trips_per_day': trips,
        'fuel_gallons': double.tryParse(_fuelController.text) ?? 0,
        'yards_per_day': capYards * trips,
        'machinery_type': _machineryType,
        'associated_service_ids': _selectedServiceIds.toList(),
        'operator_role_id': _selectedOperatorRoleId,
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
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: ScrollIndicator(
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
                        _buildTypeSelector(),
                        const SizedBox(height: 24),
                        _buildTextInput(
                          label: 'General Capacity (Text)',
                          hint: 'e.g. 30 tons, Small Size',
                          icon: Icons.fitness_center_outlined,
                          controller: _capacityController,
                          required: false,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextInput(
                                label: 'Capacity (Yards)',
                                hint: 'e.g. 1.5',
                                icon: Icons.straighten_outlined,
                                controller: _capacityYardsController,
                                keyboardType: TextInputType.number,
                                onChanged: (v) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextInput(
                                label: 'Trips per Day',
                                hint: 'e.g. 60',
                                icon: Icons.repeat_on_outlined,
                                controller: _tripsController,
                                keyboardType: TextInputType.number,
                                onChanged: (v) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.1))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Yards per Day (Production):', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate700)),
                              Text(
                                ((double.tryParse(_capacityYardsController.text) ?? 0) * (double.tryParse(_tripsController.text) ?? 0)).toStringAsFixed(1),
                                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildTextInput(
                          label: 'Fuel Gallons',
                          hint: 'e.g. 25.5',
                          icon: Icons.local_gas_station_outlined,
                          controller: _fuelController,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 32),
                        _buildServiceSelector(),
                        const SizedBox(height: 32),
                        _buildOperatorRoleSelector(),
                        const SizedBox(height: 32),
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

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Equipment Classification', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
        const SizedBox(height: 12),
        Row(
          children: [
            _typeCard('Hauling', Icons.local_shipping_outlined, 'hauling'),
            const SizedBox(width: 12),
            _typeCard('Production', Icons.precision_manufacturing_outlined, 'production'),
            const SizedBox(width: 12),
            _typeCard('Support', Icons.commute_outlined, 'support'),
          ],
        ),
      ],
    );
  }

  Widget _typeCard(String label, IconData icon, String type) {
    bool isSelected = _machineryType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _machineryType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppTheme.primaryGreen : AppTheme.slate200, width: isSelected ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppTheme.primaryGreen : AppTheme.slate400, size: 24),
              const SizedBox(height: 8),
              Text(label, style: GoogleFonts.manrope(fontSize: 12, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? AppTheme.primaryGreen : AppTheme.slate600)),
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

  Widget _buildTextInput({
    required String label, 
    required String hint, 
    required IconData icon, 
    required TextEditingController controller, 
    TextInputType keyboardType = TextInputType.text,
    bool required = true,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (required)
          RequiredLabel(label: label)
        else
          Text(label, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
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
          keyboardType: keyboardType,
          validator: required ? DialogValidators.required() : null,
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
              padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildOperatorRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const RequiredLabel(label: 'Default Operator Role'),
            if (_isLoadingRoles)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedOperatorRoleId,
          isExpanded: true,
          validator: DialogValidators.requiredDropdown<String>(),
          style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate900),
          decoration: InputDecoration(
            hintText: 'Select an operator role...',
            hintStyle: GoogleFonts.manrope(color: AppTheme.slate400),
            prefixIcon: const Icon(Icons.person_outline, color: AppTheme.slate400, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2)),
          ),
          items: _laborRoles.map((role) {
            return DropdownMenuItem<String>(
              value: role['id'].toString(),
              child: Text(role['description'] ?? 'No description'),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedOperatorRoleId = val),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This role will be automatically suggested as the operator for this machine during estimations.',
                  style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate600, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
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
                ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_pickedFileBytes!, fit: BoxFit.contain))
                : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12), 
                        child: Image.network(
                          _currentImageUrl!, 
                          fit: BoxFit.contain,
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
