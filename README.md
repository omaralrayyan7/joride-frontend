# What is JoRide Frontend Project

## Overview

**JoRide Frontend** is a **Flutter** mobile/web application for a self-service car-rental platform in Jordan. Users browse available vehicles, book a car for minutes/hours/days, pay via an in-app wallet, receive a **digital key** to unlock the car, and track trip duration with a live fare meter. The app supports **Arabic and English** (with RTL layout) and **dark/light themes**.

**Tech stack:** Flutter (Dart) · Provider (state management) · HTTP REST client → JoRide Backend API · flutter_secure_storage (JWT persistence) · flutter_localizations (AR/EN i18n)

---

## Key Code Segments

### App Entry & Providers (`lib/main.dart`)
Bootstraps theme and locale providers, and routes unauthenticated users to the login screen.

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
```

### API Service — Auth (`lib/lib/services/api_service.dart`)
Handles login/register and persists the JWT token securely on-device.

```dart
static Future<AuthResponse> login({required String email, required String password}) async {
  final res = await _post('/api/auth/login', {'email': email, 'password': password});
  final auth = AuthResponse.fromJson(res);
  await _storage.write(key: _tokenKey, value: auth.token);
  return auth;
}

static Future<AuthResponse> register({
  required String name, required String email,
  required String password, required String phone, ...
}) async {
  final res = await _post('/api/auth/register', { 'name': name, 'email': email, ... });
  final auth = AuthResponse.fromJson(res);
  await _persistAuth(auth);
  return auth;
}
```

### API Service — Trip Booking
Sends a trip-start request to the backend, which charges the wallet and issues the digital key.

```dart
static Future<Map<String, dynamic>> startTrip({
  required int userId, required int vehicleId,
  required int duration, required String durationType,
  required double totalFare, required String paymentMethod,
}) async {
  return await _post('/api/trips/start', {
    'userId': userId, 'vehicleId': vehicleId,
    'duration': duration, 'durationType': durationType,
    'totalFare': totalFare, 'paymentMethod': paymentMethod,
  });
}
```

### Screens Overview

| Screen | Purpose |
|---|---|
| `login_screen.dart` | Email/password login with JWT storage |
| `register_screen.dart` | New user registration + license upload |
| `Home Screen.dart` | Vehicle listing with availability filter |
| `CarDetailsScreen.dart` | Vehicle specs + booking form |
| `FareMeterScreen.dart` | Live timer & cost during active trip |
| `DigitalKeyScreen.dart` | Unlock/lock the rented car |
| `WalletScreen.dart` | Balance, top-up, transaction history |
| `MyReservationsScreen.dart` | Past and active trip list |
| `AdminDashboardScreen.dart` | Admin-only: user & fleet management |
