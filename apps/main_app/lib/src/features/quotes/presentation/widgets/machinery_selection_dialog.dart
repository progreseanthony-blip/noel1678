import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:google_fonts/google_fonts.dart';

class MachinerySelectionDialog extends ConsumerStatefulWidget {
  final String serviceId;
  const MachinerySelectionDialog({super.key, required this.serviceId});

  @override
  ConsumerState<MachinerySelectionDialog> createState() => _MachinerySelectionDialogState();
}

class _MachinerySelectionDialogState extends ConsumerState<MachinerySelectionDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allMachinery = [];
  List<Map<String, dynamic>> _filteredMachinery = [];
  final Set<String> _selectedIds = {};
  bool _isShowingAll = false;

  @override
  void initState() {
    super.initState();
    _loadMachinery();
  }

  Future<void> _loadMachinery() async {
    setState(() => _isLoading = true);
    try {
      final catalog = await ref.read(catalogsServiceProvider).getMachinery();
      _allMachinery = catalog;
      
      // Filter by serviceId
      _filteredMachinery = catalog.where((m) {
        final serviceIds = m['associated_service_ids'] as List?;
        if (serviceIds == null) return false;
        return serviceIds.any((id) => id.toString() == widget.serviceId);
      }).toList();

      if (_filteredMachinery.isEmpty) {
        _isShowingAll = true;
      }
      
    } catch (e) {
      debugPrint('Error loading machinery: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Machinery', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 500,
        height: 600,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : (_isShowingAll ? _allMachinery : _filteredMachinery).isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 48, color: AppTheme.slate400),
                    const SizedBox(height: 16),
                    Text('No machinery found.', style: GoogleFonts.manrope(color: AppTheme.slate500)),
                  ],
                ),
              )
            : Column(
                children: [
                  if (!_isShowingAll && _filteredMachinery.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.filter_list, size: 14, color: AppTheme.primaryGreen),
                          const SizedBox(width: 8),
                          Text('Filtered by service', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          TextButton(
                            onPressed: () => setState(() => _isShowingAll = true),
                            child: const Text('Show All'),
                          ),
                        ],
                      ),
                    ),
                  if (_isShowingAll && _filteredMachinery.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const Text('Showing all machinery'),
                          const Spacer(),
                          TextButton(
                            onPressed: () => setState(() => _isShowingAll = false),
                            child: const Text('Filter by service'),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: (_isShowingAll ? _allMachinery : _filteredMachinery).length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = (_isShowingAll ? _allMachinery : _filteredMachinery)[index];
                        final id = item['id'].toString();
                        final isSelected = _selectedIds.contains(id);
                        final photoUrl = item['photo_url'];

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) _selectedIds.add(id);
                              else _selectedIds.remove(id);
                            });
                          },
                          secondary: Container(
                            width: 50, height: 40,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: AppTheme.slate50),
                            clipBehavior: Clip.antiAlias,
                            child: (photoUrl != null && photoUrl.isNotEmpty)
                              ? Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.precision_manufacturing))
                              : const Icon(Icons.precision_manufacturing),
                          ),
                          title: Text(item['description'] ?? '', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14)),
                          subtitle: Text('Default Cap: ${item['capacity_yards'] ?? 0} | Trips: ${item['trips_per_day'] ?? 60}', style: const TextStyle(fontSize: 11)),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final listToUse = _isShowingAll ? _allMachinery : _filteredMachinery;
            final selected = listToUse.where((m) => _selectedIds.contains(m['id'].toString())).toList();
            Navigator.pop(context, selected);
          },
          child: const Text('Add Selected'),
        ),
      ],
    );
  }
}
