import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InstrumentReturnDialog extends StatefulWidget {
  final String projectId;
  final String inspectionId;
  final String projectInstrumentId;
  final String instrumentName;
  final String serviceName;
  final Map<String, dynamic>? existingReturn;

  const InstrumentReturnDialog({
    super.key,
    required this.projectId,
    required this.inspectionId,
    required this.projectInstrumentId,
    required this.instrumentName,
    required this.serviceName,
    this.existingReturn,
  });

  bool get isEditing => existingReturn != null;

  @override
  State<InstrumentReturnDialog> createState() => _InstrumentReturnDialogState();
}

class _InstrumentReturnDialogState extends State<InstrumentReturnDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final Map<String, TextEditingController> _damageNoteControllers = {};

  String _selectedCondition = 'operational';
  DateTime _returnDate = DateTime.now();
  final List<PlatformFile> _selectedFiles = [];
  List<String> _existingPhotoUrls = [];
  bool _isSaving = false;
  bool _showPhotoError = false;

  final Map<String, bool> _damages = {};
  final Map<String, String> _damageSeverities = {};
  String _cleanliness = '';

  static const _damageTypes = [
    'Cracks / breaks',
    'Corrosion / rust',
    'Missing parts',
    'Worn components',
    'Calibration issues',
    'Cosmetic damage',
    'Electrical faults',
    'Other',
  ];

  static const _cleanlinessLevels = ['clean', 'fair', 'dirty'];
  static const _severityOptions = ['minor', 'moderate', 'severe'];

  @override
  void initState() {
    super.initState();
    final ex = widget.existingReturn;
    if (ex != null) {
      _selectedCondition = ex['return_condition_status'] as String? ?? 'operational';
      _notesController.text = ex['return_observations'] as String? ?? '';
      _cleanliness = ex['return_cleanliness'] as String? ?? '';
      if (ex['returned_at'] != null) {
        _returnDate = DateTime.parse(ex['returned_at']).toLocal();
      }
      final existingPhotos = ex['return_evidence_photos'] as List? ?? [];
      _existingPhotoUrls = existingPhotos.map((p) => p.toString()).toList();
      final existingDamages = ex['return_damages'] as List? ?? [];
      for (final d in existingDamages) {
        if (d is Map) {
          final type = d['type'] as String?;
          if (type != null && _damageTypes.contains(type)) {
            _damages[type] = true;
            _damageSeverities[type] = d['severity'] as String? ?? 'minor';
            final notes = d['notes'] as String? ?? '';
            if (notes.isNotEmpty && _damageNoteControllers[type] != null) {
              _damageNoteControllers[type]!.text = notes;
            }
          }
        }
      }
    }
    for (final dt in _damageTypes) {
      _damageNoteControllers.putIfAbsent(dt, () => TextEditingController());
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final c in _damageNoteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _returnDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _returnDate = picked);
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

  void _removeFile(int index) => setState(() => _selectedFiles.removeAt(index));

  Future<void> _saveReturn() async {
    if (!_formKey.currentState!.validate()) return;
    final hasExistingPhotos = _existingPhotoUrls.isNotEmpty;
    if (!widget.isEditing && _selectedFiles.isEmpty) {
      setState(() => _showPhotoError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one return evidence photo is required.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (widget.isEditing && _selectedFiles.isEmpty && !hasExistingPhotos) {
      setState(() => _showPhotoError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one return evidence photo is required.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final supabase = Supabase.instance.client;

    try {
      final List<Map<String, dynamic>> damagesList = [];
      for (final dt in _damageTypes) {
        if (_damages[dt] == true) {
          damagesList.add({
            'type': dt,
            'severity': _damageSeverities[dt] ?? 'minor',
            'notes': _damageNoteControllers[dt]?.text.trim() ?? '',
          });
        }
      }

      final user = supabase.auth.currentUser;
      final List<String> photoUrls = [..._existingPhotoUrls];
      for (final file in _selectedFiles) {
        if (file.bytes == null) continue;
        final fileName = 'return_${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(' ', '_')}';
        final filePath = '${widget.projectId}/instruments/${widget.projectInstrumentId}/$fileName';
        await supabase.storage.from('machinery_evidence').uploadBinary(
          filePath,
          file.bytes!,
          fileOptions: FileOptions(contentType: 'image/${file.extension ?? 'jpeg'}'),
        );
        photoUrls.add(supabase.storage.from('machinery_evidence').getPublicUrl(filePath));
      }

      final updateBody = <String, dynamic>{
        'return_condition_status': _selectedCondition,
        'return_observations': _notesController.text.trim(),
        'return_evidence_photos': photoUrls,
        'return_damages': damagesList,
        'return_cleanliness': _cleanliness,
        'returned_by': user?.id,
      };
      if (!widget.isEditing) {
        updateBody['returned_at'] = DateTime.now().toUtc().toIso8601String();
      }

      await supabase.from('instrument_inspections').update(updateBody).eq('id', widget.inspectionId);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving return: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${_returnDate.month.toString().padLeft(2, '0')}/${_returnDate.day.toString().padLeft(2, '0')}/${_returnDate.year}';

    return ResponsiveDialogShell(
      title: widget.isEditing ? 'Edit Return' : 'Return Instrument',
      subtitle: widget.instrumentName,
      icon: Icons.outbound_outlined,
      isEditMode: widget.isEditing,
      maxWidth: 620,
      bodyPadding: const EdgeInsets.all(24),
      onClose: () => Navigator.of(context).pop(),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(
                widget.serviceName,
                style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.purple),
              ),
            ),
                        // ── Return Date ──
                        Text('Return Date', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
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
                                const Icon(Icons.calendar_today_outlined, color: Colors.purple, size: 18),
                                const SizedBox(width: 12),
                                Text(formattedDate, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.slate900)),
                                const Spacer(),
                                Text('Tap to change', style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate400)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Condition at Return ──
                        _buildDropdown(
                          label: 'Condition at Return',
                          value: _selectedCondition,
                          items: const [
                            DropdownMenuItem(value: 'excellent', child: Text('Excellent (Like New)')),
                            DropdownMenuItem(value: 'operational', child: Text('Good (Operational)')),
                            DropdownMenuItem(value: 'needs_maintenance', child: Text('Fair (Needs maintenance)')),
                            DropdownMenuItem(value: 'damaged', child: Text('Poor (Damaged)')),
                          ],
                          onChanged: (v) { if (v != null) setState(() => _selectedCondition = v); },
                        ),
                        const SizedBox(height: 24),

                        // ── Damage Checklist ──
                        Text('Damage Assessment', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.slate200),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ..._damageTypes.map((dt) => _buildDamageItem(dt)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Cleanliness ──
                        Text('Cleanliness', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.slate200),
                          ),
                          child: Row(
                            children: _cleanlinessLevels.map((level) {
                              final selected = _cleanliness == level;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _cleanliness = level),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: selected ? Colors.purple : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      level[0].toUpperCase() + level.substring(1),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: selected ? Colors.white : AppTheme.slate500,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Observations ──
                        _buildTextField(
                          label: 'Observations / Notes',
                          controller: _notesController,
                          icon: Icons.notes,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),

                        // ── Evidence Photos ──
                        Row(
                          children: [
                            Text('Return Evidence Photos', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text(widget.isEditing ? 'OPTIONAL' : 'REQUIRED', style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.orange)),
                            ),
                          ],
                        ),
                        if (_showPhotoError && _selectedFiles.isEmpty && _existingPhotoUrls.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('Please add at least one return photo to continue',
                                style: GoogleFonts.manrope(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600)),
                          ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ..._existingPhotoUrls.asMap().entries.map((entry) => _buildPhotoThumb(
                                  url: entry.value,
                                  label: 'Photo ${entry.key + 1}',
                                  onRemove: widget.isEditing ? () => setState(() => _existingPhotoUrls.removeAt(entry.key)) : null,
                                )),
                            ..._selectedFiles.asMap().entries.map((entry) => _buildPhotoThumb(
                                  bytes: entry.value.bytes,
                                  label: 'Photo ${_existingPhotoUrls.length + entry.key + 1}',
                                  onRemove: () => _removeFile(entry.key),
                                )),
                            GestureDetector(
                              onTap: _pickFiles,
                              child: Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _showPhotoError && _selectedFiles.isEmpty && _existingPhotoUrls.isEmpty ? Colors.orange : Colors.purple.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, color: Colors.purple),
                                    SizedBox(height: 4),
                                    Text('Add Photo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
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
              onTap: _isSaving ? null : _saveReturn,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: _isSaving ? AppTheme.slate400 : Colors.purple,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.2),
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
                      const Icon(Icons.outbound_outlined, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _isSaving ? 'Saving...' : widget.isEditing ? 'Save Changes' : 'Confirm Return',
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Damage item builder ──

  Widget _buildDamageItem(String damageType) {
    final isChecked = _damages[damageType] ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 22, height: 22,
                child: Checkbox(
                  value: isChecked,
                  onChanged: (v) => setState(() {
                    _damages[damageType] = v ?? false;
                    if (v != true) _damageSeverities.remove(damageType);
                  }),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              Text(damageType, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.slate900)),
              if (isChecked) ...[
                const SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.slate200),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _damageSeverities[damageType] ?? 'minor',
                      isDense: true,
                      style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate700),
                      items: _severityOptions.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s[0].toUpperCase() + s.substring(1), style: GoogleFonts.manrope(fontSize: 12)),
                      )).toList(),
                      onChanged: (v) { if (v != null) setState(() => _damageSeverities[damageType] = v); },
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (isChecked)
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 4),
              child: TextField(
                controller: _damageNoteControllers[damageType],
                decoration: InputDecoration(
                  hintText: 'Describe damage...',
                  hintStyle: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate400),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppTheme.slate200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppTheme.slate200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Colors.purple)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Helpers ──

  Widget _buildPhotoThumb({Uint8List? bytes, String? url, String? label, VoidCallback? onRemove}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.slate200),
            image: bytes != null
                ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover)
                : (url != null ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null),
          ),
          child: Align(
            alignment: Alignment.topRight,
            child: onRemove != null
                ? GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  )
                : null,
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.manrope(fontSize: 10, color: AppTheme.slate500)),
        ],
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(border: Border.all(color: AppTheme.slate200), borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(value: value, isExpanded: true, items: items, onChanged: onChanged),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
    bool required = false,
    String? Function(String?)? validator,
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
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.manrope(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.manrope(color: AppTheme.slate400),
            prefixIcon: maxLines == 1 ? Icon(icon, color: AppTheme.slate400, size: 20) : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.slate200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.slate200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.purple)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
