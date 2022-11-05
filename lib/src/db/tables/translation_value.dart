import 'package:drift/drift.dart';
import 'package:flutter_lokalisor/src/db/tables/locale.dart';

class TranslationValueTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get localeId => integer().references(
        LocaleTable,
        #id,
        onDelete: KeyAction.cascade,
      )();

  IntColumn get translationNodeId => integer().references(
        TranslationValueTable,
        #id,
        onDelete: KeyAction.cascade,
      )();

  TextColumn get value => text()();

  @override
  List<Set<Column<Object>>>? get uniqueKeys => [
        {localeId, translationNodeId},
      ];
}
