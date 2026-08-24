import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';
import '../ui.dart';
import 'shell.dart';

class LaunchGate extends StatefulWidget {
  const LaunchGate({super.key});
  @override State<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<LaunchGate> {
  static const lines = [
    '我重生了，这次我要夺回属于我的一切……',
    '市场不会记得你的成本价。',
    '你以为你在抄底，市场以为你在接刀。',
    '本次启动不会提高你的胜率。',
    'Sharpe 不是人格魅力。',
    '回测里没有你的情绪，现实里有。',
    '不要和一根 K 线建立长期感情。',
    '如果一组参数完美到像知道答案，它可能真的知道。',
  ];
  late String line;
  @override void initState() { super.initState(); line = lines[math.Random().nextInt(lines.length)]; }

  @override Widget build(BuildContext context) => Scaffold(body: AquaBackground(child: SafeArea(child: ListView(padding: const EdgeInsets.all(22), children: [
    const FxFHeader(subtitle: 'Quantitative Strategy Lab'),
    const SizedBox(height: 18),
    Text('启动前提示', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge),
    const SizedBox(height: 8),
    const Text('风险系统正在载入。市场不会因为界面很好看就变得温柔。', textAlign: TextAlign.center, style: TextStyle(color: FxFColors.muted)),
    const SizedBox(height: 20),
    GlassCard(padding: const EdgeInsets.all(22), child: Column(children: [
      const Icon(Icons.auto_awesome, color: FxFColors.primaryDark, size: 54),
      const SizedBox(height: 18),
      Text('“$line”', textAlign: TextAlign.center, style: const TextStyle(color: FxFColors.primaryDark, fontSize: 22, fontWeight: FontWeight.w800, height: 1.5)),
      const SizedBox(height: 14),
      TextButton.icon(onPressed: () => setState(() => line = lines[math.Random().nextInt(lines.length)]), icon: const Icon(Icons.shuffle), label: const Text('再来一句')),
    ])),
    const SizedBox(height: 14),
    const Wrap(spacing: 9, runSpacing: 9, children: [
      _RiskChip(Icons.sentiment_dissatisfied_rounded, 'FOMO'),
      _RiskChip(Icons.balance_rounded, '过度杠杆'),
      _RiskChip(Icons.bolt_rounded, '报复交易'),
      _RiskChip(Icons.query_stats_rounded, '参数过拟合'),
      _RiskChip(Icons.water_drop_outlined, '流动性风险'),
      _RiskChip(Icons.bedtime_outlined, '熬夜下单'),
    ]),
    const SizedBox(height: 14),
    const MascotPanel(title: '泽澜 · Risk Intelligence', message: 'FxF 只展示真实市场数据和真实计算结果。数据源不可用时会明确报错。', warning: true),
    const SizedBox(height: 18),
    FilledButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell())), style: FilledButton.styleFrom(backgroundColor: FxFColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)), child: const Text('进入 FxF')),
  ])))) ;
}

class _RiskChip extends StatelessWidget {
  const _RiskChip(this.icon, this.label); final IconData icon; final String label;
  @override Widget build(BuildContext context) => SizedBox(width: (MediaQuery.sizeOf(context).width - 53) / 2, child: GlassCard(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13), child: Row(children: [Icon(icon, color: FxFColors.primaryDark), const SizedBox(width: 7), Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: FxFColors.ink))])));
}
