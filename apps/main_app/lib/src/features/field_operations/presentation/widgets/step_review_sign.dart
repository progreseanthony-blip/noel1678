import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StepReviewSign extends StatefulWidget {
  final Map<String, dynamic> reportData;
  final List<Map<String, dynamic>> laborLogs;
  final List<Map<String, dynamic>> machineryLogs;
  final List<Map<String, dynamic>> materialUsage;
  final bool isReadOnly;
  final Future<void> Function() onSubmit;

  const StepReviewSign({
    super.key,
    required this.reportData,
    required this.laborLogs,
    required this.machineryLogs,
    required this.materialUsage,
    required this.isReadOnly,
    required this.onSubmit,
  });

  @override
  State<StepReviewSign> createState() => _StepReviewSignState();
}

class _StepReviewSignState extends State<StepReviewSign> {
  bool _isSubmitting = false;
  List<Offset> _signaturePoints = [];
  List<String> _photoUrls = [];
  bool _isUploading = false;

  int get _unplannedLabor => widget.laborLogs.where((l) => l['is_unplanned'] == true).length;
  int get _unplannedMachinery => widget.machineryLogs.where((m) => m['is_unplanned'] == true).length;
  bool get _hasWarnings => _unplannedLabor > 0 || _unplannedMachinery > 0;

  Future<void> _uploadPhoto() async {
    final picker = await _pickFile();
    if (picker == null) return;

    setState(() => _isUploading = true);
    try {
      final fileName = 'daily_report_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage.from('equipment_evidence').uploadBinary(
        fileName,
        picker,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
      final url = Supabase.instance.client.storage.from('equipment_evidence').getPublicUrl(fileName);
      setState(() => _photoUrls.add(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading photo: $e', style: GoogleFonts.manrope())),
        );
      }
    }
    setState(() => _isUploading = false);
  }

  Future<Uint8List?> _pickFile() async {
    return null;
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_hasWarnings) _buildWarningsBanner(),
      const SizedBox(height: 16),

      _buildSummaryCard('General', [
        _summaryRow('Date', widget.reportData['report_date'] ?? '-'),
        _summaryRow('Weather', widget.reportData['weather_condition'] ?? 'Not specified'),
        _summaryRow('Notes', widget.reportData['general_notes'] ?? '-'),
      ], Icons.info_outline, AppTheme.slate900),

      const SizedBox(height: 10),
      _buildSummaryCard('Crew', [
        _summaryRow('Workers registered', '${widget.laborLogs.length}'),
        if (_unplannedLabor > 0)
          _summaryRow('Unplanned', '$_unplannedLabor workers', warning: true),
      ], Icons.people, AppTheme.primaryGreen),

      const SizedBox(height: 10),
      _buildSummaryCard('Machinery', [
        _summaryRow('Machines registered', '${widget.machineryLogs.length}'),
        if (_unplannedMachinery > 0)
          _summaryRow('Unplanned', '$_unplannedMachinery machines', warning: true),
      ], Icons.precision_manufacturing, AppTheme.slate700),

      const SizedBox(height: 10),
      _buildSummaryCard('Materials', [
        _summaryRow('Materials registered', '${widget.materialUsage.length}'),
      ], Icons.inventory, AppTheme.slate500),

      const SizedBox(height: 24),
      _sectionTitle('Evidence Photos'),
      const SizedBox(height: 8),
      if (!widget.isReadOnly) ...[
        Wrap(spacing: 8, runSpacing: 8, children: [
          ..._photoUrls.map((url) => _buildPhoto(url)),
          _buildAddPhotoButton(),
        ]),
        if (_isUploading) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
      ] else ...[
        if (_photoUrls.isEmpty)
          Text('No photos attached', style: _t(fontSize: 12, color: AppTheme.slate400))
        else
          Wrap(spacing: 8, children: _photoUrls.map((url) => _buildPhoto(url)).toList()),
      ],

      const SizedBox(height: 24),
      _sectionTitle('Signature'),
      const SizedBox(height: 8),
      _buildSignatureArea(),

      if (!widget.isReadOnly) ...[
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _handleSubmit,
            icon: _isSubmitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send, size: 18),
            label: Text(_isSubmitting ? 'Submitting...' : 'Submit Report for Review',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('You can save a draft and submit later',
              style: _t(fontSize: 11, color: AppTheme.slate400)),
        ),
      ],
    ]);
  }

  Widget _buildWarningsBanner() {
    final warnings = <String>[];
    if (_unplannedLabor > 0) warnings.add('$_unplannedLabor unplanned workers');
    if (_unplannedMachinery > 0) warnings.add('$_unplannedMachinery unplanned machines');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withAlpha(80)),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Review needed: ${warnings.join(', ')}. These will be flagged for the Project Manager.',
            style: _t(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange[800]),
          ),
        ),
      ]),
    );
  }

  Widget _buildSummaryCard(String title, List<Widget> rows, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: AppTheme.slate200)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Text('$title', style: _t(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate900)),
          ]),
          const SizedBox(height: 10),
          ...rows,
        ]),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool warning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        SizedBox(width: 120, child: Text(label, style: _t(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate600))),
        Expanded(
          child: Text(
            value,
            style: _t(fontSize: 12, fontWeight: FontWeight.w700,
                color: warning ? Colors.orange[700] : AppTheme.slate900),
          ),
        ),
      ]),
    );
  }

  Widget _buildPhoto(String url) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.slate200),
        color: AppTheme.slate50,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: AppTheme.slate400)),
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return InkWell(
      onTap: _isUploading ? null : _uploadPhoto,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.slate200, style: BorderStyle.solid),
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_a_photo, size: 28, color: AppTheme.slate400),
            const SizedBox(height: 4),
            Text('Add photo', style: _t(fontSize: 10, color: AppTheme.slate400)),
          ]),
        ),
      ),
    );
  }

  Widget _buildSignatureArea() {
    if (widget.isReadOnly && _signaturePoints.isEmpty) {
      return Text('Not signed', style: _t(fontSize: 12, color: AppTheme.slate400));
    }
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.slate200),
        color: Colors.white,
      ),
      child: widget.isReadOnly && _signaturePoints.isNotEmpty
          ? CustomPaint(
              painter: _SignaturePainter(_signaturePoints),
              size: const Size(double.infinity, 120),
            )
          : GestureDetector(
              onPanStart: (d) => setState(() => _signaturePoints.add(d.localPosition)),
              onPanUpdate: (d) => setState(() => _signaturePoints.add(d.localPosition)),
              child: Stack(children: [
                if (_signaturePoints.isNotEmpty)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: CustomPaint(
                        painter: _SignaturePainter(_signaturePoints),
                        size: const Size(double.infinity, 120),
                      ),
                    ),
                  )
                else
                  Center(
                    child: Text('Sign here', style: _t(fontSize: 13, color: AppTheme.slate400)),
                  ),
                if (_signaturePoints.isNotEmpty && !widget.isReadOnly)
                  Positioned(
                    top: 4, right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.clear, size: 16, color: AppTheme.slate400),
                      onPressed: () => setState(() => _signaturePoints.clear()),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
              ]),
            ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: _t(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate700));
  }

  TextStyle _t({double? fontSize, FontWeight? fontWeight, Color? color}) {
    return GoogleFonts.manrope(fontSize: fontSize, fontWeight: fontWeight, color: color);
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset> points;
  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = AppTheme.slate900
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
