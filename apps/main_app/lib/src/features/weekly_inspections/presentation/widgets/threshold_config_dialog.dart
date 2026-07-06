import 'package:flutter/material.dart';
import 'package:noel_core/noel_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_data/noel_data.dart';

class ThresholdConfigDialog extends StatefulWidget {
  final Map<String, dynamic> service;
  final VoidCallback onSaved;

  const ThresholdConfigDialog({
    super.key,
    required this.service,
    required this.onSaved,
  });

  @override
  State<ThresholdConfigDialog> createState() => _ThresholdConfigDialogState();
}

class _ThresholdConfigDialogState extends State<ThresholdConfigDialog> {
  late TextEditingController _thresholdController;
  bool _isSaving = false;
  double? _currentThreshold;

  @override
  void initState() {
    super.initState();
    _thresholdController = TextEditingController(text: '5.0');
    _loadCurrent();
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrent() async {
    try {
      final service = InspectionService(Supabase.instance.client);
      final threshold =
          await service.getThresholdForService(widget.service['id']);
      if (mounted) {
        setState(() {
          _currentThreshold = threshold;
          _thresholdController.text = threshold.toString();
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final value = double.tryParse(_thresholdController.text.trim());
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid positive number.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final service = InspectionService(Supabase.instance.client);
      await service.upsertServiceThreshold(widget.service['id'], value);
      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceName =
        widget.service['description'] as String? ?? 'Unknown';
    final unit = widget.service['unit'] as String? ?? '';

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Row(
        children: [
          const Icon(Icons.tune, color: AppTheme.primaryGreen, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Inspection Threshold',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 15,
              ),
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
            Text(
              serviceName,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.slate200,
              ),
            ),
            if (unit.isNotEmpty)
              Text(
                'Unit: $unit',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: AppTheme.slate500,
                ),
              ),
            if (_currentThreshold != null) ...[
              const SizedBox(height: 8),
              Text(
                'Current: ${_currentThreshold!.toStringAsFixed(1)}%',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: AppTheme.slate400,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Deviation threshold (%)',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.slate200,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _thresholdController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.manrope(
                        fontSize: 16, color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: '5.0',
                      suffixText: '%',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'When the deviation between daily reports and weekly inspection exceeds this percentage, an alert is triggered and reconciliation is required.',
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: AppTheme.slate500,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppTheme.slate400),
          ),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: const Color(0xFF0F172A),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  'Save',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }
}
