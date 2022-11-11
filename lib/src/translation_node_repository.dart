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
    return await getNodes(
      parent: parentId,
    );
  }

  Stream<List<TranslationNode>> watchNodes({
    int? applicationId,
    int? parentId,
  }) {
    final query = translationNodeTable.select();
    if (applicationId != null) {
      query.where((tbl) => tbl.applicationId.equals(applicationId));
    }
    if (parentId != null) {
      query.where((tbl) => tbl.parent.equals(parentId));
    }
    query.orderBy([
      (tbl) => OrderingTerm(
            expression: tbl.translationKey,
          ),
    ]);
    return query.watch().map((rows) {
      return rows.map((row) => row.toTranslationNode()).toList();
    });
  }

  Stream<List<TranslationNode>> watchChildren(int parentId) {
    return watchNodes(
      parentId: parentId,
    );
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
        (tbl) => tbl.parent.equalsNullable(parent),
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

  Future<int?> getRootId(int applicationId) async {
    final query = _db.select(translationNodeTable)
      ..where(
        (tbl) => tbl.applicationId.equals(applicationId),
      )
      ..where(
        (tbl) => tbl.parent.isNull(),
      );
    final result = await query.getSingleOrNull();
    return result?.id;
  }

  Future<TranslationNode?> addNode(
    int? parentId,
    String? translationKey,
    int applicationId,
  ) async {
    parentId ??= await getRootId(applicationId);
    // Update db
    final nodeToInsert = TranslationNodeTableCompanion.insert(
      applicationId: applicationId,
      translationKey: Value(translationKey),
      parent: Value(parentId),
    );
    final nodeUpdateQuery = translationNodeTable.insert();

    final node = await nodeUpdateQuery.insertReturning(
      nodeToInsert,
      onConflict: DoUpdate(
        (old) => nodeToInsert,
        target: [
          translationNodeTable.applicationId,
          translationNodeTable.translationKey,
          translationNodeTable.parent,
        ],
      ),
    );
    final translationNode = node.toTranslationNode();
    log("Added node $translationNode");
    return translationNode;
  }

  Future<bool> deleteNode(int nodeId) async {
    log("Deleting node $nodeId...");
    final hasDeleted = await translationNodeTable.deleteOne(
      TranslationNodeTableCompanion(
        id: Value(nodeId),
      ),
    );
    log("Successfully deleted node $nodeId");
    return hasDeleted;
  }
}
