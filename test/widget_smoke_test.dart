import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fxf/main.dart';

void main() {
  testWidgets('launch gate renders and can enter the app shell', (tester) async {
    await tester.pumpWidget(const FxFApp());
    expect(find.text('启动前提示'), findsOneWidget);

    final enter = find.text('进入 FxF', skipOffstage: false);
    expect(enter, findsOneWidget);
    await tester.ensureVisible(enter);
    await tester.pumpAndSettle();
    await tester.tap(enter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('市场概览'), findsOneWidget);
  });
}
