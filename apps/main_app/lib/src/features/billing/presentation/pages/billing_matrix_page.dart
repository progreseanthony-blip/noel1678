import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/billing_controller.dart';
import '../utils/invoice_pdf_generator.dart';
import '../utils/invoice_excel_generator.dart';
import '../../../../shared/widgets/sidebar.dart';

class BillingMatrixPage extends ConsumerStatefulWidget {
  final String projectId;
  final String? invoiceId;
  final String? periodStart;
  final String? periodEnd;

  const BillingMatrixPage({
    super.key,
    required this.projectId,
    this.invoiceId,
    this.periodStart,
    this.periodEnd,
  });

  @override
  ConsumerState<BillingMatrixPage> createState() => _BillingMatrixPageState();
}

class _BillingMatrixPageState extends ConsumerState<BillingMatrixPage> {
  Map<String, dynamic>? _invoice;
  List<Map<String, dynamic>> _lines = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDirty = false;
  String? _error;
  double _retainageRate = 5.0;
  final _fmt = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      if (widget.invoiceId != null) {
        final svc = ref.read(billingServiceProvider);
        final inv = await svc.getInvoice(widget.invoiceId!);
        final details = await svc.getInvoiceDetails(widget.invoiceId!);

        if (mounted) {
          setState(() {
            _invoice = inv;
            _lines = details;
            _retainageRate = (inv['retainage_rate'] as num?)?.toDouble() ?? 5.0;
            _isLoading = false;
          });
        }
      } else if (widget.periodStart != null && widget.periodEnd != null) {
        final svc = ref.read(billingServiceProvider);
        final data = await svc.getPayApplicationData(
          projectId: widget.projectId,
          periodStart: widget.periodStart!,
          periodEnd: widget.periodEnd!,
        );

        final linesRaw = data['lines'] as List<dynamic>? ?? [];
        final loadedLines = linesRaw.cast<Map<String, dynamic>>();
        double scheduledTotal = 0;

        // Get quote_id from project
        final project = await Supabase.instance.client
            .from('projects')
            .select('quote_id')
            .eq('id', widget.projectId)
            .single();
        final quoteId = project['quote_id'] as String?;

        // Get actual scheduled values from quote_services using client-side calculation
        if (quoteId != null) {
          final qsList = await Supabase.instance.client
              .from('quote_services')
              .select()
              .eq('quote_id', quoteId)
              .order('created_at');

          for (int i = 0; i < loadedLines.length && i < qsList.length; i++) {
            final qs = qsList[i] as Map<String, dynamic>;
            final quantity = (qs['quantity'] as num?)?.toDouble() ?? 0;
            final directCost = (qs['direct_cost'] as num?)?.toDouble() ?? 0;
            final oh = (qs['overhead_percentage'] as num?)?.toDouble() ?? 0;
            final prof = (qs['profit_percentage'] as num?)?.toDouble() ?? 0;
            final base = quantity * directCost;
            final withOh = base * (1 + oh / 100);
            final sale = withOh * (1 + prof / 100);
            loadedLines[i]['scheduled_value'] = sale;
            scheduledTotal += sale;
          }
        } else {
          for (final l in loadedLines) {
            scheduledTotal += (l['scheduled_value'] as num?)?.toDouble() ?? 0;
          }
        }

        if (mounted) {
          setState(() {
            _lines = loadedLines;
            _invoice = {
              'project_id': widget.projectId,
              'period_start': widget.periodStart,
              'period_end': widget.periodEnd,
              'original_contract': data['original_contract'] ?? scheduledTotal,
              'approved_cos_total': data['approved_cos_total'] ?? 0,
              'current_contract': data['current_contract'] ?? scheduledTotal,
              'total_previous_billed': data['previous_total'] ?? 0,
              'retainage_rate': 5.0,
            };
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() { _error = 'Missing parameters'; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  double get _totalScheduled =>
      _lines.fold(0.0, (s, l) => s + ((l['scheduled_value'] as num?)?.toDouble() ?? 0));

  double get _totalThisPeriod =>
      _lines.fold(0.0, (s, l) => s + ((l['this_period_amount'] as num?)?.toDouble() ?? 0));

  double get _totalPrevious =>
      _lines.fold(0.0, (s, l) => s + ((l['previous_completed'] as num?)?.toDouble() ?? 0));

  double get _totalEquipment =>
      _lines.fold(0.0, (s, l) => s + ((l['equipment_present'] as num?)?.toDouble() ?? 0));

  double get _totalCompleted => _totalPrevious + _totalThisPeriod + _totalEquipment;

  double get _totalRetainage => _lines.fold(0.0, (s, l) {
    if (l['line_type'] == 'equipment') return s;
    final tp = (l['this_period_amount'] as num?)?.toDouble() ?? 0;
    final prev = (l['previous_completed'] as num?)?.toDouble() ?? 0;
    return s + ((tp + prev) * _retainageRate / 100);
  });

  double get _totalDue => _totalThisPeriod - _totalRetainage;
  double get _balanceToFinish => _totalScheduled - _totalCompleted;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final ctrl = ref.read(billingControllerProvider.notifier);

      if (_invoice?['id'] == null) {
        final created = await ctrl.createInvoice({
          'project_id': widget.projectId,
          'period_start': widget.periodStart,
          'period_end': widget.periodEnd,
          'original_contract': _totalScheduled,
          'approved_cos_total': _invoice?['approved_cos_total'] ?? 0,
          'total_previous_billed': _totalPrevious,
          'total_this_period': _totalThisPeriod,
          'total_retainage': _totalRetainage,
          'retainage_rate': _retainageRate,
          'created_by': Supabase.instance.client.auth.currentUser?.id,
        });
        _invoice = created;
      } else {
        await ctrl.updateInvoice(_invoice!['id'], {
          'total_this_period': _totalThisPeriod,
          'total_retainage': _totalRetainage,
          'retainage_rate': _retainageRate,
        });
      }

      // Prepare and save details
      final details = _lines.asMap().entries.map((e) {
        final l = e.value;
        return {
          'quote_service_id': l['quote_service_id'],
          'line_type': l['line_type'] ?? 'service',
          'sort_order': e.key,
          'service_name': l['service_name'] ?? '',
          'unit_of_measure': l['unit_of_measure'] ?? '',
          'scheduled_value': l['scheduled_value'] ?? 0,
          'previous_completed': l['previous_completed'] ?? 0,
          'this_period_qty': l['this_period_qty'] ?? 0,
          'this_period_amount': l['this_period_amount'] ?? 0,
          'equipment_present': l['equipment_present'] ?? 0,
          'retainage_rate': _retainageRate,
        };
      }).toList();

      await ctrl.saveInvoiceDetails(_invoice!['id'], details);
      setState(() => _isDirty = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pay Application saved', style: GoogleFonts.manrope(color: Colors.white)), backgroundColor: AppTheme.primaryGreen),
        );
      }

      // Reload to get updated computed fields
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.manrope()), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submit() async {
    if (_invoice?['id'] == null) {
      await _save();
    }
    if (_invoice?['id'] != null && mounted) {
      try {
        await ref.read(billingControllerProvider.notifier).submitInvoice(_invoice!['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pay Application submitted', style: GoogleFonts.manrope(color: Colors.white)), backgroundColor: AppTheme.primaryGreen),
          );
          context.go('/projects/${widget.projectId}/billing');
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

  Future<void> _printPdf() async {
    if (_invoice == null) return;
    final project = await Supabase.instance.client
        .from('projects')
        .select('title, client_name')
        .eq('id', widget.projectId)
        .single();

    final pdfBytes = await InvoicePdfGenerator.generate(
      invoice: _invoice!,
      lines: _lines,
      projectTitle: project['title'] ?? '',
      clientName: project['client_name'] ?? '',
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'PayApp_${_invoice?['invoice_number'] ?? 'draft'}',
    );
  }

  Future<void> _downloadExcel() async {
    if (_invoice == null) return;
    final bytes = InvoiceExcelGenerator.generate(invoice: _invoice!, lines: _lines);

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Pay Application Excel',
      fileName: 'PayApp_${_invoice?['invoice_number'] ?? 'export'}.xlsx',
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
    final isSubmitted = _invoice?['status'] == 'submitted' || _invoice?['status'] == 'paid';
    final isNew = widget.invoiceId == null;

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
                _buildTopHeader(userName, isMobile, isSubmitted, isNew),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                      : _error != null
                          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                          : _buildContent(isMobile, isSubmitted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(String userName, bool isMobile, bool isSubmitted, bool isNew) {
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
              onTap: () => context.go('/projects/${widget.projectId}/billing'),
              child: const Icon(Icons.arrow_back, size: 18, color: AppTheme.slate500),
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 8),
            Text('Billing', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate500)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.chevron_right, size: 16, color: AppTheme.slate400),
            ),
            Text(isNew ? 'New Pay Application' : _invoice?['invoice_number'] ?? '',
                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate900)),
          ],
          const Spacer(),
          if (!isSubmitted) ...[
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save, size: 18, color: Colors.white),
              label: Text('Save Draft', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _submit,
              icon: const Icon(Icons.send, size: 18, color: Colors.white),
              label: Text('Submit', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 8),
          ],
          OutlinedButton.icon(
            onPressed: _printPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
            label: Text('PDF', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              side: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _downloadExcel,
            icon: const Icon(Icons.table_chart_outlined, size: 16),
            label: Text('Excel', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
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

  Widget _buildContent(bool isMobile, bool isSubmitted) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContractSummary(isMobile, isSubmitted),
          const SizedBox(height: 24),
          _buildPayAppTable(isMobile, isSubmitted),
        ],
      ),
    );
  }

  Widget _buildContractSummary(bool isMobile, bool isSubmitted) {
    final orig = (_invoice?['original_contract'] as num?)?.toDouble() ?? _totalScheduled;
    final cosTotal = (_invoice?['approved_cos_total'] as num?)?.toDouble() ?? 0;
    final current = orig + cosTotal;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(_invoice?['invoice_number'] != null ? _invoice!['invoice_number'].toString() : 'New Application',
                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
            const Spacer(),
            Text('Retainage: ', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500)),
            if (!isSubmitted)
              SizedBox(
                width: 60,
                child: TextField(
                  controller: TextEditingController(text: _retainageRate.toString()),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(suffixText: '%', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700),
                  onChanged: (v) => setState(() { _retainageRate = double.tryParse(v) ?? 5.0; _isDirty = true; }),
                ),
              )
            else
              Text('$_retainageRate%', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500)),
          ]),
          const SizedBox(height: 12),
          _buildSummaryDetail(isMobile, orig, cosTotal, current),
        ],
      ),
    );
  }

  Widget _buildSummaryDetail(bool isMobile, double orig, double cosTotal, double current) {
    if (isMobile) {
      return Column(children: [
        _infoRow('Period:', '${_invoice?['period_start'] ?? ''} — ${_invoice?['period_end'] ?? ''}'),
        _infoRow('Original Contract:', '\$${_fmt.format(orig)}'),
        _infoRow('Approved COs:', '\$${_fmt.format(cosTotal)}'),
        _infoRow('Current Contract:', '\$${_fmt.format(current)}'),
        const Divider(height: 16),
        _infoRow('Total Previous:', '\$${_fmt.format(_totalPrevious)}'),
        _infoRow('Total This Period:', '\$${_fmt.format(_totalThisPeriod)}'),
        _infoRow('Total Completed:', '\$${_fmt.format(_totalCompleted)}'),
        const Divider(height: 16),
        _infoRow('Retainage:', '\$${_fmt.format(_totalRetainage)}'),
        _infoRow('AMOUNT DUE:', '\$${_fmt.format(_totalDue)}', bold: true, valueColor: AppTheme.primaryGreen),
        _infoRow('Balance to Finish:', '\$${_fmt.format(_balanceToFinish)}'),
      ]);
    }
    return Row(
      children: [
        Expanded(child: Column(children: [
          _infoRow('Period:', '${_invoice?['period_start'] ?? ''} — ${_invoice?['period_end'] ?? ''}'),
          _infoRow('Original Contract:', '\$${_fmt.format(orig)}'),
          _infoRow('Approved COs:', '\$${_fmt.format(cosTotal)}'),
          _infoRow('Current Contract:', '\$${_fmt.format(current)}'),
        ])),
        const SizedBox(width: 40),
        Expanded(child: Column(children: [
          _infoRow('Total Previous:', '\$${_fmt.format(_totalPrevious)}'),
          _infoRow('Total This Period:', '\$${_fmt.format(_totalThisPeriod)}'),
          _infoRow('Total Completed:', '\$${_fmt.format(_totalCompleted)}'),
        ])),
        const SizedBox(width: 40),
        Expanded(child: Column(children: [
          _infoRow('Retainage ($_retainageRate%):', '\$${_fmt.format(_totalRetainage)}'),
          _infoRow('AMOUNT DUE:', '\$${_fmt.format(_totalDue)}', bold: true, valueColor: AppTheme.primaryGreen),
          _infoRow('Balance to Finish:', '\$${_fmt.format(_balanceToFinish)}'),
        ])),
      ],
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.manrope(fontSize: 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: AppTheme.slate600)),
          Text(value, style: GoogleFonts.manrope(fontSize: 12, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: valueColor ?? AppTheme.slate900)),
        ],
      ),
    );
  }

  Widget _buildPayAppTable(bool isMobile, bool isSubmitted) {
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
            dataRowMinHeight: 40,
            dataRowMaxHeight: 60,
            headingRowHeight: 60,
            columnSpacing: 12,
            horizontalMargin: 12,
            columns: [
              DataColumn(label: _ColText('#', 10)),
              DataColumn(label: _ColText('Description', 10)),
              DataColumn(label: _ColText('Scheduled\nValue', 10), numeric: true),
              DataColumn(label: _ColText('Work Done\nThis Period', 10), numeric: true),
              DataColumn(label: _ColText('Prev.\nCompleted', 10), numeric: true),
              DataColumn(label: _ColText('Equip.\nPresent', 10), numeric: true),
              DataColumn(label: _ColText('Total\nCompleted', 10), numeric: true),
              DataColumn(label: _ColText('Balance to\nFinish', 10), numeric: true),
              DataColumn(label: _ColText('Retainage\n$_retainageRate%', 10), numeric: true),
              DataColumn(label: _ColText('Total This\nPeriod', 10), numeric: true),
            ],
            rows: _buildTableRows(isSubmitted),
          ),
        ),
      ),
    );
  }

  List<DataRow> _buildTableRows(bool isSubmitted) {
    final rows = <DataRow>[];
    double tSv = 0, tTp = 0, tPrev = 0, tEq = 0, tTc = 0, tBal = 0, tRet = 0, tThis = 0;

    for (int i = 0; i < _lines.length; i++) {
      final l = _lines[i];
      final sv = (l['scheduled_value'] as num?)?.toDouble() ?? 0;
      final tpAmt = (l['this_period_amount'] as num?)?.toDouble() ?? 0;
      final prev = (l['previous_completed'] as num?)?.toDouble() ?? 0;
      final eq = (l['equipment_present'] as num?)?.toDouble() ?? 0;
      final tc = tpAmt + prev + eq;
      final bal = sv - tc;
      final ret = l['line_type'] == 'equipment' ? 0.0 : (tpAmt + prev) * _retainageRate / 100;
      final ttp = l['line_type'] == 'equipment' ? 0.0 : (tpAmt + prev) - ret;

      tSv += sv; tTp += tpAmt; tPrev += prev; tEq += eq;
      tTc += tc; tBal += bal; tRet += ret; tThis += ttp;

      rows.add(DataRow(cells: [
        DataCell(Text('${i + 1}', style: GoogleFonts.manrope(fontSize: 11))),
        DataCell(Text(l['service_name'] ?? '', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600))),
        DataCell(Text('\$${_fmt.format(sv)}', style: GoogleFonts.manrope(fontSize: 11))),
        DataCell(
          isSubmitted
              ? Text('\$${_fmt.format(tpAmt)}', style: GoogleFonts.manrope(fontSize: 11))
              : SizedBox(
                  width: 100,
                  child: TextField(
                    controller: TextEditingController(text: tpAmt > 0 ? _fmt.format(tpAmt) : ''),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6), border: OutlineInputBorder()),
                    style: GoogleFonts.manrope(fontSize: 10),
                    onChanged: (v) {
                      final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
                      setState(() {
                        _lines[i]['this_period_amount'] = parsed;
                        _isDirty = true;
                      });
                    },
                  ),
                ),
        ),
        DataCell(Text('\$${_fmt.format(prev)}', style: GoogleFonts.manrope(fontSize: 11))),
        DataCell(
          isSubmitted
              ? Text('\$${_fmt.format(eq)}', style: GoogleFonts.manrope(fontSize: 11))
              : SizedBox(
                  width: 80,
                  child: TextField(
                    controller: TextEditingController(text: eq > 0 ? _fmt.format(eq) : ''),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6), border: OutlineInputBorder()),
                    style: GoogleFonts.manrope(fontSize: 10),
                    onChanged: (v) {
                      final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
                      setState(() {
                        _lines[i]['equipment_present'] = parsed;
                        _isDirty = true;
                      });
                    },
                  ),
                ),
        ),
        DataCell(Text('\$${_fmt.format(tc)}', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700))),
        DataCell(Text('\$${_fmt.format(bal)}', style: GoogleFonts.manrope(fontSize: 11))),
        DataCell(Text('\$${_fmt.format(ret)}', style: GoogleFonts.manrope(fontSize: 11))),
        DataCell(Text('\$${_fmt.format(ttp)}', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen))),
      ]));
    }

    // Totals row
    rows.add(DataRow(
      color:       WidgetStateProperty.all(AppTheme.slate50),
      cells: [
        const DataCell(Text('')),
        DataCell(Text('TOTALS', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800))),
        DataCell(Text('\$${_fmt.format(tSv)}', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700))),
        DataCell(Text('\$${_fmt.format(tTp)}', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700))),
        DataCell(Text('\$${_fmt.format(tPrev)}', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700))),
        DataCell(Text('\$${_fmt.format(tEq)}', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700))),
        DataCell(Text('\$${_fmt.format(tTc)}', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800))),
        DataCell(Text('\$${_fmt.format(tBal)}', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700))),
        DataCell(Text('\$${_fmt.format(tRet)}', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700))),
        DataCell(Text('\$${_fmt.format(tThis)}', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen))),
      ],
    ));

    return rows;
  }
}

class _ColText extends StatelessWidget {
  final String text;
  final double fontSize;
  const _ColText(this.text, this.fontSize);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: fontSize, height: 1.3));
  }
}
