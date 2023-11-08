import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MyAppLocalizationsService {
  final Locale locale;

  MyAppLocalizationsService(this.locale);

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {},
    'pt': {},
    'es': {},
  };

  String getTranslatedValue(String key) {
    return _localizedValues.containsKey(locale.languageCode) &&
            _localizedValues[locale.languageCode]!.containsKey(key)
        ? _localizedValues[locale.languageCode]![key]!
        : key;
  }

  static const LocalizationsDelegate<MyAppLocalizationsService> delegate =
      _MyAppLocalizationsServiceDelegate();
}

class _MyAppLocalizationsServiceDelegate
    extends LocalizationsDelegate<MyAppLocalizationsService> {
  const _MyAppLocalizationsServiceDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'pt', 'es'].contains(locale.languageCode);
  }

  @override
  Future<MyAppLocalizationsService> load(Locale locale) {
    return SynchronousFuture<MyAppLocalizationsService>(
        MyAppLocalizationsService(locale));
  }

  @override
  bool shouldReload(_MyAppLocalizationsServiceDelegate old) {
    return false;
  }
}
