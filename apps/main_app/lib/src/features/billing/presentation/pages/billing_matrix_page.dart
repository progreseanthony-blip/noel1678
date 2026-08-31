import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
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
import '../../../../shared/widgets/completed_project_banner.dart';

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
  bool _isCompleted = false;
  Map<String, dynamic>? _invoice;
  List<Map<String, dynamic>> _lines = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDirty = false;
  String? _error;
  double _retainageRate = 5.0;
  final Set<String> _linkedCoIds = {};
  final Map<String, String> _coTypeMap = {};
  final _fmt = NumberFormat('#,##0.00', 'en_US');

  Map<String, List<Map<String, dynamic>>> _machineryByService = {};
  Map<String, List<Map<String, dynamic>>> _machinerySelections = {};
  Set<String> _expandedServices = {};
  Set<String> _expandedCOs = {};
  int _daysInPeriod = 0;

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

        // Refresh approved_cos_total from RPC for draft invoices
        if (inv['status'] == 'draft') {
          try {
            final freshData = await svc.getPayApplicationData(
              projectId: widget.projectId,
              periodStart: (inv['period_start'] as String?) ?? '',
              periodEnd: (inv['period_end'] as String?) ?? '',
            );
            inv['approved_cos_total'] = freshData['approved_cos_total'] ?? inv['approved_cos_total'];
            inv['current_contract'] = freshData['current_contract'] ?? inv['current_contract'];
          } catch (_) {}
        }

        final details = await svc.getInvoiceDetails(widget.invoiceId!);

        // Load linked Change Orders
        final links = await Supabase.instance.client
            .from('invoice_change_order_links')
            .select('change_order_id')
            .eq('invoice_id', widget.invoiceId);
        _linkedCoIds.clear();
        _linkedCoIds.addAll(links.map<String>((l) => l['change_order_id'].toString()));

        // Load co_type for each linked CO to distinguish disruption vs scope_change
        _coTypeMap.clear();
        if (_linkedCoIds.isNotEmpty) {
          try {
            final coTypes = await Supabase.instance.client
                .from('change_orders')
                .select('co_number, co_type')
                .in_('id', _linkedCoIds.toList());
            for (final ct in coTypes ?? []) {
              final num = ct['co_number']?.toString();
              final type = ct['co_type']?.toString();
              if (num != null && type != null) _coTypeMap[num] = type;
            }
          } catch (_) {}
        }

        if (mounted) {
          // Sort: services → equipment → CO blocks chronologically
          details.sort(_lineComparator);
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

        // Use scheduled_value from RPC directly (direct_cost now holds totalSaleV2)
        for (final l in loadedLines) {
          scheduledTotal += (l['scheduled_value'] as num?)?.toDouble() ?? 0;
        }

        if (mounted) {
          // Sort: services → equipment → CO blocks chronologically
          loadedLines.sort(_lineComparator);
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

    if (_invoice != null && mounted) {
      _loadMachineryData();
    }
  }

  Future<void> _loadMachineryData() async {
    try {
      final svc = ref.read(billingServiceProvider);
      final allMachinery = await svc.getServiceMachineryForBilling(widget.projectId);

      final periodStartStr = _invoice?['period_start'] ?? '';
      final periodEndStr = _invoice?['period_end'] ?? '';
      int daysInPeriod = 30;
      if (periodStartStr.isNotEmpty && periodEndStr.isNotEmpty) {
        final ps = DateTime.parse(periodStartStr);
        final pe = DateTime.parse(periodEndStr);
        daysInPeriod = pe.difference(ps).inDays + 1;
      }

      final byService = <String, List<Map<String, dynamic>>>{};
      for (final m in allMachinery) {
        final qsId = m['quote_service_id']?.toString();
        if (qsId == null) continue;
        m['days_in_period'] = daysInPeriod;
        m['deduction_amount'] = ((m['daily_rental_rate'] as num?)?.toDouble() ?? 0) * daysInPeriod;
        byService.putIfAbsent(qsId, () => []).add(m);
      }

      if (mounted) {
        setState(() {
          _machineryByService = byService;
          _daysInPeriod = daysInPeriod;
        });
      }

      if (widget.invoiceId != null) {
        try {
          final existingDeductions = await svc.getMachineryDeductions(widget.invoiceId!);
          final selections = <String, List<Map<String, dynamic>>>{};
          for (final d in existingDeductions) {
            final qsId = d['quote_service_id']?.toString();
            if (qsId == null) continue;
            selections.putIfAbsent(qsId, () => []).add(d);
          }
          if (mounted) {
            setState(() {
              _machinerySelections = selections;
              _updateEquipmentPresentFromDeductions();
            });
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  void _updateEquipmentPresentFromDeductions() {
    for (int i = 0; i < _lines.length; i++) {
      final l = _lines[i];
      if (l['line_type'] != 'service') continue;
      final qsId = l['quote_service_id']?.toString();
      if (qsId == null) continue;
      final selections = _machinerySelections[qsId] ?? [];
      double total = 0;
      for (final s in selections) {
        if (s['selected'] != false) {
          total += (s['deduction_amount'] as num?)?.toDouble() ?? 0;
        }
      }
      _lines[i]['equipment_present'] = total > 0 ? -total : 0;
    }
  }

  void _toggleServiceExpansion(String qsId) {
    setState(() {
      if (_expandedServices.contains(qsId)) {
        _expandedServices.remove(qsId);
      } else {
        _expandedServices.add(qsId);
      }
    });
  }

  void _toggleCOExpansion(String coNumber) {
    setState(() {
      if (_expandedCOs.contains(coNumber)) {
        _expandedCOs.remove(coNumber);
      } else {
        _expandedCOs.add(coNumber);
      }
    });
  }

  void _toggleMachinerySelection(String qsId, Map<String, dynamic> machine, bool isSelected) {
    setState(() {
      _machinerySelections.putIfAbsent(qsId, () => []);
      final inspectionId = machine['machinery_inspection_id']?.toString();
      final existingIdx = _machinerySelections[qsId]!.indexWhere(
        (s) => s['machinery_inspection_id']?.toString() == inspectionId,
      );
      if (isSelected) {
        if (existingIdx < 0) {
          _machinerySelections[qsId]!.add({
            'quote_service_id': qsId,
            'machinery_inspection_id': inspectionId,
            'machine_name': machine['machine_name'],
            'internal_code': machine['internal_code'],
            'brand_model': machine['brand_model'],
            'monthly_rent_cost': machine['monthly_rent_cost'],
            'daily_rental_rate': machine['daily_rental_rate'],
            'days_in_period': _daysInPeriod,
            'deduction_amount': machine['deduction_amount'],
            'selected': true,
          });
        }
      } else {
        if (existingIdx >= 0) {
          _machinerySelections[qsId]!.removeAt(existingIdx);
        }
      }
      _isDirty = true;
      _updateEquipmentPresentFromDeductions();
    });
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
          'change_order_id': l['change_order_id'],
          'co_number': l['co_number'],
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

      // Save Change Order links — delete old then re-insert
      await Supabase.instance.client
          .from('invoice_change_order_links')
          .delete()
          .eq('invoice_id', _invoice!['id']);
      for (final coId in _linkedCoIds) {
        await ctrl.linkCOToInvoice(_invoice!['id'], coId);
      }

      final dedSvcs = ref.read(billingServiceProvider);
      final allDeductions = <Map<String, dynamic>>[];
      for (final entry in _machinerySelections.entries) {
        for (final d in entry.value) {
          allDeductions.add(Map<String, dynamic>.from(d));
        }
      }
      await dedSvcs.saveMachineryDeductions(_invoice!['id'], allDeductions);

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

  Future<void> _markAsPaid() async {
    if (_invoice?['id'] == null) return;
    try {
      await ref.read(billingControllerProvider.notifier).markAsPaid(_invoice!['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marked as Paid', style: GoogleFonts.manrope(color: Colors.white)), backgroundColor: AppTheme.primaryGreen),
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

  Future<void> _refreshFromReports() async {
    if (_invoice?['id'] == null || _invoice?['period_start'] == null) return;
    setState(() => _isSaving = true);
    try {
      final svc = ref.read(billingServiceProvider);
      final data = await svc.getPayApplicationData(
        projectId: widget.projectId,
        periodStart: _invoice!['period_start'],
        periodEnd: _invoice!['period_end'],
        excludeInvoiceId: _invoice!['id'],
      );
      final rpcLines = (data['lines'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

      setState(() {
        // Keep CO linked lines (manually attached), replace service lines from RPC
        final coLines = _lines.where((l) {
          final lt = l['line_type']?.toString() ?? '';
          return lt == 'change_order_header' || lt == 'change_order_detail';
        }).toList();

        _lines.clear();
        _lines.addAll(rpcLines);
        _lines.addAll(coLines);
        _lines.sort(_lineComparator);
        _isDirty = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Refreshed from daily reports', style: GoogleFonts.manrope(color: Colors.white)),
              backgroundColor: AppTheme.primaryGreen),
        );
      }
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

  int _parseCoNumber(String? coNumber) {
    // Extract numeric portion from "CO-2026-0009" → 20260009 for sorting
    if (coNumber == null || coNumber.isEmpty) return 0;
    final digits = coNumber.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  void _sortLines() {
    _lines.sort(_lineComparator);
  }

  int _lineComparator(Map<String, dynamic> a, Map<String, dynamic> b) {
    const typeOrder = {
      'service': 0, 'equipment': 1, 'co_adjustment': 2,
      'change_order_header': 3, 'change_order_detail': 4
    };
    final aType = typeOrder[a['line_type']?.toString() ?? ''] ?? 99;
    final bType = typeOrder[b['line_type']?.toString() ?? ''] ?? 99;

    final aCoSegment = a['co_segment']?.toString();
    final bCoSegment = b['co_segment']?.toString();
    final aIsIncrement = aCoSegment == 'increment';
    final bIsIncrement = bCoSegment == 'increment';

    // RPC segmented increment lines: sort right after their parent original service
    if (aIsIncrement && bIsIncrement) {
      final aCoNum = _parseCoNumber(a['co_number']?.toString());
      final bCoNum = _parseCoNumber(b['co_number']?.toString());
      if (aCoNum != bCoNum) return aCoNum.compareTo(bCoNum);
      return ((a['co_detail_id']?.toString() ?? '').compareTo(b['co_detail_id']?.toString() ?? ''));
    }

    // Increment next to its parent original (same quote_service_id)
    if (aIsIncrement) {
      if (b['line_type'] == 'service' && b['quote_service_id'] == a['quote_service_id']) return 1;
      return -1; // increment before other items
    }
    if (bIsIncrement) {
      if (a['line_type'] == 'service' && a['quote_service_id'] == b['quote_service_id']) return -1;
      return 1;
    }

    final aIsCO = aType >= 3;
    final bIsCO = bType >= 3;

    // CO lines: group by co_number first (each CO with its sub-lines)
    if (aIsCO && bIsCO) {
      final aNum = _parseCoNumber(a['co_number']?.toString());
      final bNum = _parseCoNumber(b['co_number']?.toString());
      if (aNum != bNum) return aNum.compareTo(bNum);
      return aType.compareTo(bType); // header (3) before detail (4)
    }

    // Mixed: non-CO always before CO (unless increment was handled above)
    if (aIsCO) return 1;
    if (bIsCO) return -1;

    // Non-CO lines: sort by type group then sort_order
    if (aType != bType) return aType.compareTo(bType);
    return ((a['sort_order'] as num?)?.toInt() ?? 0)
        .compareTo((b['sort_order'] as num?)?.toInt() ?? 0);
  }

  Future<void> _linkChangeOrders() async {
    final svc = ref.read(billingServiceProvider);
    final allCOs = await svc.getChangeOrders(widget.projectId);
    final approved = allCOs.where((co) => co['status'] == 'approved').toList();
    // Sort chronologically (oldest first) so CO blocks appear in order
    approved.sort((a, b) {
      final aDate = a['created_at'] ?? '';
      final bDate = b['created_at'] ?? '';
      return aDate.toString().compareTo(bDate.toString());
    });

    if (approved.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No approved Change Orders available', style: GoogleFonts.manrope())),
        );
      }
      return;
    }

    // Get COs already linked to other invoices
    final linkedResult = await Supabase.instance.client
        .from('invoice_change_order_links')
        .select('change_order_id');
    final alreadyLinked = linkedResult.map((r) => r['change_order_id'].toString()).toSet();
    final available = approved.where((co) => !alreadyLinked.contains(co['id'].toString()) || _linkedCoIds.contains(co['id'].toString())).toList();

    if (!mounted) return;

    final selectedIds = Set<String>.from(_linkedCoIds);
    final result = await showSafeDialog<Set<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Link Change Orders', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
          content: SizedBox(
            width: 400,
            child: available.isEmpty
                ? Text('No approved Change Orders available', style: GoogleFonts.manrope(color: AppTheme.slate500))
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: available.map((co) => CheckboxListTile(
                      dense: true,
                      title: Text(co['co_number'] ?? '', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text('\$${_fmt.format((co['adjustment_amount'] as num?)?.toDouble() ?? 0)} — ${co['title'] ?? ''}',
                          style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate500)),
                      value: selectedIds.contains(co['id'] as String),
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            selectedIds.add(co['id'] as String);
                          } else {
                            selectedIds.remove(co['id'] as String);
                          }
                        });
                      },
                    )).toList(),
                  ),
                ),
              ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, selectedIds), child: const Text('Apply')),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _lines.removeWhere((l) => (l['line_type'] == 'change_order_header' || l['line_type'] == 'change_order_detail') && !result.contains(l['co_id']));
        _coTypeMap.removeWhere((k, v) => !_linkedCoIds.any((cid) => _coTypeMap[k] == cid));
      });

      for (final co in approved) {
        final coId = co['id'] as String;
        final coNumber = co['co_number']?.toString() ?? '';
        if (result.contains(coId) && !_lines.any((l) => l['co_id'] == coId)) {
          _coTypeMap[coNumber] = co['co_type']?.toString() ?? '';
          final coDetails = await svc.getChangeOrderDetails(coId);
          final adjAmount = (co['adjustment_amount'] as num?)?.toDouble() ?? 0;

          setState(() {
            // Header line
            _lines.add({
              'quote_service_id': null,
              'line_type': 'change_order_header',
              'co_id': coId,
              'change_order_id': coId,
              'co_number': co['co_number']?.toString() ?? '',
              'service_name': 'CO: ${co['co_number'] ?? coId} — ${co['title'] ?? ''}',
              'unit_of_measure': '',
              'scheduled_value': adjAmount,
              'previous_completed': 0,
              'this_period_qty': 0,
              'this_period_amount': adjAmount,
              'equipment_present': 0,
            });

            // Detail sub-lines
            for (final d in coDetails) {
              final lt = d['line_type']?.toString() ?? '';
              final isStandbyLabor = lt == 'standby_labor';
              final isStandbyMachinery = lt == 'standby_machinery';
              final isStandbyMaterial = lt == 'standby_material';
              final isStandbyLine = isStandbyLabor || isStandbyMachinery || isStandbyMaterial;

              final qty = isStandbyMaterial
                  ? ((d['quantity_lost'] as num?)?.toDouble() ?? 0)
                  : (isStandbyLine
                      ? ((d['standby_hours'] as num?)?.toDouble() ?? 0)
                      : ((d['quantity_change'] as num?)?.toDouble() ?? 0));
              final up = isStandbyLine
                  ? ((d['standby_rate'] as num?)?.toDouble() ?? (d['replacement_unit_cost'] as num?)?.toDouble() ?? 0)
                  : ((d['unit_price'] as num?)?.toDouble() ?? 0);
              final total = (d['total_change'] as num?)?.toDouble() ?? (qty * up);
              final typeLabel = lt == 'deduction' ? 'Deduct' : (lt == 'new_service' ? 'New' : '');
              final unitStr = isStandbyLine ? 'hrs' : (d['unit_of_measure']?.toString() ?? '');
              final qtyStr = isStandbyLine
                  ? qty.toStringAsFixed(0)
                  : (qty >= 0 ? '+${qty.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}' : qty.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), ''));
              _lines.add({
                'quote_service_id': null,
                'line_type': 'change_order_detail',
                'co_id': coId,
                'change_order_id': coId,
                'co_number': co['co_number']?.toString() ?? '',
                'service_name': '  ${typeLabel.isNotEmpty ? '$typeLabel: ' : ''}${d['service_name'] ?? ''} ($qtyStr $unitStr × \$${_fmt.format(up)})',
                'unit_of_measure': unitStr,
                'scheduled_value': total,
                'previous_completed': 0,
                'this_period_qty': 0,
                'this_period_amount': total,
                'equipment_present': 0,
              });
            }
          });
        }
      }

      setState(() {
        _linkedCoIds
          ..clear()
          ..addAll(result);
        _sortLines();
        _isDirty = true;
      });
    }
  }

  Future<void> _printPdf() async {
    if (_invoice == null) return;
    final project = await Supabase.instance.client
        .from('projects')
        .select('title, client_name')
        .eq('id', widget.projectId)
        .single();

    final allDeductions = <Map<String, dynamic>>[];
    for (final entry in _machinerySelections.entries) {
      allDeductions.addAll(entry.value);
    }

    final pdfBytes = await InvoicePdfGenerator.generate(
      invoice: _invoice!,
      lines: _lines,
      projectTitle: project['title'] ?? '',
      clientName: project['client_name'] ?? '',
      machineryDeductions: allDeductions,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'PayApp_${_invoice?['invoice_number'] ?? 'draft'}',
    );
  }

  Future<void> _downloadExcel() async {
    if (_invoice == null) return;
    final allDeductions = <Map<String, dynamic>>[];
    for (final entry in _machinerySelections.entries) {
      allDeductions.addAll(entry.value);
    }
    final bytes = InvoiceExcelGenerator.generate(
        invoice: _invoice!, lines: _lines, machineryDeductions: allDeductions);

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
    final List<Widget> actionButtons = [
      if (_invoice?['status'] == 'submitted') ...[
        ElevatedButton.icon(
          onPressed: _isCompleted ? null : _markAsPaid,
          icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
          label: Text('Mark as Paid', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
        const SizedBox(width: 8),
      ],
      if (!isSubmitted) ...[
        ElevatedButton.icon(
          onPressed: _isCompleted || _isSaving ? null : _save,
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
          onPressed: _isCompleted || _isSaving ? null : _submit,
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
      if (!isNew) ...[
        OutlinedButton.icon(
          onPressed: _isSaving ? null : _refreshFromReports,
          icon: const Icon(Icons.refresh, size: 16),
          label: Text('Refresh', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryGreen,
            side: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.3)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppTheme.slate200))),
      child: isMobile
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
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
                    const Spacer(),
                    Text(
                      isNew ? 'New Pay Application' : _invoice?['invoice_number'] ?? '',
                      style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate900),
                    ),
                  ],
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: actionButtons),
                ),
                const SizedBox(height: 4),
              ],
            )
          : Row(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.go('/projects/${widget.projectId}/billing'),
                    child: const Icon(Icons.arrow_back, size: 18, color: AppTheme.slate500),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Billing', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate500)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.chevron_right, size: 16, color: AppTheme.slate400),
                ),
                Text(isNew ? 'New Pay Application' : _invoice?['invoice_number'] ?? '',
                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate900)),
                const Spacer(),
                ...actionButtons,
              ],
            ),
    );
  }

  Widget _buildContent(bool isMobile, bool isSubmitted) {
    return CompletedProjectBanner(
      projectId: widget.projectId,
      isCompletedCallback: (completed) {
        if (completed != _isCompleted) setState(() => _isCompleted = completed);
      },
      child: SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContractSummary(isMobile, isSubmitted),
          const SizedBox(height: 24),
          _buildPayAppTable(isMobile, isSubmitted),
        ],
      ),
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
          if (!isSubmitted && cosTotal > 0) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _linkChangeOrders,
              icon: const Icon(Icons.link, size: 16),
              label: Text('Link Change Orders${_linkedCoIds.isNotEmpty ? ' (${_linkedCoIds.length})' : ''}',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                side: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
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

    int mainSeq = 0;
    int? coHeaderSeq;

    for (int i = 0; i < _lines.length; i++) {
      final l = _lines[i];
      final lt = l['line_type']?.toString() ?? '';
      final coSeg = l['co_segment']?.toString();

      bool isRpcIncrement = lt == 'change_order_detail' && coSeg == 'increment';
      bool isLegacyHeader = lt == 'change_order_header';
      bool isLegacyDetail = lt == 'change_order_detail' && !isRpcIncrement;

      // Skip legacy detail rows — they're rendered as children of the header
      if (isLegacyDetail) continue;

      // Collect detail children for this CO header (if any)
      List<Map<String, dynamic>> detailChildren = [];
      String? coNumber;
      if (isLegacyHeader) {
        coNumber = l['co_number']?.toString() ?? '';
        // Find all detail rows sharing this co_number until the next header or end
        int j = i + 1;
        while (j < _lines.length) {
          final next = _lines[j];
          final nextLt = next['line_type']?.toString() ?? '';
          if (nextLt == 'change_order_header') break;
          if (nextLt == 'change_order_detail' && (next['co_segment']?.toString() ?? '') != 'increment') {
            final nextCoNum = next['co_number']?.toString() ?? '';
            if (nextCoNum == coNumber || nextCoNum.isEmpty) {
              detailChildren.add(Map<String, dynamic>.from(next));
            }
          }
          j++;
        }
      }

      // --- Render row ---
      String rowNumber;
      final coType = (coNumber != null) ? _coTypeMap[coNumber] : null;
      final isDisruptionCO = coType == 'disruption';
      bool isCOParent = isLegacyHeader && isDisruptionCO;
      bool isScopeCO = isLegacyHeader && !isDisruptionCO;

      // For scope_change COs: merge header with its first detail into single row
      Map<String, dynamic> effectiveLine = l;
      if (isScopeCO && detailChildren.isNotEmpty) {
        final detail = detailChildren.first;
        final qtyChange = detail['quantity_change']?.toString() ?? '';
        final unitPrice = l['unit_price']?.toString() ?? (detail['unit_price']?.toString() ?? '');
        effectiveLine = Map<String, dynamic>.from(l);
        effectiveLine['service_name'] = 'CO: ${detail['service_name'] ?? ''} (+$qtyChange ${detail['unit_of_measure'] ?? ''}' +
            (unitPrice.isNotEmpty ? ' × \$${unitPrice}' : '') + ') ' + (coNumber ?? '');
        effectiveLine['scheduled_value'] = detail['scheduled_value'] ?? l['scheduled_value'];
        effectiveLine['this_period_amount'] = detail['this_period_amount'] ?? l['this_period_amount'];
        effectiveLine['previous_completed'] = detail['previous_completed'] ?? l['previous_completed'];
        effectiveLine['line_type'] = 'change_order_detail';
        isRpcIncrement = true;
        isCOParent = false;
        detailChildren.clear();
      }

      // Use isScopeCO to skip when already handled (only for non-disruption)
      if (isScopeCO && !isRpcIncrement) {
        mainSeq++;
        continue; // already handled via merged effectiveLine or skip orphan
      }

      if (isCOParent) {
        mainSeq++;
        rowNumber = '$mainSeq';
      } else if (isRpcIncrement) {
        mainSeq++;
        rowNumber = '$mainSeq';
      } else {
        mainSeq++;
        rowNumber = '$mainSeq';
      }

      final sv = (effectiveLine['scheduled_value'] as num?)?.toDouble() ?? 0;
      final tpAmt = (effectiveLine['this_period_amount'] as num?)?.toDouble() ?? 0;
      final prev = (effectiveLine['previous_completed'] as num?)?.toDouble() ?? 0;
      final eq = (effectiveLine['equipment_present'] as num?)?.toDouble() ?? 0;
      final tc = tpAmt + prev + eq;
      final bal = sv - tc;
      final ret = effectiveLine['line_type'] == 'equipment' ? 0.0 : (tpAmt + prev) * _retainageRate / 100;
      final ttp = effectiveLine['line_type'] == 'equipment' ? 0.0 : (tpAmt + prev) - ret;

      final qsId = l['quote_service_id']?.toString();
      final hasMachinery = lt == 'service' && qsId != null && (_machineryByService[qsId]?.isNotEmpty ?? false);
      final isMachExpanded = hasMachinery && _expandedServices.contains(qsId);
      final isCOExpanded = isCOParent && _expandedCOs.contains(coNumber ?? '');

      // Only add to totals if NOT a collapsed CO parent (header sums include children)
      // RPC increment rows DO add to totals (they're independent billable items)
      bool addToTotals = !isCOParent || !isCOExpanded;
      if (addToTotals) {
        tSv += sv; tTp += tpAmt; tPrev += prev; tEq += eq;
        tTc += tc; tBal += bal; tRet += ret; tThis += ttp;
      }

      rows.add(DataRow(
        color: isRpcIncrement || lt == 'change_order_detail'
            ? MaterialStateProperty.all(AppTheme.primaryGreen.withOpacity(0.06))
            : null,
        cells: [
        DataCell(
          hasMachinery
              ? InkWell(
                  onTap: () => _toggleServiceExpansion(qsId!),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(isMachExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                        size: 16, color: AppTheme.primaryGreen),
                    const SizedBox(width: 2),
                    Text(rowNumber, style: GoogleFonts.manrope(fontSize: 11)),
                  ]),
                )
              : isCOParent && detailChildren.isNotEmpty
                  ? InkWell(
                      onTap: () => _toggleCOExpansion(coNumber!),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(isCOExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                            size: 16, color: Colors.orange.shade700),
                        const SizedBox(width: 2),
                        Text(rowNumber, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                    )
                  : Text(rowNumber, style: GoogleFonts.manrope(fontSize: 11)),
        ),
        DataCell(
          isRpcIncrement
              ? Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Text(effectiveLine['service_name'] ?? '',
                      style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic)),
                )
              : Text(effectiveLine['service_name'] ?? '', style: GoogleFonts.manrope(fontSize: 11,
                  fontWeight: isCOParent ? FontWeight.w700 : FontWeight.w600)),
        ),
        DataCell(Text('\$${_fmt.format(sv)}', style: GoogleFonts.manrope(fontSize: 11))),
        DataCell(
          isSubmitted || isCOParent || isRpcIncrement
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
          isSubmitted || isCOParent || isRpcIncrement || hasMachinery
              ? Text(eq < 0 ? '-\$${_fmt.format(-eq)}' : '\$${_fmt.format(eq)}',
                  style: GoogleFonts.manrope(fontSize: 11,
                      fontWeight: eq < 0 ? FontWeight.w700 : FontWeight.w400,
                      color: eq < 0 ? AppTheme.errorRed : null))
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

      // --- CO detail children (expandable) ---
      if (isCOParent && isCOExpanded && coNumber != null) {
        int childSeq = 0;
        for (final child in detailChildren) {
          childSeq++;
          final cSv = (child['scheduled_value'] as num?)?.toDouble() ?? 0;
          final cTpAmt = (child['this_period_amount'] as num?)?.toDouble() ?? 0;
          final cPrev = (child['previous_completed'] as num?)?.toDouble() ?? 0;
          final cEq = (child['equipment_present'] as num?)?.toDouble() ?? 0;
          final cTc = cTpAmt + cPrev + cEq;
          final cBal = cSv - cTc;
          final cRet = (cTpAmt + cPrev) * _retainageRate / 100;
          final cTtp = (cTpAmt + cPrev) - cRet;

          rows.add(DataRow(
            color: MaterialStateProperty.all(Colors.orange.withOpacity(0.04)),
            cells: [
              DataCell(Text('$mainSeq.$childSeq', style: GoogleFonts.manrope(fontSize: 10, color: AppTheme.slate500))),
              DataCell(Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(child['service_name'] ?? '', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.slate600, fontStyle: FontStyle.italic)),
              )),
              DataCell(Text('\$${_fmt.format(cSv)}', style: GoogleFonts.manrope(fontSize: 10, color: AppTheme.slate500))),
              DataCell(Text('\$${_fmt.format(cTpAmt)}', style: GoogleFonts.manrope(fontSize: 10, color: AppTheme.slate500))),
              DataCell(Text('\$${_fmt.format(cPrev)}', style: GoogleFonts.manrope(fontSize: 10, color: AppTheme.slate500))),
              DataCell(Text('\$${_fmt.format(cEq)}', style: GoogleFonts.manrope(fontSize: 10, color: AppTheme.slate500))),
              DataCell(Text('\$${_fmt.format(cTc)}', style: GoogleFonts.manrope(fontSize: 10, color: AppTheme.slate500))),
              DataCell(Text('\$${_fmt.format(cBal)}', style: GoogleFonts.manrope(fontSize: 10, color: AppTheme.slate500))),
              DataCell(Text('\$${_fmt.format(cRet)}', style: GoogleFonts.manrope(fontSize: 10, color: AppTheme.slate500))),
              DataCell(Text('\$${_fmt.format(cTtp)}', style: GoogleFonts.manrope(fontSize: 10, color: AppTheme.slate500))),
            ],
          ));
        }
      }

      // --- Machinery expansion (unchanged) ---
      if (isMachExpanded && qsId != null) {
        final machines = _machineryByService[qsId] ?? [];
        for (final m in machines) {
          final inspectionId = m['machinery_inspection_id']?.toString() ?? '';
          final mName = m['machine_name']?.toString() ?? 'Machine';
          final internalCode = m['internal_code']?.toString() ?? '';
          final brandModel = m['brand_model']?.toString() ?? '';
          final subLabel = internalCode.isNotEmpty
              ? internalCode
              : (brandModel.isNotEmpty ? brandModel : mName);
          final dailyRate = (m['daily_rental_rate'] as num?)?.toDouble() ?? 0;
          final dedAmount = (m['deduction_amount'] as num?)?.toDouble() ?? 0;
          final isSelected = _machinerySelections[qsId]?.any((s) =>
            s['machinery_inspection_id']?.toString() == inspectionId) ?? false;
          final monthlyRent = (m['monthly_rent_cost'] as num?)?.toDouble() ?? 0;

          rows.add(DataRow(
            color: MaterialStateProperty.all(AppTheme.primaryGreen.withOpacity(0.04)),
            cells: [
              DataCell(const SizedBox.shrink()),
              DataCell(Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (!isSubmitted)
                    SizedBox(
                      width: 24, height: 24,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (v) => _toggleMachinerySelection(qsId!, m, v ?? false),
                        activeColor: AppTheme.primaryGreen,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(subLabel, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.slate700)),
                      if (brandModel.isNotEmpty && internalCode.isNotEmpty)
                        Text(brandModel, style: GoogleFonts.manrope(fontSize: 9, color: AppTheme.slate500)),
                      Text('\$${_fmt.format(monthlyRent)}/mo \u2192 \$${dailyRate.toStringAsFixed(2)}/day × $_daysInPeriod days',
                          style: GoogleFonts.manrope(fontSize: 9, color: AppTheme.slate400)),
                    ]),
                  ),
                ]),
              )),
              const DataCell(Text('')),
              const DataCell(Text('')),
              const DataCell(Text('')),
              DataCell(Text('-\$${_fmt.format(dedAmount)}',
                  style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.errorRed))),
              const DataCell(Text('')),
              const DataCell(Text('')),
              const DataCell(Text('')),
              DataCell(Text('-\$${_fmt.format(dedAmount)}',
                  style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.errorRed))),
            ],
          ));
        }
      }
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
