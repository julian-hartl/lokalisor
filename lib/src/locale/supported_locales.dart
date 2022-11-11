import 'package:flutter_lokalisor/src/translation_locale.dart';

const _german = TranslationLocale(
  flag: "🇩🇪",
  code: "de",
  name: "German",
  id: 1,
);
const _us = TranslationLocale(
  flag: "🇺🇸",
  code: "en-US",
  name: "English (US)",
  id: 2,
);
const _uk = TranslationLocale(
  flag: "🇬🇧",
  code: "en-UK",
  name: "English (UK)",
  id: 3,
);

const _en = TranslationLocale(
  flag: "🇬🇧",
  code: "en",
  name: "English",
  id: 4,
);
const _french = TranslationLocale(
  flag: "🇫🇷",
  code: "fr",
  name: "French",
  id: 5,
);

/// List of all supported locales and their flags.
const List<TranslationLocale> availableLocales = [
  _german,
  _us,
  _uk,
  _en,
  _french,
];
