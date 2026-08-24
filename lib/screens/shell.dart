import 'package:flutter/material.dart';
import '../ui.dart';
import 'home.dart';
import 'markets.dart';
import 'portfolio.dart';
import 'risk.dart';
import 'strategy.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  late final pages = const [HomeScreen(), MarketsScreen(), StrategyScreen(), PortfolioScreen(), RiskScreen()];
  @override Widget build(BuildContext context) => Scaffold(
    body: AquaBackground(child: SafeArea(child: IndexedStack(index: index, children: pages))),
    bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v), destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: '首页'),
      NavigationDestination(icon: Icon(Icons.candlestick_chart_outlined), label: '市场'),
      NavigationDestination(icon: Icon(Icons.science_outlined), label: '策略'),
      NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: '组合'),
      NavigationDestination(icon: Icon(Icons.shield_outlined), label: '风控'),
    ]),
  );
}
