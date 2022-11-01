import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';

import 'db/collections/translation.dart';
import 'translation_tree/translation_node.dart';

@lazySingleton
class TranslationNodeRepository {
  TranslationNodeRepository(this._isar);

  final Isar _isar;

  TranslationNode? getNode(String nodeId) {
    final result = _isar
        .collection<TranslationNodeCollection>()
        .getSync(int.parse(nodeId));

    return result?.toNode();
  }

  Future<List<TranslationNode>> getAllNodes() async {
    final result = await _isar
        .collection<TranslationNodeCollection>()
        .filter()
        .translationKeyIsNotEmpty()
        .findAll();
    return result
        .map(
          (value) => value.toNode(),
        )
        .toList();
  }

  TranslationNode getNodeOrThrow(String nodeId) {
    final node = getNode(nodeId);
    if (node == null) {
      throw StateError("Node $nodeId not found");
    }
    return node;
  }

  Future<TranslationNode> getNodeAsyncOrThrow(String nodeId) async {
    final node = (await _isar.collection<TranslationNodeCollection>().get(
              int.parse(
                nodeId,
              ),
            ))
        ?.toNode();
    if (node == null) {
      throw StateError("Node $nodeId not found");
    }
    return node;
  }

  String? getParentId(String nodeId) {
    return getNode(nodeId)?.parent;
  }

  Future<void> updateNode(TranslationNode node) async {
    await _isar.writeTxn(() async {
      await _isar.collection<TranslationNodeCollection>().put(
            TranslationNodeCollection.fromNode(node),
          );
    });
  }

  Future<TranslationNode?> addNode(
    String? parentId,
    String translationKey,
  ) async {
    // Update db
    final collection = _isar.collection<TranslationNodeCollection>();
    final parent = parentId != null
        ? await collection
            .filter()
            .idEqualTo(int.parse(parentId))
            .build()
            .findFirst()
        : null;
    final newCollection = TranslationNodeCollection(
      parent: parentId,
      translationKey: translationKey,
    );

    TranslationNode? result;

    await _isar.writeTxn(() async {
      await collection.put(newCollection);
      if (parent != null) {
        parent.children = [...parent.children, newCollection.id.toString()];
        await collection.put(parent);
      }
      result = newCollection.toNode();
    });
    return result;
  }

  Future<void> _deleteChildrenWithoutTransaction(String nodeId) async {
    final node = await getNodeAsyncOrThrow(nodeId);
    final collection = _isar.collection<TranslationNodeCollection>();
    for (final childId in node.children) {
      await _deleteChildrenWithoutTransaction(childId);
    }
    await collection.delete(int.parse(nodeId));
  }

  Future<void> deleteNode(String nodeId) async {
    final collection = _isar.collection<TranslationNodeCollection>();
    final node = getNode(nodeId);
    if (node == null) {
      return;
    }
    final parent = node.parent != null
        ? await collection
            .filter()
            .idEqualTo(int.parse(node.parent!))
            .build()
            .findFirst()
        : null;
    await _isar.writeTxn(() async {
      if (parent != null) {
        parent.children = parent.children
            .where((element) => element != nodeId)
            .toList(growable: false);
        await collection.put(parent);
      }
      await _deleteChildrenWithoutTransaction(nodeId);
      await collection.delete(
        int.parse(
          node.id,
        ),
      );
    });
  }
}
