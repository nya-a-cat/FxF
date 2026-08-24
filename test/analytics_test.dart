import 'package:flutter_test/flutter_test.dart';
import 'package:fxf/core/analytics.dart';
import 'package:fxf/core/models.dart';

void main() {
  test('historical VaR and CVaR use the left tail', () {
    final r = [-0.10, -0.05, -0.02, 0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07];
    expect(RiskAnalytics.historicalVar(r, confidence: .90), closeTo(-0.10, 1e-9));
    expect(RiskAnalytics.historicalCvar(r, confidence: .90), closeTo(-0.10, 1e-9));
  });

  test('max drawdown finds peak to trough decline', () {
    expect(RiskAnalytics.maxDrawdown([100, 120, 90, 110]), closeTo(-0.25, 1e-9));
  });

  test('vanilla option payoff supports arbitrary signed legs', () {
    final call = OptionInstrument(name: 'X', underlying: 'BTC', expiration: DateTime.utc(2030), strike: 100, isCall: true, bid: null, ask: null, markPrice: null, iv: null, delta: null, gamma: null, theta: null, vega: null);
    final legs = [OptionLeg(instrument: call, quantity: 1, premium: 5)];
    expect(OptionPayoff.vanillaAtExpiration(legs, 120), 15);
    expect(OptionPayoff.vanillaAtExpiration(legs, 80), -5);
  });

  test('Deribit inverse call payoff is settled in base coin', () {
    final call = OptionInstrument(name: 'BTC-X', underlying: 'BTC', expiration: DateTime.utc(2030), strike: 100000, isCall: true, bid: null, ask: null, markPrice: null, iv: null, delta: null, gamma: null, theta: null, vega: null);
    final legs = [OptionLeg(instrument: call, quantity: 1, premium: 0.05)];
    expect(OptionPayoff.deribitInverseAtExpiration(legs, 125000), closeTo(0.15, 1e-9));
  });

  test('backtest rejects inverted EMA parameters', () {
    final candles = List.generate(20, (i) => Candle(openTime: DateTime.utc(2026, 1, 1).add(Duration(hours: i)), open: 100 + i.toDouble(), high: 101 + i.toDouble(), low: 99 + i.toDouble(), close: 100 + i.toDouble(), volume: 1));
    expect(() => const BacktestEngine().emaCross(candles, const BacktestConfig(fastEma: 10, slowEma: 5)), throwsArgumentError);
  });
}
