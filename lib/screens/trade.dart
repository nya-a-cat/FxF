import 'package:flutter/material.dart';
import '../core/models.dart';
import '../services.dart';
import '../theme.dart';
import '../ui.dart';

class TradeScreen extends StatefulWidget {
  const TradeScreen({super.key, required this.symbol}); final String symbol;
  @override State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  final qtyController = TextEditingController(text: '0.001');
  late Future<(MarketQuote, BookTicker, List<Candle>)> future;
  @override void initState() { super.initState(); future = _load(); }
  Future<(MarketQuote, BookTicker, List<Candle>)> _load() async => (await binance.quote(widget.symbol), await binance.bookTicker(widget.symbol), await binance.candles(widget.symbol, interval: '1h', limit: 240));

  Future<void> _record(String side) async {
    final qty = double.tryParse(qtyController.text);
    if (qty == null || qty <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('数量无效'))); return; }
    final proceed = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('执行边界'),
      content: const Text('这里开始与真钱交易明确分开：FxF v0.1 会重新读取当前真实买一/卖一价并记录到本地研究账户，不会向交易所提交资金订单。'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('记录'))],
    )) ?? false;
    if (!proceed || !mounted) return;
    try {
      final fill = await researchAccount.recordAtObservedQuote(symbol: widget.symbol, side: side, quantity: qty);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${fill.side} ${fill.quantity} ${fill.symbol} @ ${fill.price.toStringAsFixed(6)}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('记录失败：$e')));
    }
  }

  @override Widget build(BuildContext context) => Scaffold(body: AquaBackground(child: SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
    Row(children: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)), Text(widget.symbol, style: Theme.of(context).textTheme.headlineMedium), const Spacer(), const Icon(Icons.circle, size: 9, color: FxFColors.positive), const SizedBox(width: 5), const Text('LIVE')]),
    AsyncPane<(MarketQuote, BookTicker, List<Candle>)>(future: future, builder: (context, data) {
      final q = data.$1; final book = data.$2; final candles = data.$3;
      return Column(children: [
        GlassCard(child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(q.price.toStringAsFixed(2), style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: q.changePercent >= 0 ? FxFColors.positive : FxFColors.negative)), Text('${q.changePercent.toStringAsFixed(2)}% · H ${q.high.toStringAsFixed(2)} · L ${q.low.toStringAsFixed(2)}', style: const TextStyle(color: FxFColors.muted))])), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('Bid ${book.bid}', style: const TextStyle(color: FxFColors.positive)), Text('Ask ${book.ask}', style: const TextStyle(color: FxFColors.negative)), Text('Spread ${book.spread.toStringAsFixed(6)}', style: const TextStyle(color: FxFColors.muted, fontSize: 11))])])),
        const SizedBox(height: 12),
        GlassCard(child: CandleLineChart(candles: candles, height: 250)),
        const SizedBox(height: 12),
        GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Research Execution', style: TextStyle(color: FxFColors.ink, fontWeight: FontWeight.w800)),
          const SizedBox(height: 9),
          TextField(controller: qtyController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: '数量')),
          const SizedBox(height: 10),
          Row(children: [Expanded(child: FilledButton(onPressed: () => _record('BUY'), style: FilledButton.styleFrom(backgroundColor: FxFColors.positive, foregroundColor: Colors.white), child: const Text('Buy / Long'))), const SizedBox(width: 8), Expanded(child: FilledButton(onPressed: () => _record('SELL'), style: FilledButton.styleFrom(backgroundColor: FxFColors.negative, foregroundColor: Colors.white), child: const Text('Sell / Short')))]),
        ])),
      ]);
    }),
  ])))) ;
}
