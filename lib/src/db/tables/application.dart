import 'package:drift/drift.dart';

import '../../locale/supported_locales.dart';
import '../converters/supported_locales_converter.dart';

class ApplicationTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  TextColumn get description => text().nullable()();

  TextColumn get logoPath => text().nullable()();

  TextColumn get path => text()();

  TextColumn get supportedLocales => text()
      .map(const SupportedLocalesConverter())
      .clientDefault(() => availableLocales.map((e) => e.id).join(","))();

  @override
  List<Set<Column<Object>>>? get uniqueKeys => [
        {
          path,
        },
        {
          name,
        },
      ];
}
