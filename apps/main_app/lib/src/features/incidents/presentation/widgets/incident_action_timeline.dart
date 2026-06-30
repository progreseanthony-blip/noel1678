import 'package:flutter/material.dart';
import 'package:noel_core/noel_core.dart';

class IncidentActionTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> actions;
  final String? currentUserId;
  final ValueChanged<String>? onComplete;
  final VoidCallback? onAddAction;
  final ValueChanged<String>? onDeleteAction;

  const IncidentActionTimeline({
    super.key,
    required this.actions,
    this.currentUserId,
    this.onComplete,
    this.onAddAction,
    this.onDeleteAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Follow-up Actions', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.slate900)),
          const Spacer(),
          if (onAddAction != null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryGreen),
              onPressed: onAddAction,
            ),
        ]),
        const SizedBox(height: 12),
        if (actions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Icon(Icons.checklist, size: 40, color: AppTheme.slate200),
                const SizedBox(height: 8),
                Text('No actions registered', style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 13)),
              ]),
            ),
          )
        else
          ...actions.asMap().entries.map((entry) => _buildActionItem(entry.value, entry.key)),
      ],
    );
  }

  Widget _buildActionItem(Map<String, dynamic> action, int index) {
    final isCompleted = action['status'] == 'completed';
    final isPending = action['status'] == 'pending';
    final desc = action['description'] as String? ?? '';
    final dueDate = action['due_date'] as String?;
    bool isOverdue = false;
    if (isPending && dueDate != null) {
      try {
        final due = DateTime.parse(dueDate);
        if (due.isBefore(DateTime.now())) {
          isOverdue = true;
        }
      } catch (_) {}
    }

    final circleColor = isOverdue ? Colors.deepOrange : (isCompleted ? AppTheme.primaryGreen : AppTheme.slate200);
    final circleBorderColor = isOverdue ? Colors.deepOrange : (isCompleted ? AppTheme.primaryGreen : AppTheme.slate400);
    final descColor = isCompleted ? AppTheme.slate400 : (isOverdue ? Colors.deepOrange : AppTheme.slate900);

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: circleColor,
                  border: Border.all(
                    color: circleBorderColor,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : isOverdue
                        ? const Icon(Icons.warning_amber, size: 12, color: Colors.white)
                        : null,
              ),
              if (index < actions.length - 1)
                Expanded(
                  child: Container(width: 2, color: AppTheme.slate200),
                ),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      desc,
                      style: GoogleFonts.manrope(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: descColor,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (dueDate != null) ...[
                      const SizedBox(height: 2),
                      Row(children: [
                        if (isOverdue)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.warning_amber, size: 12, color: Colors.deepOrange),
                          ),
                        Text(
                          'Due: $dueDate',
                          style: GoogleFonts.manrope(fontSize: 11, color: isOverdue ? Colors.deepOrange : AppTheme.slate400),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
            if (!isCompleted && onComplete != null)
              SizedBox(
                height: 28,
                child: TextButton.icon(
                  onPressed: () => onComplete!(action['id'] as String),
                  icon: const Icon(Icons.check, size: 14),
                  label: Text('Complete', style: GoogleFonts.manrope(fontSize: 11)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            if (onDeleteAction != null && !isCompleted)
              SizedBox(
                height: 28,
                child: IconButton(
                  onPressed: () => onDeleteAction!(action['id'] as String),
                  icon: const Icon(Icons.close, size: 14, color: AppTheme.errorRed),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
