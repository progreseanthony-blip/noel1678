import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_ui_components/noel_ui_components.dart';

/// Shared two-box period picker (Start date + End date).
///
/// Standardizes every "select a period" flow on the individual-scheduling
/// style: two tappable boxes, each opening a single [showDatePicker],
/// instead of the native [showDateRangePicker] month-grid view.
class StandardPeriodPickerDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Optional reference banner (e.g. original estimation period).
  final String referenceLabel;
  final DateTime? referenceStart;
  final DateTime? referenceEnd;
  final String? referenceSuffix;
  final String referenceFallback;

  final String confirmLabel;

  const StandardPeriodPickerDialog({
    super.key,
    this.title = 'Select Period',
    this.subtitle,
    this.initialStart,
    this.initialEnd,
    this.firstDate,
    this.lastDate,
    this.referenceLabel = 'REFERENCE PERIOD',
    this.referenceStart,
    this.referenceEnd,
    this.referenceSuffix,
    this.referenceFallback = 'No reference dates',
    this.confirmLabel = 'Save',
  });

  @override
  State<StandardPeriodPickerDialog> createState() =>
      _StandardPeriodPickerDialogState();
}

class _StandardPeriodPickerDialogState
    extends State<StandardPeriodPickerDialog> {
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
  }

  DateTime get _firstDate => widget.firstDate ?? DateTime(2020);
  DateTime get _lastDate => widget.lastDate ?? DateTime(2100, 12, 31);

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start ?? widget.initialStart ?? DateTime.now(),
      firstDate: _firstDate,
      lastDate: _lastDate,
    );
    if (picked == null) return;
    setState(() {
      _start = picked;
      if (_end == null || _end!.isBefore(picked)) {
        _end = picked;
      }
    });
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end ?? _start ?? widget.initialEnd ?? DateTime.now(),
      firstDate: _start ?? _firstDate,
      lastDate: _lastDate,
    );
    if (picked == null) return;
    setState(() => _end = picked);
  }

  void _save() {
    if (_start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates.')),
      );
      return;
    }
    if (_end!.isBefore(_start!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date cannot be before start date.')),
      );
      return;
    }
    Navigator.of(context).pop(DateTimeRange(start: _start!, end: _end!));
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveDialogShell(
      title: widget.title,
      subtitle: widget.subtitle,
      icon: Icons.calendar_month,
      maxWidth: 480,
      bodyPadding: const EdgeInsets.all(24),
      onClose: () => Navigator.of(context).pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildReferenceBanner(),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickStart,
                  child: _buildDateBox('Start Date', _start),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _pickEnd,
                  child: _buildDateBox('End Date', _end),
                ),
              ),
            ],
          ),
        ],
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.slate700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              widget.confirmLabel,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceBanner() {
    final hasRef = widget.referenceStart != null || widget.referenceEnd != null;
    String text;
    if (hasRef) {
      final s = widget.referenceStart?.toString().split(' ').first ?? '?';
      final e = widget.referenceEnd?.toString().split(' ').first ?? '?';
      text = widget.referenceSuffix != null ? '$s → $e · ${widget.referenceSuffix}' : '$s → $e';
    } else {
      text = widget.referenceFallback;
    }
    String? deviation;
    if (hasRef && widget.referenceStart != null && _start != null) {
      final diff = _start!.difference(widget.referenceStart!).inDays;
      if (diff != 0) {
        deviation = diff > 0
            ? 'Starts $diff day${diff == 1 ? '' : 's'} after reference'
            : 'Starts ${-diff} day${diff == -1 ? '' : 's'} before reference';
      }
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryGreen, width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, size: 18, color: AppTheme.primaryGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.referenceLabel,
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryGreen,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (deviation != null)
                  Text(
                    deviation,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: Colors.orange,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBox(String label, DateTime? date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 16, color: Colors.orange),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.slate400,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  date != null ? date.toString().split(' ').first : 'Choose...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
