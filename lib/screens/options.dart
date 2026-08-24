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
  late Future<List<OptionInstrument>> future;
  final legs = <OptionLeg>[];
  double payoffPrice = 0;

  @override void initState() { super.initState(); future = deribit.optionChain(currency); }

  void _reload(String value) => setState(() { currency = value; legs.clear(); future = deribit.optionChain(value); });

  void _toggleLeg(OptionInstrument o, int quantity) {
    final premium = o.markPrice ?? ((o.bid != null && o.ask != null) ? ((o.bid! + o.ask!) / 2) : null);
    if (premium == null) return;
    setState(() {
      final index = legs.indexWhere((x) => x.instrument.name == o.name);
      if (index >= 0) {
        legs.removeAt(index);
      } else {
        legs.add(OptionLeg(instrument: o, quantity: quantity, premium: premium));
      }
    });
  }

  @override Widget build(BuildContext context) => Scaffold(body: AquaBackground(child: SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
    Row(children: [
      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
      Text('期权实验室', style: Theme.of(context).textTheme.headlineMedium),
      const Spacer(),
      DropdownButton<String>(value: currency, items: const [DropdownMenuItem(value: 'BTC', child: Text('BTC')), DropdownMenuItem(value: 'ETH', child: Text('ETH'))], onChanged: (v) { if (v != null) _reload(v); }),
    ]),
    const Text('Deribit Public API · 任意多腿组合', style: TextStyle(color: FxFColors.muted)),
    const SizedBox(height: 12),
    AsyncPane<List<OptionInstrument>>(future: future, builder: (_, chain) {
      if (chain.isEmpty) return const GlassCard(child: Text('当前没有可用期权合约'));
      final expiry = chain.first.expiration;
      final expiryChain = chain.where((o) => o.expiration == expiry).toList();
      final strikes = expiryChain.map((o) => o.strike).toSet().toList()..sort();
      if (payoffPrice == 0 && strikes.isNotEmpty) payoffPrice = strikes[strikes.length ~/ 2];
      return Column(children: [
        GlassCard(child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('最近到期', style: TextStyle(color: FxFColors.muted)), Text(expiry.toIso8601String().split('T').first, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20))])), Text('${expiryChain.length} contracts', style: const TextStyle(color: FxFColors.primaryDark, fontWeight: FontWeight.w800))])),
        const SizedBox(height: 10),
        GlassCard(child: Column(children: [for (final o in expiryChain.take(60)) _OptionContractRow(option: o, selected: legs.any((x) => x.instrument.name == o.name), onBuy: () => _toggleLeg(o, 1), onSell: () => _toggleLeg(o, -1))])),
        const SizedBox(height: 10),
        if (legs.isNotEmpty) _LegBuilder(legs: legs, underlyingPrice: payoffPrice, onPriceChanged: (v) => setState(() => payoffPrice = v)),
        const SizedBox(height: 10),
        const MascotPanel(title: '全策略不是菜单，是表达能力', message: 'Straddle、Strangle、Vertical、Calendar、Butterfly、Iron Condor 最终都只是多腿 Call/Put 组合。FxF 的核心是允许你任意添加正负腿。'),
      ]);
    }),
  ])))) ;
}

class _OptionContractRow extends StatelessWidget {
  const _OptionContractRow({required this.option, required this.selected, required this.onBuy, required this.onSell});
  final OptionInstrument option; final bool selected; final VoidCallback onBuy, onSell;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
    SizedBox(width: 72, child: Text(option.strike.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.w700))),
    SizedBox(width: 42, child: Text(option.isCall ? 'CALL' : 'PUT', style: TextStyle(color: option.isCall ? FxFColors.positive : FxFColors.negative, fontWeight: FontWeight.w800, fontSize: 11))),
    Expanded(child: Text('IV ${option.iv?.toStringAsFixed(1) ?? '—'} · Mark ${option.markPrice?.toStringAsFixed(4) ?? '—'}', overflow: TextOverflow.ellipsis, style: const TextStyle(color: FxFColors.muted, fontSize: 11))),
    IconButton(onPressed: onBuy, tooltip: '买入腿', icon: const Icon(Icons.add_circle_outline, color: FxFColors.positive)),
    IconButton(onPressed: onSell, tooltip: '卖出腿', icon: const Icon(Icons.remove_circle_outline, color: FxFColors.negative)),
    if (selected) const Icon(Icons.check_circle, color: FxFColors.primaryDark, size: 18),
  ]));
}

class _LegBuilder extends StatelessWidget {
  const _LegBuilder({required this.legs, required this.underlyingPrice, required this.onPriceChanged});
  final List<OptionLeg> legs; final double underlyingPrice; final ValueChanged<double> onPriceChanged;
  @override Widget build(BuildContext context) {
    final minStrike = legs.map((x) => x.instrument.strike).reduce((a,b) => a < b ? a : b);
    final maxStrike = legs.map((x) => x.instrument.strike).reduce((a,b) => a > b ? a : b);
    final lower = minStrike * .7;
    final upper = maxStrike * 1.3;
    final clamped = underlyingPrice.clamp(lower, upper).toDouble();
    final pnl = OptionPayoff.atExpiration(legs, clamped);
    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('当前组合 · ${legs.length} legs', style: const TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      for (final leg in legs) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('${leg.quantity > 0 ? 'BUY' : 'SELL'} ${leg.quantity.abs()} × ${leg.instrument.name} @ ${leg.premium.toStringAsFixed(4)}', style: TextStyle(color: leg.quantity > 0 ? FxFColors.positive : FxFColors.negative))),
      const Divider(),
      Text('到期标的价格 ${clamped.toStringAsFixed(2)}'),
      Slider(value: clamped, min: lower, max: upper, onChanged: onPriceChanged),
      Text('到期 P/L ${pnl.toStringAsFixed(4)}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: pnl >= 0 ? FxFColors.positive : FxFColors.negative)),
    ]));
  }
}
