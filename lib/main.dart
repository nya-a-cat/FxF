import 'package:flutter/material.dart';
import 'screens.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FxFApp());
}

class FxFApp extends StatelessWidget {
  const FxFApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'FxF',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const LaunchGate(),
      );
}
