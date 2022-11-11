import 'package:drift/drift.dart';

import 'application.dart';

class TranslationNodeTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get parent => integer().nullable().references(
        TranslationNodeTable,
        #id,
        onDelete: KeyAction.cascade,
      )();

  TextColumn get translationKey => text().nullable()();

  IntColumn get applicationId => integer().references(
        ApplicationTable,
        #id,
        onDelete: KeyAction.cascade,
      )();

  @override
  List<Set<Column<Object>>>? get uniqueKeys => [
        {applicationId, translationKey, parent},
      ];
}
