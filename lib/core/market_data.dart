import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class MarketDataException implements Exception {
  const MarketDataException(this.message);
  final String message;
  @override String toString() => message;
}

class BinanceMarketData {
  BinanceMarketData({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static final Uri _base = Uri.parse('https://api.binance.com');

  Future<MarketQuote> quote(String symbol) async {
    final uri = _base.replace(path: '/api/v3/ticker/24hr', queryParameters: {'symbol': symbol});
    final r = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) throw MarketDataException('Binance ${r.statusCode}: ${r.body}');
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    return MarketQuote(
      symbol: symbol,
      price: double.parse(j['lastPrice'] as String),
      changePercent: double.parse(j['priceChangePercent'] as String),
      high: double.parse(j['highPrice'] as String),
      low: double.parse(j['lowPrice'] as String),
      volume: double.parse(j['volume'] as String),
      timestamp: DateTime.fromMillisecondsSinceEpoch(j['closeTime'] as int, isUtc: true),
    );
  }

  Future<List<MarketQuote>> quotes(Iterable<String> symbols) => Future.wait(symbols.map(quote));

  Future<BookTicker> bookTicker(String symbol) async {
    final uri = _base.replace(path: '/api/v3/ticker/bookTicker', queryParameters: {'symbol': symbol});
    final r = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) throw MarketDataException('Binance book ${r.statusCode}: ${r.body}');
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    return BookTicker(symbol: symbol, bid: double.parse(j['bidPrice'] as String), bidQty: double.parse(j['bidQty'] as String), ask: double.parse(j['askPrice'] as String), askQty: double.parse(j['askQty'] as String), timestamp: DateTime.now().toUtc());
  }

  Future<List<Candle>> candles(String symbol, {String interval = '1h', int limit = 500, DateTime? start, DateTime? end}) async {
    final params = <String, String>{'symbol': symbol, 'interval': interval, 'limit': limit.clamp(1, 1000).toString()};
    if (start != null) params['startTime'] = start.millisecondsSinceEpoch.toString();
    if (end != null) params['endTime'] = end.millisecondsSinceEpoch.toString();
    final uri = _base.replace(path: '/api/v3/klines', queryParameters: params);
    final r = await _client.get(uri).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) throw MarketDataException('Binance klines ${r.statusCode}: ${r.body}');
    final rows = jsonDecode(r.body) as List<dynamic>;
    return rows.map((raw) {
      final x = raw as List<dynamic>;
      return Candle(openTime: DateTime.fromMillisecondsSinceEpoch(x[0] as int, isUtc: true), open: double.parse(x[1] as String), high: double.parse(x[2] as String), low: double.parse(x[3] as String), close: double.parse(x[4] as String), volume: double.parse(x[5] as String));
    }).toList(growable: false);
  }

  Future<List<Candle>> candlesRange(String symbol, {required String interval, required DateTime start, required DateTime end}) async {
    final out = <Candle>[];
    var cursor = start.toUtc();
    while (cursor.isBefore(end)) {
      final page = await candles(symbol, interval: interval, limit: 1000, start: cursor, end: end);
      if (page.isEmpty) break;
      out.addAll(page.where((c) => c.openTime.isBefore(end)));
      final next = page.last.openTime.add(const Duration(milliseconds: 1));
      if (!next.isAfter(cursor)) break;
      cursor = next;
      if (page.length < 1000) break;
    }
    return out;
  }
}

class DeribitMarketData {
  DeribitMarketData({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static final Uri _base = Uri.parse('https://www.deribit.com');

  Future<List<OptionInstrument>> optionChain(String currency) async {
    final uri = _base.replace(path: '/api/v2/public/get_book_summary_by_currency', queryParameters: {'currency': currency.toUpperCase(), 'kind': 'option'});
    final r = await _client.get(uri).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) throw MarketDataException('Deribit ${r.statusCode}: ${r.body}');
    final root = jsonDecode(r.body) as Map<String, dynamic>;
    final result = (root['result'] as List<dynamic>? ?? const []);
    final out = <OptionInstrument>[];
    for (final raw in result) {
      final j = raw as Map<String, dynamic>;
      final name = j['instrument_name'] as String;
      final parsed = _parseInstrumentName(name);
      if (parsed == null) continue;
      out.add(OptionInstrument(name: name, underlying: currency.toUpperCase(), expiration: parsed.$1, strike: parsed.$2, isCall: parsed.$3, bid: (j['bid_price'] as num?)?.toDouble(), ask: (j['ask_price'] as num?)?.toDouble(), markPrice: (j['mark_price'] as num?)?.toDouble(), iv: (j['mark_iv'] as num?)?.toDouble(), delta: null, gamma: null, theta: null, vega: null));
    }
    out.sort((a, b) { final d = a.expiration.compareTo(b.expiration); return d != 0 ? d : a.strike.compareTo(b.strike); });
    return out;
  }

  (DateTime, double, bool)? _parseInstrumentName(String name) {
    final p = name.split('-');
    if (p.length != 4) return null;
    final date = _parseDeribitDate(p[1]);
    final strike = double.tryParse(p[2]);
    if (date == null || strike == null) return null;
    return (date, strike, p[3] == 'C');
  }

  DateTime? _parseDeribitDate(String s) {
    final m = RegExp(r'^(\d{1,2})([A-Z]{3})(\d{2})$').firstMatch(s);
    if (m == null) return null;
    const months = {'JAN':1,'FEB':2,'MAR':3,'APR':4,'MAY':5,'JUN':6,'JUL':7,'AUG':8,'SEP':9,'OCT':10,'NOV':11,'DEC':12};
    final month = months[m.group(2)];
    if (month == null) return null;
    return DateTime.utc(2000 + int.parse(m.group(3)!), month, int.parse(m.group(1)!), 8);
  }
}
