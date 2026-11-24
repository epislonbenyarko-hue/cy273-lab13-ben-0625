import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lab13_release/main.dart';

void main() {
  testWidgets('app starts with the UMaT Market title', (tester) async {
    await tester.pumpWidget(const ReleaseApp());
    await tester.pumpAndSettle();

    expect(find.text('UMaT Market'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
