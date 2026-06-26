import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../providers/change_order_providers.dart';
import '../providers/change_order_controller.dart';
import '../../../../shared/widgets/sidebar.dart';
import 'package:noel_ui_components/noel_ui_components.dart';

class ChangeOrderFormPage extends ConsumerStatefulWidget {
  final String projectId;
  final String? coId;

  const ChangeOrderFormPage({super.key, required this.projectId, this.coId});

  bool get isEditing => coId != null;

  @override
  ConsumerState<ChangeOrderFormPage> createState() => _ChangeOrderFormPageState();
}

class _ChangeOrderFormPageState extends ConsumerState<ChangeOrderFormPage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _schedDays = 0;
  bool _saving = false;
  bool _loadingData = false;

  final _lines = <Map<String, dynamic>>[];
  final _fmt = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadData();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  double get _totalAdjustment => _lines.fold(0.0, (s, l) {
    final qty = (l['quantity_change'] as num?)?.toDouble() ?? 0;
    final up = (l['unit_price'] as num?)?.toDouble() ?? 0;
    return s + (qty * up);
  });

  bool get _isEditing => widget.isEditing;

  Future<void> _loadData() async {
    setState(() => _loadingData = true);
    try {
      final co = await ref.read(changeOrderDetailProvider(widget.coId!).future);
      final details = co['details'] as List<dynamic>? ?? [];

      _titleCtrl.text = co['title'] ?? '';
      _descCtrl.text = co['description'] ?? '';
      _schedDays = (co['schedule_days_change'] as num?)?.toInt() ?? 0;
      _lines.clear();
      for (final d in details) {
        _lines.add(Map<String, dynamic>.from(d as Map));
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingData = false);
  }

  Future<void> _addExistingService() async {
    final services = await ref.read(quoteServiceListProvider(widget.projectId).future);
    if (!mounted) return;

    final selected = await showSafeDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (ctx) => SimpleDialog(
        title: Text('Select Service', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
        children: services.map((s) => SimpleDialogOption(
          onPressed: () => Navigator.of(ctx).pop(s),
          child: ListTile(
            dense: true,
            title: Text(s['name'] ?? '', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text('${s['unit_of_measure'] ?? ''}', style: GoogleFonts.manrope(fontSize: 11)),
          ),
        )).toList(),
      ),
    );

    if (selected != null && mounted) {
      _showLineEditor(
        serviceName: selected['name'] ?? '',
        unitOfMeasure: selected['unit_of_measure'] ?? 'und',
        quoteServiceId: selected['id'] as String?,
        lineType: 'existing_service',
      );
    }
  }

  Future<void> _addNewService() async {
    final catalog = await ref.read(servicesCatalogProvider.future);
    if (!mounted) return;

    final selected = await showSafeDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (ctx) => SimpleDialog(
        title: Text('Select from Catalog', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
        children: catalog.map((s) => SimpleDialogOption(
          onPressed: () => Navigator.of(ctx).pop(s),
          child: ListTile(
            dense: true,
            title: Text(s['description'] ?? '', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text(s['unit'] ?? '', style: GoogleFonts.manrope(fontSize: 11)),
          ),
        )).toList(),
      ),
    );

    if (selected != null && mounted) {
      _showLineEditor(
        serviceName: selected['description'] ?? '',
        unitOfMeasure: selected['unit'] ?? 'und',
        catalogServiceId: selected['id'] as String?,
        lineType: 'new_service',
      );
    }
  }

  Future<void> _showLineEditor({
    required String serviceName,
    required String unitOfMeasure,
    String? quoteServiceId,
    String? catalogServiceId,
    String lineType = 'existing_service',
    Map<String, dynamic>? existing,
  }) async {
    final qtyCtrl = TextEditingController(text: existing?['quantity_change']?.toString() ?? '0');
    final priceCtrl = TextEditingController(text: existing?['unit_price']?.toString() ?? '0');
    String type = existing?['line_type'] ?? lineType;

    final result = await showSafeDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(serviceName, style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'existing_service', child: Text('Increase/Decrease Existing')),
                  DropdownMenuItem(value: 'new_service', child: Text('Add New Service')),
                  DropdownMenuItem(value: 'deduction', child: Text('Deduction')),
                ],
                onChanged: (v) => type = v ?? 'existing_service',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(labelText: 'Quantity Change (+/-)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'Unit Price (\$)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(qtyCtrl.text) ?? 0;
              final price = double.tryParse(priceCtrl.text) ?? 0;
              Navigator.of(ctx).pop({
                'service_name': serviceName,
                'unit_of_measure': unitOfMeasure,
                'quote_service_id': quoteServiceId,
                'catalog_service_id': catalogServiceId,
                'line_type': type,
                'quantity_change': qty,
                'unit_price': price,
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (existing != null) {
          final idx = _lines.indexOf(existing);
          if (idx >= 0) _lines[idx] = result;
        } else {
          _lines.add(result);
        }
      });
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Title is required', style: GoogleFonts.manrope()), backgroundColor: AppTheme.errorRed),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final controller = ref.read(changeOrderControllerProvider.notifier);

      if (_isEditing) {
        await controller.updateChangeOrder(widget.coId!, {
          'title': _titleCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'schedule_days_change': _schedDays,
        });

        if (_lines.isNotEmpty) {
          await controller.saveDetails(widget.coId!, _lines);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Change Order updated', style: GoogleFonts.manrope(color: Colors.white)), backgroundColor: AppTheme.primaryGreen),
          );
          context.go('/projects/${widget.projectId}/change-orders/${widget.coId}');
        }
      } else {
        final co = await controller.createChangeOrder({
          'project_id': widget.projectId,
          'title': _titleCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'executed_date': DateTime.now().toIso8601String().split('T')[0],
          'original_contract_amount': 0,
          'schedule_days_change': _schedDays,
          'created_by': Supabase.instance.client.auth.currentUser?.id,
        });

        if (_lines.isNotEmpty) {
          await controller.saveDetails(co['id'], _lines);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Change Order created', style: GoogleFonts.manrope(color: Colors.white)), backgroundColor: AppTheme.primaryGreen),
          );
          context.go('/projects/${widget.projectId}/change-orders/${co['id']}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.manrope()), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userName = currentUser?.userMetadata?['name'] ?? 'Admin';
    final userEmail = currentUser?.email ?? '';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1250;

    if (_loadingData) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

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
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: _buildForm(isMobile),
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
            Text(_isEditing ? 'Edit' : 'New', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate900)),
          ],
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save, size: 18, color: Colors.white),
            label: Text('Save', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white)),
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

  Widget _buildForm(bool isMobile) {
    return Column(
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
              Text(_isEditing ? 'Edit Change Order' : 'New Change Order', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
              const SizedBox(height: 20),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title *'),
                style: GoogleFonts.manrope(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description of Change'),
                maxLines: 4,
                style: GoogleFonts.manrope(),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(labelText: 'Schedule Days Change (+/-)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => _schedDays = int.tryParse(v) ?? 0,
                style: GoogleFonts.manrope(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
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
              Row(
                children: [
                  Text('Line Items', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _addExistingService,
                    icon: const Icon(Icons.edit, size: 16),
                    label: Text('Add Existing Service', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      side: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _addNewService,
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: Text('Add New Service', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      side: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_lines.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text('No line items yet. Add services to modify.', style: GoogleFonts.manrope(color: AppTheme.slate500))),
                )
              else ...[
                if (isMobile)
                  Column(children: _lines.asMap().entries.map((e) => _lineCard(e.key, e.value)).toList())
                else
                  _linesTable(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Total Adjustment: \$${_fmt.format(_totalAdjustment)}', style: GoogleFonts.manrope(
                fontSize: 18, fontWeight: FontWeight.w800,
                color: _totalAdjustment >= 0 ? AppTheme.primaryGreen : AppTheme.errorRed,
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _linesTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Service', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
          DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
          DataColumn(label: Text('Qty Change', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), numeric: true),
          DataColumn(label: Text('Unit Price', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), numeric: true),
          DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), numeric: true),
          DataColumn(label: Text('', style: TextStyle(fontSize: 12))),
        ],
        rows: _lines.asMap().entries.map((e) {
          final i = e.key;
          final l = e.value;
          final qty = (l['quantity_change'] as num?)?.toDouble() ?? 0;
          final up = (l['unit_price'] as num?)?.toDouble() ?? 0;
          return DataRow(cells: [
            DataCell(Text(l['service_name'] ?? '', style: GoogleFonts.manrope(fontSize: 12))),
            DataCell(Text(l['line_type']?.toString().replaceAll('_', ' ') ?? '', style: GoogleFonts.manrope(fontSize: 11))),
            DataCell(Text(qty.toString(), style: GoogleFonts.manrope(fontSize: 12))),
            DataCell(Text('\$${_fmt.format(up)}', style: GoogleFonts.manrope(fontSize: 12))),
            DataCell(Text('\$${_fmt.format(qty * up)}', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700))),
            DataCell(IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorRed),
              onPressed: () => setState(() => _lines.removeAt(i)),
            )),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _lineCard(int i, Map<String, dynamic> l) {
    final qty = (l['quantity_change'] as num?)?.toDouble() ?? 0;
    final up = (l['unit_price'] as num?)?.toDouble() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(l['service_name'] ?? '', style: GoogleFonts.manrope(fontWeight: FontWeight.w700))),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.errorRed),
              onPressed: () => setState(() => _lines.removeAt(i)),
            ),
          ]),
          Text('${l['line_type']?.toString().replaceAll('_', ' ') ?? ''} | Qty: $qty | \$${_fmt.format(up)} | Total: \$${_fmt.format(qty * up)}',
              style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate500)),
        ],
      ),
    );
  }
}
