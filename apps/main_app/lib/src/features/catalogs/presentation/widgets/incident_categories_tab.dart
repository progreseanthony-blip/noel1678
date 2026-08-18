import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:noel_ui_components/noel_ui_components.dart';

class IncidentCategoriesTab extends ConsumerStatefulWidget {
  const IncidentCategoriesTab({super.key});

  @override
  ConsumerState<IncidentCategoriesTab> createState() => _IncidentCategoriesTabState();
}

class _IncidentCategoriesTabState extends ConsumerState<IncidentCategoriesTab> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final categories = await ref.read(incidentsServiceProvider).getAllCategories();
      if (mounted) setState(() { _categories = categories; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _create() async {
    final result = await showSafeDialog<Map<String, String>>(
      context: context,
      fullscreenOnMobile: true,
      builder: (ctx) => _CategoryFormDialog(),
    );
    if (result == null) return;
    try {
      await ref.read(incidentsServiceProvider).createCategory(result);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _edit(Map<String, dynamic> cat) async {
    final result = await showSafeDialog<Map<String, String>>(
      context: context,
      fullscreenOnMobile: true,
      builder: (ctx) => _CategoryFormDialog(initial: cat),
    );
    if (result == null) return;
    try {
      await ref.read(incidentsServiceProvider).updateCategory(cat['id'] as String, result);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showSafeDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(incidentsServiceProvider).deleteCategory(id);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Text('Incident Categories', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.slate900)),
            const Spacer(),
            FilledButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Category'),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            ),
          ]),
        ),
        Expanded(
          child: _categories.isEmpty
              ? Center(child: Text('No categories', style: GoogleFonts.manrope(color: AppTheme.slate400)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final cat = _categories[i];
                    return ListTile(
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Color(int.parse((cat['color'] as String? ?? '#EF4444').replaceFirst('#', '0xFF'))).withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.warning_amber_rounded, size: 18, color: Color(int.parse((cat['color'] as String? ?? '#EF4444').replaceFirst('#', '0xFF')))),
                      ),
                      title: Text(cat['name'] as String? ?? '', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                      subtitle: Text(cat['code'] as String? ?? '', style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate400)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _edit(cat)),
                        IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorRed), onPressed: () => _delete(cat['id'] as String)),
                      ]),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CategoryFormDialog extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _CategoryFormDialog({this.initial});

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _colorCtrl;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.initial?['code'] as String? ?? '');
    _nameCtrl = TextEditingController(text: widget.initial?['name'] as String? ?? '');
    _colorCtrl = TextEditingController(text: widget.initial?['color'] as String? ?? '#EF4444');
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'New Category' : 'Edit Category'),
      content: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: _codeCtrl, decoration: const InputDecoration(labelText: 'Code', hintText: 'MATERIAL_DAMAGE', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name', hintText: 'Material Damage', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _colorCtrl, decoration: const InputDecoration(labelText: 'Color Hex', hintText: '#EF4444', border: OutlineInputBorder())),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          if (_formKey.currentState!.validate()) {
            Navigator.pop(context, {
              'code': _codeCtrl.text.trim().toUpperCase().replaceAll(' ', '_'),
              'name': _nameCtrl.text.trim(),
              'color': _colorCtrl.text.trim().isEmpty ? '#EF4444' : _colorCtrl.text.trim(),
            });
          }
        }, child: const Text('Save')),
      ],
    );
  }
}
