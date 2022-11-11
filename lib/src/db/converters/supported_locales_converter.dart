import 'package:drift/drift.dart';

class SupportedLocalesConverter extends TypeConverter<List<int>, String> {
  const SupportedLocalesConverter();

  @override
  List<int> fromSql(String fromDb) {
    return fromDb.split(',').map((e) => int.parse(e)).toList();
  }

  @override
  String toSql(List<int> value) {
    return value.join(',');
  }
}
