# FxF

FxF is an anime-themed quantitative research playground for Android.

## v0.1 principles

- **No mock market numbers.** Screens render live/public market data or a clear unavailable/configuration state.
- Real crypto market data comes from Binance public REST endpoints.
- Real BTC/ETH option-chain data comes from Deribit public endpoints.
- Backtests run locally over downloaded historical candles; metrics are calculated by FxF.
- The generic option engine supports arbitrary multi-leg combinations, so named strategies are presets rather than hard-coded products.
- The research account records fills against observed market quotes locally. It does **not** connect to a broker/exchange account, custody assets, deposit/withdraw funds, or submit real-money orders.

The product intentionally looks like a serious quant terminal. The execution boundary is disclosed when the user reaches an action that could reasonably be mistaken for a real-money transaction.

## Bootstrap and run

Requirements: Flutter stable, Android SDK.

```bash
./tool/bootstrap.sh
flutter run
```

For CI the Android platform folder is generated from the Flutter SDK to keep the repository focused on application code.
