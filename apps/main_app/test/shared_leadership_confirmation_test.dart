import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noel_app/src/features/quotes/presentation/widgets/shared_leadership_confirmation.dart';

void main() {
  for (final confirm in [false, true]) {
    testWidgets('shared coverage requires an explicit decision: $confirm', (
      tester,
    ) async {
      bool? decision;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  decision = await confirmSharedLeadership(
                    context,
                    resources: ['Supervisor 1: Clearing, Topsoil'],
                    previousTotal: 22000,
                    total: 11000,
                    serviceAmounts: ['Clearing: \$5,500', 'Topsoil: \$5,500'],
                  );
                },
                child: const Text('Review'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      expect(decision, isNull);
      expect(find.text('Supervisor 1: Clearing, Topsoil'), findsOneWidget);
      expect(find.text('Clearing: \$5,500'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(
        find.text(confirm ? 'Confirm coverage and allocation' : 'Cancel'),
      );
      await tester.pumpAndSettle();
      expect(decision, confirm);
    });
  }
}
