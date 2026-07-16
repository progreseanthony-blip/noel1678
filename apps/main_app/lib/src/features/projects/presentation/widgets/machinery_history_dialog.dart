import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'machinery_reception_dialog.dart';

class MachineryHistoryDialog extends StatefulWidget {
  final String projectId;
  final String projectMachineryId;
  final String machineryName;
  final String serviceName;

  const MachineryHistoryDialog({
    super.key,
    required this.projectId,
    required this.projectMachineryId,
    required this.machineryName,
    required this.serviceName,
  });

  @override
  State<MachineryHistoryDialog> createState() => _MachineryHistoryDialogState();
}

class _MachineryHistoryDialogState extends State<MachineryHistoryDialog> {
  List<Map<String, dynamic>> _inspections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('machinery_inspections')
          .select()
          .eq('project_machinery_id', widget.projectMachineryId)
          .order('received_at', ascending: false);
          
      final data = List<Map<String, dynamic>>.from(res ?? []);
      
      // Fetch user names manually to avoid auth.users join issues
      if (data.isNotEmpty) {
        final userIds = data.map((e) => e['received_by']).where((id) => id != null).toSet().toList();
        if (userIds.isNotEmpty) {
          final profilesRes = await Supabase.instance.client
              .from('profiles')
              .select('id, name')
              .filter('id', 'in', userIds);
              
          final profilesMap = {for (var p in profilesRes) p['id']: p['name']};
          for (var item in data) {
            item['inspector_name'] = profilesMap[item['received_by']] ?? 'Unknown';
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _inspections = data;
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _demobilizeMachinery(String inspectionId) async {
    final hmController = TextEditingController();
    final result = await showSafeDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => AlertDialog(
        title: Text('Demobilize Machine', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter the final hour meter reading (optional):', style: GoogleFonts.manrope(fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: hmController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Final Hour Meter',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await Supabase.instance.client
                    .from('machinery_inspections')
                    .update({
                      'returned_at': DateTime.now().toUtc().toIso8601String(),
                      if (hmController.text.isNotEmpty) 'hour_meter_end': double.tryParse(hmController.text),
                    })
                    .eq('id', inspectionId);
                if (mounted) Navigator.pop(context, true);
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            child: const Text('Confirm Return', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadHistory();
    }
  }

  void _openEditDialog(String inspectionId) {
    showSafeDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => MachineryReceptionDialog(
        projectId: widget.projectId,
        projectMachineryId: widget.projectMachineryId,
        machineryName: widget.machineryName,
        serviceName: widget.serviceName,
        inspectionId: inspectionId,
      ),
    ).then((updated) {
      if (updated == true) {
        _loadHistory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 650,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.history, color: AppTheme.primaryGreen, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reception History', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
                            const SizedBox(height: 4),
                            Text(widget.machineryName, style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate500, height: 1.0)),
                          ],
                        ),
                      ],
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(true),
                        child: const Icon(Icons.close, color: AppTheme.slate400, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Body
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                : _inspections.isEmpty
                  ? Center(child: Text('No receptions recorded yet.', style: GoogleFonts.manrope(color: AppTheme.slate500)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: _inspections.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final item = _inspections[index];
                        final dateStr = item['received_at'] != null 
                          ? DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.parse(item['received_at']).toLocal())
                          : '-';
                        final inspectorName = item['inspector_name'] ?? 'Unknown';
                        final photos = (item['evidence_photos'] as List?) ?? [];

                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.slate200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(dateStr, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate900)),
                                  Row(
                                    children: [
                                      if (item['returned_at'] == null)
                                        TextButton.icon(
                                          onPressed: () => _demobilizeMachinery(item['id']),
                                          icon: const Icon(Icons.outbound_outlined, size: 16, color: Colors.orange),
                                          label: Text('Return', style: GoogleFonts.manrope(color: Colors.orange, fontWeight: FontWeight.bold)),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            backgroundColor: Colors.orange.withOpacity(0.05),
                                          ),
                                        ),
                                      if (item['returned_at'] == null) const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: () => _openEditDialog(item['id']),
                                        icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.primaryGreen),
                                        label: Text('Edit', style: GoogleFonts.manrope(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          backgroundColor: AppTheme.primaryGreen.withOpacity(0.05),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _infoChip('Serial: ${item['internal_code'] ?? '-'}'),
                                  const SizedBox(width: 8),
                                  _infoChip('HM Start: ${item['hour_meter_start'] ?? '-'}'),
                                  if (item['hour_meter_end'] != null) ...[
                                    const SizedBox(width: 8),
                                    _infoChip('HM End: ${item['hour_meter_end']}'),
                                  ],
                                  const SizedBox(width: 8),
                                  _infoChip('Cond: ${item['condition_status'] ?? '-'}'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text('Inspector: $inspectorName', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500)),
                              if (item['observations'] != null && item['observations'].toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text('Notes: ${item['observations']}', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate600)),
                              ],
                              if (item['returned_at'] != null) ...[
                                const SizedBox(height: 8),
                                Text('Returned: ${DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.parse(item['returned_at']).toLocal())}', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
                              ],
                              if (photos.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 60,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: photos.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                                    itemBuilder: (context, photoIndex) {
                                      return Container(
                                        width: 60,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          image: DecorationImage(image: NetworkImage(photos[photoIndex].toString()), fit: BoxFit.cover),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.slate600)),
    );
  }
}
