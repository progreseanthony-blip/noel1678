import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:google_fonts/google_fonts.dart';

class MachinerySelectionDialog extends ConsumerStatefulWidget {
  final String serviceId;
  final bool isInstrument;
  const MachinerySelectionDialog({
    super.key,
    required this.serviceId,
    this.isInstrument = false,
  });

  @override
  ConsumerState<MachinerySelectionDialog> createState() =>
      _MachinerySelectionDialogState();
}

class _MachinerySelectionDialogState
    extends ConsumerState<MachinerySelectionDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allInventory = [];
  List<Map<String, dynamic>> _filteredInventory = [];
  final Set<String> _selectedIds = {};
  bool _isShowingAll = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> catalog;
      if (widget.isInstrument) {
        catalog = await ref.read(catalogsServiceProvider).getLogisticsEquipment();
      } else {
        catalog = await ref.read(catalogsServiceProvider).getMachinery();
      }
      
      _allInventory = catalog;

      // Filter by serviceId
      _filteredInventory = catalog.where((m) {
        final serviceIds = m['associated_service_ids'] as List?;
        if (serviceIds == null) return false;
        return serviceIds.any((id) => id.toString() == widget.serviceId);
      }).toList();

      if (_filteredInventory.isEmpty || widget.serviceId.isEmpty) {
        _isShowingAll = true;
      }
    } catch (e) {
      debugPrint('Error loading selection data: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final listToDisplay = _isShowingAll ? _allInventory : _filteredInventory;
    final title = widget.isInstrument ? 'Select Instruments' : 'Select Machinery';

    return AlertDialog(
      title: Text(title,
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 500,
        height: 600,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : listToDisplay.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 48, color: AppTheme.slate400),
                        const SizedBox(height: 16),
                        Text('No items found.',
                            style:
                                GoogleFonts.manrope(color: AppTheme.slate500)),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      if (!_isShowingAll && _filteredInventory.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.filter_list,
                                  size: 14, color: AppTheme.primaryGreen),
                              const SizedBox(width: 8),
                              Text('Filtered by service',
                                  style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.bold)),
                              const Spacer(),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _isShowingAll = true),
                                child: const Text('Show All'),
                              ),
                            ],
                          ),
                        ),
                      if (_isShowingAll && _filteredInventory.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Text('Showing all',
                                  style: GoogleFonts.manrope(
                                      fontSize: 12, color: AppTheme.slate500)),
                              const Spacer(),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _isShowingAll = false),
                                child: const Text('Filter by service'),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: listToDisplay.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final item = listToDisplay[index];
                            final id = item['id'].toString();
                            final isSelected = _selectedIds.contains(id);
                            final photoUrl = item['photo_url'];

                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedIds.add(id);
                                  } else {
                                    _selectedIds.remove(id);
                                  }
                                });
                              },
                              secondary: Container(
                                width: 50,
                                height: 40,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: AppTheme.slate50),
                                clipBehavior: Clip.antiAlias,
                                child: (photoUrl != null && photoUrl.isNotEmpty)
                                    ? Image.network(photoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                            widget.isInstrument
                                                ? Icons.handyman_outlined
                                                : Icons
                                                    .precision_manufacturing))
                                    : Icon(widget.isInstrument
                                        ? Icons.handyman_outlined
                                        : Icons.precision_manufacturing),
                              ),
                              title: Text(
                                  item['description'] ?? item['name'] ?? '',
                                  style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              subtitle: !widget.isInstrument
                                  ? Text(
                                      'Default Cap: ${item['capacity_yards'] ?? 0} | Trips: ${item['trips_per_day'] ?? 60}',
                                      style: const TextStyle(fontSize: 11))
                                  : Text(
                                      'Rate: \$${item['daily_rate'] ?? 0}/day',
                                      style: const TextStyle(fontSize: 11)),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final listToUse = _isShowingAll ? _allInventory : _filteredInventory;
            final selected = listToUse
                .where((m) => _selectedIds.contains(m['id'].toString()))
                .toList();
            Navigator.pop(context, selected);
          },
          child: const Text('Add Selected'),
        ),
      ],
    );
  }
}
