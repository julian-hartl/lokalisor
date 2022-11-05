import 'package:drift/drift.dart';

class ApplicationTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  TextColumn get description => text().nullable()();

  TextColumn get logoPath => text().nullable()();

  TextColumn get path => text()();
}
