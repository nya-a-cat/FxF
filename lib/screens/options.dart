import 'package:flutter/material.dart';
import '../core/analytics.dart';
import '../core/models.dart';
import '../services.dart';
import '../theme.dart';
import '../ui.dart';

class OptionsScreen extends StatefulWidget {
  const OptionsScreen({super.key});
  @override State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  String currency = 'BTC';
  DateTime? selectedExpiry;
  late Future<({List<OptionInstrument> chain, MarketQuote spot})> future;
  final legs = <OptionLeg>[];
  double payoffPrice = 0;

  @override
  void initState() {
    super.initState();
    future = _load(currency);
  }

  Future<({List<OptionInstrument> chain, MarketQuote spot})> _load(String value) async {
    final symbol = value == 'BTC' ? 'BTCUSDT' : 'ETHUSDT';
    final result = await Future.wait<dynamic>([
      deribit.optionChain(value),
      binance.quote(symbol),
    ]);
    return (chain: result[0] as List<OptionInstrument>, spot: result[1] as MarketQuote);
  }

  void _reload(String value) => setState(() {
        currency = value;
        selectedExpiry = null;
        legs.clear();
        payoffPrice = 0;
        future = _load(value);
      });

  double? _premium(OptionInstrument option) => option.markPrice ??
      ((option.bid != null && option.ask != null) ? (option.bid! + option.ask!) / 2 : null);

  void _addLeg(OptionInstrument option, int quantity) {
    final premium = _premium(option);
    if (premium == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('该合约当前没有可用真实报价')));
      return;
    }
    setState(() {
      final index = legs.indexWhere((x) => x.instrument.name == option.name);
      if (index >= 0) legs.removeAt(index);
      legs.add(OptionLeg(instrument: option, quantity: quantity, premium: premium));
    });
  }

  OptionInstrument? _nearest(List<OptionInstrument> options, double spot, {required bool call}) {
    final filtered = options.where((o) => o.isCall == call && _premium(o) != null).toList();
    if (filtered.isEmpty) return null;
    filtered.sort((a, b) => (a.strike - spot).abs().compareTo((b.strike - spot).abs()));
    return filtered.first;
  }

  void _preset(String name, List<OptionInstrument> chain, double spot) {
    final expiry = selectedExpiry ?? chain.first.expiration;
    final options = chain.where((o) => o.expiration == expiry).toList();
    if (options.isEmpty) return;
    final calls = options.where((o) => o.isCall && _premium(o) != null).toList()..sort((a, b) => a.strike.compareTo(b.strike));
    final puts = options.where((o) => !o.isCall && _premium(o) != null).toList()..sort((a, b) => a.strike.compareTo(b.strike));
    final atmCall = _nearest(options, spot, call: true);
    final atmPut = _nearest(options, spot, call: false);
    if (atmCall == null || atmPut == null) return;

    final preset = <OptionLeg>[];
    void add(OptionInstrument option, int quantity) {
      final premium = _premium(option);
      if (premium != null) preset.add(OptionLeg(instrument: option, quantity: quantity, premium: premium));
    }

    if (name == 'Straddle') {
      add(atmCall, 1);
      add(atmPut, 1);
    } else if (name == 'Bull Call') {
      final higher = calls.where((o) => o.strike > atmCall.strike).take(1).toList();
      if (higher.isEmpty) return;
      add(atmCall, 1);
      add(higher.first, -1);
    } else if (name == 'Bear Put') {
      final lower = puts.where((o) => o.strike < atmPut.strike).toList();
      if (lower.isEmpty) return;
      add(atmPut, 1);
      add(lower.last, -1);
    } else if (name == 'Iron Condor') {
      final lowerPuts = puts.where((o) => o.strike < spot).toList();
      final higherCalls = calls.where((o) => o.strike > spot).toList();
      if (lowerPuts.length < 2 || higherCalls.length < 2) return;
      final shortPut = lowerPuts.last;
      final longPut = lowerPuts[lowerPuts.length - 2];
      final shortCall = higherCalls.first;
      final longCall = higherCalls[1];
      add(longPut, 1);
      add(shortPut, -1);
      add(shortCall, -1);
      add(longCall, 1);
    }

    setState(() {
      legs
        ..clear()
        ..addAll(preset);
      payoffPrice = spot;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: AquaBackground(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
                  Text('期权实验室', style: Theme.of(context).textTheme.headlineMedium),
                  const Spacer(),
                  DropdownButton<String>(
                    value: currency,
                    items: const [
                      DropdownMenuItem(value: 'BTC', child: Text('BTC')),
                      DropdownMenuItem(value: 'ETH', child: Text('ETH')),
                    ],
                    onChanged: (value) {
                      if (value != null) _reload(value);
                    },
                  ),
                ]),
                const Text('Deribit Public API · 任意多腿 / 多到期组合', style: TextStyle(color: FxFColors.muted)),
                const SizedBox(height: 12),
                AsyncPane<({List<OptionInstrument> chain, MarketQuote spot})>(
                  future: future,
                  builder: (_, data) {
                    final chain = data.chain;
                    final spot = data.spot.price;
                    if (chain.isEmpty) return const GlassCard(child: Text('当前没有可用期权合约'));
                    final expiries = chain.map((o) => o.expiration).toSet().toList()..sort();
                    final expiry = selectedExpiry != null && expiries.contains(selectedExpiry) ? selectedExpiry! : expiries.first;
                    final expiryChain = chain.where((o) => o.expiration == expiry).toList();
                    if (payoffPrice == 0) payoffPrice = spot;

                    return Column(children: [
                      GlassCard(
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('标的现价', style: TextStyle(color: FxFColors.muted)),
                            Text('${data.spot.symbol}  ${spot.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
                          ])),
                          DropdownButton<DateTime>(
                            value: expiry,
                            items: [for (final e in expiries) DropdownMenuItem(value: e, child: Text(e.toIso8601String().split('T').first))],
                            onChanged: (value) => setState(() => selectedExpiry = value),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 10),
                      GlassCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('快捷策略', style: TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            ActionChip(label: const Text('Long Straddle'), onPressed: () => _preset('Straddle', chain, spot)),
                            ActionChip(label: const Text('Bull Call Spread'), onPressed: () => _preset('Bull Call', chain, spot)),
                            ActionChip(label: const Text('Bear Put Spread'), onPressed: () => _preset('Bear Put', chain, spot)),
                            ActionChip(label: const Text('Iron Condor'), onPressed: () => _preset('Iron Condor', chain, spot)),
                            ActionChip(label: const Text('Clear'), onPressed: () => setState(legs.clear)),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 10),
                      GlassCard(
                        child: Column(children: [
                          for (final option in expiryChain.take(80))
                            _OptionContractRow(
                              option: option,
                              selected: legs.any((x) => x.instrument.name == option.name),
                              onBuy: () => _addLeg(option, 1),
                              onSell: () => _addLeg(option, -1),
                            ),
                        ]),
                      ),
                      const SizedBox(height: 10),
                      if (legs.isNotEmpty)
                        _LegBuilder(
                          legs: legs,
                          underlyingPrice: payoffPrice,
                          onPriceChanged: (value) => setState(() => payoffPrice = value),
                        ),
                      const SizedBox(height: 10),
                      const MascotPanel(
                        title: '全策略不是菜单，是表达能力',
                        message: '你可以切换到期日后继续加腿，因此 Calendar / Diagonal 也能表达。多到期组合不会被强行塞进一个错误的单到期 payoff。',
                      ),
                    ]);
                  },
                ),
              ],
            ),
          ),
        ),
      );
}

class _OptionContractRow extends StatelessWidget {
  const _OptionContractRow({required this.option, required this.selected, required this.onBuy, required this.onSell});
  final OptionInstrument option;
  final bool selected;
  final VoidCallback onBuy;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(width: 72, child: Text(option.strike.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.w700))),
          SizedBox(width: 42, child: Text(option.isCall ? 'CALL' : 'PUT', style: TextStyle(color: option.isCall ? FxFColors.positive : FxFColors.negative, fontWeight: FontWeight.w800, fontSize: 11))),
          Expanded(child: Text('Mark ${option.markPrice?.toStringAsFixed(4) ?? '—'} · Bid ${option.bid?.toStringAsFixed(4) ?? '—'} · Ask ${option.ask?.toStringAsFixed(4) ?? '—'}', overflow: TextOverflow.ellipsis, style: const TextStyle(color: FxFColors.muted, fontSize: 11))),
          IconButton(onPressed: onBuy, tooltip: '买入腿', icon: const Icon(Icons.add_circle_outline, color: FxFColors.positive)),
          IconButton(onPressed: onSell, tooltip: '卖出腿', icon: const Icon(Icons.remove_circle_outline, color: FxFColors.negative)),
          if (selected) const Icon(Icons.check_circle, color: FxFColors.primaryDark, size: 18),
        ]),
      );
}

class _LegBuilder extends StatelessWidget {
  const _LegBuilder({required this.legs, required this.underlyingPrice, required this.onPriceChanged});
  final List<OptionLeg> legs;
  final double underlyingPrice;
  final ValueChanged<double> onPriceChanged;

  @override
  Widget build(BuildContext context) {
    final expiries = legs.map((x) => x.instrument.expiration).toSet();
    final sameExpiry = expiries.length == 1;
    final minStrike = legs.map((x) => x.instrument.strike).reduce((a, b) => a < b ? a : b);
    final maxStrike = legs.map((x) => x.instrument.strike).reduce((a, b) => a > b ? a : b);
    final lower = minStrike * .7;
    final upper = maxStrike * 1.3;
    final clamped = underlyingPrice.clamp(lower, upper).toDouble();
    final pnl = sameExpiry ? OptionPayoff.deribitInverseAtExpiration(legs, clamped) : null;

    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('当前组合 · ${legs.length} legs', style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        for (final leg in legs)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '${leg.quantity > 0 ? 'BUY' : 'SELL'} ${leg.quantity.abs()} × ${leg.instrument.name} @ ${leg.premium.toStringAsFixed(4)}',
              style: TextStyle(color: leg.quantity > 0 ? FxFColors.positive : FxFColors.negative),
            ),
          ),
        const Divider(),
        if (sameExpiry) ...[
          Text('交割价 ${clamped.toStringAsFixed(2)}'),
          Slider(value: clamped, min: lower, max: upper, onChanged: onPriceChanged),
          Text('到期 P/L ${pnl!.toStringAsFixed(4)} $currency', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: pnl! >= 0 ? FxFColors.positive : FxFColors.negative)),
        ] else
          const Text('该组合包含多个到期日。Calendar / Diagonal 的价值依赖时间、波动率和远期曲面，不能用单一到期内在价值图准确表达。', style: TextStyle(color: FxFColors.warning, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
