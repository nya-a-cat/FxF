import 'dart:math' as math;
import 'models.dart';

class BacktestConfig {
  const BacktestConfig({this.fastEma = 20, this.slowEma = 50, this.feeBps = 5, this.slippageBps = 2, this.initialCapital = 10000});
  final int fastEma;
  final int slowEma;
  final double feeBps;
  final double slippageBps;
  final double initialCapital;
}

class BacktestResult {
  const BacktestResult({required this.equity, required this.trades, required this.totalReturn, required this.cagr, required this.sharpe, required this.sortino, required this.maxDrawdown, required this.winRate});
  final List<double> equity;
  final int trades;
  final double totalReturn;
  final double cagr;
  final double sharpe;
  final double sortino;
  final double maxDrawdown;
  final double winRate;
}

class BacktestEngine {
  const BacktestEngine();
  BacktestResult emaCross(List<Candle> candles, BacktestConfig cfg) {
    if (cfg.fastEma >= cfg.slowEma) throw ArgumentError('fastEma must be smaller than slowEma');
    if (candles.length <= cfg.slowEma + 2) throw ArgumentError('Not enough candles');
    final closes = candles.map((e) => e.close).toList(growable: false);
    final fast = _ema(closes, cfg.fastEma);
    final slow = _ema(closes, cfg.slowEma);
    var cash = cfg.initialCapital;
    var units = 0.0;
    var entry = 0.0;
    var wins = 0;
    var trades = 0;
    final equity = <double>[];
    for (var i = 1; i < candles.length; i++) {
      final px = candles[i].close;
      final wasBelow = fast[i - 1] <= slow[i - 1];
      final nowAbove = fast[i] > slow[i];
      final wasAbove = fast[i - 1] >= slow[i - 1];
      final nowBelow = fast[i] < slow[i];
      if (units == 0 && wasBelow && nowAbove) {
        final buyPx = px * (1 + cfg.slippageBps / 10000);
        final fee = cash * cfg.feeBps / 10000;
        units = (cash - fee) / buyPx;
        cash = 0;
        entry = buyPx;
      } else if (units > 0 && wasAbove && nowBelow) {
        final sellPx = px * (1 - cfg.slippageBps / 10000);
        final gross = units * sellPx;
        final fee = gross * cfg.feeBps / 10000;
        cash = gross - fee;
        if (sellPx > entry) wins++;
        units = 0;
        trades++;
      }
      equity.add(cash + units * px);
    }
    if (units > 0) {
      final px = candles.last.close;
      cash = units * px * (1 - cfg.feeBps / 10000);
      if (px > entry) wins++;
      trades++;
      equity[equity.length - 1] = cash;
    }
    final totalReturn = equity.last / cfg.initialCapital - 1;
    final days = candles.last.openTime.difference(candles.first.openTime).inHours / 24.0;
    final years = math.max(days / 365.25, 1 / 365.25).toDouble();
    final cagr = math.pow(equity.last / cfg.initialCapital, 1 / years).toDouble() - 1;
    final returns = <double>[];
    for (var i = 1; i < equity.length; i++) {
      if (equity[i - 1] != 0) returns.add(equity[i] / equity[i - 1] - 1);
    }
    return BacktestResult(
      equity: equity,
      trades: trades,
      totalReturn: totalReturn,
      cagr: cagr,
      sharpe: RiskAnalytics.sharpe(returns),
      sortino: RiskAnalytics.sortino(returns),
      maxDrawdown: RiskAnalytics.maxDrawdown(equity),
      winRate: trades == 0 ? 0.0 : wins / trades,
    );
  }

  List<double> _ema(List<double> values, int period) {
    final out = List<double>.filled(values.length, values.first);
    final k = 2 / (period + 1);
    for (var i = 1; i < values.length; i++) out[i] = values[i] * k + out[i - 1] * (1 - k);
    return out;
  }
}

class RiskAnalytics {
  static double mean(List<double> xs) => xs.isEmpty ? 0.0 : xs.reduce((a, b) => a + b) / xs.length;

  static double std(List<double> xs) {
    if (xs.length < 2) return 0.0;
    final m = mean(xs);
    final variance = xs.map((x) => math.pow(x - m, 2).toDouble()).reduce((a, b) => a + b) / (xs.length - 1);
    return math.sqrt(variance);
  }

  static double sharpe(List<double> returns, {double periodsPerYear = 365 * 24}) {
    final s = std(returns);
    return s == 0 ? 0.0 : mean(returns) / s * math.sqrt(periodsPerYear);
  }

  static double sortino(List<double> returns, {double periodsPerYear = 365 * 24}) {
    final downside = returns.where((x) => x < 0).toList();
    final s = std(downside);
    return s == 0 ? 0.0 : mean(returns) / s * math.sqrt(periodsPerYear);
  }

  static double maxDrawdown(List<double> equity) {
    if (equity.isEmpty) return 0.0;
    var peak = equity.first;
    var dd = 0.0;
    for (final x in equity) {
      if (x > peak) peak = x;
      final d = peak == 0 ? 0.0 : x / peak - 1;
      if (d < dd) dd = d;
    }
    return dd;
  }

  static double historicalVar(List<double> returns, {double confidence = .95}) {
    if (returns.isEmpty) return 0.0;
    final xs = [...returns]..sort();
    final idx = ((1 - confidence) * (xs.length - 1)).floor().clamp(0, xs.length - 1).toInt();
    return xs[idx];
  }

  static double historicalCvar(List<double> returns, {double confidence = .95}) {
    final v = historicalVar(returns, confidence: confidence);
    final tail = returns.where((r) => r <= v).toList();
    return mean(tail);
  }
}

class OptionPayoff {
  static double atExpiration(List<OptionLeg> legs, double underlyingPrice) {
    var pnl = 0.0;
    for (final leg in legs) {
      final intrinsic = leg.instrument.isCall
          ? math.max(0, underlyingPrice - leg.instrument.strike).toDouble()
          : math.max(0, leg.instrument.strike - underlyingPrice).toDouble();
      pnl += leg.quantity.toDouble() * (intrinsic - leg.premium);
    }
    return pnl;
  }
}
