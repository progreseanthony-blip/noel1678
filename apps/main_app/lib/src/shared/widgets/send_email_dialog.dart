import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:noel_ui_components/noel_ui_components.dart';

/// Reusable dialog to send a generated PDF by email through the
/// `send-document-email` edge function.
///
/// Usage: build the PDF bytes first, then
/// `showSafeDialog(context: context, builder: (_) => SendEmailDialog(...))`.
class SendEmailDialog extends ConsumerStatefulWidget {
  final String dialogTitle;
  final String initialTo;
  final String subject;
  final String body;
  final String fileName;
  final List<int> pdfBytes;
  final String docType;
  final String? projectId;
  final String? invoiceId;
  final String? quoteId;

  const SendEmailDialog({
    super.key,
    this.dialogTitle = 'Send by Email',
    this.initialTo = '',
    required this.subject,
    required this.body,
    required this.fileName,
    required this.pdfBytes,
    required this.docType,
    this.projectId,
    this.invoiceId,
    this.quoteId,
  });

  @override
  ConsumerState<SendEmailDialog> createState() => _SendEmailDialogState();
}

class _SendEmailDialogState extends ConsumerState<SendEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _toCtrl;
  late TextEditingController _ccCtrl;
  late TextEditingController _subjectCtrl;
  late TextEditingController _bodyCtrl;
  bool _isSending = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _toCtrl = TextEditingController(text: widget.initialTo);
    _ccCtrl = TextEditingController();
    _subjectCtrl = TextEditingController(text: widget.subject);
    _bodyCtrl = TextEditingController(text: widget.body);
  }

  @override
  void dispose() {
    _toCtrl.dispose();
    _ccCtrl.dispose();
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCustomer() async {
    List<Map<String, dynamic>> customers = [];
    try {
      customers = await ref.read(customersServiceProvider).getCustomers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load customers: $e')),
        );
      }
      return;
    }
    final withEmail = customers
        .where((c) => (c['email']?.toString() ?? '').trim().isNotEmpty)
        .toList();
    if (!mounted) return;
    if (withEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No customers with email found.')),
      );
      return;
    }
    String query = '';
    final picked = await showSafeDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final q = query.toLowerCase();
          final filtered = withEmail.where((c) {
            final name = (c['name'] ?? '').toString().toLowerCase();
            final email = (c['email'] ?? '').toString().toLowerCase();
            return q.isEmpty || name.contains(q) || email.contains(q);
          }).toList();
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text('Select Customer',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
            content: SizedBox(
              width: 400,
              height: 420,
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) => setDialogState(() => query = v),
                    decoration: const InputDecoration(
                      hintText: 'Search by name or email...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        return ListTile(
                          title: Text(c['name']?.toString() ?? ''),
                          subtitle:
                              Text(c['email']?.toString() ?? ''),
                          onTap: () => Navigator.of(ctx).pop(c),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
    if (picked != null && mounted) {
      setState(() => _toCtrl.text = picked['email']?.toString() ?? '');
    }
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSending = true;
      _errorMsg = null;
    });
    try {
      await ref.read(emailServiceProvider).sendDocumentEmail(
            to: _toCtrl.text,
            cc: _ccCtrl.text.trim().isEmpty ? null : _ccCtrl.text,
            subject: _subjectCtrl.text,
            body: _bodyCtrl.text,
            fileName: widget.fileName,
            pdfBytes: widget.pdfBytes,
            docType: widget.docType,
            projectId: widget.projectId,
            invoiceId: widget.invoiceId,
            quoteId: widget.quoteId,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      // Inline error: snackbars render behind the modal barrier.
      if (mounted) {
        setState(() => _errorMsg = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kbSize = (widget.pdfBytes.length / 1024).toStringAsFixed(0);
    return ResponsiveDialogShell(
      title: widget.dialogTitle,
      subtitle: 'Attachment: ${widget.fileName} ($kbSize KB)',
      icon: Icons.email_outlined,
      maxWidth: 520,
      bodyPadding: const EdgeInsets.all(24),
      onClose: () => Navigator.of(context).pop(),
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMsg != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppTheme.errorRed.withOpacity(0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 18, color: AppTheme.errorRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Send failed: $_errorMsg',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _toCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'To *',
                      hintText: 'client@example.com',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        EmailService.isValidEmail(v ?? '')
                            ? null
                            : 'Enter a valid email',
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Pick from customers',
                  onPressed: _pickCustomer,
                  icon: const Icon(Icons.contacts_outlined,
                      color: AppTheme.primaryGreen),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ccCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'CC (optional)',
                prefixIcon: Icon(Icons.copy_outlined),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty || EmailService.isValidEmail(v!)
                      ? null
                      : 'Enter a valid email',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(
                labelText: 'Subject *',
                prefixIcon: Icon(Icons.subject_outlined),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Subject is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bodyCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Message',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.message_outlined),
              ),
            ),
          ],
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed:
                _isSending ? null : () => Navigator.of(context).pop(),
            child: Text('Cancel',
                style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700, color: AppTheme.slate700)),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isSending ? null : _send,
            icon: _isSending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_outlined,
                    size: 18, color: Colors.white),
            label: Text(_isSending ? 'Sending...' : 'Send',
                style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
