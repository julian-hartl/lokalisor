import 'package:flutter_lokalisor/src/locale/supported_locales.dart';
import 'package:flutter_lokalisor/src/translation_locale.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'application.freezed.dart';

@freezed
class Application with _$Application {
  const Application._();

  const factory Application({
    required String name,
    required String? logoPath,
    required String? description,
    required String path,
    required int id,
    required List<int> supportedLocales,
  }) = _Application;

  List<TranslationLocale> get locales => availableLocales
      .where((element) => supportedLocales.contains(element.id))
      .toList();
}
