import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../controllers/workers_controller.dart';
import '../../../catalogs/presentation/controllers/catalogs_controller.dart';

class WorkerFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? worker;
  const WorkerFormDialog({super.key, this.worker});

  @override
  ConsumerState<WorkerFormDialog> createState() => _WorkerFormDialogState();
}

class _WorkerFormDialogState extends ConsumerState<WorkerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idNumberCtrl;
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  
  String? _selectedRoleId;
  Map<String, dynamic>? _selectedRoleData;

  final _phoneFormatter = MaskTextInputFormatter(
    mask: '(###) ###-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void initState() {
    super.initState();
    _idNumberCtrl = TextEditingController(text: widget.worker?['id_number']);
    _fullNameCtrl = TextEditingController(text: widget.worker?['full_name']);
    _phoneCtrl = TextEditingController(text: widget.worker?['phone']);
    _emailCtrl = TextEditingController(text: widget.worker?['email']);
    
    if (widget.worker?['role_id'] != null) {
      _selectedRoleId = widget.worker?['role_id'];
      _selectedRoleData = widget.worker?['role'];
    }
  }

  @override
  void dispose() {
    _idNumberCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(laborRolesControllerProvider);
    final isEditing = widget.worker != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Worker' : 'Add New Worker'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _idNumberCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ID / Cédula',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fullNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtrl,
                  inputFormatters: [_phoneFormatter],
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    hintText: '(###) ###-####',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'example@email.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  onChanged: (val) {
                    // Force lowercase for emails
                    if (val != val.toLowerCase()) {
                      _emailCtrl.value = _emailCtrl.value.copyWith(
                        text: val.toLowerCase(),
                        selection: TextSelection.fromPosition(
                          TextPosition(offset: _emailCtrl.selection.baseOffset),
                        ),
                      );
                    }
                  },
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegExp.hasMatch(v)) {
                        return 'Invalid email format';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                rolesAsync.when(
                  data: (roles) {
                    return DropdownButtonFormField<String>(
                      value: _selectedRoleId,
                      decoration: const InputDecoration(
                        labelText: 'Role / Position',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                      items: roles.map((r) => DropdownMenuItem(
                        value: r['id'] as String,
                        child: Text(r['description']),
                      )).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedRoleId = val;
                          _selectedRoleData = roles.firstWhere((r) => r['id'] == val);
                        });
                      },
                      validator: (v) => v == null ? 'Required' : null,
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, st) => Text('Error loading roles: $e'),
                ),
                if (_selectedRoleData != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0, left: 4),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.payments_outlined, color: AppTheme.primaryGreen, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Salary Rate: \$${_selectedRoleData!['hourly_rate']} / hr',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => _submit(),
          icon: Icon(isEditing ? Icons.check : Icons.save),
          label: Text(isEditing ? 'Update Worker' : 'Save Worker'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        final isEditing = widget.worker != null;
        final data = {
          'id_number': _idNumberCtrl.text,
          'full_name': _fullNameCtrl.text,
          'phone': _phoneCtrl.text,
          'email': _emailCtrl.text,
          'role_id': _selectedRoleId,
        };

        if (isEditing) {
          await ref.read(workersControllerProvider.notifier).updateWorker(widget.worker!['id'], data);
        } else {
          data['hire_date'] = DateTime.now().toIso8601String().split('T').first;
          data['status'] = 'Active';
          await ref.read(workersControllerProvider.notifier).createWorker(data);
        }
        
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
