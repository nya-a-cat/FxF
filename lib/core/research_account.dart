import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'market_data.dart';
import 'models.dart';

class ResearchAccount {
  ResearchAccount(this.market);
  final BinanceMarketData market;
  static const _key = 'research_fills_v1';

  Future<List<ResearchFill>> fills() async {
    final p = await SharedPreferences.getInstance();
    final rows = p.getStringList(_key) ?? const [];
    return rows.map((s) => ResearchFill.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList()..sort((a, b) => b.observedAt.compareTo(a.observedAt));
  }

  Future<ResearchFill> recordAtObservedQuote({required String symbol, required String side, required double quantity}) async {
    if (quantity <= 0) throw ArgumentError.value(quantity, 'quantity', 'must be positive');
    final book = await market.bookTicker(symbol);
    final price = side.toUpperCase() == 'BUY' ? book.ask : book.bid;
    final fill = ResearchFill(id: DateTime.now().microsecondsSinceEpoch.toString(), symbol: symbol, side: side.toUpperCase(), quantity: quantity, price: price, observedAt: book.timestamp);
    final p = await SharedPreferences.getInstance();
    final rows = p.getStringList(_key) ?? <String>[];
    await p.setStringList(_key, [...rows, jsonEncode(fill.toJson())]);
    return fill;
  }
}
