import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import 'package:intl/intl.dart';
import '../controllers/workers_controller.dart';
import '../../../catalogs/presentation/controllers/catalogs_controller.dart';
import 'worker_form_dialog.dart';

class WorkerProfileDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> worker;

  const WorkerProfileDialog({super.key, required this.worker});

  @override
  ConsumerState<WorkerProfileDialog> createState() => _WorkerProfileDialogState();
}

class _WorkerProfileDialogState extends ConsumerState<WorkerProfileDialog> {
  late String _status;
  String? _selectedRoleId;
  Map<String, dynamic>? _selectedRoleData;
  List<Map<String, dynamic>> _history = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _status = widget.worker['status'] ?? 'Active';
    _selectedRoleId = widget.worker['role_id'];
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final service = ref.read(workersServiceProvider);
      final history = await service.getWorkerHistory(widget.worker['id']);
      if (mounted) {
        setState(() {
          _history = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(laborRolesControllerProvider);

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text('Profile: ${widget.worker['full_name']}')),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryGreen),
            onPressed: () {
              Navigator.pop(context);
              showSafeDialog(
                context: context,
                fullscreenOnMobile: true,
                builder: (context) => WorkerFormDialog(worker: widget.worker),
              );
            },
            tooltip: 'Edit Full Profile',
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.badge, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('ID: ${widget.worker['id_number'] ?? 'N/A'}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(widget.worker['phone'] ?? 'N/A'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.email, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(widget.worker['email'] ?? 'N/A'),
                ],
              ),
              const Divider(height: 32),
              const Text('Assignment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                items: ['Active', 'Inactive'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => _status = val!),
              ),
              const SizedBox(height: 16),
              rolesAsync.when(
                data: (roles) {
                  if (_selectedRoleData == null && _selectedRoleId != null) {
                    try {
                      _selectedRoleData = roles.firstWhere((r) => r['id'] == _selectedRoleId);
                    } catch (_) {}
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedRoleId,
                    decoration: const InputDecoration(
                      labelText: 'Role / Position',
                      border: OutlineInputBorder(),
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
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, st) => Text('Error loading roles: $e'),
              ),
              if (_selectedRoleData != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4),
                  child: Text(
                    'Current Base Salary: \$${_selectedRoleData!['hourly_rate']} / hr',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                  ),
                ),
              const Divider(height: 32),
              const Text('Role History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _isLoadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : _history.isEmpty
                      ? const Text('No recent role changes.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            final h = _history[index];
                            final date = DateFormat.yMMMd().format(DateTime.parse(h['changed_at']));
                            return Card(
                              elevation: 0,
                              color: Colors.grey.shade50,
                              child: ListTile(
                                dense: true,
                                title: Text('Changed to: ${h['new_role']?['description'] ?? 'None'}'),
                                subtitle: Text('Previously: ${h['prev_role']?['description'] ?? 'None'} (Rate: \$${h['previous_hourly_rate'] ?? 0})'),
                                trailing: Text(date, style: const TextStyle(fontSize: 12)),
                              ),
                            );
                          },
                        ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _submit(),
          child: const Text('Save Changes'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    try {
      final data = {
        'status': _status,
        'role_id': _selectedRoleId,
      };
      await ref.read(workersControllerProvider.notifier).updateWorker(widget.worker['id'], data);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
