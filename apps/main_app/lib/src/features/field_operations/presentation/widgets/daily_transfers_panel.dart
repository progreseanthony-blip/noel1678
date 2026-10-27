import 'package:flutter/material.dart';

class DailyTransfersPanel extends StatelessWidget {
  final List<Map<String, dynamic>> transfers;
  final bool canReview, readOnly;
  final String? currentUser;
  final void Function(Map<String, dynamic>, String) onAction;
  const DailyTransfersPanel({
    super.key,
    required this.transfers,
    required this.canReview,
    required this.readOnly,
    required this.currentUser,
    required this.onAction,
  });
  @override
  Widget build(BuildContext context) {
    if (transfers.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temporary crew loans',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          for (final t in transfers)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                '${t['worker_name']} · ${t['from_name']} → ${t['to_name']}',
              ),
              subtitle: Text(
                '${t['starts_at'].toString().substring(0, 5)}–${t['ends_at'].toString().substring(0, 5)} · ${t['status']}\n${t['reason']}',
              ),
              isThreeLine: true,
              trailing: readOnly
                  ? null
                  : Wrap(
                      spacing: 4,
                      children: [
                        if (canReview && t['status'] == 'pending') ...[
                          IconButton(
                            tooltip: 'Authorize loan',
                            icon: const Icon(Icons.check_circle_outline),
                            onPressed: () => onAction(t, 'approve'),
                          ),
                          IconButton(
                            tooltip: 'Reject loan',
                            icon: const Icon(Icons.block),
                            onPressed: () => onAction(t, 'reject'),
                          ),
                        ],
                        if ((canReview &&
                                [
                                  'pending',
                                  'approved',
                                ].contains(t['status'])) ||
                            t['status'] == 'pending' &&
                                t['requested_by'] == currentUser)
                          IconButton(
                            tooltip: 'Cancel loan',
                            icon: const Icon(Icons.close),
                            onPressed: () => onAction(t, 'cancel'),
                          ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}
