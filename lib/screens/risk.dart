import 'package:flutter/material.dart';
import '../core/analytics.dart';
import '../core/models.dart';
import '../services.dart';
import '../theme.dart';
import '../ui.dart';
import 'behavior.dart';

class RiskScreen extends StatefulWidget {
  const RiskScreen({super.key});
  @override State<RiskScreen> createState() => _RiskScreenState();
}

class _RiskScreenState extends State<RiskScreen> {
  late Future<List<Candle>> future;
  @override void initState() { super.initState(); future = binance.candles('BTCUSDT', interval: '1h', limit: 1000); }

  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.only(bottom: 24), children: [
    const FxFHeader(),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('风险中心', style: Theme.of(context).textTheme.headlineLarge),
      const Text('BTCUSDT · 最近 1000 根真实 1h K 线', style: TextStyle(color: FxFColors.muted)),
      const SizedBox(height: 12),
      AsyncPane<List<Candle>>(future: future, builder: (_, candles) {
        final returns = <double>[];
        for (var i = 1; i < candles.length; i++) returns.add(candles[i].close / candles[i - 1].close - 1);
        final var95 = RiskAnalytics.historicalVar(returns);
        final cvar95 = RiskAnalytics.historicalCvar(returns);
        final dd = RiskAnalytics.maxDrawdown(candles.map((e) => e.close).toList());
        return Column(children: [
          Row(children: [Expanded(child: MetricBox(label: 'VaR 95%', value: '${(var95 * 100).toStringAsFixed(2)}%', color: FxFColors.negative)), const SizedBox(width: 8), Expanded(child: MetricBox(label: 'CVaR 95%', value: '${(cvar95 * 100).toStringAsFixed(2)}%', color: FxFColors.negative)), const SizedBox(width: 8), Expanded(child: MetricBox(label: 'Max DD', value: '${(dd * 100).toStringAsFixed(2)}%', color: FxFColors.negative))]),
          const SizedBox(height: 10),
          GlassCard(child: CandleLineChart(candles: candles, height: 190)),
          const SizedBox(height: 10),
          const MascotPanel(title: 'Tail Risk', message: '历史尾部不是未来保证，但这里的 VaR/CVaR 至少由实际收益序列计算。', warning: true),
        ]);
      }),
      const SizedBox(height: 12),
      GlassCard(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BehaviorScreen())), child: const Row(children: [Icon(Icons.psychology_alt_outlined, color: FxFColors.primaryDark), SizedBox(width: 10), Expanded(child: Text('打开行为日志', style: TextStyle(color: FxFColors.ink, fontWeight: FontWeight.w800))), Icon(Icons.chevron_right)])),
    ])),
  ]);
}
