import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:google_fonts/google_fonts.dart';
import 'material_dialog.dart';

class MaterialsTab extends ConsumerStatefulWidget {
  const MaterialsTab({super.key});

  @override
  ConsumerState<MaterialsTab> createState() => _MaterialsTabState();
}

class _MaterialsTabState extends ConsumerState<MaterialsTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _materials = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ref.read(catalogsServiceProvider).getMaterials();
      setState(() {
        _materials = data;
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

  void _showForm([Map<String, dynamic>? item]) {
    showDialog(
      context: context,
      builder: (context) => MaterialDialog(materialToEdit: item),
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
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _showForm(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_circle_outline, color: Color(0xFF0F172A), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Add Material',
                          style: GoogleFonts.manrope(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
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
              child: _materials.isEmpty 
                ? Center(child: Text('No materials found in catalog', style: GoogleFonts.manrope(color: AppTheme.slate500)))
                : ListView.separated(
                    itemCount: _materials.length,
                    separatorBuilder: (context, index) => const Divider(color: AppTheme.slate200, height: 1),
                    itemBuilder: (context, index) {
                      final item = _materials[index];
                      final serviceCount = (item['associated_service_ids'] as List?)?.length ?? 0;
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        leading: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryGreen, size: 16),
                        ),
                        title: Text(item['description'], style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppTheme.slate900, fontSize: 13)),
                        subtitle: Row(
                          children: [
                            Text('Unit: ${item['unit']}', style: GoogleFonts.manrope(color: AppTheme.slate500, fontSize: 11)),
                            const SizedBox(width: 8),
                            Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppTheme.slate400, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text('Yield: ${item['yield_factor'] ?? 1.0}', style: GoogleFonts.manrope(color: AppTheme.slate500, fontSize: 11)),
                            const SizedBox(width: 8),
                            Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppTheme.slate400, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text('$serviceCount services', style: GoogleFonts.manrope(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(onPressed: () => _showForm(item), icon: const Icon(Icons.edit_outlined, color: AppTheme.slate500, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
                            IconButton(onPressed: () => _deleteItem(item['id']), icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
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

  Future<void> _deleteItem(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: const Text('Are you sure you want to delete this material?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: AppTheme.errorRed))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(catalogsServiceProvider).deleteMaterial(id);
        _loadData();
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed));
        }
      }
    }
  }
}
