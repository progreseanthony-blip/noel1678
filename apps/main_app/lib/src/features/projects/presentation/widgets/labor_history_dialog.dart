import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_ui_components/noel_ui_components.dart';

class LaborHistoryDialog extends StatefulWidget {
  final String projectLaborId;
  final String roleName;

  const LaborHistoryDialog({
    super.key,
    required this.projectLaborId,
    required this.roleName,
  });

  @override
  State<LaborHistoryDialog> createState() => _LaborHistoryDialogState();
}

class _LaborHistoryDialogState extends State<LaborHistoryDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _activeCheckins = [];
  List<Map<String, dynamic>> _pastCheckins = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      
      final result = await supabase
          .from('labor_checkins')
          .select('*, workers(full_name, id_number), project_tasks(name)')
          .eq('project_labor_id', widget.projectLaborId)
          .order('check_in', ascending: false);

      final all = List<Map<String, dynamic>>.from(result);
      
      if (mounted) {
        setState(() {
          _activeCheckins = all.where((c) => c['status'] == 'active').toList();
          _pastCheckins = all.where((c) => c['status'] == 'completed').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e')),
        );
      }
    }
  }

  Future<void> _handleCheckOut(String checkinId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('labor_checkins').update({
        'status': 'completed',
        'check_out': DateTime.now().toIso8601String(),
      }).eq('id', checkinId);

      _loadHistory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during check-out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 600,
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                            Text(
                              'Personnel Management',
                              style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.roleName,
                              style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate500, height: 1.0),
                            ),
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
                  : DefaultTabController(
                      length: 2,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        child: Column(
                          children: [
                            TabBar(
                              labelColor: AppTheme.primaryGreen,
                              unselectedLabelColor: AppTheme.slate500,
                              indicatorColor: AppTheme.primaryGreen,
                              labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                              tabs: [
                                Tab(text: 'Active (${_activeCheckins.length})'),
                                const Tab(text: 'Past Logs'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _buildActiveList(),
                                  _buildPastList(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveList() {
    if (_activeCheckins.isEmpty) {
      return Center(child: Text('No active workers in this role.', style: GoogleFonts.manrope(color: AppTheme.slate400)));
    }
    return ListView.builder(
      itemCount: _activeCheckins.length,
      itemBuilder: (context, index) {
        final c = _activeCheckins[index];
        final w = c['workers'];
        final checkIn = DateTime.parse(c['check_in']);
        
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppTheme.slate200)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                  child: Text(w['full_name'][0], style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w['full_name'], style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          const Icon(Icons.assignment_outlined, size: 12, color: AppTheme.primaryGreen),
                          const SizedBox(width: 4),
                          Text(
                            c['project_tasks'] != null ? c['project_tasks']['name'] : 'General Activity',
                            style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen),
                          ),
                        ],
                      ),
                      Text('Since: ${DateFormat('HH:mm').format(checkIn.toLocal())}', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _handleCheckOut(c['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    foregroundColor: Colors.red,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Check-out'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPastList() {
    if (_pastCheckins.isEmpty) {
      return Center(child: Text('No past logs found.', style: GoogleFonts.manrope(color: AppTheme.slate400)));
    }
    return ListView.builder(
      itemCount: _pastCheckins.length,
      itemBuilder: (context, index) {
        final c = _pastCheckins[index];
        final w = c['workers'];
        final checkIn = DateTime.parse(c['check_in']);
        final checkOut = c['check_out'] != null ? DateTime.parse(c['check_out']) : null;
        
        return ListTile(
          leading: const Icon(Icons.history, size: 20, color: AppTheme.slate400),
          title: Text(w['full_name'], style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Task: ${c['project_tasks'] != null ? c['project_tasks']['name'] : 'General'}',
                style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate600, fontWeight: FontWeight.w600),
              ),
              Text(
                '${DateFormat('MMM d').format(checkIn)}: ${DateFormat('HH:mm').format(checkIn.toLocal())} - ${checkOut != null ? DateFormat('HH:mm').format(checkOut.toLocal()) : '?'}',
                style: GoogleFonts.manrope(fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }
}
