import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Approval is about coverage capacity, not extra people or extra hours.
Future<bool> confirmSharedLeadership(
  BuildContext context, {
  required List<String> resources,
  required double total,
  double? previousTotal,
  List<String> serviceAmounts = const [],
}) async {
  final money = NumberFormat.currency(symbol: '\$');
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm shared coverage'),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'These resources cover more than one service on overlapping dates. '
                    'Confirm that the same person can supervise these work groups.',
                  ),
                  const SizedBox(height: 12),
                  for (final resource in resources)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(resource),
                    ),
                  const Text(
                    'Time is counted once. Cost is distributed automatically across '
                    'overlapping services, or charged to the cost service selected in the estimate. '
                    'Exclusive periods retain their full time.',
                  ),
                  const SizedBox(height: 12),
                  for (final amount in serviceAmounts) Text(amount),
                  const SizedBox(height: 12),
                  if (previousTotal != null)
                    Text(
                      'Previous estimate total: ${money.format(previousTotal)}',
                    ),
                  Text(
                    'Estimate total after allocation: ${money.format(total)}',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm coverage and allocation'),
            ),
          ],
        ),
      ) ??
      false;
}
