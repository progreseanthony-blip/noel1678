import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:google_fonts/google_fonts.dart';
import 'labor_role_dialog.dart';

class LaborRolesTab extends ConsumerStatefulWidget {
  const LaborRolesTab({super.key});

  @override
  ConsumerState<LaborRolesTab> createState() => _LaborRolesTabState();
}

class _LaborRolesTabState extends ConsumerState<LaborRolesTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _roles = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ref.read(catalogsServiceProvider).getLaborRoles();
      setState(() {
        _roles = data;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showForm([Map<String, dynamic>? role]) {
    showDialog(
      context: context,
      builder: (context) => LaborRoleDialog(roleToEdit: role),
    ).then((success) {
      if (success == true) _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
    if (_error != null) return Center(child: Text('Error: $_error'));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showForm(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('ADD ROLE'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(0, 40),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: ListView.separated(
                itemCount: _roles.length,
                separatorBuilder: (context, index) => const Divider(color: AppTheme.slate200, height: 1),
                itemBuilder: (context, index) {
                  final role = _roles[index];
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    title: Text(role['description'], style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppTheme.slate900, fontSize: 13)),
                    subtitle: Text('Rate: \$${role['hourly_rate']}/hr', style: GoogleFonts.manrope(color: AppTheme.slate500, fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(onPressed: () => _showForm(role), icon: const Icon(Icons.edit_outlined, color: AppTheme.slate500, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
                        IconButton(onPressed: () => _deleteRole(role['id']), icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRole(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Role'),
        content: const Text('Are you sure you want to delete this role?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: AppTheme.errorRed))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(catalogsServiceProvider).deleteLaborRole(id);
        _loadData();
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed));
        }
      }
    }
  }
}
