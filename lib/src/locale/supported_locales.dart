import 'package:flutter_lokalisor/src/translation_locale.dart';

const _german = TranslationLocale(
  flag: "π©πͺ",
  code: "de",
  name: "German",
  id: 1,
);
const _us = TranslationLocale(
  flag: "πΊπΈ",
  code: "en-US",
  name: "English (US)",
  id: 2,
);
const _uk = TranslationLocale(
  flag: "π¬π§",
  code: "en-UK",
  name: "English (UK)",
  id: 3,
);

const _en = TranslationLocale(
  flag: "π¬π§",
  code: "en",
  name: "English",
  id: 4,
);
const _french = TranslationLocale(
  flag: "π«π·",
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
