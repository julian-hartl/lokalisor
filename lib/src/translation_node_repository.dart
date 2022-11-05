import 'package:drift/drift.dart';
import 'package:flutter_lokalisor/src/db/drift.dart';
import 'package:flutter_lokalisor/src/logger/logger.dart';
import 'package:injectable/injectable.dart';

import 'translation_tree/translation_node.dart';

extension on TranslationNodeTableData {
  TranslationNode toTranslationNode() {
    return TranslationNode(
      id: id,
      applicationId: applicationId,
      parent: parent,
      translationKey: translationKey ?? "",
    );
  }
}

@lazySingleton
class TranslationNodeRepository with LoggerProvider {
  TranslationNodeRepository(this._db);

  final DriftDb _db;

  $TranslationNodeTableTable get translationNodeTable =>
      _db.translationNodeTable;

  $TranslationValueTableTable get translationValueTable =>
      _db.translationValueTable;

  $LocaleTableTable get localeTable => _db.localeTable;

  Future<TranslationNode?> getNode(int nodeId) async {
    final result = await getNodes(
      ids: [nodeId],
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<List<TranslationNode>> getChildren(int parentId) async {
    return await getNodes(parent: parentId);
  }

  Stream<List<TranslationNode>> watchChildren(int parentId) {
    final query = translationNodeTable.select()
      ..where((tbl) => tbl.parent.equals(parentId));
    return query.watch().map((nodes) => nodes
        .map(
          (node) => node.toTranslationNode(),
        )
        .toList());
  }

  Future<List<TranslationNode>> getNodes({
    String? translationKey,
    int? parent,
    List<int>? ids,
    int? applicationId,
  }) async {
    final nodeQuery = _db.select(translationNodeTable)
      ..where(
        (tbl) =>
            ids == null ? const CustomExpression("TRUE") : tbl.id.isIn(ids),
      );
    if (translationKey != null) {
      nodeQuery.where(
        (tbl) => tbl.translationKey.equals(translationKey),
      );
    }
    if (parent != null) {
      nodeQuery.where(
        (tbl) => tbl.parent.equals(parent),
      );
    }

    final nodeResult = await nodeQuery.get();
    return nodeResult
        .map(
          (node) => node.toTranslationNode(),
        )
        .toList();
  }

  Future<List<TranslationNode>> getAllNodes() async {
    return getNodes();
  }

  Future<TranslationNode> getNodeOrThrow(int nodeId) async {
    final node = await getNode(nodeId);
    if (node == null) {
      throw StateError("Node $nodeId not found");
    }
    return node;
  }

  Future<int?> getParentId(int nodeId) async {
    return (await getNode(nodeId))?.parent;
  }

  Future<TranslationNode> updateNode(TranslationNode node) async {
    final updatedNode = TranslationNodeTableData(
      id: node.id,
      applicationId: node.applicationId,
      parent: node.parent,
      translationKey: node.translationKey,
    );
    final nodeUpdateQuery = translationNodeTable.update();

    await nodeUpdateQuery.replace(updatedNode);
    return updatedNode.toTranslationNode();
  }

  Future<TranslationNode?> addNode(
    int? parentId,
    String? translationKey,
    int applicationId,
  ) async {
    // Update db
    final nodeToInsert = TranslationNodeTableCompanion.insert(
      applicationId: applicationId,
      translationKey: Value(translationKey),
      parent: Value(parentId),
    );
    final nodeUpdateQuery = translationNodeTable.insert();

    final node = await nodeUpdateQuery.insertReturning(nodeToInsert);
    final translationNode = node.toTranslationNode();
    log("Added node $translationNode");
    return translationNode;
  }

  Future<void> deleteNode(int nodeId) async {
    log("Deleting node $nodeId...");
    await _db.transaction(() async {
      final amount = await translationNodeTable
          .deleteWhere((tbl) => tbl.id.equals(nodeId));
      log("Successfully deleted $amount nodes");
    });
  }
}
