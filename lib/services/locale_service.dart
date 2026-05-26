import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

/// Holds the user's chosen locale and persists it across launches.
///
/// `null` means "follow the device locale" — Flutter then resolves to the
/// closest match from [AppLocalizations.supportedLocales] (falling back to
/// English if nothing matches).
class LocaleService extends ChangeNotifier {
  static const _prefsKey = 'app_locale';

  static final LocaleService instance = LocaleService._();
  LocaleService._();

  Locale? _locale;
  Locale? get locale => _locale;

  /// Languages the user can pick from. The order here drives the picker UI.
  static const List<Locale> selectableLocales = [
    Locale('en'),
    Locale('ar'),
    Locale('fr'),
    Locale('es'),
    Locale('it'),
    Locale('ko'),
    Locale('ja'),
    Locale('zh'),
  ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == null || code.isEmpty) {
      _locale = null;
    } else {
      _locale = Locale(code);
    }
  }

  /// Pass `null` to revert to device default.
  Future<void> setLocale(Locale? locale) async {
    if (_locale?.languageCode == locale?.languageCode) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }
    notifyListeners();
  }

  /// Human-readable name for a locale, used in the picker.
  static String displayName(Locale? locale, AppLocalizations l) {
    if (locale == null) return l.accountLanguageSystem;
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      case 'fr':
        return 'Français';
      case 'es':
        return 'Español';
      case 'it':
        return 'Italiano';
      case 'ko':
        return '한국어';
      case 'ja':
        return '日本語';
      case 'zh':
        return '中文';
      default:
        return locale.languageCode;
    }
  }
}
