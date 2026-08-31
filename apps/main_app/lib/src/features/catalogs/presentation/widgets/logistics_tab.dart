import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import 'logistics_dialog.dart';

class LogisticsTab extends ConsumerStatefulWidget {
  const LogisticsTab({super.key});

  @override
  ConsumerState<LogisticsTab> createState() => _LogisticsTabState();
}

class _LogisticsTabState extends ConsumerState<LogisticsTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _equipment = [];
  List<Map<String, dynamic>> _allServices = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final catalogService = ref.read(catalogsServiceProvider);
      final data = await catalogService.getLogisticsEquipment();
      final services = await catalogService.getServices();
      setState(() {
        _equipment = data;
        _allServices = services;
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
    showSafeDialog(
      context: context,
      fullscreenOnMobile: true,
      builder: (context) => LogisticsDialog(itemToEdit: item),
    ).then((success) {
      if (success == true) _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
    if (_error != null) return Center(child: Text('Error: $_error'));

    final isMobile = MediaQuery.of(context).size.width < 768;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 16),
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
                          'Add Logistics',
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
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: _equipment.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _equipment[index];
                final photoUrl = item['photo_url'];
                final serviceIds = (item['associated_service_ids'] as List?) ?? [];
                final apps = (item['applications'] as List?) ?? [];

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.slate200),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 140,
                                color: AppTheme.slate50,
                                child: (photoUrl != null && photoUrl.toString().isNotEmpty)
                                    ? Image.network(photoUrl.toString(), fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.inventory_2_outlined, color: AppTheme.slate400, size: 32)))
                                    : const Center(child: Icon(Icons.inventory_2_outlined, color: AppTheme.slate400, size: 32)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['description'] ?? 'No Description',
                                            style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: AppTheme.slate900, fontSize: 16),
                                          ),
                                        ),
                                        IconButton(onPressed: () => _showForm(item), icon: const Icon(Icons.edit_outlined, color: AppTheme.slate400, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                        const SizedBox(width: 8),
                                        IconButton(onPressed: () => _deleteItem(item['id']), icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _buildChipsWrap(serviceIds, apps),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  width: 120,
                                  decoration: BoxDecoration(
                                    color: AppTheme.slate50,
                                    border: Border(right: BorderSide(color: AppTheme.slate200)),
                                  ),
                                  child: (photoUrl != null && photoUrl.toString().isNotEmpty)
                                      ? Image.network(photoUrl.toString(), fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.inventory_2_outlined, color: AppTheme.slate400, size: 32)))
                                      : const Center(child: Icon(Icons.inventory_2_outlined, color: AppTheme.slate400, size: 32)),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item['description'] ?? 'No Description',
                                                style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: AppTheme.slate900, fontSize: 16),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(onPressed: () => _showForm(item), icon: const Icon(Icons.edit_outlined, color: AppTheme.slate400, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                                const SizedBox(width: 12),
                                                IconButton(onPressed: () => _deleteItem(item['id']), icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        _buildChipsWrap(serviceIds, apps),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipsWrap(List<dynamic> serviceIds, List<dynamic> apps) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...serviceIds.map((id) {
          final svc = _allServices.firstWhere((s) => s['id'].toString() == id.toString(), orElse: () => {'description': 'Unknown'});
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(svc['description'].toString().toUpperCase(), style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen)),
          );
        }),
        ...apps.map((app) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppTheme.slate200, borderRadius: BorderRadius.circular(6)),
          child: Text(app.toString().toUpperCase(), style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.slate500)),
        )),
      ],
    );
  }

  Future<void> _deleteItem(String id) async {
    final confirm = await showSafeDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this logistics record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: AppTheme.errorRed))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(catalogsServiceProvider).deleteLogisticsEquipment(id);
        _loadData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed));
      }
    }
  }
}
