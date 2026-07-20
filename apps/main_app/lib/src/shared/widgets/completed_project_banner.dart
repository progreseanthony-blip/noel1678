import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompletedProjectBanner extends StatefulWidget {
  final String projectId;
  final Widget child;
  final void Function(bool isCompleted)? isCompletedCallback;

  const CompletedProjectBanner({
    super.key,
    required this.projectId,
    required this.child,
    this.isCompletedCallback,
  });

  @override
  State<CompletedProjectBanner> createState() => _CompletedProjectBannerState();
}

class _CompletedProjectBannerState extends State<CompletedProjectBanner> {
  bool _isLoading = true;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final supabase = Supabase.instance.client;
      final result = await supabase
          .from('projects')
          .select('status')
          .eq('id', widget.projectId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _isCompleted = (result?['status'] as String?) == 'completed';
          _isLoading = false;
        });
        widget.isCompletedCallback?.call(_isCompleted);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!_isLoading && _isCompleted)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              border: const Border(bottom: BorderSide(color: Color(0xFFBBF7D0))),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 18, color: AppTheme.primaryGreen),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Este proyecto está completado. Las ediciones están bloqueadas.',
                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.slate700),
                  ),
                ),
              ],
            ),
          ),
        widget.child,
      ],
    );
  }
}
