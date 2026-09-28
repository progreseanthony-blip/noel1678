import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../remote/supabase_client.dart';

part 'email_service.g.dart';

@riverpod
EmailService emailService(EmailServiceRef ref) {
  return EmailService(ref.watch(supabaseClientProvider));
}

/// Sends generated PDF documents by email through the
/// `send-document-email` edge function (SMTP of the company domain).
class EmailService {
  static const int maxAttachmentBytes = 9 * 1024 * 1024;

  final SupabaseClient _supabase;

  EmailService(this._supabase);

  /// Sends [pdfBytes] as attachment. Throws on validation or send errors.
  Future<void> sendDocumentEmail({
    required String to,
    String? cc,
    required String subject,
    required String body,
    required String fileName,
    required List<int> pdfBytes,
    required String docType,
    String? projectId,
    String? invoiceId,
    String? quoteId,
  }) async {
    final toAddr = to.trim();
    if (!_isValidEmail(toAddr)) {
      throw 'Invalid recipient email';
    }
    if (cc != null && cc.trim().isNotEmpty && !_isValidEmail(cc.trim())) {
      throw 'Invalid CC email';
    }
    if (subject.trim().isEmpty) {
      throw 'Subject is required';
    }
    if (pdfBytes.length > maxAttachmentBytes) {
      throw 'Attachment too large (max ~9 MB)';
    }

    final response = await _supabase.functions.invoke(
      'send-document-email',
      body: {
        'to': toAddr,
        'cc': cc?.trim(),
        'subject': subject.trim(),
        'body': body,
        'fileName': fileName,
        'pdfBase64': base64Encode(pdfBytes),
        'docType': docType,
        if (projectId != null) 'projectId': projectId,
        if (invoiceId != null) 'invoiceId': invoiceId,
        if (quoteId != null) 'quoteId': quoteId,
      },
    );

    final data = response.data;
    if (data is Map && data['error'] != null) {
      throw data['error'].toString();
    }
  }

  static bool isValidEmail(String value) => _isValidEmail(value);

  static bool _isValidEmail(String value) {
    final v = value.trim();
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v);
  }
}
