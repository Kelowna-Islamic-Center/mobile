# Kelowna Islamic Center Flutter Mobile App

The KIC Mobile App is a public facing Flutter-based application used by Kelowna Islamic Center community members to see prayer times on thier phones.

The full documentation for this repository can be found on the [**Official Documentation Website**](https://kelowna-islamic-center.github.io/documentation/kiosk-app/).

[![Read the Documentation](https://img.shields.io/badge/Read%20the%20Full%20Documentation-4CAF50?style=for-the-badge)](https://kelowna-islamic-center.github.io/documentation/mobile-app/)

## Features

- Fully Cross-platform (Android & iOS)
- Real-time synchronized masjid announcements
- Cloud messaging enabled announcement notifications
- Locally scheduled platform native Athan & Iqamah reminder notifications
- Fully internationalized with multi-language support (Current full Arabic and English support)
- Admin tools for creating and editing announcements
- Offline support for devices with limited connectivity

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable)  
- Firebase project configured with:  
  - Cloud Messaging
  - Firestore
  - Authentication (for admin tools)

## Getting Started

Clone the repository and install dependencies:

```bash
git https://github.com/Kelowna-Islamic-Center/mobile
cd mobile
flutter pub get
````

Run the app in debug mode:

```bash
flutter run
```

## Environment Setup

Add a `.env` file or configure `firebase_options.dart` with your Firebase project credentials using the FlutterFire CLI:

```bash
flutterfire configure
```

## Build & Distribution

For Android:

```bash
flutter build apk --release
```

For iOS:

```bash
flutter build ios --release
```

For more details, see [Building & Distribution Documentation](https://kelowna-islamic-center.github.io/documentation/mobile-app/development/building/).

## Project Source Structure

- `assets` - App assets
- `android` - Android build configuration files and platform native support
- `ios` - iOS build configuration files
- `fonts` - App wide fonts
- `lib/sections/` – UI controllers (business logic)
- `lib/structs/` – Models and structures
- `lib/services/` – Background Services
- `lib/l10n` - Localization files for per language translations
- `lib/locales/` - Locale provider for app wide locales
- `lib/theme/` – Theme providers for app wide theming

## License

GPL-v3
