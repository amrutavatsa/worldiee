import 'package:flutter_test/flutter_test.dart';

import 'package:world_companion/main.dart';

void main() {
  testWidgets('World Companion app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const WorldCompanionApp());

    expect(find.text('World Companion'), findsWidgets);
  });
}