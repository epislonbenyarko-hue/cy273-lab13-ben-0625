import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lab13_release/main.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ReleaseApp());
    await tester.pumpAndSettle();
  }

  test('Favourites notifier toggles and notifies', () {
    final favourites = Favourites();
    var notifications = 0;
    favourites.addListener(() => notifications++);

    expect(favourites.count, 0);
    favourites.toggle(3);
    expect(favourites.contains(3), isTrue);
    expect(favourites.count, 1);
    favourites.toggle(3);
    expect(favourites.contains(3), isFalse);
    expect(favourites.count, 0);
    expect(notifications, 2);
  });

  test('products list has 2000 lazily built items', () {
    expect(products.length, 2000);
    expect(products.first.name, 'Campus item 1');
    expect(products.last.priceGhs, 5 + (1999 % 50) * 1.5);
  });

  testWidgets('starter list shows items and the favourite counter', (tester) async {
    await pumpApp(tester);

    expect(find.text('UMaT Market'), findsOneWidget);
    expect(find.text('Campus item 1'), findsOneWidget);
    expect(find.text('♥ 0'), findsOneWidget);
    expect(find.byType(ListTile).evaluate().length, lessThan(50));
  });

  testWidgets('exercise 2: search filters products', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField), '1999');
    await tester.pumpAndSettle();

    expect(find.text('Campus item 1999'), findsOneWidget);
    expect(find.text('Campus item 1'), findsNothing);
  });

  testWidgets('exercise 2: typing does not rebuild the AppBar', (tester) async {
    await pumpApp(tester);
    final appBarElement = tester.element(find.text('UMaT Market'));

    await tester.enterText(find.byType(TextField), 'item 42');
    await tester.pumpAndSettle();

    // The same Element instance survived: the AppBar subtree was not rebuilt.
    expect(tester.element(find.text('UMaT Market')), same(appBarElement));
  });

  testWidgets('exercise 3: favourites use Provider and context.select',
      (tester) async {
    await pumpApp(tester);

    final firstHeart = find.ancestor(
      of: find.byTooltip('Add favourite'),
      matching: find.byType(IconButton),
    );
    await tester.tap(firstHeart.first);
    await tester.pumpAndSettle();

    expect(find.text('♥ 1'), findsOneWidget);
    expect(find.byTooltip('Remove favourite'), findsWidgets);

    await tester.tap(find.byTooltip('Remove favourite').first);
    await tester.pumpAndSettle();
    expect(find.text('♥ 0'), findsOneWidget);
  });

  testWidgets('search can be cleared', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byType(TextField), 'missing item');
    await tester.pumpAndSettle();
    expect(find.text('No matching items'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Campus item 1'), findsOneWidget);
  });
}
