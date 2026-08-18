import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../../../../shared/widgets/top_header.dart';
import '../../../../shared/widgets/completed_project_banner.dart';
import '../utils/payroll_pdf_generator.dart';
import '../utils/payroll_excel_generator.dart';
import '../utils/worker_signoff_pdf_generator.dart';
import '../utils/worker_individual_report_pdf_generator.dart';
import 'package:noel_ui_components/noel_ui_components.dart';

class PayrollPeriodPage extends ConsumerStatefulWidget {
  final String projectId;
  final String periodId;

  const PayrollPeriodPage({
    super.key,
    required this.projectId,
    required this.periodId,
  });

  @override
  ConsumerState<PayrollPeriodPage> createState() => _PayrollPeriodPageState();
}

class _PayrollPeriodPageState extends ConsumerState<PayrollPeriodPage> {
  bool _isCompleted = false;
  Map<String, dynamic>? _period;
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;
  bool _isCalculating = false;
  String? _error;
  String _projectTitle = '';

  // Slider state — accumulate from fixed start
  double _accumDays = 1;
  DateTime? _originalStart;
  DateTime? _originalEnd;
  int _originalDuration = 1;
  DateTime? _currentEnd;
  List<Map<String, dynamic>> _virtualEntries = [];
  bool _isVirtual = false;
  bool _isRecalculating = false;
  bool _isSignoffLoading = false;
  bool _isIndividualLoading = false;
  Timer? _debounce;
  Map<String, dynamic> _virtualTotals = {
    'total_regular_hours': 0,
    'total_overtime_hours': 0,
    'total_workers': 0,
    'total_cost': 0,
  };

  final DateFormat _dateFmt = DateFormat('MMM dd, yyyy');
  final DateFormat _shortFmt = DateFormat('MMM dd');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(payrollServiceProvider);
      _period = await service.getPeriod(widget.periodId);
      _entries = await service.calculatePeriod(widget.periodId);

      final proj = await Supabase.instance.client
          .from('projects')
          .select('title')
          .eq('id', widget.projectId)
          .single();
      _projectTitle = proj['title'] ?? '';

      final s = _period?['start_date'] as String?;
      final e = _period?['end_date'] as String?;
      if (s != null) _originalStart = DateTime.parse(s);
      if (e != null) _originalEnd = DateTime.parse(e);
      if (_originalStart != null && _originalEnd != null) {
        _originalDuration = _originalEnd!.difference(_originalStart!).inDays;
        _accumDays = _originalDuration.toDouble();
        _currentEnd = _originalEnd;
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _recalculate() async {
    setState(() => _isCalculating = true);
    try {
      final service = ref.read(payrollServiceProvider);
      _entries = await service.calculatePeriod(widget.periodId);
      _period = await service.getPeriod(widget.periodId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    if (mounted) setState(() => _isCalculating = false);
  }

  void _onSliderChanged(double value) {
    setState(() {
      _accumDays = value;
      _isVirtual = value.toInt() != _originalDuration;
      if (_originalStart != null) {
        _currentEnd = _originalStart!.add(Duration(days: value.toInt()));
      }
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _doVirtualCalc);
  }

  void _onSliderChangeEnd(double value) {
    _debounce?.cancel();
    _doVirtualCalc();
  }

  Future<void> _doVirtualCalc() async {
    if (_originalStart == null || _currentEnd == null) return;
    setState(() => _isRecalculating = true);
    try {
      final service = ref.read(payrollServiceProvider);
      final result = await service.calculateVirtualPeriod(
        widget.projectId,
        DateFormat('yyyy-MM-dd').format(_originalStart!),
        DateFormat('yyyy-MM-dd').format(_currentEnd!),
      );
      if (mounted) {
        setState(() {
          _virtualEntries = List<Map<String, dynamic>>.from(result['entries'] as List);
          _virtualTotals = {
            'total_regular_hours': result['total_regular_hours'],
            'total_overtime_hours': result['total_overtime_hours'],
            'total_workers': result['total_workers'],
            'total_cost': result['total_cost'],
          };
          _isRecalculating = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isRecalculating = false);
    }
  }

  void _resetSlider() {
    _debounce?.cancel();
    setState(() {
      _accumDays = _originalDuration.toDouble();
      _isVirtual = false;
      _currentEnd = _originalEnd;
      _virtualEntries = [];
      _virtualTotals = {
        'total_regular_hours': 0,
        'total_overtime_hours': 0,
        'total_workers': 0,
        'total_cost': 0,
      };
    });
  }

  bool get _hasEntries => (_isVirtual ? _virtualEntries : _entries).isNotEmpty;

  String get _exportName {
    final p = _period;
    final name = (p?['name'] as String?) ?? 'Labor_Cost';
    final start = (p?['start_date'] as String?) ?? '';
    final end = (p?['end_date'] as String?) ?? '';
    final datePart = start.isNotEmpty && end.isNotEmpty ? '_${start}_$end' : '';
    return '${name}${datePart}_${_projectTitle.replaceAll(' ', '_')}';
  }

  List<Map<String, dynamic>> get _currentEntries => _isVirtual ? _virtualEntries : _entries;

  String? get _virtualStart =>
      _isVirtual && _originalStart != null ? DateFormat('yyyy-MM-dd').format(_originalStart!) : null;
  String? get _virtualEnd =>
      _isVirtual && _currentEnd != null ? DateFormat('yyyy-MM-dd').format(_currentEnd!) : null;

  String get _displayStart =>
      _isVirtual && _originalStart != null ? DateFormat('yyyy-MM-dd').format(_originalStart!) : (_period?['start_date'] as String?) ?? '';
  String get _displayEnd =>
      _isVirtual && _currentEnd != null ? DateFormat('yyyy-MM-dd').format(_currentEnd!) : (_period?['end_date'] as String?) ?? '';

  num get _totalReg => (_isVirtual ? _virtualTotals['total_regular_hours'] : _period?['total_regular_hours'] ?? 0) as num;
  num get _totalOT => (_isVirtual ? _virtualTotals['total_overtime_hours'] : _period?['total_overtime_hours'] ?? 0) as num;
  num get _totalCost => (_isVirtual ? _virtualTotals['total_cost'] : _period?['total_cost'] ?? 0) as num;
  num get _totalWorkers => (_isVirtual ? _virtualTotals['total_workers'] : _period?['total_workers'] ?? 0) as num;

  Future<void> _exportPdf() async {
    if (!_hasEntries) return;
    try {
      final bytes = await PayrollPdfGenerator.generate(
        projectTitle: _projectTitle,
        periodName: _period?['name'] ?? '',
        startDate: _displayStart,
        endDate: _displayEnd,
        entries: _currentEntries,
        totalReg: _totalReg,
        totalOT: _totalOT,
        totalCost: _totalCost,
        totalWorkers: _totalWorkers,
      );
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: _exportName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF error: $e')));
      }
    }
  }

  Future<void> _exportExcel() async {
    if (!_hasEntries) return;
    try {
      final bytes = PayrollExcelGenerator.generate(
        projectTitle: _projectTitle,
        periodName: _period?['name'] ?? '',
        startDate: _displayStart,
        endDate: _displayEnd,
        entries: _currentEntries,
        totalReg: _totalReg,
        totalOT: _totalOT,
        totalCost: _totalCost,
        totalWorkers: _totalWorkers,
      );
      final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..download = '${_exportName}.xlsx'
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excel error: $e')));
      }
    }
  }

  Future<void> _exportWorkerSignoffPdf() async {
    if (!_hasEntries) return;
    setState(() => _isSignoffLoading = true);
    try {
      final service = ref.read(payrollServiceProvider);
      final result = await service.getWorkerDetailedLogs(
        widget.periodId,
        startDate: _virtualStart,
        endDate: _virtualEnd,
      );
      final workers = List<Map<String, dynamic>>.from(result['workers'] as List);
      if (workers.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No workers found for this period.')));
        }
        return;
      }
      final bytes = await WorkerSignoffPdfGenerator.generate(
        projectTitle: _projectTitle,
        periodName: _period?['name'] ?? '',
        startDate: _displayStart,
        endDate: _displayEnd,
        workers: workers,
        totalReg: result['total_regular_hours'] as num,
        totalOT: result['total_overtime_hours'] as num,
        totalHours: result['total_hours'] as num,
        totalWorkers: result['total_workers'] as num,
      );
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: '${_exportName}_SignOff',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign-off PDF error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSignoffLoading = false);
    }
  }

  Future<void> _exportIndividualReport(Map<String, dynamic> workerEntry) async {
    setState(() => _isIndividualLoading = true);
    try {
      final service = ref.read(payrollServiceProvider);
      final workerId = workerEntry['worker_id'] as String;
      final result = await service.getDailyLogsForWorker(
        widget.periodId,
        workerId,
        startDate: _virtualStart,
        endDate: _virtualEnd,
      );

      if (result['worker'] == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No logs found for this worker.')));
        }
        return;
      }

      final bytes = await WorkerIndividualReportPdfGenerator.generate(
        projectTitle: _projectTitle,
        periodName: _period?['name'] ?? '',
        startDate: _displayStart,
        endDate: _displayEnd,
        worker: result['worker'] as Map<String, dynamic>,
        dailyLogs: List<Map<String, dynamic>>.from(result['daily_logs'] as List),
        totalReg: result['total_regular_hours'] as num,
        totalOT: result['total_overtime_hours'] as num,
        totalHours: result['total_hours'] as num,
      );

      final workerName = (result['worker'] as Map<String, dynamic>)['full_name'] ?? 'Worker';
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: '${_exportName}_${workerName.toString().replaceAll(' ', '_')}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Individual report error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isIndividualLoading = false);
    }
  }

  Future<void> _closePeriod() async {
    final confirmed = await showSafeDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Period'),
        content: const Text('Once closed, period data becomes read-only. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Close Period')),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final service = ref.read(payrollServiceProvider);
        await service.closePeriod(widget.periodId);
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  String _fmt(num v) => '\$${v.toStringAsFixed(2)}';
  String _fmtHrs(num v) => v.toStringAsFixed(1);

  Color _statusColor(String status) {
    switch (status) {
      case 'calculated': return AppTheme.primaryGreen;
      case 'closed': return AppTheme.slate500;
      default: return AppTheme.primaryGreen;
    }
  }

  String _dateLabel() {
    if (_originalStart == null || _currentEnd == null) return '';
    return '${_shortFmt.format(_originalStart!)} — ${_dateFmt.format(_currentEnd!)}';
  }

  Widget _buildDateScrubber() {
    final accum = _accumDays.toInt();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.slate50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.date_range, size: 16, color: _isVirtual ? AppTheme.primaryGreen : AppTheme.slate400),
              const SizedBox(width: 8),
              Text(
                'Accumulate from start',
                style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate500, letterSpacing: 0.5),
              ),
              if (_isVirtual) ...[
                const Spacer(),
                if (_isRecalculating)
                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen)),
                if (_isRecalculating) const SizedBox(width: 8),
                GestureDetector(
                  onTap: _resetSlider,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.slate200),
                    ),
                    child: Text('Reset', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.slate600)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'FIXED',
                  style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _originalStart != null ? _shortFmt.format(_originalStart!) : '',
                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 14, color: AppTheme.slate400),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentEnd != null ? _dateFmt.format(_currentEnd!) : '',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: _isVirtual ? FontWeight.w700 : FontWeight.w500,
                    color: _isVirtual ? AppTheme.slate900 : AppTheme.slate700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (MediaQuery.of(context).size.width < 768)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  _dayStepBtn('−1d', () { if (_originalStart == null) return; _onSliderChanged((_accumDays - 1).clamp(1, 90)); }),
                  const SizedBox(width: 6),
                  _dayStepBtn('−7d', () { if (_originalStart == null) return; _onSliderChanged((_accumDays - 7).clamp(1, 90)); }),
                  const Spacer(),
                  _dayStepBtn('+7d', () { if (_originalStart == null) return; _onSliderChanged((_accumDays + 7).clamp(1, 90)); }),
                  const SizedBox(width: 6),
                  _dayStepBtn('+1d', () { if (_originalStart == null) return; _onSliderChanged((_accumDays + 1).clamp(1, 90)); }),
                ]),
                const SizedBox(height: 8),
                _buildAccumSlider(accum),
              ],
            )
          else
            Row(children: [
              _dayStepBtn('−1d', () { if (_originalStart == null) return; _onSliderChanged((_accumDays - 1).clamp(1, 90)); }),
              const SizedBox(width: 6),
              _dayStepBtn('−7d', () { if (_originalStart == null) return; _onSliderChanged((_accumDays - 7).clamp(1, 90)); }),
              const SizedBox(width: 8),
              Expanded(child: _buildAccumSlider(accum)),
              const SizedBox(width: 8),
              _dayStepBtn('+7d', () { if (_originalStart == null) return; _onSliderChanged((_accumDays + 7).clamp(1, 90)); }),
              const SizedBox(width: 6),
              _dayStepBtn('+1d', () { if (_originalStart == null) return; _onSliderChanged((_accumDays + 1).clamp(1, 90)); }),
            ]),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${accum}d of 90 days',
                style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.slate400),
              ),
              const Spacer(),
              if (_originalStart != null && _currentEnd != null)
                Text(
                  'Duration: ${_currentEnd!.difference(_originalStart!).inDays} days',
                  style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.slate400),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayStepBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.slate200),
        ),
        child: Text(label, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.slate600)),
      ),
    );
  }

  Widget _buildAccumSlider(int accum) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: AppTheme.primaryGreen,
        inactiveTrackColor: AppTheme.slate200,
        thumbColor: AppTheme.primaryGreen,
        overlayColor: AppTheme.primaryGreen.withOpacity(0.1),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      child: Slider(
        value: _accumDays,
        min: 1,
        max: 90,
        divisions: 89,
        label: '$accum days',
        onChanged: _onSliderChanged,
        onChangeEnd: _onSliderChangeEnd,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['name'] ?? 'Admin User';
    final userEmail = user?.email ?? '';
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) return _buildMobileLayout(userName, userEmail);
    return _buildDesktopLayout(userName, userEmail);
  }

  Widget _buildDesktopLayout(String userName, String userEmail) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Row(
        children: [
          Sidebar(
            userName: userName,
            userEmail: userEmail,
            currentPath: '/payroll',
            onLogout: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/signin');
            },
          ),
          Expanded(
            child: Column(
              children: [
                TopHeader(userName: userName, breadcrumbs: const ['Projects', 'Labor Cost', 'Period Detail']),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(String userName, String userEmail) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(_period?['name'] ?? 'Period', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Error: $_error', style: GoogleFonts.manrope(color: Colors.red)),
          const SizedBox(height: 16),
          FilledButton(onPressed: _loadData, child: const Text('Retry')),
        ]),
      );
    }

    final p = _period;
    if (p == null) return const SizedBox.shrink();

    final isClosed = p['status'] == 'closed';

    return CompletedProjectBanner(
      projectId: widget.projectId,
      isCompletedCallback: (completed) {
        if (completed != _isCompleted) setState(() => _isCompleted = completed);
      },
      child: SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 768 ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _isVirtual ? AppTheme.primaryGreen.withOpacity(0.3) : AppTheme.slate200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + status row + actions
                LayoutBuilder(builder: (ctx, constraints) {
                  final titleBlock = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(
                            _isVirtual ? 'Preview' : (p['name'] ?? ''),
                            style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (!_isVirtual)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(p['status']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (p['status'] as String?)?.toUpperCase() ?? '',
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _statusColor(p['status']),
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'VIRTUAL',
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                        _isVirtual
                            ? 'From ${_shortFmt.format(_originalStart!)} — accumulating to ${_dateFmt.format(_currentEnd!)}'
                            : '${p['start_date']} — ${p['end_date']}',
                        style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _projectTitle,
                        style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
                      ),
                    ],
                  );
                  final buttons = <Widget>[
                    if (!isClosed) ...[
                      FilledButton.icon(
                        onPressed: _isCompleted || _isVirtual ? null : _recalculate,
                        icon: _isCalculating
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.refresh, size: 20),
                        label: Text(_isCalculating ? 'Calculating...' : 'Calculate'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _isCompleted ? null : _closePeriod,
                        icon: const Icon(Icons.lock_outline, size: 20),
                        label: const Text('Close Period'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(color: AppTheme.slate200),
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    if (_hasEntries) ...[
                      if (_isSignoffLoading)
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen))
                      else
                        _exportButton(
                          icon: Icons.fact_check_outlined,
                          label: 'Sign-off',
                          onTap: _exportWorkerSignoffPdf,
                        ),
                      const SizedBox(width: 8),
                      _exportButton(
                        icon: Icons.download,
                        label: 'Excel',
                        onTap: _exportExcel,
                      ),
                      const SizedBox(width: 8),
                      _exportButton(
                        icon: Icons.picture_as_pdf_outlined,
                        label: 'PDF',
                        onTap: _exportPdf,
                      ),
                    ],
                  ];
                  if (constraints.maxWidth < 700) {
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      titleBlock,
                      const SizedBox(height: 16),
                      Wrap(spacing: 12, runSpacing: 12, children: buttons),
                    ]);
                  }
                  return Row(children: [
                    Expanded(child: titleBlock),
                    ...buttons,
                  ]);
                }),
                const SizedBox(height: 20),
                // Date scrubber
                _buildDateScrubber(),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Summary row
          LayoutBuilder(builder: (ctx, constraints) {
            final tiles = [
              _summaryTileInner('Workers', '${_isVirtual ? _virtualTotals['total_workers'] : p['total_workers'] ?? 0}', Icons.people_outline),
              _summaryTileInner('Regular Hours', _fmtHrs((_isVirtual ? _virtualTotals['total_regular_hours'] : p['total_regular_hours'] ?? 0).toDouble()), Icons.access_time),
              _summaryTileInner('Overtime Hours', _fmtHrs((_isVirtual ? _virtualTotals['total_overtime_hours'] : p['total_overtime_hours'] ?? 0).toDouble()), Icons.timer_outlined),
              _summaryTileInner('Total Cost', _fmt((_isVirtual ? _virtualTotals['total_cost'] : p['total_cost'] ?? 0).toDouble()), Icons.attach_money, isHighlight: true),
            ];
            if (constraints.maxWidth < 700) {
              final half = (constraints.maxWidth - 12) / 2;
              return Wrap(spacing: 12, runSpacing: 12, children: [
                for (final t in tiles) SizedBox(width: half, child: t),
              ]);
            }
            return Row(children: [
              Expanded(child: tiles[0]),
              const SizedBox(width: 16),
              Expanded(child: tiles[1]),
              const SizedBox(width: 16),
              Expanded(child: tiles[2]),
              const SizedBox(width: 16),
              Expanded(child: tiles[3]),
            ]);
          }),
          const SizedBox(height: 28),

          // Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: MediaQuery.of(context).size.width < 768
              ? Column(
                  children: [
                    if (_isVirtual && _virtualEntries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No labor logs found for this period.')),
                      )
                    else if (!_isVirtual && _entries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No labor logs found for this period.')),
                      )
                    else ...[
                      ...(_isVirtual ? _virtualEntries : _entries).map((e) => _buildMobileWorkerCard(e, onTap: _isIndividualLoading ? null : () => _exportIndividualReport(e))),
                      _buildMobileTotalCard(),
                    ],
                  ],
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                      child: Row(
                        children: [
                          _col('WORKER', 25),
                          _col('ROLE', 18),
                          _col('RATE', 10),
                          _col('REG HRS', 10),
                          _col('OT HRS', 10),
                          _col('TOTAL HRS', 12),
                          _col('TOTAL COST', 15),
                        ],
                      ),
                    ),
                    if (_isVirtual && _virtualEntries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No labor logs found for this period.')),
                      )
                    else if (!_isVirtual && _entries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No labor logs found for this period.')),
                      )
                    else
                      ...(_isVirtual ? _virtualEntries : _entries).map((e) => _buildRow(e, onTap: _isIndividualLoading ? null : () => _exportIndividualReport(e))),
                    // Grand total row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: AppTheme.slate200)),
                        color: AppTheme.slate50,
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 25, child: Text(
                            'TOTAL',
                            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                          )),
                          const Expanded(flex: 18, child: SizedBox.shrink()),
                          const Expanded(flex: 10, child: SizedBox.shrink()),
                          Expanded(flex: 10, child: Text(
                            _fmtHrs((_isVirtual ? _virtualTotals['total_regular_hours'] : _period?['total_regular_hours'] ?? 0).toDouble()),
                            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                          )),
                          Expanded(flex: 10, child: Text(
                            _fmtHrs((_isVirtual ? _virtualTotals['total_overtime_hours'] : _period?['total_overtime_hours'] ?? 0).toDouble()),
                            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                          )),
                          Expanded(flex: 12, child: Text(
                            _fmtHrs(((_isVirtual ? _virtualTotals['total_regular_hours'] : _period?['total_regular_hours'] ?? 0) + (_isVirtual ? _virtualTotals['total_overtime_hours'] : _period?['total_overtime_hours'] ?? 0)).toDouble()),
                            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                          )),
                          Expanded(flex: 15, child: Text(
                            _fmt((_isVirtual ? _virtualTotals['total_cost'] : _period?['total_cost'] ?? 0).toDouble()),
                            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _summaryTileInner(String label, String value, IconData icon, {bool isHighlight = false}) {
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isHighlight ? AppTheme.primaryGreen.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isHighlight ? AppTheme.primaryGreen.withOpacity(0.2) : AppTheme.slate200),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isHighlight ? AppTheme.primaryGreen.withOpacity(0.1) : AppTheme.slate50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: isHighlight ? AppTheme.primaryGreen : AppTheme.slate500, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate500, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: isHighlight ? AppTheme.primaryGreen : AppTheme.slate900), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ]),
      );
  }

  Widget _col(String title, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppTheme.slate500),
      ),
    );
  }

  Widget _buildMobileWorkerCard(Map<String, dynamic> e, {VoidCallback? onTap}) {
    final reg = (e['regular_hours'] ?? 0).toDouble();
    final ot = (e['overtime_hours'] ?? 0).toDouble();
    final rate = (e['hourly_rate'] ?? 0).toDouble();
    final totalCost = (e['total_pay'] ?? (reg + ot) * rate).toDouble();

    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                e['full_name'] ?? 'N/A',
                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate900),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(_fmt(totalCost), style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen)),
          ]),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppTheme.slate50, borderRadius: BorderRadius.circular(4)),
            child: Text(
              (e['role_name'] ?? '').toUpperCase(),
              style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.slate600, letterSpacing: 0.3),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: [
            _mobileStatChip('Rate', _fmt(rate)),
            _mobileStatChip('Reg', '${_fmtHrs(reg)}h'),
            _mobileStatChip('OT', '${_fmtHrs(ot)}h'),
            _mobileStatChip('Total', '${_fmtHrs(reg + ot)}h'),
          ]),
        ],
      ),
    );
    if (onTap == null) return card;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: card),
    );
  }

  Widget _buildMobileTotalCard() {
    final reg = (_isVirtual ? _virtualTotals['total_regular_hours'] : _period?['total_regular_hours'] ?? 0).toDouble();
    final ot = (_isVirtual ? _virtualTotals['total_overtime_hours'] : _period?['total_overtime_hours'] ?? 0).toDouble();
    final cost = (_isVirtual ? _virtualTotals['total_cost'] : _period?['total_cost'] ?? 0).toDouble();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppTheme.slate50, border: const Border(top: BorderSide(color: AppTheme.slate200))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('TOTAL', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
          const Spacer(),
          Text(_fmt(cost), style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen)),
        ]),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 6, children: [
          _mobileStatChip('Reg', '${_fmtHrs(reg)}h'),
          _mobileStatChip('OT', '${_fmtHrs(ot)}h'),
          _mobileStatChip('Total', '${_fmtHrs(reg + ot)}h'),
        ]),
      ]),
    );
  }

  Widget _mobileStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppTheme.slate50, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppTheme.slate200)),
      child: Text(
        '$label $value',
        style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate700),
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> e, {VoidCallback? onTap}) {
    final reg = (e['regular_hours'] ?? 0).toDouble();
    final ot = (e['overtime_hours'] ?? 0).toDouble();
    final rate = (e['hourly_rate'] ?? 0).toDouble();
    final totalCost = (e['total_pay'] ?? (reg + ot) * rate).toDouble();

    final row = Row(
      children: [
        Expanded(flex: 25, child: Text(
          e['full_name'] ?? 'N/A',
          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.slate900),
        )),
        Expanded(flex: 18, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.slate50,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            (e['role_name'] ?? '').toUpperCase(),
            style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.slate600, letterSpacing: 0.3),
            overflow: TextOverflow.ellipsis,
          ),
        )),
        Expanded(flex: 10, child: Text(
          _fmt(rate),
          style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate700),
        )),
        Expanded(flex: 10, child: Text(
          _fmtHrs(reg),
          style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate700),
        )),
        Expanded(flex: 10, child: Text(
          _fmtHrs(ot),
          style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate700),
        )),
        Expanded(flex: 12, child: Text(
          _fmtHrs(reg + ot),
          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate900),
        )),
        Expanded(flex: 15, child: Text(
          _fmt(totalCost),
          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen),
        )),
      ],
    );

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: row,
    );

    if (onTap == null) {
      return Container(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
        child: content,
      );
    }
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: content,
        ),
      ),
    );
  }

  Widget _exportButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.manrope(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
