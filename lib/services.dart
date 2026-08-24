import 'core/market_data.dart';
import 'core/research_account.dart';

final binance = BinanceMarketData();
final deribit = DeribitMarketData();
final researchAccount = ResearchAccount(binance);
