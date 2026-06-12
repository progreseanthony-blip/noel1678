import 'package:flutter/material.dart';
import 'package:noel_core/noel_core.dart';

class AffectedItemsSection extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final bool editable;
  final VoidCallback? onAddItem;
  final ValueChanged<String>? onRemoveItem;

  const AffectedItemsSection({
    super.key,
    required this.items,
    this.editable = false,
    this.onAddItem,
    this.onRemoveItem,
  });

  String _resourceIcon(String type) {
    switch (type) {
      case 'material': return 'inventory_2';
      case 'machinery': return 'precision_manufacturing';
      case 'labor': return 'people';
      case 'instrument': return 'build';
      default: return 'warning';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(children: [
          Icon(Icons.inventory_2_outlined, size: 40, color: AppTheme.slate200),
          const SizedBox(height: 8),
          Text('No affected resources', style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 13)),
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...items.map((item) => _buildItemCard(item)),
        if (editable && onAddItem != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onAddItem,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Affected Resource'),
            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
          ),
        ],
      ],
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final type = item['affected_type'] as String? ?? '';
    final name = item['resource_name'] as String? ?? '';
    final qty = item['quantity_affected'] ?? 0;
    final unit = item['unit'] as String? ?? '';
    final cost = item['estimated_cost'] ?? 0;
    final desc = item['description'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppTheme.slate200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                  color: AppTheme.slate50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(_resourceIcon(type) == 'inventory_2' ? Icons.inventory_2 : 
                         _resourceIcon(type) == 'precision_manufacturing' ? Icons.precision_manufacturing : 
                         _resourceIcon(type) == 'people' ? Icons.people : Icons.build,
                    size: 16, color: AppTheme.slate500),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.slate900)),
                  const SizedBox(height: 4),
                  Text('$qty $unit', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500)),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(desc, style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate400)),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.slate50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '\$${(cost as num).toStringAsFixed(0)}',
                    style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate700),
                  ),
                ),
                if (editable && onRemoveItem != null) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 24, width: 24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 16,
                      icon: const Icon(Icons.close, color: AppTheme.errorRed),
                      onPressed: () => onRemoveItem!(item['id'] as String),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension _StringExtension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
