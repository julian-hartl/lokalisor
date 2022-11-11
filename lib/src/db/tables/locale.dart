import 'package:drift/drift.dart';

class LocaleTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  TextColumn get code => text()();

  TextColumn get flag => text()();
}
