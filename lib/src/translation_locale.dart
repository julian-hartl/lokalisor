import 'package:flutter/material.dart';

/// A representation of a locale.
class TranslationLocale {
  /// The flag for the language.
  final String flag;

  /// The locale code for the language.

  final String code;

  /// The name of the language.
  final String name;

  final int id;

  const TranslationLocale({
    required this.flag,
    required this.id,
    required this.code,
    required this.name,
  });
}

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
