import 'package:flutter/material.dart';
import '../core/analytics.dart';
import '../core/models.dart';
import '../services.dart';
import '../theme.dart';
import '../ui.dart';

class StrategyScreen extends StatefulWidget {
  const StrategyScreen({super.key});
  @override State<StrategyScreen> createState() => _StrategyScreenState();
}

class _StrategyScreenState extends State<StrategyScreen> {
  final symbolController = TextEditingController(text: 'BTCUSDT');
  double fast = 20;
  double slow = 50;
  double fee = 5;
  double slippage = 2;
  Future<({BacktestResult result, List<Candle> candles})>? resultFuture;

  Future<({BacktestResult result, List<Candle> candles})> _run() async {
    final symbol = symbolController.text.trim().toUpperCase();
    final candles = await binance.candles(symbol, interval: '1h', limit: 1000);
    final config = BacktestConfig(fastEma: fast.round(), slowEma: slow.round(), feeBps: fee, slippageBps: slippage);
    return (result: const BacktestEngine().emaCross(candles, config), candles: candles);
  }

  void _start() => setState(() => resultFuture = _run());

  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.only(bottom: 24), children: [
    const FxFHeader(),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('策略工作室', style: Theme.of(context).textTheme.headlineLarge),
      const Text('真实历史 K 线 · 本地策略计算', style: TextStyle(color: FxFColors.muted)),
      const SizedBox(height: 12),
      GlassCard(child: Column(children: [
        TextField(controller: symbolController, decoration: const InputDecoration(labelText: 'Universe / Symbol')),
        const SizedBox(height: 8),
        _SliderParam(label: 'Fast EMA', value: fast, min: 2, max: 100, onChanged: (v) => setState(() => fast = v)),
        _SliderParam(label: 'Slow EMA', value: slow, min: 5, max: 200, onChanged: (v) => setState(() => slow = v)),
        _SliderParam(label: 'Fee bps', value: fee, min: 0, max: 30, onChanged: (v) => setState(() => fee = v)),
        _SliderParam(label: 'Slippage bps', value: slippage, min: 0, max: 30, onChanged: (v) => setState(() => slippage = v)),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerLeft, child: Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF4FBFD), borderRadius: BorderRadius.circular(14)), child: Text('universe: ${symbolController.text.trim().toUpperCase()}\nsignal: cross(EMA(close,${fast.round()}), EMA(close,${slow.round()}))\nexecution: close\ncosts: fee=${fee.toStringAsFixed(1)}bps, slippage=${slippage.toStringAsFixed(1)}bps', style: const TextStyle(fontFamily: 'monospace', color: FxFColors.primaryDark)))),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _start, icon: const Icon(Icons.play_arrow), label: const Text('运行真实回测'))),
      ])),
      if (resultFuture != null) ...[
        const SizedBox(height: 12),
        AsyncPane<({BacktestResult result, List<Candle> candles})>(future: resultFuture!, builder: (_, data) => _BacktestResultPanel(data)),
      ],
    ])),
  ]);
}

class _SliderParam extends StatelessWidget {
  const _SliderParam({required this.label, required this.value, required this.min, required this.max, required this.onChanged});
  final String label; final double value, min, max; final ValueChanged<double> onChanged;
  @override Widget build(BuildContext context) => Row(children: [SizedBox(width: 120, child: Text('$label ${value.toStringAsFixed(1)}')), Expanded(child: Slider(value: value, min: min, max: max, onChanged: onChanged))]);
}

class _BacktestResultPanel extends StatelessWidget {
  const _BacktestResultPanel(this.data); final ({BacktestResult result, List<Candle> candles}) data;
  String pct(double x) => '${(x * 100).toStringAsFixed(2)}%';
  @override Widget build(BuildContext context) {
    final r = data.result;
    return Column(children: [
      Row(children: [Expanded(child: MetricBox(label: '总收益', value: pct(r.totalReturn), color: r.totalReturn >= 0 ? FxFColors.positive : FxFColors.negative)), const SizedBox(width: 8), Expanded(child: MetricBox(label: 'CAGR', value: pct(r.cagr))), const SizedBox(width: 8), Expanded(child: MetricBox(label: '最大回撤', value: pct(r.maxDrawdown), color: FxFColors.negative))]),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: MetricBox(label: 'Sharpe', value: r.sharpe.toStringAsFixed(2))), const SizedBox(width: 8), Expanded(child: MetricBox(label: 'Sortino', value: r.sortino.toStringAsFixed(2))), const SizedBox(width: 8), Expanded(child: MetricBox(label: 'Trades', value: '${r.trades}', sub: '胜率 ${(r.winRate * 100).toStringAsFixed(1)}%'))]),
      const SizedBox(height: 8),
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('真实行情区间', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8), CandleLineChart(candles: data.candles, height: 180)])),
      const SizedBox(height: 8),
      const MascotPanel(title: '回测提示', message: '这些指标由下载到本机的真实 K 线计算。漂亮结果仍然需要样本外和 walk-forward 验证。', warning: true),
    ]);
  }
}
