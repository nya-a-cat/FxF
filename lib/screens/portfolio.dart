import 'package:flutter/material.dart';
import '../core/models.dart';
import '../services.dart';
import '../theme.dart';
import '../ui.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});
  @override State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  late Future<({List<ResearchFill> fills, Map<String, MarketQuote> marks})> future;
  @override void initState() { super.initState(); future = _load(); }

  Future<({List<ResearchFill> fills, Map<String, MarketQuote> marks})> _load() async {
    final fills = await researchAccount.fills();
    final symbols = fills.map((f) => f.symbol).toSet().toList();
    final quotes = symbols.isEmpty ? <MarketQuote>[] : await binance.quotes(symbols);
    return (fills: fills, marks: {for (final q in quotes) q.symbol: q});
  }

  @override Widget build(BuildContext context) => RefreshIndicator(onRefresh: () async { setState(() => future = _load()); await future; }, child: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
    const FxFHeader(),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('研究账户', style: Theme.of(context).textTheme.headlineLarge),
      const Text('成交记录使用真实观察价；持仓按当前真实报价 mark-to-market', style: TextStyle(color: FxFColors.muted)),
      const SizedBox(height: 12),
      AsyncPane<({List<ResearchFill> fills, Map<String, MarketQuote> marks})>(future: future, builder: (_, data) {
        if (data.fills.isEmpty) return const GlassCard(child: Text('还没有研究成交。到市场页选择交易对后记录第一笔。'));
        final positions = <String, ({double qty, double cost})>{};
        for (final f in data.fills.reversed) {
          final sign = f.side == 'BUY' ? 1.0 : -1.0;
          final prev = positions[f.symbol] ?? (qty: 0.0, cost: 0.0);
          positions[f.symbol] = (qty: prev.qty + sign * f.quantity, cost: prev.cost + sign * f.quantity * f.price);
        }
        final rows = positions.entries.where((e) => e.value.qty.abs() > 1e-12).toList();
        final totalPnl = rows.fold<double>(0, (sum, e) { final mark = data.marks[e.key]?.price; return mark == null ? sum : sum + e.value.qty * mark - e.value.cost; });
        return Column(children: [
          MetricBox(label: '未实现 P/L', value: totalPnl.toStringAsFixed(2), color: totalPnl >= 0 ? FxFColors.positive : FxFColors.negative, sub: '按当前 Binance 报价'),
          const SizedBox(height: 10),
          GlassCard(child: Column(children: [for (final e in rows) _PositionRow(symbol: e.key, qty: e.value.qty, cost: e.value.cost, mark: data.marks[e.key]?.price)])),
          const SizedBox(height: 10),
          GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('最近成交', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8), for (final f in data.fills.take(12)) Text('${f.side} ${f.symbol} ${f.quantity} @ ${f.price.toStringAsFixed(6)}', style: const TextStyle(color: FxFColors.muted))])),
        ]);
      }),
      const SizedBox(height: 12),
      const MascotPanel(title: '组合数据边界', message: '没有成交记录就没有仓位，没有当前报价就不计算浮盈。空白比假数字更诚实。'),
    ])),
  ]));
}

class _PositionRow extends StatelessWidget {
  const _PositionRow({required this.symbol, required this.qty, required this.cost, required this.mark});
  final String symbol; final double qty, cost; final double? mark;
  @override Widget build(BuildContext context) {
    final avg = qty == 0 ? 0.0 : cost / qty;
    final pnl = mark == null ? null : qty * mark! - cost;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(symbol, style: const TextStyle(fontWeight: FontWeight.w800)), Text('Qty ${qty.toStringAsFixed(6)} · Avg ${avg.toStringAsFixed(4)}', style: const TextStyle(color: FxFColors.muted, fontSize: 11))])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(mark == null ? 'Mark —' : mark!.toStringAsFixed(4)), if (pnl != null) Text('${pnl >= 0 ? '+' : ''}${pnl.toStringAsFixed(2)}', style: TextStyle(color: pnl >= 0 ? FxFColors.positive : FxFColors.negative, fontWeight: FontWeight.w800))]),
    ]));
  }
}
