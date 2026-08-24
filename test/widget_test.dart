import 'package:flutter_test/flutter_test.dart';
import 'package:fxf/main.dart';

void main() {
  testWidgets('FxF launches', (tester) async {
    await tester.pumpWidget(const FxFApp());
    expect(find.text('启动前提示'), findsOneWidget);
  });
}
