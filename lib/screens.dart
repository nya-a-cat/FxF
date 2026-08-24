import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'core/analytics.dart';
import 'core/market_data.dart';
import 'core/models.dart';
import 'core/research_account.dart';
import 'theme.dart';
import 'ui.dart';

final binance = BinanceMarketData();
final deribit = DeribitMarketData();
final researchAccount = ResearchAccount(binance);

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
    '如果一个参数组合看起来完美，它通常已经知道答案。',
    '不要和一根 K 线建立长期感情。',
  ];
  late String line;
  @override void initState() { super.initState(); line = lines[math.Random().nextInt(lines.length)]; }
  void reroll() => setState(() => line = lines[math.Random().nextInt(lines.length)]);

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
      TextButton.icon(onPressed: reroll, icon: const Icon(Icons.shuffle), label: const Text('再来一句')),
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
    const MascotPanel(title: '泽澜 · Risk Intelligence', message: 'FxF 会优先展示真实市场数据。数据源不可用时会明确报错，不会用演示数字填空。', warning: true),
    const SizedBox(height: 18),
    FilledButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell())), style: FilledButton.styleFrom(backgroundColor: FxFColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)), child: const Text('进入 FxF')),
  ]))));
}

class _RiskChip extends StatelessWidget {
  const _RiskChip(this.icon, this.label); final IconData icon; final String label;
  @override Widget build(BuildContext context) => SizedBox(width: (MediaQuery.sizeOf(context).width - 53) / 2, child: GlassCard(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13), child: Row(children: [Icon(icon, color: FxFColors.primaryDark), const SizedBox(width: 7), Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: FxFColors.ink))])));
}

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<MarketQuote>> quotesFuture;
  late Future<List<Candle>> btcCandles;
  @override void initState() { super.initState(); refresh(); }
  void refresh() { quotesFuture = binance.quotes(const ['BTCUSDT','ETHUSDT','SOLUSDT','BNBUSDT','XRPUSDT']); btcCandles = binance.candles('BTCUSDT', interval: '1h', limit: 168); }
  @override Widget build(BuildContext context) => RefreshIndicator(onRefresh: () async { setState(refresh); await quotesFuture; }, child: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
    const FxFHeader(),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('市场概览', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 4),
      const Text('数据：Binance Public API', style: TextStyle(color: FxFColors.muted)),
      const SizedBox(height: 14),
      AsyncPane<List<MarketQuote>>(future: quotesFuture, builder: (context, data) => SizedBox(height: 130, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: data.length, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (_, i) => SizedBox(width: 150, child: QuoteTile(quote: data[i], onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TradeScreen(symbol: data[i].symbol))))))),
      const SizedBox(height: 16),
      AsyncPane<List<Candle>>(future: btcCandles, builder: (_, data) => GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('BTC · 7D', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8), CandleLineChart(candles: data, height: 190)]))),
      const SizedBox(height: 14),
      const MascotPanel(title: '泽澜 · Market Note', message: '这里只显示从数据源拿到的东西。网络断了就是断了，不会假装市场还在跳。'),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: GlassCard(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OptionsScreen())), child: const _Shortcut(Icons.stacked_line_chart, '期权实验室', 'Deribit 实时链'))),
        const SizedBox(width: 10),
        Expanded(child: GlassCard(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BehaviorScreen())), child: const _Shortcut(Icons.psychology_alt_outlined, '行为日志', '基于真实记录'))),
      ]),
    ])),
  ]));
}

class _Shortcut extends StatelessWidget { const _Shortcut(this.icon, this.title, this.sub); final IconData icon; final String title, sub; @override Widget build(BuildContext c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: FxFColors.primaryDark), const SizedBox(height: 8), Text(title, style: const TextStyle(color: FxFColors.ink, fontWeight: FontWeight.w800)), Text(sub, style: const TextStyle(color: FxFColors.muted, fontSize: 11))]); }

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key});
  @override State<MarketsScreen> createState() => _MarketsScreenState();
}
class _MarketsScreenState extends State<MarketsScreen> {
  final controller = TextEditingController();
  List<String> symbols = const ['BTCUSDT','ETHUSDT','SOLUSDT','BNBUSDT','XRPUSDT','DOGEUSDT','ADAUSDT','LINKUSDT','AVAXUSDT','SUIUSDT'];
  late Future<List<MarketQuote>> future;
  @override void initState() { super.initState(); future = binance.quotes(symbols); }
  void search() { final raw = controller.text.trim().toUpperCase(); if (raw.isEmpty) return; final s = raw.endsWith('USDT') ? raw : '${raw}USDT'; setState(() => future = binance.quotes([s])); }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.only(bottom: 24), children: [
    const FxFHeader(),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('市场', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 10),
      TextField(controller: controller, onSubmitted: (_) => search(), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(onPressed: search, icon: const Icon(Icons.arrow_forward)), hintText: '输入 Binance 交易对，例如 ARBUSDT')),
      const SizedBox(height: 14),
      AsyncPane<List<MarketQuote>>(future: future, builder: (context, data) => GlassCard(child: Column(children: [for (final q in data) _MarketRow(q: q)]))),
    ])),
  ]);
}

class _MarketRow extends StatelessWidget {
  const _MarketRow({required this.q}); final MarketQuote q;
  @override Widget build(BuildContext context) => InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TradeScreen(symbol: q.symbol))), child: Padding(padding: const EdgeInsets.symmetric(vertical: 11), child: Row(children: [
    CircleAvatar(radius: 18, backgroundColor: const Color(0xFFDDF7FB), child: Text(q.symbol.substring(0,1), style: const TextStyle(color: FxFColors.primaryDark, fontWeight: FontWeight.w800))),
    const SizedBox(width: 10), Expanded(child: Text(q.symbol, style: const TextStyle(fontWeight: FontWeight.w800))),
    Text(q.price.toStringAsFixed(q.price < 10 ? 4 : 2), style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(width: 12),
    SizedBox(width: 70, child: Text('${q.changePercent >= 0 ? '+' : ''}${q.changePercent.toStringAsFixed(2)}%', textAlign: TextAlign.right, style: TextStyle(color: q.changePercent >= 0 ? FxFColors.positive : FxFColors.negative, fontWeight: FontWeight.w800))),
  ])));
}

class TradeScreen extends StatefulWidget {
  const TradeScreen({super.key, required this.symbol}); final String symbol;
  @override State<TradeScreen> createState() => _TradeScreenState();
}
class _TradeScreenState extends State<TradeScreen> {
  late Future<(MarketQuote, BookTicker, List<Candle>)> future;
  final qty = TextEditingController(text: '0.001');
  @override void initState() { super.initState(); future = _load(); }
  Future<(MarketQuote, BookTicker, List<Candle>)> _load() async => (await binance.quote(widget.symbol), await binance.bookTicker(widget.symbol), await binance.candles(widget.symbol, interval: '1h', limit: 240));
  Future<void> submit(String side) async {
    final amount = double.tryParse(qty.text);
    if (amount == null || amount <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('数量无效'))); return; }
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('执行边界'), content: const Text('FxF v0.1 不连接你的真实交易账户。继续后会以当前真实买一/卖一价格记录到本地研究账户，不会向交易所提交资金订单。'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('记录'))])) ?? false;
    if (!ok || !mounted) return;
    final fill = await researchAccount.recordAtObservedQuote(symbol: widget.symbol, side: side, quantity: amount);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${fill.side} ${fill.quantity} ${fill.symbol} @ ${fill.price}')));
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
        GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const Text('Research Execution', style: TextStyle(color: FxFColors.ink, fontWeight: FontWeight.w800)), const SizedBox(height: 9), TextField(controller: qty, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: '数量')), const SizedBox(height: 10), Row(children: [Expanded(child: FilledButton(onPressed: () => submit('BUY'), style: FilledButton.styleFrom(backgroundColor: FxFColors.positive, foregroundColor: Colors.white), child: const Text('Buy / Long'))), const SizedBox(width: 8), Expanded(child: FilledButton(onPressed: () => submit('SELL'), style: FilledButton.styleFrom(backgroundColor: FxFColors.negative, foregroundColor: Colors.white), child: const Text('Sell / Short')))])])),
      ]);
    }),
  ])))) ;
}

class StrategyScreen extends StatefulWidget {
  const StrategyScreen({super.key});
  @override State<StrategyScreen> createState() => _StrategyScreenState();
}
class _StrategyScreenState extends State<StrategyScreen> {
  final symbol = TextEditingController(text: 'BTCUSDT');
  int fast = 20; int slow = 50; double fee = 5; double slippage = 2;
  bool running = false;
  Future<({BacktestResult result, List<Candle> candles})>? resultFuture;
  Future<({BacktestResult result, List<Candle> candles})> run() async {
    final candles = await binance.candles(symbol.text.trim().toUpperCase(), interval: '1h', limit: 1000);
    final result = const BacktestEngine().emaCross(candles, BacktestConfig(fastEma: fast, slowEma: slow, feeBps: fee, slippageBps: slippage));
    return (result: result, candles: candles);
  }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.only(bottom: 24), children: [
    const FxFHeader(),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('策略工作室', style: Theme.of(context).textTheme.headlineLarge),
      const Text('真实历史 K 线 · 本地计算', style: TextStyle(color: FxFColors.muted)),
      const SizedBox(height: 12),
      GlassCard(child: Column(children: [
        TextField(controller: symbol, decoration: const InputDecoration(labelText: 'Universe / Symbol')), const SizedBox(height: 9),
        _Param('Fast EMA', fast.toDouble(), 2, 100, (v) => setState(() => fast = v.round())),
        _Param('Slow EMA', slow.toDouble(), 5, 200, (v) => setState(() => slow = v.round())),
        _Param('Fee bps', fee, 0, 30, (v) => setState(() => fee = v)),
        _Param('Slippage bps', slippage, 0, 30, (v) => setState(() => slippage = v)),
        const SizedBox(height: 8),
        const Align(alignment: Alignment.centerLeft, child: Text('DSL 预览', style: TextStyle(fontWeight: FontWeight.w800))),
        const SizedBox(height: 7),
        Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF4FBFD), borderRadius: BorderRadius.circular(14)), child: Text('universe: ${symbol.text}\nsignal: cross(EMA(close,$fast), EMA(close,$slow))\nexecution: close\ncosts: fee=${fee.toStringAsFixed(1)}bps, slippage=${slippage.toStringAsFixed(1)}bps', style: const TextStyle(fontFamily: 'monospace', color: FxFColors.primaryDark))),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: running ? null : () { setState(() { running = true; resultFuture = run().whenComplete(() { if (mounted) setState(() => running = false); }); }); }, icon: const Icon(Icons.play_arrow), label: Text(running ? '计算中…' : '运行真实回测'))),
      ])),
      if (resultFuture != null) ...[const SizedBox(height: 12), AsyncPane<({BacktestResult result, List<Candle> candles})>(future: resultFuture!, builder: (context, data) => BacktestPanel(data: data))],
    ])),
  ]);
}

class _Param extends StatelessWidget { const _Param(this.label, this.value, this.min, this.max, this.onChanged); final String label; final double value, min, max; final ValueChanged<double> onChanged; @override Widget build(BuildContext c) => Row(children: [SizedBox(width: 110, child: Text('$label ${value.toStringAsFixed(value.roundToDouble() == value ? 0 : 1)}')), Expanded(child: Slider(value: value.clamp(min,max), min: min, max: max, onChanged: onChanged))]); }

class BacktestPanel extends StatelessWidget {
  const BacktestPanel({super.key, required this.data}); final ({BacktestResult result, List<Candle> candles}) data;
  String pct(double x) => '${(x*100).toStringAsFixed(2)}%';
  @override Widget build(BuildContext context) { final r = data.result; return Column(children: [
    Row(children: [Expanded(child: MetricBox(label: '总收益', value: pct(r.totalReturn), color: r.totalReturn >= 0 ? FxFColors.positive : FxFColors.negative)), const SizedBox(width: 8), Expanded(child: MetricBox(label: 'CAGR', value: pct(r.cagr))), const SizedBox(width: 8), Expanded(child: MetricBox(label: '最大回撤', value: pct(r.maxDrawdown), color: FxFColors.negative))]),
    const SizedBox(height: 8),
    Row(children: [Expanded(child: MetricBox(label: 'Sharpe', value: r.sharpe.toStringAsFixed(2))), const SizedBox(width: 8), Expanded(child: MetricBox(label: 'Sortino', value: r.sortino.toStringAsFixed(2))), const SizedBox(width: 8), Expanded(child: MetricBox(label: 'Trades', value: '${r.trades}', sub: '胜率 ${(r.winRate*100).toStringAsFixed(1)}%'))]),
    const SizedBox(height: 8),
    GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('真实行情区间', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8), CandleLineChart(candles: data.candles, height: 170)])),
    const SizedBox(height: 8),
    const MascotPanel(title: '过拟合检查', message: '第一版先把数据和计算做真。下一步会加入 walk-forward / OOS，避免只盯着样本内漂亮数字。', warning: true),
  ]); }
}

class OptionsScreen extends StatefulWidget {
  const OptionsScreen({super.key});
  @override State<OptionsScreen> createState() => _OptionsScreenState();
}
class _OptionsScreenState extends State<OptionsScreen> {
  String currency = 'BTC';
  late Future<List<OptionInstrument>> future;
  @override void initState() { super.initState(); future = deribit.optionChain(currency); }
  @override Widget build(BuildContext context) => Scaffold(body: AquaBackground(child: SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
    Row(children: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)), Text('期权实验室', style: Theme.of(context).textTheme.headlineMedium), const Spacer(), DropdownButton<String>(value: currency, items: const [DropdownMenuItem(value:'BTC', child: Text('BTC')), DropdownMenuItem(value:'ETH', child: Text('ETH'))], onChanged: (v) { if (v != null) setState(() { currency = v; future = deribit.optionChain(v); }); })]),
    const Text('Deribit Public API · 实时 option summaries', style: TextStyle(color: FxFColors.muted)),
    const SizedBox(height: 12),
    AsyncPane<List<OptionInstrument>>(future: future, builder: (context, chain) {
      if (chain.isEmpty) return const GlassCard(child: Text('当前没有可用期权合约'));
      final expiry = chain.first.expiration;
      final subset = chain.where((x) => x.expiration == expiry).take(40).toList();
      return Column(children: [
        GlassCard(child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('最近到期', style: TextStyle(color: FxFColors.muted)), Text(expiry.toIso8601String().split('T').first, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20))])), Text('${subset.length} legs', style: const TextStyle(color: FxFColors.primaryDark, fontWeight: FontWeight.w800))])),
        const SizedBox(height: 10),
        GlassCard(child: Column(children: [for (final o in subset) _OptionRow(o)])),
        const SizedBox(height: 10),
        const MascotPanel(title: 'Generic Multi-Leg Engine', message: '所有策略最终都表示成任意数量的 Call/Put 多腿组合。Iron Condor、Calendar、Straddle 等只是预设，不需要伪造独立产品。'),
      ]);
    }),
  ])))) ;
}
class _OptionRow extends StatelessWidget { const _OptionRow(this.o); final OptionInstrument o; @override Widget build(BuildContext c) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [SizedBox(width: 72, child: Text(o.strike.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.w700))), SizedBox(width: 40, child: Text(o.isCall ? 'CALL':'PUT', style: TextStyle(color: o.isCall ? FxFColors.positive : FxFColors.negative, fontSize: 11, fontWeight: FontWeight.w800))), Expanded(child: Text(o.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: FxFColors.muted))), Text('IV ${o.iv?.toStringAsFixed(1) ?? '—'}', style: const TextStyle(fontSize: 11)), const SizedBox(width: 8), Text(o.markPrice?.toStringAsFixed(4) ?? '—', style: const TextStyle(fontWeight: FontWeight.w700))])); }

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});
  @override State<PortfolioScreen> createState() => _PortfolioScreenState();
}
class _PortfolioScreenState extends State<PortfolioScreen> {
  late Future<List<ResearchFill>> fillsFuture;
  @override void initState() { super.initState(); fillsFuture = researchAccount.fills(); }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.only(bottom: 24), children: [
    const FxFHeader(),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('研究账户', style: Theme.of(context).textTheme.headlineLarge),
      const Text('真实观察价格 · 本地记录', style: TextStyle(color: FxFColors.muted)),
      const SizedBox(height: 12),
      AsyncPane<List<ResearchFill>>(future: fillsFuture, builder: (context, fills) {
        if (fills.isEmpty) return const GlassCard(child: Text('还没有研究账户成交记录。到市场页选择交易对后记录第一笔。'));
        return GlassCard(child: Column(children: [for (final f in fills) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [Text(f.side, style: TextStyle(color: f.side == 'BUY' ? FxFColors.positive : FxFColors.negative, fontWeight: FontWeight.w800)), const SizedBox(width: 10), Expanded(child: Text(f.symbol, style: const TextStyle(fontWeight: FontWeight.w700))), Text('${f.quantity} @ ${f.price.toStringAsFixed(4)}'), const SizedBox(width: 8), Text('${f.observedAt.toLocal().hour.toString().padLeft(2,'0')}:${f.observedAt.toLocal().minute.toString().padLeft(2,'0')}', style: const TextStyle(color: FxFColors.muted, fontSize: 11))]))]));
      }),
      const SizedBox(height: 12),
      const MascotPanel(title: '关于“盈亏”', message: '组合页不会凭空生成资产曲线。只有你实际记录过的研究成交和后续真实市场价格才能产生持仓与盈亏。'),
    ])),
  ]);
}

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
      const Text('Historical VaR / CVaR · BTCUSDT 1h', style: TextStyle(color: FxFColors.muted)),
      const SizedBox(height: 12),
      AsyncPane<List<Candle>>(future: future, builder: (_, candles) {
        final returns = <double>[]; for (var i=1;i<candles.length;i++) returns.add(candles[i].close/candles[i-1].close-1);
        final var95 = RiskAnalytics.historicalVar(returns); final cvar95 = RiskAnalytics.historicalCvar(returns); final dd = RiskAnalytics.maxDrawdown(candles.map((e)=>e.close).toList());
        return Column(children: [
          Row(children: [Expanded(child: MetricBox(label: 'VaR 95%', value: '${(var95*100).toStringAsFixed(2)}%', color: FxFColors.negative)), const SizedBox(width: 8), Expanded(child: MetricBox(label: 'CVaR 95%', value: '${(cvar95*100).toStringAsFixed(2)}%', color: FxFColors.negative)), const SizedBox(width: 8), Expanded(child: MetricBox(label: 'Max DD', value: '${(dd*100).toStringAsFixed(2)}%', color: FxFColors.negative))]),
          const SizedBox(height: 10), GlassCard(child: CandleLineChart(candles: candles, height: 190)),
          const SizedBox(height: 10), const MascotPanel(title: 'Tail Risk', message: '这些指标来自最近 1000 根真实小时 K 线。历史尾部不等于未来尾部，但至少不是 UI 编出来的数字。', warning: true),
        ]);
      }),
      const SizedBox(height: 12),
      GlassCard(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BehaviorScreen())), child: const Row(children: [Icon(Icons.psychology_alt_outlined, color: FxFColors.primaryDark), SizedBox(width: 10), Expanded(child: Text('打开行为日志', style: TextStyle(color: FxFColors.ink, fontWeight: FontWeight.w800))), Icon(Icons.chevron_right)])),
    ])),
  ]);
}

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
      final buys = fills.where((f)=>f.side=='BUY').length; final sells = fills.length - buys;
      return Column(children: [
        MascotPanel(title: fills.isEmpty ? '还没有足够行为数据' : '你的记录已经开始形成模式', message: fills.isEmpty ? '行为分析不会生成假“心理画像”。先正常使用研究账户，FxF 再从真实操作时间和频率里做统计。' : '共 ${fills.length} 笔记录，其中深夜记录 $night 笔。下面的统计直接来自本地成交日志。', warning: night > 0),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: MetricBox(label: '总记录', value: '${fills.length}')), const SizedBox(width: 8), Expanded(child: MetricBox(label: 'BUY / SELL', value: '$buys / $sells')), const SizedBox(width: 8), Expanded(child: MetricBox(label: '23:00-03:00', value: '$night', color: night > 0 ? FxFColors.negative : FxFColors.positive))]),
        if (fills.isNotEmpty) ...[const SizedBox(height: 10), GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('最近行为', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8), for (final f in fills.take(12)) Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Text('${f.observedAt.toLocal()}  ${f.side} ${f.symbol} ${f.quantity}', style: const TextStyle(color: FxFColors.muted))) ]))],
      ]);
    }),
  ])))) ;
}
