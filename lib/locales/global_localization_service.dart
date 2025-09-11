import "package:flutter/material.dart";
import "package:kelowna_islamic_center/l10n/app_localizations.dart";
import "package:kelowna_islamic_center/locales/locale_provider.dart";

// A context-free localization service that provides localized strings without requiring BuildContext. 
// Used in background tasks and services (UI-less elements).

class GlobalLocalizationService {

  static final GlobalLocalizationService _instance = GlobalLocalizationService._internal();

  factory GlobalLocalizationService() => _instance;

  GlobalLocalizationService._internal();

  Locale? _currentLocale;
  AppLocalizations? _localizations;

  // Initialize with a locale provider
  void initialize(LocaleProvider localeProvider) {
    _currentLocale = localeProvider.locale;

    localeProvider.addListener(() {
      _currentLocale = localeProvider.locale;
      _localizations = null;
    });
  }

  // Get localized strings without a BuildContext
  Future<AppLocalizations> get strings async {
    // fallback to system locale
    _currentLocale ??= WidgetsBinding.instance.platformDispatcher.locale;

    _localizations ??= await AppLocalizations.delegate.load(_currentLocale!);
    return _localizations!;
  }
}
