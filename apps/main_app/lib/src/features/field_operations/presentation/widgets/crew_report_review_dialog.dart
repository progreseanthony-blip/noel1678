import 'package:flutter/material.dart';

/// Keeps form state alive until the dialog's closing animation finishes.
class CrewReportReviewDialog extends StatefulWidget {
  final bool approve;
  const CrewReportReviewDialog({super.key, required this.approve});

  @override
  State<CrewReportReviewDialog> createState() => _CrewReportReviewDialogState();
}

class _CrewReportReviewDialogState extends State<CrewReportReviewDialog> {
  final _reason = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.approve ? 'Approve crew report' : 'Return crew report'),
    content: widget.approve
        ? const Text(
            'Confirm that you have reviewed this crew’s working hours, machinery and material usage.',
          )
        : Form(
            key: _form,
            child: TextFormField(
              controller: _reason,
              decoration: const InputDecoration(labelText: 'Reason (required)'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a reason'
                  : null,
            ),
          ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (widget.approve || _form.currentState!.validate()) {
            Navigator.pop(context, widget.approve ? '' : _reason.text.trim());
          }
        },
        child: const Text('Confirm'),
      ),
    ],
  );
}
