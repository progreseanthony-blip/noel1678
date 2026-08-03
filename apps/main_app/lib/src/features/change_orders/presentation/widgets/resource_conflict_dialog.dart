import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';

class ResourceConflictDialog extends StatefulWidget {
  final String projectId;
  final List<Map<String, dynamic>> conflicts;
  final Future<String?> Function(Map<String, dynamic> conflict, String strategy) onResolve;

  const ResourceConflictDialog({
    super.key,
    required this.projectId,
    required this.conflicts,
    required this.onResolve,
  });

  @override
  State<ResourceConflictDialog> createState() => _ResourceConflictDialogState();
}

class _ResourceConflictDialogState extends State<ResourceConflictDialog> {
  final Map<int, String> _strategies = {};
  final _resolving = <int>{};
  final _resolved = <int>{};

  @override
  Widget build(BuildContext context) {
    final autoResolved = widget.conflicts.where((c) => c['auto_resolved'] == true).toList();
    final manual = widget.conflicts.where((c) => c['auto_resolved'] != true).toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 24),
          const SizedBox(width: 10),
          Text(
            'Resource Conflicts Detected',
            style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.slate900),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${manual.length} conflict(s) require your decision after the schedule shift.',
                style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500),
              ),
              const SizedBox(height: 16),
              if (autoResolved.isNotEmpty) ...[
                _buildAutoResolved(autoResolved),
                const SizedBox(height: 16),
              ],
              ...manual.asMap().entries.map((entry) {
                final i = entry.key;
                final c = entry.value;
                return _buildConflictItem(i, c);
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text('Cancel', style: GoogleFonts.manrope(color: AppTheme.slate500)),
        ),
        ElevatedButton(
          onPressed: _resolving.isNotEmpty ? null : _applyAll,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            _resolving.isNotEmpty ? 'Resolving...' : 'Apply All',
            style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildAutoResolved(List<Map<String, dynamic>> auto) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, size: 14, color: AppTheme.primaryGreen),
              const SizedBox(width: 6),
              Text(
                '${auto.length} auto-resolved',
                style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...auto.map((c) => Padding(
            padding: const EdgeInsets.only(left: 20, top: 2),
            child: Text(
              '${c['resource_type']}: ${_extractName(c)} — cascade applied (${c['overlap_days']} day(s))',
              style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate500),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildConflictItem(int index, Map<String, dynamic> c) {
    final resourceType = c['resource_type'] as String? ?? '';
    final resourceName = _extractName(c);
    final overlapDays = (c['overlap_days'] as num?)?.toInt() ?? 0;
    final strategy = _strategies[index] ?? '';
    final isResolving = _resolving.contains(index);
    final isResolved = _resolved.contains(index);
    final serviceAName = c['service_a_id']?.toString() ?? 'Service A';
    final serviceBName = c['service_b_id']?.toString() ?? 'Service B';

    if (isResolved) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, size: 14, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            Text('$resourceType: $resourceName — resolved', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.primaryGreen)),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, size: 16, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$resourceType: $resourceName',
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Overlap: $overlapDays day(s)',
            style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange.shade700),
          ),
          const SizedBox(height: 10),
          if (isResolving)
            const SizedBox(
              height: 40,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            Column(
              children: [
                RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Keep on affected service — find replacement for the other',
                    style: GoogleFonts.manrope(fontSize: 12),
                  ),
                  value: 'keep_on_a',
                  groupValue: strategy,
                  onChanged: (v) => setState(() => _strategies[index] = v!),
                ),
                RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Reassign to the other service — find replacement for the affected',
                    style: GoogleFonts.manrope(fontSize: 12),
                  ),
                  value: 'reassign_to_b',
                  groupValue: strategy,
                  onChanged: (v) => setState(() => _strategies[index] = v!),
                ),
                RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Cascade the other service +$overlapDays day(s)',
                    style: GoogleFonts.manrope(fontSize: 12),
                  ),
                  value: 'cascade',
                  groupValue: strategy,
                  onChanged: (v) => setState(() => _strategies[index] = v!),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _extractName(Map<String, dynamic> c) {
    final name = c['resource_name']?.toString() ?? '';
    if (name.isNotEmpty && name != '#null') return name;
    return '${c['resource_type']} #${c['resource_id']}'.replaceAll('#null', '-');
  }

  Future<void> _applyAll() async {
    for (final entry in _strategies.entries) {
      final index = entry.key;
      final strategy = entry.value;
      if (strategy.isEmpty) continue;

      setState(() => _resolving.add(index));

      try {
        final result = await widget.onResolve(widget.conflicts[index], strategy);
        if (result == null) {
          setState(() {
            _resolved.add(index);
            _resolving.remove(index);
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result, style: GoogleFonts.manrope(color: Colors.white)),
                backgroundColor: AppTheme.errorRed,
              ),
            );
          }
          setState(() => _resolving.remove(index));
          return;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e', style: GoogleFonts.manrope(color: Colors.white)),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
        setState(() => _resolving.remove(index));
        return;
      }
    }

    if (mounted) Navigator.of(context).pop(true);
  }
}
