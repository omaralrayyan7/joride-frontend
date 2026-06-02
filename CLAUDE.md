# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`joRide` is a Flutter **web** app for a car-rental / IoT-tracking concept set in Amman, Jordan. Prices are displayed in JOD; map is centered on `LatLng(32.0252, 35.8850)`.

## Repo state — read this first

This checkout is partial and will not build as-is. Two things to know before running anything:

1. **`pubspec.yaml` is missing.** Only `pubspec.lock` is present. Before `flutter pub get` will work, a `pubspec.yaml` must be reconstructed. The direct dependencies recorded in `pubspec.lock` are:
   - `flutter` (SDK), `cupertino_icons`, `google_maps_flutter`, `http`, `location`, `provider`, `shared_preferences`
   - SDK constraints: `dart: ">=3.8.0 <4.0.0"`, `flutter: ">=3.32.0"`
2. **Only the `web/` platform directory exists** — no `android/`, `ios/`, `linux/`, `macos/`, `windows/`. This is a web-only project. To target other platforms run `flutter create . --platforms=android,ios` first.

## Commands

Once `pubspec.yaml` is restored:

```bash
flutter pub get          # install deps
flutter run -d chrome    # run on web (the only configured platform)
flutter analyze          # static analysis
flutter build web        # production build → build/web/
```

There is no test directory and no test framework configured in the lockfile, so `flutter test` will be a no-op until tests are added.

## Architecture

### Directory layout quirk

The Dart sources sit in **`lib/lib/`**, not `lib/`:

```
lib/
  main.dart              # app entry; imports from lib/
  lib/
    login_screen.dart
    register_screen.dart
    Home Screen.dart     # note the space in the filename
    CarCard.dart, CarDetailsScreen.dart, Checkout.dart, ...
    theme_provider.dart
```

`main.dart` imports siblings via `import 'lib/login_screen.dart';`. Screen files import each other with bare names (e.g. `import 'Home Screen.dart';`). When adding a new screen, place it in `lib/lib/` and follow the existing bare-import convention — do **not** "fix" the layout to standard Flutter (`lib/screens/...`) without also updating every import site.

Filenames are inconsistent: PascalCase (`CarDetailsScreen.dart`), snake_case (`login_screen.dart`), and one with a space (`Home Screen.dart`). Match the style of neighboring files when adding new ones.

### Navigation flow

`main.dart` → `LoginScreen` → `HomeScreen` (also reachable as guest from login). `HomeScreen` is a `StatefulWidget` that owns a 5-tab `IndexedStack`:

| Index | Screen | Notes |
|-------|--------|-------|
| 0 | Map view (built inline in `_buildMainMapStack`) | GoogleMap + category chips + ad carousel + `_buildQuickInfoCard` when a marker is tapped |
| 1 | `MyReservationsScreen` | receives `bookedCar`, `duration`, `type` |
| 2 | `DigitalKeyScreen` | when active, the AppBar and BottomNav are hidden (`isKeyPage` branch) |
| 3 | `WalletScreen` | |
| 4 | `SettingsScreen` | |

`HomeScreen` accepts `bookedCar`, `initialIndex`, `bookingDuration`, `bookingType` — these are how the post-payment flow returns the user to the home with reservation data attached. Booking flow: `HomeScreen` → `CarDetailsScreen` → `CheckoutScreen` → `PaymentScreen` → back to `HomeScreen` with the booking payload.

### Data model

The car catalog is **hardcoded in `HomeScreen._HomeScreenState.cars`** as `List<Map<String, dynamic>>` — there is no backend, repository layer, or model class. Each car map has keys: `id`, `model`, `plate`, `fuel`, `rates: {min, hour, day}`, `pos: LatLng`, `category`, `img` (remote URL), `color`. The same untyped `Map<String, dynamic>` shape is passed through `CarDetailsScreen` → `Checkout` → `PaymentScreen` → back to `HomeScreen`. When changing this shape, all four screens must be updated together.

### State management

`provider` is wired only for theming: `ThemeProvider` (`lib/lib/theme_provider.dart`) toggles `ThemeMode.light/dark` and is the single `ChangeNotifierProvider` at the root in `main.dart`. Everything else is local `setState`. There is no global app state — booking data is passed via constructor args between screens.

### Theming

Brand color is `Color(0xFF13366B)` (referenced as `joRideAccent` in most screens, `Color(0xFF1A3D7C)` in login/register — these are slightly different and were not unified). Scaffold background is `Color(0xFFF8F9FD)`. When adding screens, use `joRideAccent` as a `static const` at the top of the `State` class to match existing files.

### Google Maps

API key is **hardcoded** in `web/index.html` (`<script src="https://maps.googleapis.com/maps/api/js?key=...">`). Maps will not render without a key restricted to the deployment domain.

### Localization

Code comments are in Arabic; UI strings are English. Don't translate the comments — leave them as-is unless asked.
