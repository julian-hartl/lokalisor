import 'package:drift/drift.dart';
import 'package:flutter_lokalisor/src/db/drift.dart';
import 'package:flutter_lokalisor/src/di/get_it.dart';
import 'package:flutter_lokalisor/src/locale/supported_locales.dart';
import 'package:flutter_lokalisor/src/translation_locale.dart';
import 'package:injectable/injectable.dart';

extension on LocaleTableData {
  TranslationLocale toTranslationLocale() => TranslationLocale(
        id: id,
        name: name,
        code: code,
        flag: flag,
      );
}

@lazySingleton
class LocaleRepository {
  final DriftDb _db;

  $LocaleTableTable get localeTable => _db.localeTable;

  const LocaleRepository(this._db);

  Future<List<TranslationLocale>> getLocales() async {
    final locales = await _db.select(localeTable).get();
    return locales
        .map(
          (locale) => locale.toTranslationLocale(),
        )
        .toList();
  }

  Future<TranslationLocale?> getLocale(int id) async {
    final query = _db.select(localeTable)..where((tbl) => tbl.id.equals(id));
    final locale = await query.getSingleOrNull();
    if (locale == null) {
      return null;
    }
    return locale.toTranslationLocale();
  }

  Future<void> populateSupportedLocales() async {
    final statement = localeTable.insert();
    await _db.transaction(() async {
      for (final locale in availableLocales) {
        await statement.insertOnConflictUpdate(
          LocaleTableCompanion.insert(
            id: Value(locale.id),
            name: locale.name,
            code: locale.code,
            flag: locale.flag,
          ),
        );
      }
    });
  }
}

Future<void> populateSupportedLocales() async {
  await getIt<LocaleRepository>().populateSupportedLocales();
}
