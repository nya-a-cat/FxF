class MarketQuote {
  const MarketQuote({required this.symbol, required this.price, required this.changePercent, required this.high, required this.low, required this.volume, required this.timestamp});
  final String symbol;
  final double price;
  final double changePercent;
  final double high;
  final double low;
  final double volume;
  final DateTime timestamp;
}

class Candle {
  const Candle({required this.openTime, required this.open, required this.high, required this.low, required this.close, required this.volume});
  final DateTime openTime;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
}

class BookTicker {
  const BookTicker({required this.symbol, required this.bid, required this.bidQty, required this.ask, required this.askQty, required this.timestamp});
  final String symbol;
  final double bid;
  final double bidQty;
  final double ask;
  final double askQty;
  final DateTime timestamp;
  double get mid => (bid + ask) / 2;
  double get spread => ask - bid;
}

class OptionInstrument {
  const OptionInstrument({required this.name, required this.underlying, required this.expiration, required this.strike, required this.isCall, required this.bid, required this.ask, required this.markPrice, required this.iv, required this.delta, required this.gamma, required this.theta, required this.vega});
  final String name;
  final String underlying;
  final DateTime expiration;
  final double strike;
  final bool isCall;
  final double? bid;
  final double? ask;
  final double? markPrice;
  final double? iv;
  final double? delta;
  final double? gamma;
  final double? theta;
  final double? vega;
}

class OptionLeg {
  const OptionLeg({required this.instrument, required this.quantity, required this.premium});
  final OptionInstrument instrument;
  final int quantity;
  final double premium;
}

class ResearchFill {
  const ResearchFill({required this.id, required this.symbol, required this.side, required this.quantity, required this.price, required this.observedAt});
  final String id;
  final String symbol;
  final String side;
  final double quantity;
  final double price;
  final DateTime observedAt;

  Map<String, dynamic> toJson() => {'id': id, 'symbol': symbol, 'side': side, 'quantity': quantity, 'price': price, 'observedAt': observedAt.toIso8601String()};
  factory ResearchFill.fromJson(Map<String, dynamic> j) => ResearchFill(id: j['id'] as String, symbol: j['symbol'] as String, side: j['side'] as String, quantity: (j['quantity'] as num).toDouble(), price: (j['price'] as num).toDouble(), observedAt: DateTime.parse(j['observedAt'] as String));
}
