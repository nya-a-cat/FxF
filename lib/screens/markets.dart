import 'package:flutter/material.dart';
import '../core/models.dart';
import '../services.dart';
import '../theme.dart';
import '../ui.dart';
import 'trade.dart';

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key});
  @override State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> {
  final searchController = TextEditingController();
  late Future<List<MarketQuote>> future;
  static const defaults = ['BTCUSDT','ETHUSDT','SOLUSDT','BNBUSDT','XRPUSDT','DOGEUSDT','ADAUSDT','LINKUSDT','AVAXUSDT','SUIUSDT'];
  @override void initState() { super.initState(); future = binance.quotes(defaults); }
  void _search() {
    final raw = searchController.text.trim().toUpperCase();
    setState(() => future = raw.isEmpty ? binance.quotes(defaults) : binance.quotes([raw.endsWith('USDT') ? raw : '${raw}USDT']));
  }

  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.only(bottom: 24), children: [
    const FxFHeader(),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('市场', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 10),
      TextField(controller: searchController, onSubmitted: (_) => _search(), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(onPressed: _search, icon: const Icon(Icons.arrow_forward)), hintText: '任意 Binance 现货交易对，例如 ARBUSDT')),
      const SizedBox(height: 14),
      AsyncPane<List<MarketQuote>>(future: future, builder: (context, quotes) => GlassCard(child: Column(children: [for (final q in quotes) _MarketRow(q)]))),
    ])),
  ]);
}

class _MarketRow extends StatelessWidget {
  const _MarketRow(this.q); final MarketQuote q;
  @override Widget build(BuildContext context) => InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TradeScreen(symbol: q.symbol))), child: Padding(padding: const EdgeInsets.symmetric(vertical: 11), child: Row(children: [
    CircleAvatar(radius: 18, backgroundColor: const Color(0xFFDDF7FB), child: Text(q.symbol.substring(0,1), style: const TextStyle(color: FxFColors.primaryDark, fontWeight: FontWeight.w800))),
    const SizedBox(width: 10), Expanded(child: Text(q.symbol, style: const TextStyle(fontWeight: FontWeight.w800))),
    Text(q.price.toStringAsFixed(q.price < 10 ? 4 : 2), style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(width: 12),
    SizedBox(width: 72, child: Text('${q.changePercent >= 0 ? '+' : ''}${q.changePercent.toStringAsFixed(2)}%', textAlign: TextAlign.right, style: TextStyle(color: q.changePercent >= 0 ? FxFColors.positive : FxFColors.negative, fontWeight: FontWeight.w800))),
  ])));
}
