import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'core/models.dart';
import 'theme.dart';

class AquaBackground extends StatelessWidget {
  const AquaBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE7F9FF), Color(0xFFFBFDFF), Color(0xFFEAF8FF)]),
        ),
        child: Stack(children: [
          const Positioned(top: 82, right: 22, child: _Bubble(64)),
          const Positioned(top: 220, left: 12, child: _Bubble(28)),
          const Positioned(bottom: 180, right: 14, child: _Bubble(42)),
          child,
        ]),
      );
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.size);
  final double size;
  @override Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white), gradient: const LinearGradient(colors: [Color(0x55FFFFFF), Color(0x2220C6D7)])));
}

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  @override Widget build(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: .84),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white), boxShadow: const [BoxShadow(color: Color(0x12006A8E), blurRadius: 22, offset: Offset(0, 8))]),
            child: child,
          ),
        ),
      );
}

class FxFHeader extends StatelessWidget {
  const FxFHeader({super.key, this.subtitle = '全球量化研究终端'});
  final String subtitle;
  @override Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
        child: Row(children: [
          Container(width: 38, height: 38, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF8BE8F4), Color(0xFF1EAFC8)])), child: const Icon(Icons.water_drop_rounded, color: Colors.white)),
          const SizedBox(width: 9),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('FxF', style: Theme.of(context).textTheme.headlineMedium), Text(subtitle, style: const TextStyle(color: FxFColors.muted, fontSize: 10))]),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .75), borderRadius: BorderRadius.circular(18)), child: const Row(children: [CircleAvatar(radius: 4, backgroundColor: FxFColors.positive), SizedBox(width: 6), Text('LIVE', style: TextStyle(color: FxFColors.primaryDark, fontWeight: FontWeight.w800, fontSize: 11))])),
        ]),
      );
}

class MascotPanel extends StatelessWidget {
  const MascotPanel({super.key, required this.title, required this.message, this.warning = false});
  final String title;
  final String message;
  final bool warning;
  @override Widget build(BuildContext context) => GlassCard(child: Row(children: [
        Container(width: 72, height: 72, decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [Color(0xFFD8F7FC), Colors.white])), child: Stack(alignment: Alignment.center, children: [const Icon(Icons.water_drop_rounded, size: 48, color: Color(0x6630B8CC)), Icon(warning ? Icons.warning_amber_rounded : Icons.auto_awesome, color: warning ? FxFColors.warning : FxFColors.primaryDark)])),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 4), Text(message, style: Theme.of(context).textTheme.bodyMedium)])),
      ]));
}

class AsyncPane<T> extends StatelessWidget {
  const AsyncPane({super.key, required this.future, required this.builder, this.emptyMessage = '暂无数据'});
  final Future<T> future;
  final Widget Function(BuildContext, T) builder;
  final String emptyMessage;
  @override Widget build(BuildContext context) => FutureBuilder<T>(future: future, builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator()));
        if (snapshot.hasError) return GlassCard(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.cloud_off_rounded, color: FxFColors.negative), const SizedBox(width: 10), Expanded(child: Text('真实数据源暂不可用\n${snapshot.error}', style: const TextStyle(color: FxFColors.muted)))]));
        if (!snapshot.hasData) return GlassCard(child: Text(emptyMessage));
        return builder(context, snapshot.data as T);
      });
}

class QuoteTile extends StatelessWidget {
  const QuoteTile({super.key, required this.quote, this.onTap});
  final MarketQuote quote;
  final VoidCallback? onTap;
  @override Widget build(BuildContext context) => GlassCard(onTap: onTap, padding: const EdgeInsets.all(13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(quote.symbol, style: const TextStyle(color: FxFColors.ink, fontWeight: FontWeight.w800)),
        const Spacer(),
        Text(quote.price.toStringAsFixed(quote.price < 100 ? 4 : 2), style: const TextStyle(color: FxFColors.ink, fontWeight: FontWeight.w800, fontSize: 20)),
        Text('${quote.changePercent >= 0 ? '+' : ''}${quote.changePercent.toStringAsFixed(2)}%', style: TextStyle(color: quote.changePercent >= 0 ? FxFColors.positive : FxFColors.negative, fontWeight: FontWeight.w700)),
      ]));
}

class CandleLineChart extends StatelessWidget {
  const CandleLineChart({super.key, required this.candles, this.height = 180, this.negative = false});
  final List<Candle> candles;
  final double height;
  final bool negative;
  @override Widget build(BuildContext context) {
    if (candles.isEmpty) return const SizedBox.shrink();
    final sample = candles.length > 120 ? candles.sublist(candles.length - 120) : candles;
    final minY = sample.map((e) => e.close).reduce((a, b) => a < b ? a : b);
    final maxY = sample.map((e) => e.close).reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY).abs() * .08 + .000001;
    return SizedBox(height: height, child: LineChart(LineChartData(
      minY: minY - pad,
      maxY: maxY + pad,
      gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => const FlLine(color: FxFColors.line, strokeWidth: 1)),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [LineChartBarData(spots: [for (var i = 0; i < sample.length; i++) FlSpot(i.toDouble(), sample[i].close)], isCurved: true, barWidth: 2.5, color: negative ? FxFColors.negative : FxFColors.primary, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: (negative ? FxFColors.negative : FxFColors.primary).withValues(alpha: .10)))],
    )));
  }
}

class MetricBox extends StatelessWidget {
  const MetricBox({super.key, required this.label, required this.value, this.color = FxFColors.ink, this.sub});
  final String label;
  final String value;
  final Color color;
  final String? sub;
  @override Widget build(BuildContext context) => GlassCard(padding: const EdgeInsets.all(13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: FxFColors.muted, fontSize: 11)), const SizedBox(height: 5), Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)), if (sub != null) ...[const SizedBox(height: 3), Text(sub!, style: const TextStyle(color: FxFColors.muted, fontSize: 11))]]));
}
