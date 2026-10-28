import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noel_app/src/features/workers/presentation/widgets/searchable_role_field.dart';

void main() {
  for (final width in [390.0, 1000.0]) {
    testWidgets('roles filter and open below the field at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Map<String, dynamic>? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlertDialog(
              title: const Text('Add New Worker'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 240),
                      SearchableRoleField(
                        roles: const [
                          {'id': '1', 'description': 'Supervisor'},
                          {'id': '2', 'description': 'Skilled Labor'},
                          {'id': '3', 'description': 'Topcon GPS'},
                        ],
                        onChanged: (role) => selected = role,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () {}, child: const Text('Save Worker')),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'sKiLlEd');
      await tester.pumpAndSettle();
      expect(find.text('Skilled Labor'), findsOneWidget);
      expect(find.text('Supervisor'), findsNothing);
      expect(
        tester.getTopLeft(find.byType(ListTile)).dy,
        greaterThanOrEqualTo(
          tester.getBottomLeft(find.byType(TextFormField)).dy,
        ),
      );
      expect(
        tester.getBottomLeft(find.byType(ListTile)).dy,
        lessThanOrEqualTo(700),
      );
      await tester.tap(find.text('Skilled Labor'));
      await tester.pumpAndSettle();
      expect(selected?['id'], '2');
      expect(find.byType(ListTile), findsNothing);
      await tester.tap(find.byTooltip('Search roles'));
      await tester.pumpAndSettle();
      expect(find.text('Supervisor'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
