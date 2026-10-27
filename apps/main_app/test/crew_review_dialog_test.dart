import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noel_app/src/features/field_operations/presentation/widgets/crew_report_review_dialog.dart';
import 'package:noel_ui_components/noel_ui_components.dart';

void main() {
  for (final approve in [false, true]) {
    for (final cancel in [false, true]) {
      testWidgets(
        '${approve ? 'approve' : 'return'} ${cancel ? 'cancel' : 'confirm'} closes safely during report reload',
        (tester) async {
          String? submitted;
          await tester.pumpWidget(
            MaterialApp(
              home: StatefulBuilder(
                builder: (context, setState) => Scaffold(
                  body: TextButton(
                    onPressed: () async {
                      final result = await showSafeDialog<String>(
                        context: context,
                        builder: (_) =>
                            CrewReportReviewDialog(approve: approve),
                      );
                      if (result != null) setState(() => submitted = result);
                    },
                    child: Text(submitted == null ? 'Review' : 'Reloaded'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Review'));
          await tester.pumpAndSettle();
          if (!approve) {
            await tester.tap(find.text('Confirm'));
            await tester.pumpAndSettle();
            expect(find.text('Enter a reason'), findsOneWidget);
            expect(submitted, isNull);
            await tester.enterText(
              find.byType(TextFormField),
              '  Correct hours  ',
            );
          }
          await tester.tap(find.text(cancel ? 'Cancel' : 'Confirm'));
          // Exercise the frame after pop, when the route still animates but
          // the caller can already rebuild/reload its report.
          await tester.pump();
          await tester.pumpAndSettle();
          expect(
            submitted,
            cancel ? isNull : equals(approve ? '' : 'Correct hours'),
          );
          expect(find.byType(CrewReportReviewDialog), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
