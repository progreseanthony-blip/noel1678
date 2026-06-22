import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../providers/change_order_providers.dart';
import '../providers/change_order_controller.dart';
import '../utils/change_order_pdf_generator.dart';
import '../../../../shared/widgets/sidebar.dart';

class ChangeOrderDetailPage extends ConsumerStatefulWidget {
  final String projectId;
  final String coId;

  const ChangeOrderDetailPage({super.key, required this.projectId, required this.coId});

  @override
  ConsumerState<ChangeOrderDetailPage> createState() => _ChangeOrderDetailPageState();
}

class _ChangeOrderDetailPageState extends ConsumerState<ChangeOrderDetailPage> {
  final _fmt = NumberFormat('#,##0.00', 'en_US');
  String? _rejectionReason;
  Map<String, dynamic>? _cachedCo;
  List<Map<String, dynamic>> _cachedDetails = [];

  Future<void> _printPdf(Map<String, dynamic> co, List<Map<String, dynamic>> details) async {
    final project = await Supabase.instance.client
        .from('projects')
        .select('title, client_name')
        .eq('id', widget.projectId)
        .single();

    final pdfBytes = await ChangeOrderPdfGenerator.generate(
      changeOrder: co,
      details: details,
      projectTitle: project['title'] ?? '',
      clientName: project['client_name'] ?? '',
      projectAddress: '',
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'CO_${co['co_number'] ?? widget.coId}',
    );
  }

  Future<void> _approve() async {
    try {
      await ref.read(changeOrderControllerProvider.notifier).approveChangeOrder(widget.coId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Change Order approved', style: GoogleFonts.manrope(color: Colors.white)), backgroundColor: AppTheme.primaryGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.manrope()), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  Future<void> _reject() async {
    final reason = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Change Order', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
        content: TextField(
          decoration: const InputDecoration(labelText: 'Rejection Reason'),
          onChanged: (v) => _rejectionReason = v,
          style: GoogleFonts.manrope(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(_rejectionReason ?? 'No reason provided'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: Text('Reject', style: GoogleFonts.manrope(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reason != null && mounted) {
      try {
        await ref.read(changeOrderControllerProvider.notifier).rejectChangeOrder(widget.coId, reason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Change Order rejected', style: GoogleFonts.manrope(color: Colors.white)), backgroundColor: AppTheme.errorRed),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e', style: GoogleFonts.manrope()), backgroundColor: AppTheme.errorRed),
          );
        }
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

    final coAsync = ref.watch(changeOrderDetailProvider(widget.coId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      drawer: isMobile ? Sidebar(userName: userName, userEmail: userEmail, currentPath: '/projects/${widget.projectId}/change-orders', onLogout: () async {
        await Supabase.instance.client.auth.signOut();
        if (context.mounted) context.go('/signin');
      }) : null,
      body: Row(
        children: [
          if (!isMobile)
            Sidebar(userName: userName, userEmail: userEmail, currentPath: '/projects/${widget.projectId}/change-orders', onLogout: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/signin');
            }),
          Expanded(
            child: Column(
              children: [
                _buildTopHeader(userName, isMobile),
                Expanded(
                  child: coAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
                    error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
                    data: (co) {
          _cachedCo = co;
          _cachedDetails = (co['details'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
          return _buildContent(co, isMobile);
        },
                  ),
                ),
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
              onTap: () => context.go('/projects/${widget.projectId}/change-orders'),
              child: const Icon(Icons.arrow_back, size: 18, color: AppTheme.slate500),
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 8),
            Text('Change Orders', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate500)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.chevron_right, size: 16, color: AppTheme.slate400),
            ),
            Text('Detail', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate900)),
          ],
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {
              if (_cachedCo != null) _printPdf(_cachedCo!, _cachedDetails);
            },
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
            label: Text('PDF', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              side: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> co, bool isMobile) {
    final details = (co['details'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final status = co['status']?.toString() ?? 'draft';
    final adj = (co['adjustment_amount'] as num?)?.toDouble() ?? 0;
    final orig = (co['original_contract_amount'] as num?)?.toDouble() ?? 0;
    final newCt = (co['new_contract_amount'] as num?)?.toDouble() ?? 0;
    final sched = (co['schedule_days_change'] as num?)?.toInt() ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 20 : 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(co['co_number'] ?? '', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
                  const SizedBox(width: 12),
                  _statusBadge(status),
                ]),
                const SizedBox(height: 12),
                Text(co['title'] ?? '', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                const SizedBox(height: 8),
                if (co['description'] != null && (co['description'] as String).isNotEmpty)
                  Text(co['description'], style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFE2E8F0)),
                  ),
                  child: isMobile
                      ? Column(children: [
                          _infoRow('Original Contract', '\$${_fmt.format(orig)}'),
                          _infoRow('Adjustment', '\$${_fmt.format(adj)}', valueColor: adj >= 0 ? AppTheme.primaryGreen : AppTheme.errorRed),
                          const Divider(height: 16),
                          _infoRow('New Contract', '\$${_fmt.format(newCt)}', bold: true),
                          _infoRow('Schedule Change', sched >= 0 ? '+$sched days' : '$sched days'),
                        ])
                      : Row(children: [
                          Expanded(child: _infoRow('Original Contract', '\$${_fmt.format(orig)}')),
                                          const SizedBox(width: 24),
                          Expanded(child: _infoRow('Adjustment', '\$${_fmt.format(adj)}', valueColor: adj >= 0 ? AppTheme.primaryGreen : AppTheme.errorRed)),
                          const SizedBox(width: 24),
                          Expanded(child: _infoRow('New Contract', '\$${_fmt.format(newCt)}', bold: true)),
                          const SizedBox(width: 24),
                          Expanded(child: _infoRow('Schedule', sched >= 0 ? '+$sched days' : '$sched days')),
                        ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (details.isNotEmpty)
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Details', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
                  const SizedBox(height: 16),
                  if (isMobile)
                    Column(children: details.asMap().entries.map((e) => _detailCard(e.key, e.value)).toList())
                  else
                    _detailsTable(details),
                ],
              ),
            ),
          if (status == 'submitted') ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _approve,
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: Text('Approve', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _reject,
                    icon: const Icon(Icons.cancel_outlined, color: Colors.white),
                    label: Text('Reject', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorRed,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (status == 'rejected' && co['rejection_reason'] != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.errorRed.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rejection Reason', style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.errorRed)),
                  const SizedBox(height: 4),
                  Text(co['rejection_reason'], style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate700)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.manrope(fontSize: 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: AppTheme.slate600)),
          Text(value, style: GoogleFonts.manrope(fontSize: 12, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: valueColor ?? AppTheme.slate900)),
        ],
      ),
    );
  }

  Widget _detailsTable(List<Map<String, dynamic>> details) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
          DataColumn(label: Text('Service', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
          DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
          DataColumn(label: Text('Qty', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), numeric: true),
          DataColumn(label: Text('Unit Price', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), numeric: true),
          DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), numeric: true),
        ],
        rows: details.asMap().entries.map((e) {
          final i = e.key + 1;
          final d = e.value;
          final qty = (d['quantity_change'] as num?)?.toDouble() ?? 0;
          final up = (d['unit_price'] as num?)?.toDouble() ?? 0;
          return DataRow(cells: [
            DataCell(Text('$i', style: GoogleFonts.manrope(fontSize: 12))),
            DataCell(Text(d['service_name'] ?? '', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600))),
            DataCell(Text(d['line_type']?.toString().replaceAll('_', ' ') ?? '', style: GoogleFonts.manrope(fontSize: 11))),
            DataCell(Text(qty.toString(), style: GoogleFonts.manrope(fontSize: 12))),
            DataCell(Text('\$${_fmt.format(up)}', style: GoogleFonts.manrope(fontSize: 12))),
            DataCell(Text('\$${_fmt.format(qty * up)}', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _detailCard(int i, Map<String, dynamic> d) {
    final qty = (d['quantity_change'] as num?)?.toDouble() ?? 0;
    final up = (d['unit_price'] as num?)?.toDouble() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.slate50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${i + 1}. ${d['service_name'] ?? ''}', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          Text('${d['line_type']?.toString().replaceAll('_', ' ') ?? ''} | Qty: $qty | \$${_fmt.format(up)} ea. | Total: \$${_fmt.format(qty * up)}',
              style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate500)),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = AppTheme.primaryGreen;
        break;
      case 'rejected':
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
