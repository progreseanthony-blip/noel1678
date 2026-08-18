import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'material_reception_dialog.dart';

class MaterialHistoryDialog extends StatefulWidget {
  final String projectId;
  final String projectMaterialId;
  final String materialName;
  final String serviceName;
  final String unitName;
  final num expectedQuantity;

  const MaterialHistoryDialog({
    super.key,
    required this.projectId,
    required this.projectMaterialId,
    required this.materialName,
    required this.serviceName,
    required this.unitName,
    required this.expectedQuantity,
  });

  @override
  State<MaterialHistoryDialog> createState() => _MaterialHistoryDialogState();
}

class _MaterialHistoryDialogState extends State<MaterialHistoryDialog> {
  List<Map<String, dynamic>> _receptions = [];
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
          .from('material_receptions')
          .select()
          .eq('project_material_id', widget.projectMaterialId)
          .order('received_at', ascending: false);
          
      final data = List<Map<String, dynamic>>.from(res ?? []);
      
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
          _receptions = data;
        });
      }
    } catch (e) {
      debugPrint('Error loading material history: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openEditDialog(String receptionId) {
    showSafeDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      fullscreenOnMobile: true,
      builder: (_) => MaterialReceptionDialog(
        projectId: widget.projectId,
        projectMaterialId: widget.projectMaterialId,
        materialName: widget.materialName,
        serviceName: widget.serviceName,
        unitName: widget.unitName,
        expectedQuantity: widget.expectedQuantity,
        currentReceived: 0, // Not used in edit mode
        receptionId: receptionId,
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
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Center(
                            child: Icon(Icons.history, color: AppTheme.primaryGreen, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Material Reception History', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
                            const SizedBox(height: 4),
                            Text(widget.materialName, style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate500, height: 1.0)),
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
                : _receptions.isEmpty
                  ? Center(child: Text('No material deliveries recorded yet.', style: GoogleFonts.manrope(color: AppTheme.slate500)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: _receptions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final item = _receptions[index];
                        final dateStr = item['received_at'] != null 
                          ? DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.parse(item['received_at']).toLocal())
                          : '-';
                        final inspectorName = item['inspector_name'] ?? 'Unknown';
                        final photos = (item['evidence_photos'] as List?) ?? [];
                        final qty = item['quantity_received'];

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
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _infoChip('+$qty ${widget.unitName}', AppTheme.primaryGreen),
                                  const SizedBox(width: 8),
                                  _infoChip('Inv: ${item['invoice_number'] ?? '-'}', AppTheme.slate600),
                                  const SizedBox(width: 8),
                                  _infoChip('Cond: ${item['condition_status'] ?? '-'}', AppTheme.slate600),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text('Provider: ${item['provider_name'] ?? '-'}', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate700, fontWeight: FontWeight.w600)),
                              Text('Received By: $inspectorName', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500)),
                              if (item['observations'] != null && item['observations'].toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text('Notes: ${item['observations']}', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate600)),
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

  Widget _infoChip(String text, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: textColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: textColor)),
    );
  }
}
