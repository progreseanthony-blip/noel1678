import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceCompletionDialog extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  final String projectId;
  final int currentPct;
  final String currentStatus;

  const ServiceCompletionDialog({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.projectId,
    required this.currentPct,
    required this.currentStatus,
  });

  @override
  State<ServiceCompletionDialog> createState() => _ServiceCompletionDialogState();
}

class _ServiceCompletionDialogState extends State<ServiceCompletionDialog> {
  late double _pct;
  late String _status;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pct = widget.currentPct.toDouble();
    _status = widget.currentStatus;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    final isComplete = _pct >= 100;
    final newStatus = isComplete
        ? 'completed'
        : (_pct > 0 ? 'in_progress' : 'pending');

    try {
      await supabase.from('quote_services').update({
        'completion_pct': _pct,
        'completion_status': newStatus,
        if (isComplete) 'completed_at': DateTime.now().toUtc().toIso8601String(),
        if (isComplete) 'completed_by': user?.id,
        if (!isComplete && widget.currentStatus == 'completed')
          'completed_at': null,
        if (!isComplete && widget.currentStatus == 'completed')
          'completed_by': null,
      }).eq('id', widget.serviceId);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 420,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: _pct >= 100 ? AppTheme.primaryGreen.withOpacity(0.1) : AppTheme.primaryGreen.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _pct >= 100 ? Icons.check_circle : Icons.trending_up,
                            color: _pct >= 100 ? AppTheme.primaryGreen : AppTheme.primaryGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pct >= 100 ? 'Service Complete' : 'Service Progress',
                              style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.serviceName,
                              style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate500, height: 1.0),
                            ),
                          ],
                        ),
                      ],
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.close, color: AppTheme.slate400, size: 24),
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completion Percentage',
                      style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate700),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: _pct >= 100 ? AppTheme.primaryGreen : Colors.orange,
                              inactiveTrackColor: const Color(0xFFF1F5F9),
                              thumbColor: _pct >= 100 ? AppTheme.primaryGreen : Colors.orange,
                              overlayColor: (_pct >= 100 ? AppTheme.primaryGreen : Colors.orange).withOpacity(0.1),
                              valueIndicatorColor: _pct >= 100 ? AppTheme.primaryGreen : Colors.orange,
                              valueIndicatorTextStyle: GoogleFonts.manrope(
                                fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white,
                              ),
                            ),
                            child: Slider(
                              value: _pct,
                              min: 0,
                              max: 100,
                              divisions: 100,
                              label: '${_pct.round()}%',
                              onChanged: (v) => setState(() => _pct = v),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 64, height: 48,
                          decoration: BoxDecoration(
                            color: _pct >= 100 ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '${_pct.round()}%',
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: _pct >= 100 ? AppTheme.primaryGreen : Colors.orange,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(
                          _pct >= 100 ? Icons.check_circle_outline : Icons.info_outline,
                          size: 18,
                          color: _pct >= 100 ? AppTheme.primaryGreen : AppTheme.slate400,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _pct >= 100
                                ? 'This service will be marked as completed.'
                                : _pct > 0
                                    ? 'Set progress to 100% to mark as completed.'
                                    : 'Slide to set the completion percentage.',
                            style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate500)),
                    ),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pct >= 100 ? AppTheme.primaryGreen : Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _pct >= 100 ? 'Mark Complete' : 'Save Progress',
                              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
