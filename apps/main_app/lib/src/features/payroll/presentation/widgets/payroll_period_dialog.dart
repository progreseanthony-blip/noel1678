import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_ui_components/noel_ui_components.dart';

class PayrollPeriodDialog extends ConsumerStatefulWidget {
  final String projectId;
  final Map<String, dynamic>? periodToEdit;

  const PayrollPeriodDialog({
    super.key,
    required this.projectId,
    this.periodToEdit,
  });

  @override
  ConsumerState<PayrollPeriodDialog> createState() => _PayrollPeriodDialogState();
}

class _PayrollPeriodDialogState extends ConsumerState<PayrollPeriodDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final p = widget.periodToEdit;
    _nameCtrl = TextEditingController(text: p?['name'] ?? '');
    _startDate = p != null ? DateTime.parse(p['start_date'] as String) : null;
    _endDate = p != null ? DateTime.parse(p['end_date'] as String) : null;
    _startCtrl = TextEditingController(
      text: _startDate != null ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}' : '',
    );
    _endCtrl = TextEditingController(
      text: _endDate != null ? '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}' : '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl, bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? _startDate ?? now),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked; else _endDate = picked;
        ctrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) return;
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }
    final data = {
      'project_id': widget.projectId,
      'name': _nameCtrl.text.trim(),
      'start_date': _startDate!.toIso8601String().split('T')[0],
      'end_date': _endDate!.toIso8601String().split('T')[0],
    };
    Navigator.pop(context, data);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveDialogShell(
      title: widget.periodToEdit != null ? 'Edit Period' : 'New Period',
      subtitle: 'Define a date range to calculate labor costs.',
      maxWidth: 440,
      bodyPadding: const EdgeInsets.all(28),
      onClose: () => Navigator.of(context).pop(),
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Period Name',
                hintText: 'e.g. Quincena 1 Junio',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              style: GoogleFonts.manrope(fontSize: 14),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _startCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Start Date',
                    suffixIcon: const Icon(Icons.calendar_today, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  style: GoogleFonts.manrope(fontSize: 14),
                  onTap: () => _pickDate(_startCtrl, true),
                  validator: (_) => _startDate == null ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _endCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'End Date',
                    suffixIcon: const Icon(Icons.calendar_today, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  style: GoogleFonts.manrope(fontSize: 14),
                  onTap: () => _pickDate(_endCtrl, false),
                  validator: (_) => _endDate == null ? 'Required' : null,
                ),
              ),
            ]),
          ],
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.manrope(color: AppTheme.slate500)),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            child: Text('Save', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
