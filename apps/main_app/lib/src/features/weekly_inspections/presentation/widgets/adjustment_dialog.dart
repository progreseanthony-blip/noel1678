import 'package:flutter/material.dart';
import 'package:noel_core/noel_core.dart';
import 'package:google_fonts/google_fonts.dart';

class AdjustmentDialog extends StatefulWidget {
  final String resourceType;
  final String logId;
  final Map<String, dynamic> log;
  final double originalValue;
  final double currentAdjustedValue;
  final String currentReason;
  final String unit;

  const AdjustmentDialog({
    super.key,
    required this.resourceType,
    required this.logId,
    required this.log,
    required this.originalValue,
    required this.currentAdjustedValue,
    required this.currentReason,
    required this.unit,
  });

  @override
  State<AdjustmentDialog> createState() => _AdjustmentDialogState();
}

class _AdjustmentDialogState extends State<AdjustmentDialog> {
  late TextEditingController _valueController;
  late TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _valueController =
        TextEditingController(text: widget.currentAdjustedValue.toString());
    _reasonController = TextEditingController(text: widget.currentReason);
  }

  @override
  void dispose() {
    _valueController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasExisting =
        widget.currentAdjustedValue != widget.originalValue;

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Row(
        children: [
          Icon(
            widget.resourceType == 'machinery'
                ? Icons.precision_manufacturing
                : Icons.inventory,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Adjust ${widget.resourceType == 'machinery' ? 'Production' : 'Quantity'}',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(
              'Resource',
              _getMachineName(),
              AppTheme.slate400,
            ),
            _infoRow(
              'Original Value',
              '${widget.originalValue.toStringAsFixed(2)} ${widget.unit}',
              AppTheme.slate400,
            ),
            const Divider(color: Color(0xFF334155), height: 20),
            const SizedBox(height: 8),
            Text(
              'Adjusted Value (${widget.unit})',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.slate200,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _valueController,
              keyboardType:
                  TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style:
                  GoogleFonts.manrope(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter new value',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.edit,
                  size: 16,
                  color: Colors.orange.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Reason for adjustment',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.slate200,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              style:
                  GoogleFonts.manrope(fontSize: 13, color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'e.g. Drone measurement shows less actual volume...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (hasExisting)
          TextButton(
            onPressed: () => Navigator.pop(context, {'action': 'reset'}),
            child: const Text(
              'Reset to Original',
              style: TextStyle(color: AppTheme.errorRed),
            ),
          ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppTheme.slate400),
          ),
        ),
        TextButton(
          onPressed: () {
            final newVal =
                double.tryParse(_valueController.text.trim());
            if (newVal == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid number.'),
                  backgroundColor: AppTheme.errorRed,
                ),
              );
              return;
            }
            Navigator.pop(context, {
              'action': 'apply',
              'value': newVal,
              'reason': _reasonController.text.trim(),
            });
          },
          child: Text(
            'Apply',
            style: TextStyle(color: AppTheme.primaryGreen),
          ),
        ),
      ],
    );
  }

  String _getMachineName() {
    if (widget.resourceType == 'machinery') {
      final pm = widget.log['project_machinery'] as Map?;
      return pm?['machinery_name'] as String? ?? 'Unknown';
    }
    final pm = widget.log['project_material'] as Map?;
    return pm?['material_name'] as String? ?? 'Unknown';
  }

  Widget _infoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppTheme.slate500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
