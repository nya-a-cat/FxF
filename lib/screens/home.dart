import 'package:flutter/material.dart';
import '../core/models.dart';
import '../services.dart';
import '../theme.dart';
import '../ui.dart';
import 'behavior.dart';
import 'options.dart';
import 'trade.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<MarketQuote>> quotesFuture;
  late Future<List<Candle>> candlesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    quotesFuture = binance.quotes(const [
      'BTCUSDT',
      'ETHUSDT',
      'SOLUSDT',
      'BNBUSDT',
      'XRPUSDT',
    ]);
    candlesFuture = binance.candles('BTCUSDT', interval: '1h', limit: 168);
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: () async {
          setState(_reload);
          await Future.wait<dynamic>([quotesFuture, candlesFuture]);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const FxFHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('市场概览', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 4),
                  const Text('Binance Public API · 实时请求', style: TextStyle(color: FxFColors.muted)),
                  const SizedBox(height: 14),
                  AsyncPane<List<MarketQuote>>(
                    future: quotesFuture,
                    builder: (context, quotes) => SizedBox(
                      height: 130,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: quotes.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => SizedBox(
                          width: 150,
                          child: QuoteTile(
                            quote: quotes[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TradeScreen(symbol: quotes[i].symbol)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AsyncPane<List<Candle>>(
                    future: candlesFuture,
                    builder: (_, candles) => GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BTC · 最近 7 天', style: TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          CandleLineChart(candles: candles, height: 190),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const MascotPanel(title: '泽澜 · Market Note', message: '网络断了就是断了，FxF 不会用本地假行情把页面装满。'),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OptionsScreen())),
                          child: const _Shortcut(Icons.stacked_line_chart, '期权实验室', 'Deribit 实时链'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassCard(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BehaviorScreen())),
                          child: const _Shortcut(Icons.psychology_alt_outlined, '行为日志', '基于真实记录'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _Shortcut extends StatelessWidget {
  const _Shortcut(this.icon, this.title, this.sub);
  final IconData icon;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: FxFColors.primaryDark),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: FxFColors.ink, fontWeight: FontWeight.w800)),
          Text(sub, style: const TextStyle(color: FxFColors.muted, fontSize: 11)),
        ],
      );
}
