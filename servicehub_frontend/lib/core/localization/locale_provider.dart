import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'locale_storage.dart';

/// Riverpod notifier that owns the current locale and persists changes.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('fr')) {
    _load();
  }

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('fr'),
  ];

  static const Locale fallbackLocale = Locale('fr');

  Future<void> _load() async {
    final stored = await LocaleStorage.getLocale();
    if (stored != null && _isSupported(stored)) {
      state = Locale(stored);
      return;
    }

    final deviceLocale =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    if (_isSupported(deviceLocale)) {
      state = Locale(deviceLocale);
    } else {
      state = fallbackLocale;
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!_isSupported(locale.languageCode)) return;
    state = locale;
    await LocaleStorage.saveLocale(locale.languageCode);
  }

  Future<void> toggle() async {
    final next = state.languageCode == 'en' ? const Locale('fr') : const Locale('en');
    await setLocale(next);
  }

  bool _isSupported(String code) {
    return supportedLocales.any((l) => l.languageCode == code);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});