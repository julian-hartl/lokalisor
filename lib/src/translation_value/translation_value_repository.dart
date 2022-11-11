import 'package:drift/drift.dart';
import 'package:flutter_lokalisor/src/db/drift.dart';
import 'package:flutter_lokalisor/src/logger/logger.dart';
import 'package:flutter_lokalisor/src/translation_tree/translation_node_data.dart';
import 'package:injectable/injectable.dart';

extension on TranslationValueTableData {
  TranslationValue toTranslationValue() {
    return TranslationValue(
      value: value,
      localeId: localeId,
      translationNodeId: translationNodeId,
    );
  }
}

@lazySingleton
class TranslationValueRepository with LoggerProvider {
  const TranslationValueRepository(this._db);

  final DriftDb _db;

  $TranslationValueTableTable get translationValueTable =>
      _db.translationValueTable;

  $LocaleTableTable get localeTable => _db.localeTable;

  Future<Map<int, List<TranslationValue>>> getTranslationValuesForNodes(
      List<int> nodeIds,
      {int? localeId}) async {
    final translationValueQuery = _db.select(translationValueTable)
      ..where(
        (tbl) => tbl.translationNodeId.isIn(nodeIds),
      );
    if (localeId != null) {
      translationValueQuery.where((tbl) => tbl.localeId.equals(localeId));
    }
    final values = await translationValueQuery.get();
    final result = <int, List<TranslationValue>>{};
    for (final value in values) {
      result
          .putIfAbsent(value.translationNodeId, () => [])
          .add(value.toTranslationValue());
    }
    return result;
  }

  Future<List<TranslationValue>> getTranslationValues({
    required int nodeId,
    int? localeId,
  }) async {
    final result = await getTranslationValuesForNodes(
      [nodeId],
      localeId: localeId,
    );
    return result[nodeId] ?? [];
  }

  Future<TranslationValue> updateTranslation({
    required int translationNodeId,
    required int localeId,
    required String value,
  }) async {
    final query = translationValueTable.insert();
    final insertable = TranslationValueTableCompanion.insert(
      localeId: localeId,
      translationNodeId: translationNodeId,
      value: value,
    );
    final returning = await query.insertReturning(
      insertable,
      onConflict: DoUpdate(
        (_) => TranslationValueTableCompanion(
          value: Value(value),
        ),
      ),
    );
    final translation = returning.toTranslationValue();
    log("Updated translation $translation");
    return translation;
  }
}
