import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fxf/main.dart';

void main() {
  testWidgets('launch gate renders and can enter the app shell', (tester) async {
    await tester.pumpWidget(const FxFApp());
    expect(find.text('启动前提示'), findsOneWidget);
    expect(find.text('进入 FxF'), findsOneWidget);

    await tester.tap(find.text('进入 FxF'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('市场概览'), findsOneWidget);
  });
}
