import 'package:flutter/material.dart';

/// A representation of a locale.
class TranslationLocale {
  /// The flag for the language.
  final String flag;

  /// The locale code for the language.

  final String code;

  /// The name of the language.
  final String name;

  const TranslationLocale({
    required this.flag,
    required this.code,
    required this.name,
  });

  static const german = TranslationLocale(
    flag: "🇩🇪",
    code: "de",
    name: "German",
  );
  static const us = TranslationLocale(
    flag: "🇺🇸",
    code: "en-US",
    name: "English (US)",
  );
  static const uk = TranslationLocale(
    flag: "🇬🇧",
    code: "en-UK",
    name: "English (UK)",
  );

  static const en = TranslationLocale(
    flag: "🇬🇧",
    code: "en",
    name: "English",
  );
}

/// List of all supported locales and their flags.
const List<TranslationLocale> supportedLocales = [
  TranslationLocale.german,
  TranslationLocale.us,
  TranslationLocale.uk,
  TranslationLocale.en,
];

extension TranslationLocaleExtension on TranslationLocale {
  /// Returns the locale as a [Locale].
  Locale get asLocale => Locale(code);
}

extension TransitionLocaleListQueryExtension on List<TranslationLocale> {
  /// Returns the [TranslationLocale] with the given [locale].
  TranslationLocale getLocale(String locale) {
    return firstWhere((element) => element.code == locale);
  }
}
