import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class LogisticsDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? itemToEdit;
  const LogisticsDialog({super.key, this.itemToEdit});

  @override
  ConsumerState<LogisticsDialog> createState() => _LogisticsDialogState();
}

class _LogisticsDialogState extends ConsumerState<LogisticsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _appController = TextEditingController(); 
  
  Set<String> _selectedServiceIds = {};
  List<String> _applications = [];
  List<Map<String, dynamic>> _allServices = [];
  List<Map<String, dynamic>> _globalApplications = [];
  bool _isLoadingServices = false;
  bool _isLoadingApps = false;
  bool _isSaving = false;
  Uint8List? _pickedFileBytes;
  String? _pickedFileName;
  String? _currentImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchServices();
    _fetchGlobalApps();
    if (widget.itemToEdit != null) {
      final m = widget.itemToEdit!;
      _descriptionController.text = m['description'] ?? '';
      _currentImageUrl = m['photo_url'];
      
      final ids = m['associated_service_ids'] as List?;
      if (ids != null) _selectedServiceIds = Set<String>.from(ids.map((id) => id.toString()));
      
      final apps = m['applications'] as List?;
      if (apps != null) _applications = List<String>.from(apps.map((a) => a.toString()));
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

  Future<void> _fetchGlobalApps() async {
    setState(() => _isLoadingApps = true);
    try {
      final apps = await ref.read(catalogsServiceProvider).getLogisticsApplications();
      setState(() => _globalApplications = apps);
    } catch (e) {
      debugPrint('***** Error fetching applications: $e');
    } finally {
      if (mounted) setState(() => _isLoadingApps = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _appController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.itemToEdit != null;

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
        'associated_service_ids': _selectedServiceIds.toList(),
        'applications': _applications,
      };
      
      if (_isEditing) {
        await ref.read(catalogsServiceProvider).updateLogisticsEquipment(widget.itemToEdit!['id'], data);
      } else {
        await ref.read(catalogsServiceProvider).createLogisticsEquipment(data);
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
          child: Material(
            type: MaterialType.transparency,
            child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTextInput(
                          label: 'Equipment/Tool Description',
                          hint: 'e.g. Laser Level, Total Station, Drone',
                          icon: Icons.inventory_2_outlined,
                          controller: _descriptionController,
                        ),
                        const SizedBox(height: 32),
                        _buildServiceSelector(),
                        const SizedBox(height: 32),
                        _buildApplicationTags(),
                        const SizedBox(height: 32),
                        _buildImagePicker(),
            ],
           ),
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
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
                  child: Center(child: Icon(_isEditing ? Icons.edit_outlined : Icons.add_circle_outline, color: AppTheme.primaryGreen, size: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isEditing ? 'Edit Logistics' : 'Add Logistics', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.slate900), overflow: TextOverflow.ellipsis, maxLines: 1),
                      Text('Registration of tools and logistics equipment', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500), overflow: TextOverflow.ellipsis, maxLines: 1),
                    ],
                  ),
                ),
              ],
            ),
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
  }) {
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
          keyboardType: keyboardType,
          validator: required ? (value) => value == null || value.trim().isEmpty ? 'Required field' : null : null,
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
            child: Material(
              type: MaterialType.transparency,
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
          ),
      ],
    );
  }

  Widget _buildApplicationTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Applications', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
            if (_applications.isNotEmpty)
              Text('${_applications.length} active', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: AppTheme.slate50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.slate200),
          ),
          child: Column(
            children: [
              Expanded(
                child: _isLoadingApps 
                  ? const Center(child: CircularProgressIndicator())
                  : _globalApplications.isEmpty && _applications.isEmpty
                    ? Center(child: Text('No applications yet', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate400)))
                    : ListView(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        children: [
                           ..._globalApplications.map((app) {
                              final id = app['id'].toString();
                              final name = app['name'] ?? '';
                              final isSelected = _applications.contains(name);
                              return CheckboxListTile(
                                value: isSelected,
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                secondary: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.slate400),
                                      onPressed: () => _editApp(app),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.errorRed),
                                      onPressed: () => _deleteApp(id, name),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                title: Text(name, style: GoogleFonts.manrope(fontSize: 13, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, color: isSelected ? AppTheme.slate900 : AppTheme.slate500)),
                                activeColor: AppTheme.primaryGreen,
                                checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) _applications.add(name);
                                    else _applications.remove(name);
                                  });
                                },
                              );
                           }),
                        ],
                      ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _appController,
                        style: GoogleFonts.manrope(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'New application...',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.slate200)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.slate200)),
                        ),
                        onSubmitted: (v) => _addNewApp(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(8)),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: _addNewApp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addNewApp() async {
    final val = _appController.text.trim();
    if (val.isEmpty) return;
    if (_applications.contains(val)) { _appController.clear(); return; }
    try {
      final existing = _globalApplications.any((a) => a['name'].toString().toLowerCase() == val.toLowerCase());
      if (!existing) {
        await ref.read(catalogsServiceProvider).createLogisticsApplication(val);
        await _fetchGlobalApps();
      }
      setState(() { _applications.add(val); _appController.clear(); });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding application: $e'), backgroundColor: AppTheme.errorRed));
    }
  }

  Future<void> _editApp(Map<String, dynamic> app) async {
    final curName = app['name'] ?? '';
    final curId = app['id'].toString();
    final ctrl = TextEditingController(text: curName);
    final newName = await showSafeDialog<String>(
      context: context,
      fullscreenOnMobile: true,
      builder: (context) => AlertDialog(
        title: Text('Edit Application', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        content: TextField(controller: ctrl, decoration: InputDecoration(hintText: 'Application name'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && newName != curName) {
      try {
        await ref.read(catalogsServiceProvider).updateLogisticsApplication(curId, newName);
        if (_applications.remove(curName)) _applications.add(newName);
        await _fetchGlobalApps();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed));
      }
    }
  }

  Future<void> _deleteApp(String id, String name) async {
    final confirm = await showSafeDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Application'),
        content: Text('Are you sure you want to delete "$name" globally?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed), child: const Text('Yes')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ref.read(catalogsServiceProvider).deleteLogisticsApplication(id);
        setState(() { _applications.remove(name); });
        await _fetchGlobalApps();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed));
      }
    }
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
                          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.inventory_2_outlined, color: AppTheme.slate400, size: 40)),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined, size: 40, color: AppTheme.slate400),
                          const SizedBox(height: 12),
                          Text('Upload Equipment Photo', style: GoogleFonts.manrope(color: AppTheme.slate500, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      )),
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
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppTheme.slate700))),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: (_isSaving || _isUploading) ? null : _submit,
            child: (_isSaving || _isUploading)
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_isEditing ? 'Save Changes' : 'Add Logistics', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
