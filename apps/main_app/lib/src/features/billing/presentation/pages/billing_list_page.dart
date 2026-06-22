import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../providers/billing_providers.dart';
import '../utils/invoice_pdf_generator.dart';
import '../utils/invoice_excel_generator.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../../shared/widgets/sidebar.dart';

class BillingListPage extends ConsumerStatefulWidget {
  final String projectId;

  const BillingListPage({super.key, required this.projectId});

  @override
  ConsumerState<BillingListPage> createState() => _BillingListPageState();
}

class _BillingListPageState extends ConsumerState<BillingListPage> {
  final _fmt = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
  }

  Future<void> _newInvoice() async {
    DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: DateTime.now().subtract(const Duration(days: 30)), end: DateTime.now()),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primaryGreen, brightness: Brightness.light),
        ),
        child: child!,
      ),
    );

    if (range != null && mounted) {
      context.go('/projects/${widget.projectId}/billing/new', extra: {
        'periodStart': DateFormat('yyyy-MM-dd').format(range.start),
        'periodEnd': DateFormat('yyyy-MM-dd').format(range.end),
      });
    }
  }

  Future<void> _printPdf(Map<String, dynamic> invoice) async {
    final details = (invoice['details'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final project = await Supabase.instance.client
        .from('projects')
        .select('title, client_name')
        .eq('id', widget.projectId)
        .single();

    final pdfBytes = await InvoicePdfGenerator.generate(
      invoice: invoice,
      lines: details,
      projectTitle: project['title'] ?? '',
      clientName: project['client_name'] ?? '',
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Invoice_${invoice['invoice_number'] ?? invoice['id']}',
    );
  }

  Future<void> _downloadExcel(Map<String, dynamic> invoice) async {
    final details = (invoice['details'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final bytes = InvoiceExcelGenerator.generate(invoice: invoice, lines: details);

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Pay Application Excel',
      fileName: 'PayApp_${invoice['invoice_number'] ?? 'export'}.xlsx',
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (path != null) {
      await File(path).writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to $path', style: GoogleFonts.manrope(color: Colors.white)), backgroundColor: AppTheme.primaryGreen),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userName = currentUser?.userMetadata?['name'] ?? 'Admin';
    final userEmail = currentUser?.email ?? '';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1250;

    final invAsync = ref.watch(invoiceListProvider(widget.projectId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      drawer: isMobile ? Sidebar(userName: userName, userEmail: userEmail, currentPath: '/projects/${widget.projectId}/billing', onLogout: () async {
        await Supabase.instance.client.auth.signOut();
        if (context.mounted) context.go('/signin');
      }) : null,
      body: Row(
        children: [
          if (!isMobile)
            Sidebar(userName: userName, userEmail: userEmail, currentPath: '/projects/${widget.projectId}/billing', onLogout: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/signin');
            }),
          Expanded(
            child: Column(
              children: [
                _buildTopHeader(userName, isMobile),
                Expanded(child: invAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
                  error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
                  data: (invoices) => _buildContent(invoices, isMobile),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(String userName, bool isMobile) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppTheme.slate200))),
      child: Row(
        children: [
          if (isMobile)
            Builder(builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: AppTheme.slate700),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            )),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/projects/${widget.projectId}'),
              child: const Icon(Icons.arrow_back, size: 18, color: AppTheme.slate500),
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 8),
            Text('Project', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate500, fontWeight: FontWeight.w500)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.chevron_right, size: 16, color: AppTheme.slate400),
            ),
            Flexible(
              child: Text('Billing', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate900, fontWeight: FontWeight.w700)),
            ),
          ],
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _newInvoice,
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: Text('New Pay Application', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> invoices, bool isMobile) {
    if (invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.slate200),
            const SizedBox(height: 16),
            Text('No Pay Applications yet', style: GoogleFonts.manrope(fontSize: 16, color: AppTheme.slate500)),
            const SizedBox(height: 8),
            Text('Create a new Pay Application to start billing', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate400)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${invoices.length} Pay Application${invoices.length != 1 ? 's' : ''}',
              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate600)),
          const SizedBox(height: 16),
          if (isMobile)
            Column(children: invoices.map((inv) => _invoiceCard(inv)).toList())
          else
            _invoiceTable(invoices),
        ],
      ),
    );
  }

  Widget _invoiceCard(Map<String, dynamic> inv) {
    final status = inv['status']?.toString() ?? 'draft';
    final due = (inv['total_due'] as num?)?.toDouble() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(inv['invoice_number'] ?? '', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.slate900))),
            _statusBadge(status),
          ]),
          const SizedBox(height: 4),
          Text('Due: \$${_fmt.format(due)}', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
          Text('${inv['period_start'] ?? ''} — ${inv['period_end'] ?? ''}', style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate500)),
          const SizedBox(height: 8),
          Row(children: [
            if (status == 'draft')
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/projects/${widget.projectId}/billing/${inv['id']}'),
                  child: const Text('Edit'),
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _printPdf(inv),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 14),
                label: const Text('PDF'),
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _downloadExcel(inv),
                icon: const Icon(Icons.table_chart_outlined, size: 14),
                label: const Text('Excel'),
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _invoiceTable(List<Map<String, dynamic>> invoices) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            dataRowMinHeight: 48,
            dataRowMaxHeight: 56,
            headingRowHeight: 44,
            columns: const [
              DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
              DataColumn(label: Text('Period', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
              DataColumn(label: Text('Total Due', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), numeric: true),
              DataColumn(label: Text('Balance', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), numeric: true),
              DataColumn(label: Text('', style: TextStyle(fontSize: 12))),
              DataColumn(label: Text('', style: TextStyle(fontSize: 12))),
              DataColumn(label: Text('', style: TextStyle(fontSize: 12))),
            ],
            rows: invoices.map((inv) {
              final status = inv['status']?.toString() ?? 'draft';
              final due = (inv['total_due'] as num?)?.toDouble() ?? 0;
              final bal = (inv['balance_to_finish'] as num?)?.toDouble() ?? 0;
              return DataRow(
                onSelectChanged: (_) => context.go('/projects/${widget.projectId}/billing/${inv['id']}'),
                cells: [
                  DataCell(Text(inv['invoice_number'] ?? '', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 12))),
                  DataCell(Text('${inv['period_start'] ?? ''} — ${inv['period_end'] ?? ''}', style: GoogleFonts.manrope(fontSize: 11))),
                  DataCell(_statusBadge(status)),
                  DataCell(Text('\$${_fmt.format(due)}', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700))),
                  DataCell(Text('\$${_fmt.format(bal)}', style: GoogleFonts.manrope(fontSize: 12))),
                  DataCell(IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppTheme.primaryGreen),
                    onPressed: () => _printPdf(inv),
                  )),
                  DataCell(IconButton(
                    icon: const Icon(Icons.table_chart_outlined, size: 18, color: AppTheme.primaryGreen),
                    onPressed: () => _downloadExcel(inv),
                  )),
                  DataCell(Icon(Icons.chevron_right, size: 18, color: AppTheme.slate400)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'paid':
        color = AppTheme.primaryGreen;
        break;
      case 'cancelled':
        color = AppTheme.errorRed;
        break;
      case 'submitted':
        color = const Color(0xFFF59E0B);
        break;
      default:
        color = AppTheme.slate400;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(5)),
      child: Text(status.toUpperCase(), style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }
}
