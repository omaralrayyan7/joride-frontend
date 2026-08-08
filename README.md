# JoRide Frontend

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev/)
[![Provider](https://img.shields.io/badge/State-Provider-informational)](https://pub.dev/packages/provider)

Flutter mobile/web application for the **JoRide** self-service car-rental platform in Jordan. Users browse vehicles, book by the minute/hour/day, pay via in-app wallet, receive a **digital key** to unlock the car, and track trip cost with a live fare meter. Supports Arabic and English (RTL) and dark/light themes.

> **Related:** [joride-backend](https://github.com/omaralrayyan7/joride-backend) — ASP.NET Core REST API

## Screenshots

| Home | Car Details | Fare Meter | Wallet |
|------|------------|-----------|--------|
| ![home](docs/screen_home.png) | ![car](docs/screen_car.png) | ![fare](docs/screen_fare.png) | ![wallet](docs/screen_wallet.png) |

> Screenshots captured on Android emulator. Run the app to see the full UI.

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Provider (ChangeNotifier) |
| HTTP Client | `http` package → JoRide Backend REST API |
| Auth Storage | `flutter_secure_storage` (JWT) |
| i18n | `flutter_localizations` (AR / EN) |
| Calendar | `table_calendar` |

## Key Features

- **Vehicle Browser** — filter by availability, type, price
- **Live Booking** — select duration (minutes/hours/days), confirm fare upfront
- **Digital Key** — receive time-limited unlock token on trip start
- **Fare Meter** — real-time cost counter during active trip
- **In-app Wallet** — top up, pay trips, view transaction history
- **AR / EN + RTL** — full bilingual support with automatic RTL layout
- **Dark / Light Theme** — persisted preference via Provider

## Screens

| Screen | Purpose |
|---|---|
| Login / Register | JWT auth with license upload |
| Home | Vehicle listing with availability filter |
| Car Details | Specs + booking form |
| Fare Meter | Live timer & cost during trip |
| Digital Key | Unlock/lock the rented car |
| Wallet | Balance, top-up, history |
| My Reservations | Past and active trips |
| Admin Dashboard | User & fleet management |

## Getting Started

```bash
git clone https://github.com/omaralrayyan7/joride-frontend.git
cd joride-frontend
flutter pub get
```

```bash
flutter run
```

Requires Flutter SDK ≥ 3.0.0. Tested on Android and Web.

### Configuring the backend URL

`ApiService.baseUrl` defaults to `http://localhost:9000` (web) / `http://10.0.2.2:9000` (Android emulator) for local development. Point the app at a different backend — staging, production, or a LAN-hosted dev server — with `--dart-define=BASE_URL=...` at run or build time:

```bash
# Local backend (default, no flag needed)
flutter run -d chrome

# Staging
flutter run -d chrome --dart-define=BASE_URL=https://staging.joride.app

# Production build
flutter build web --dart-define=BASE_URL=https://api.joride.app
```

## License

[MIT](LICENSE)
