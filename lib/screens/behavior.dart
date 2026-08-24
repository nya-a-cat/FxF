import 'package:flutter/material.dart';
import '../core/models.dart';
import '../services.dart';
import '../theme.dart';
import '../ui.dart';

class BehaviorScreen extends StatefulWidget {
  const BehaviorScreen({super.key});
  @override State<BehaviorScreen> createState() => _BehaviorScreenState();
}

class _BehaviorScreenState extends State<BehaviorScreen> {
  late Future<List<ResearchFill>> future;
  @override void initState() { super.initState(); future = researchAccount.fills(); }

  @override Widget build(BuildContext context) => Scaffold(body: AquaBackground(child: SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
    Row(children: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)), Text('行为日志 · 心理', style: Theme.of(context).textTheme.headlineMedium)]),
    AsyncPane<List<ResearchFill>>(future: future, builder: (_, fills) {
      final night = fills.where((f) { final h = f.observedAt.toLocal().hour; return h >= 23 || h < 3; }).length;
      final buys = fills.where((f) => f.side == 'BUY').length;
      final sells = fills.length - buys;
      final symbols = fills.map((f) => f.symbol).toSet().length;
      return Column(children: [
        MascotPanel(title: fills.isEmpty ? '还没有足够行为数据' : '你的操作已经开始形成统计', message: fills.isEmpty ? 'FxF 不会生成假的心理画像。先正常使用研究账户，再根据真实记录做分析。' : '共 ${fills.length} 笔记录，涉及 $symbols 个交易对，其中深夜记录 $night 笔。', warning: night > 0),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: MetricBox(label: '总记录', value: '${fills.length}')), const SizedBox(width: 8), Expanded(child: MetricBox(label: 'BUY / SELL', value: '$buys / $sells')), const SizedBox(width: 8), Expanded(child: MetricBox(label: '23:00-03:00', value: '$night', color: night > 0 ? FxFColors.negative : FxFColors.positive))]),
        if (fills.isNotEmpty) ...[
          const SizedBox(height: 10),
          GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('最近行为', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8), for (final f in fills.take(16)) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('${f.observedAt.toLocal()}  ${f.side} ${f.symbol} ${f.quantity}', style: const TextStyle(color: FxFColors.muted))) ])),
        ],
      ]);
    }),
  ])))) ;
}
