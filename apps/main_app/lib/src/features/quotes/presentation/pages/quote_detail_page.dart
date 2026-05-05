import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../../projects/services/project_service.dart';
import '../widgets/quote_form_dialog.dart';
import '../widgets/service_estimation_dialog.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../utils/quote_pdf_generator.dart';

class QuoteDetailPage extends ConsumerStatefulWidget {
  final String quoteId;
  const QuoteDetailPage({super.key, required this.quoteId});
  @override
  ConsumerState<QuoteDetailPage> createState() => _QuoteDetailPageState();
}

class _QuoteDetailPageState extends ConsumerState<QuoteDetailPage> {
  Map<String, dynamic>? _quote;
  List<Map<String, dynamic>> _services = [];
  Map<String, List<Map<String, dynamic>>> _machineries = {};
  Map<String, List<Map<String, dynamic>>> _labors = {};
  Map<String, List<Map<String, dynamic>>> _materials = {};
  Map<String, List<Map<String, dynamic>>> _instruments = {};
  Map<String, Map<String, dynamic>> _estimations = {};
  bool _isLoading = true;
  bool _isConverting = false;
  String? _error;

  final _fmt = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final sb = Supabase.instance.client;

      final quoteData = await sb.from('quotes').select().eq('id', widget.quoteId).single();
      final servicesData = await sb.from('quote_services').select().eq('quote_id', widget.quoteId).order('created_at');

      final machMap = <String, List<Map<String, dynamic>>>{};
      final laborMap = <String, List<Map<String, dynamic>>>{};
      final materialMap = <String, List<Map<String, dynamic>>>{};
      final instrumentMap = <String, List<Map<String, dynamic>>>{};
      final estMap = <String, Map<String, dynamic>>{};

      for (final svc in servicesData) {
        final svcId = svc['id'] as String;
        final machRaw = await sb.from('quote_service_machineries').select().eq('quote_service_id', svcId);
        machMap[svcId] = List<Map<String, dynamic>>.from(machRaw);
        final laborRaw = await sb.from('quote_service_labors').select().eq('quote_service_id', svcId);
        laborMap[svcId] = List<Map<String, dynamic>>.from(laborRaw);
        
        // Fetch materials
        final materialRaw = await sb.from('quote_service_materials').select().eq('quote_service_id', svcId);
        materialMap[svcId] = List<Map<String, dynamic>>.from(materialRaw);

        // Fetch instruments
        final instrumentRaw = await sb.from('quote_service_instruments').select().eq('quote_service_id', svcId);
        instrumentMap[svcId] = List<Map<String, dynamic>>.from(instrumentRaw);

        // Fetch estimation
        final estData = await sb.from('quote_service_estimations').select().eq('quote_service_id', svcId).maybeSingle();
        if (estData != null) {
          estMap[svcId] = estData;
        }
      }

      if (mounted) {
        setState(() {
          _quote = quoteData;
          _services = List<Map<String, dynamic>>.from(servicesData);
          _machineries = machMap;
          _labors = laborMap;
          _materials = materialMap;
          _instruments = instrumentMap;
          _estimations = estMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }
  Future<void> _generateAndPrintPdf() async {
    if (_quote == null) return;

    double grandTotal = 0;
    Map<String, Map<String, double>> serviceTotals = {};
    
    for (final svc in _services) {
      final t = _svcTotals(svc['id'], svc);
      serviceTotals[svc['id']] = t;
      grandTotal += t['sale'] ?? 0.0;
    }

    final pdfBytes = await QuotePdfGenerator.generate(
      quote: _quote!,
      services: _services,
      serviceTotals: serviceTotals,
      grandTotal: grandTotal,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Estimate_${_quote?['id'].toString().substring(0, 8) ?? '0000'}',
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 24),
            const SizedBox(width: 10),
            Text('Delete Estimation', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${_quote?['title']}"?\n\nThis will permanently remove all services, machinery, and labor data.',
          style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate700, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppTheme.slate500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client.from('quotes').delete().eq('id', widget.quoteId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Estimation deleted', style: GoogleFonts.manrope(color: Colors.white)), backgroundColor: AppTheme.primaryGreen),
          );
          context.go('/quotes');
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

  Future<void> _approveAndCreateProject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.rocket_launch, color: AppTheme.primaryGreen, size: 24),
            const SizedBox(width: 10),
            Text('Start Project', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Are you sure you want to approve this estimate?\n\nThis will convert it into an active project and generate the machinery reception list.',
          style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate700, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppTheme.slate500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Approve & Start', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isConverting = true);
    try {
      await ProjectService.convertQuoteToProject(widget.quoteId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project successfully created!', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.primaryGreen,
          )
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.manrope()), backgroundColor: AppTheme.errorRed)
        );
      }
    } finally {
      if (mounted) setState(() => _isConverting = false);
    }
  }

  // ── Calculation helpers ──
  double _machRatePerHour(Map<String, dynamic> m) => _d(m, 'monthly_rent_cost') / 160;
  double _machHoursPerMonth(Map<String, dynamic> m) => _d(m, 'months_to_use') * _d(m, 'quantity') * 220;
  double _machTotalRent(Map<String, dynamic> m) => _machRatePerHour(m) * _machHoursPerMonth(m);
  double _machTotalGallons(Map<String, dynamic> m) => _machHoursPerMonth(m) * _d(m, 'gallons_per_hour');
  double _machTotalGasCost(Map<String, dynamic> m) => _machTotalGallons(m) * _d(m, 'gallon_cost');
  double _machTotal(Map<String, dynamic> m) => _machTotalRent(m) + _machTotalGasCost(m);

  double _laborHoursPerMonth(Map<String, dynamic> l) => _d(l, 'months_to_work') * 220 * _d(l, 'employees_quantity');
  double _laborTotalPay(Map<String, dynamic> l) => _laborHoursPerMonth(l) * _d(l, 'hourly_rate');
  double _laborTotalPerDiem(Map<String, dynamic> l) => _laborHoursPerMonth(l) * _d(l, 'per_diem');
  double _laborTotal(Map<String, dynamic> l) => _laborTotalPay(l) + _laborTotalPerDiem(l);
  double _matTotal(Map<String, dynamic> m) => _d(m, 'quantity') * _d(m, 'unit_price');

  double _d(Map<String, dynamic> m, String k) => (m[k] as num?)?.toDouble() ?? 0;

  Map<String, double> _svcTotals(String svcId, Map<String, dynamic> svc) {
    final mList = _machineries[svcId] ?? [];
    final lList = _labors[svcId] ?? [];
    final matList = _materials[svcId] ?? [];
    final instList = _instruments[svcId] ?? [];

    final totalMach = mList.fold(0.0, (s, m) => s + _machTotalRent(m));
    final totalGas = mList.fold(0.0, (s, m) => s + _machTotalGasCost(m));
    final totalLabor = lList.fold(0.0, (s, l) => s + _laborTotalPay(l));
    final totalPD = lList.fold(0.0, (s, l) => s + _laborTotalPerDiem(l));
    final totalMats = matList.fold(0.0, (s, m) => s + _matTotal(m));
    final totalInst = instList.fold(0.0, (s, i) => s + (_d(i, 'quantity') * _d(i, 'unit_price')));

    final isStaffing = _quote?['quote_type'] == 'staffing';
    final isLS = (svc['unit_of_measure'] ?? svc['unit'] ?? '').toString().toLowerCase() == 'ls' || isStaffing;
    final direct = _d(svc, 'direct_cost');
    final qty = _d(svc, 'quantity');
    final sub = isLS ? (qty * direct) : (totalMach + totalGas + totalLabor + totalPD + totalMats + totalInst);
    final ohPct = _d(svc, 'overhead_percentage');
    final profPct = _d(svc, 'profit_percentage');

    final oh = sub * (ohPct / 100);
    final plusOh = sub + oh;
    final prof = plusOh * (profPct / 100);
    final sale = plusOh + prof;

    final unitP = qty > 0 ? sale / qty : 0.0;

    return {
      'totalMach': totalMach,
      'totalGas': totalGas,
      'totalLabor': totalLabor,
      'totalPD': totalPD,
      'totalMats': totalMats,
      'totalInst': totalInst,
      'direct': direct,
      'sub': sub,
      'oh': oh,
      'plusOh': plusOh,
      'prof': prof,
      'sale': sale,
      'unitP': unitP,
    };
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userName = currentUser?.userMetadata?['name'] ?? 'Admin User';
    final userEmail = currentUser?.email ?? '';

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 1250;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      drawer: isMobile ? Sidebar(
        userName: userName,
        userEmail: userEmail,
        currentPath: '/quotes',
        onLogout: () async {
          await Supabase.instance.client.auth.signOut();
          if (context.mounted) context.go('/signin');
        },
      ) : null,
      body: Row(
        children: [
          if (!isMobile) Sidebar(
            userName: userName,
            userEmail: userEmail,
            currentPath: '/quotes',
            onLogout: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/signin');
            },
          ),
          Expanded(
            child: Column(
              children: [
                _buildTopHeader(userName, isMobile),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen, strokeWidth: 3))
                      : _error != null
                          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                          : _buildContent(isMobile),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  TOP HEADER
  // ══════════════════════════════════════════════════════════════
  Widget _buildTopHeader(String userName, bool isMobile) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppTheme.slate200))),
      child: Row(
        children: [
          if (isMobile) ...[
            Builder(builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: AppTheme.slate700),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            )),
            const SizedBox(width: 8),
          ],
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/quotes'),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back, size: 18, color: AppTheme.slate500),
                  if (!isMobile) ...[
                    const SizedBox(width: 8),
                    Text('Estimates', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate500, fontWeight: FontWeight.w500)),
                  ],
                ],
              ),
            ),
          ),
          if (!isMobile) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.chevron_right, size: 16, color: AppTheme.slate400),
            ),
            Flexible(
              child: Text(
                _quote?['title'] ?? '', 
                style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate900, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(_quote?['title'] ?? '', style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate900, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
              ),
            ),
          if (!isMobile) ...[
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(userName, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate900)),
                Text('Active User', style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate500)),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: AppTheme.slate200, shape: BoxShape.circle, border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2))),
              child: Center(child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate700))),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  MAIN CONTENT
  // ══════════════════════════════════════════════════════════════
  Widget _buildContent(bool isMobile) {
    final title = _quote?['title'] ?? '';
    final status = (_quote?['status'] ?? 'draft').toString();
    final date = _quote?['created_at'] != null
        ? DateFormat('MMMM dd, yyyy – HH:mm').format(DateTime.parse(_quote!['created_at']).toLocal())
        : '-';

    double grandTotal = 0;
    double totalOverhead = 0;
    double totalProfit = 0;
    double totalSubTotal = 0;
    for (final svc in _services) {
      final t = _svcTotals(svc['id'], svc);
      grandTotal += t['sale']!;
      totalOverhead += t['oh']!;
      totalProfit += t['prof']!;
      totalSubTotal += t['sub']!;
    }

    final ohPct = totalSubTotal > 0 ? (totalOverhead / totalSubTotal) * 100 : 0.0;
    final prPct = totalSubTotal > 0 ? (totalProfit / totalSubTotal) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header Card (Sticky) ──
        Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24).copyWith(bottom: 0),
          child: Container(
            padding: EdgeInsets.all(isMobile ? 20 : 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: isMobile 
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.request_quote_rounded, color: AppTheme.primaryGreen, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
                              const SizedBox(height: 4),
                              _statusBadge(status),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('GRAND TOTAL', style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.slate500)),
                            Text('\$${_fmt.format(grandTotal)}', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen)),
                            const SizedBox(height: 4),
                            Text('Sub Total: \$${_fmt.format(totalSubTotal)}', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate600)),
                            Text('OH: \$${_fmt.format(totalOverhead)} (${ohPct.toStringAsFixed(1)}%) | Prof: \$${_fmt.format(totalProfit)} (${prPct.toStringAsFixed(1)}%)', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.slate500)),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _generateAndPrintPdf(),
                              icon: const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.primaryGreen),
                            ),
                            IconButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  barrierColor: Colors.black.withOpacity(0.2),
                                  builder: (_) => QuoteFormDialog(quoteToEdit: _quote),
                                ).then((updated) { if (updated == true) _loadData(); });
                              },
                              icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryGreen),
                            ),
                            IconButton(
                              onPressed: () => _confirmDelete(),
                              icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (status.toLowerCase() != 'accepted') ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isConverting ? null : _approveAndCreateProject,
                          icon: _isConverting 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.rocket_launch, color: Colors.white, size: 18),
                          label: Text('Approve & Start Project', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.request_quote_rounded, color: AppTheme.primaryGreen, size: 28),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              Text(
                                title, 
                                style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                              ),
                              _statusBadge(status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Created on $date', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate500)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // ── Grand Total ──
                    Flexible(
                      flex: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            Text('GRAND TOTAL', style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppTheme.slate500)),
                            const SizedBox(height: 2),
                            Text('\$${_fmt.format(grandTotal)}', style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen)),
                            const SizedBox(height: 4),
                            Text('Sub Total: \$${_fmt.format(totalSubTotal)}', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.slate600)),
                            Text('OH: \$${_fmt.format(totalOverhead)} (${ohPct.toStringAsFixed(1)}%) | Prof: \$${_fmt.format(totalProfit)} (${prPct.toStringAsFixed(1)}%)', textAlign: TextAlign.center, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate500)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    barrierColor: Colors.black.withOpacity(0.2),
                                    builder: (_) => QuoteFormDialog(quoteToEdit: _quote),
                                  ).then((updated) { if (updated == true) _loadData(); });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen,
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryGreen.withOpacity(0.25),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.edit_outlined, color: Color(0xFF0F172A), size: 20),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Edit Estimate',
                                        style: GoogleFonts.manrope(
                                          color: const Color(0xFF0F172A),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => _confirmDelete(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorRed.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.errorRed.withOpacity(0.2)),
                                  ),
                                  child: const Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => _generateAndPrintPdf(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.primaryGreen, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Export to PDF',
                                    style: GoogleFonts.manrope(
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (status.toLowerCase() != 'accepted') ...[
                          const SizedBox(height: 8),
                          MouseRegion(
                            cursor: _isConverting ? SystemMouseCursors.basic : SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _isConverting ? null : _approveAndCreateProject,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [AppTheme.primaryGreen, Color(0xFF0D9488)]),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isConverting)
                                      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    else
                                      const Icon(Icons.rocket_launch, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Approve & Start Project',
                                      style: GoogleFonts.manrope(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
          ),
        ),
        
        // ── Services (Scrollable) ──
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_services.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.slate200)),
                    child: Center(child: Text('No services added to this estimation yet.', style: GoogleFonts.manrope(color: AppTheme.slate500, fontSize: 14))),
                  )
                else
                  ..._services.asMap().entries.map((e) => _buildServiceSection(e.key, e.value, isMobile)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  SERVICE SECTION
  // ══════════════════════════════════════════════════════════════
  Widget _buildServiceSection(int index, Map<String, dynamic> svc, bool isMobile) {
    final svcId = svc['id'] as String;
    final isStaffing = _quote?['quote_type'] == 'staffing';
    final name = svc['name'] ?? (isStaffing ? 'Role ${index + 1}' : 'Service ${index + 1}');
    final unit = (svc['unit_of_measure'] ?? svc['unit'] ?? 'und').toString();
    final qty = _d(svc, 'quantity');
    final isLS = unit.toLowerCase() == 'ls' || isStaffing;
    final mList = _machineries[svcId] ?? [];
    final lList = _labors[svcId] ?? [];
    final totals = _svcTotals(svcId, svc);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Service Title Bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            ),
            child: isMobile 
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(5)),
                          child: Text('#${index + 1}', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(name, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _infoChipDark('Qty', qty.toString()),
                          const SizedBox(width: 8),
                          _infoChipDark('Unit', unit),
                          const SizedBox(width: 8),
                          _buildEstimationSummaryBoxes(svcId),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(5)),
                      child: Text('#${index + 1}', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(name, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
                    _infoChipDark('Quantity', qty.toString()),
                    const SizedBox(width: 8),
                    _infoChipDark('Unit', unit),
                    const SizedBox(width: 8),
                    _infoChipDark('OH%', '${_d(svc, 'overhead_percentage')}%'),
                    const SizedBox(width: 8),
                    _infoChipDark('Profit%', '${_d(svc, 'profit_percentage')}%'),
                    const SizedBox(width: 12),
                    _buildEstimationSummaryBoxes(svcId),
                  ],
                ),
          ),

          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isLS) ...[
                  // ── Machinery ──
                  _tableTitle(Icons.construction, 'Machinery', mList.length),
                  const SizedBox(height: 12),
                  if (mList.isEmpty)
                    _emptyPlaceholder('No machinery assigned')
                  else if (isMobile)
                    Column(children: mList.map((m) => _buildMachineryCard(m)).toList())
                  else
                    _buildMachineryTable(mList),

                  const SizedBox(height: 28),

                  // ── Labor ──
                  _tableTitle(Icons.engineering, 'Labor', lList.length),
                  const SizedBox(height: 12),
                  if (lList.isEmpty)
                    _emptyPlaceholder('No labor assigned')
                  else if (isMobile)
                    Column(children: lList.map((l) => _buildLaborCard(l)).toList())
                  else
                    _buildLaborTable(lList),

                  const SizedBox(height: 28),

                  // ── Materials ──
                  _tableTitle(Icons.inventory_2_outlined, 'Materials', ( _materials[svcId] ?? []).length),
                  const SizedBox(height: 12),
                  if ((_materials[svcId] ?? []).isEmpty)
                    _emptyPlaceholder('No materials assigned')
                  else if (isMobile)
                    Column(children: (_materials[svcId] ?? []).map((m) => _buildMaterialCard(m)).toList())
                  else
                    _buildMaterialsTable(_materials[svcId] ?? []),

                  const SizedBox(height: 28),
                ],

                // ── Financial Summary ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _summaryTitle('Financial Summary'),
                      const SizedBox(height: 16),
                      isMobile 
                        ? Column(
                            children: [
                              if (isLS)
                                _summaryLine('Direct Cost', totals['direct']!)
                              else ...[
                                _summaryLine('Total Machinery', totals['totalMach']!),
                                _summaryLine('Total Gasoline', totals['totalGas']!),
                                _summaryLine('Total Labor', totals['totalLabor']!),
                                _summaryLine('Total Per Diem', totals['totalPD']!),
                                _summaryLine('Total Materials', totals['totalMats']!),
                                _summaryLine('Total Instruments', totals['totalInst']!),
                              ],
                              const Divider(height: 24),
                              _summaryLine('Overhead (${_d(svc, 'overhead_percentage')}%)', totals['oh']!),
                              _summaryLine('Profit (${_d(svc, 'profit_percentage')}%)', totals['prof']!),
                              const Divider(height: 24),
                              _summaryLine('Sale Total', totals['sale']!, bold: true, highlight: true),
                              _summaryLine('Unit Price', totals['unitP']!),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    if (isLS)
                                      _summaryLine('Direct Cost', totals['direct']!)
                                    else ...[
                                      _summaryLine('Total Machinery', totals['totalMach']!),
                                      _summaryLine('Total Gasoline', totals['totalGas']!),
                                      _summaryLine('Total Labor', totals['totalLabor']!),
                                      _summaryLine('Total Per Diem', totals['totalPD']!),
                                      _summaryLine('Total Instruments', totals['totalInst']!),
                                    ],
                                    const Divider(height: 20),
                                    _summaryLine('Sub Total', totals['sub']!, bold: true),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 40),
                              Expanded(
                                child: Column(
                                  children: [
                                    _summaryLine('Overhead (${_d(svc, 'overhead_percentage')}%)', totals['oh']!),
                                    _summaryLine('Total + Overhead', totals['plusOh']!),
                                    _summaryLine('Profit (${_d(svc, 'profit_percentage')}%)', totals['prof']!),
                                    const Divider(height: 20),
                                    _summaryLine('Sale Total', totals['sale']!, bold: true, highlight: true),
                                    _summaryLine('Unit Price', totals['unitP']!),
                                  ],
                                ),
                              ),
                            ],
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMachineryCard(Map<String, dynamic> m) {
    final bool isPrimary = m['is_primary_mover'] as bool? ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.white : AppTheme.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPrimary ? AppTheme.primaryGreen.withOpacity(0.3) : AppTheme.slate200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(isPrimary ? Icons.star : Icons.build_circle, size: 16, color: isPrimary ? AppTheme.primaryGreen : AppTheme.slate500),
              const SizedBox(width: 8),
              Expanded(child: Text(m['machine_name'] ?? '-', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.slate900))),
              _statusBadgeSmall(isPrimary ? 'PRIMARY' : 'SUPPORT'),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _cardField('Qty', _d(m, 'quantity').toStringAsFixed(0)),
              _cardField('Months', _d(m, 'months_to_use').toStringAsFixed(0)),
              _cardField('Total Rent', '\$${_fmt.format(_machTotalRent(m))}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _cardField('Gas/Hr', _d(m, 'gallons_per_hour').toStringAsFixed(1)),
              _cardField('Gas Cost', '\$${_fmt.format(_machTotalGasCost(m))}'),
              _cardField('TOTAL', '\$${_fmt.format(_machTotal(m))}', highlight: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLaborCard(Map<String, dynamic> l) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: AppTheme.slate600),
              const SizedBox(width: 8),
              Expanded(child: Text(l['role_name'] ?? 'Labor', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.slate900))),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _cardField('Qty', _d(l, 'employees_quantity').toStringAsFixed(0)),
              _cardField('Months', _d(l, 'months_to_work').toStringAsFixed(0)),
              _cardField('Hourly', '\$${_fmt.format(_d(l, 'hourly_rate'))}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _cardField('Tot Pay', '\$${_fmt.format(_laborTotalPay(l))}'),
              _cardField('Per Diem', '\$${_fmt.format(_laborTotalPerDiem(l))}'),
              _cardField('TOTAL', '\$${_fmt.format(_laborTotal(l))}', highlight: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardField(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.slate500)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: highlight ? AppTheme.primaryGreen : AppTheme.slate900)),
      ],
    );
  }

  Widget _statusBadgeSmall(String text) {
     return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: GoogleFonts.manrope(fontSize: 8, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen)),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  MACHINERY TABLE
  // ══════════════════════════════════════════════════════════════
  Widget _buildMachineryTable(List<Map<String, dynamic>> mList) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC), border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
            child: Row(
              children: [
                _colH('Machine', 2.5),
                _colH('Mo', 0.8),
                _colH('Rent/Mo', 1),
                _colH('Qty', 0.8),
                _colH('Rate/Hr', 1),
                _colH('Hrs', 0.8),
                _colH('Rent Tot', 1),
                _colH('G/H', 0.8),
                _colH('Gas \$', 1),
                _colH('TOTAL', 1.2),
              ],
            ),
          ),
          // Rows
          ...mList.map((m) {
            final bool isPrimary = m['is_primary_mover'] as bool? ?? true;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isPrimary ? Colors.white : AppTheme.slate50.withOpacity(0.5),
                border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 25, // corresponds to 2.5 in _colH
                    child: Padding(
                      padding: EdgeInsets.only(left: isPrimary ? 0 : 24.0, right: 8.0),
                      child: Row(
                        children: [
                          if (isPrimary)
                            const Icon(Icons.star, size: 12, color: Color(0xFF11D411))
                          else
                            const Icon(Icons.build_circle, size: 12, color: AppTheme.slate500),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              m['machine_name'] ?? '-',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w600,
                                color: isPrimary ? AppTheme.slate900 : AppTheme.slate700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _colV(_d(m, 'months_to_use').toStringAsFixed(0), 0.8),
                  _colV('\$${_fmt.format(_d(m, 'monthly_rent_cost'))}', 1),
                  _colV(_d(m, 'quantity').toStringAsFixed(0), 0.8),
                  _colV('\$${_fmt.format(_machRatePerHour(m))}', 1),
                  _colV(_machHoursPerMonth(m).toStringAsFixed(0), 0.8),
                  _colV('\$${_fmt.format(_machTotalRent(m))}', 1),
                  _colV(_d(m, 'gallons_per_hour').toStringAsFixed(1), 0.8),
                  _colV('\$${_fmt.format(_machTotalGasCost(m))}', 1),
                  _colV('\$${_fmt.format(_machTotal(m))}', 1.2, highlight: true),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  LABOR TABLE
  // ══════════════════════════════════════════════════════════════
  Widget _buildLaborTable(List<Map<String, dynamic>> lList) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC), border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
            child: Row(
              children: [
                _colH('Position', 2.5),
                _colH('Mo', 1),
                _colH('Emp', 1),
                _colH('Rate/Hr', 1.2),
                _colH('Hrs/Mo', 1),
                _colH('Tot Pay', 1.5),
                _colH('P.Diem', 1.2),
                _colH('Tot PD', 1.5),
                _colH('TOTAL', 1.5),
              ],
            ),
          ),
          ...lList.map((l) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
              child: Row(
                children: [
                  _colV(l['role_name'] ?? 'Labor', 2.5, bold: true),
                  _colV(_d(l, 'months_to_work').toStringAsFixed(0), 1),
                  _colV(_d(l, 'employees_quantity').toStringAsFixed(0), 1),
                  _colV('\$${_fmt.format(_d(l, 'hourly_rate'))}', 1.2),
                  _colV(_laborHoursPerMonth(l).toStringAsFixed(0), 1),
                  _colV('\$${_fmt.format(_laborTotalPay(l))}', 1.5),
                  _colV('\$${_fmt.format(_d(l, 'per_diem'))}', 1.2),
                  _colV('\$${_fmt.format(_laborTotalPerDiem(l))}', 1.5),
                  _colV('\$${_fmt.format(_laborTotal(l))}', 1.5, highlight: true),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  MATERIALS TABLE
  // ══════════════════════════════════════════════════════════════
  Widget _buildMaterialsTable(List<Map<String, dynamic>> matList) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC), border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
            child: Row(
              children: [
                _colH('Material / Supply', 3),
                _colH('Qty', 1),
                _colH('Unit', 1),
                _colH('Unit Price', 1.5),
                _colH('TOTAL', 1.8),
              ],
            ),
          ),
          ...matList.map((m) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
              child: Row(
                children: [
                  _colV(m['material_name'] ?? '-', 3),
                  _colV(_fmt.format(_d(m, 'quantity')), 1),
                  _colV(m['unit_name'] ?? 'und', 1),
                  _colV('\$${_fmt.format(_d(m, 'unit_price'))}', 1.5),
                  _colV('\$${_fmt.format(_matTotal(m))}', 1.8, highlight: true),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(Map<String, dynamic> m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 16, color: AppTheme.slate600),
              const SizedBox(width: 8),
              Expanded(child: Text(m['material_name'] ?? 'Material', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.slate900))),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _cardField('Qty', _d(m, 'quantity').toStringAsFixed(1)),
              _cardField('Unit', m['unit_name'] ?? 'und'),
              _cardField('Unit Price', '\$${_fmt.format(_d(m, 'unit_price'))}'),
              _cardField('TOTAL', '\$${_fmt.format(_matTotal(m))}', highlight: true),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  REUSABLE WIDGETS
  // ══════════════════════════════════════════════════════════════
  Widget _statusBadge(String status) {
    Color bg; Color text;
    switch (status.toLowerCase()) {
      case 'accepted': bg = AppTheme.primaryGreen.withOpacity(0.1); text = AppTheme.primaryGreen; break;
      case 'sent': bg = Colors.blue.withOpacity(0.1); text = Colors.blue; break;
      case 'rejected': bg = AppTheme.errorRed.withOpacity(0.1); text = AppTheme.errorRed; break;
      default: bg = AppTheme.slate200; text = AppTheme.slate700; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: text, letterSpacing: 0.5)),
    );
  }

  Widget _infoChipDark(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: GoogleFonts.manrope(fontSize: 11, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w600)),
          Text(value, style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _tableTitle(IconData icon, String title, int count) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.slate700),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Text('$count', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen)),
        ),
      ],
    );
  }

  Widget _emptyPlaceholder(String msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Center(child: Text(msg, style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate400))),
    );
  }

  Widget _colH(String label, num flex) {
    return Expanded(flex: (flex * 10).toInt(), child: Text(label.toUpperCase(), style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppTheme.slate500)));
  }

  Widget _colV(String val, num flex, {bool bold = false, bool highlight = false}) {
    return Expanded(
      flex: (flex * 10).toInt(),
      child: Text(val, style: GoogleFonts.manrope(fontSize: 12, fontWeight: bold || highlight ? FontWeight.w700 : FontWeight.w500, color: highlight ? AppTheme.primaryGreen : AppTheme.slate900)),
    );
  }

  Widget _summaryTitle(String title) {
    return Row(
      children: [
        const Icon(Icons.bar_chart_rounded, size: 18, color: AppTheme.primaryGreen),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
      ],
    );
  }

  Widget _summaryLine(String label, double value, {bool bold = false, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.manrope(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: AppTheme.slate700)),
          Text('\$${_fmt.format(value)}', style: GoogleFonts.manrope(fontSize: 13, fontWeight: bold || highlight ? FontWeight.w800 : FontWeight.w600, color: highlight ? AppTheme.primaryGreen : AppTheme.slate900)),
        ],
      ),
    );
  }


  Widget _buildEstimationSummaryBoxes(String svcId) {
    final data = _estimations[svcId];
    if (data == null) return const SizedBox.shrink();

    final startDateStr = data['start_date'] as String?;
    final endDateStr = data['end_date'] as String?;
    final workingDays = data['total_working_days'] ?? 0;
    
    String period = '-';
    String months = '0';
    String calendarDays = '0';

    if (startDateStr != null && endDateStr != null) {
      final startDate = DateTime.parse(startDateStr);
      final endDate = DateTime.parse(endDateStr);
      period = '${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd').format(endDate)}';
      final diff = endDate.difference(startDate).inDays;
      calendarDays = diff.toString();
      months = (diff / 30.44).toStringAsFixed(1);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _estBoxDark('Period', period),
        _estBoxDark('Months', months),
        _estBoxDark('Production Days', workingDays.toString()),
        _estBoxDark('Total Days', calendarDays),
      ],
    );
  }

  Widget _estBoxDark(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.manrope(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.4))),
          Text(value, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }
}
