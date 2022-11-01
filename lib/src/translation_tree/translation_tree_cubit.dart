import 'package:bloc/bloc.dart';
import 'package:flutter_lokalisor/src/db/collections/translation.dart';
import 'package:flutter_lokalisor/src/notifications/error_notification.dart';
import 'package:flutter_lokalisor/src/translation_node_repository.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';

import '../notifications/success_notification.dart';
import 'translation_node.dart';

part 'translation_tree_cubit.freezed.dart';

part 'translation_tree_state.dart';

@lazySingleton
class TranslationTreeCubit extends Cubit<TranslationTreeState> {
  TranslationTreeCubit(
    this._isar,
    this._nodeRepository,
  ) : super(
          const TranslationTreeState.loading(),
        ) {
    load();
  }

  final Isar _isar;
  final TranslationNodeRepository _nodeRepository;

  void _reportError(String message, Object exception,
      [StackTrace? stackTrace]) {
    print(exception);
    print(stackTrace);
    showErrorNotification(message);
    emit(
      TranslationTreeState.error(
        message: message,
      ),
    );
  }

  Future<void> removeNode(String nodeId) async {
    try {
      _checkState();
      final nodes = state.whenOrNull(
        loaded: (nodes) => nodes,
      )!;
      emit(const TranslationTreeState.loading());

      final node = _nodeRepository.getNodeOrThrow(nodeId);
      await _nodeRepository.deleteNode(node.id);

      showSuccessNotification(
        "Successfully removed translation entry.",
      );
      emit(
        TranslationTreeState.loaded(
          nodes: [...nodes]..removeWhere(
              (element) => element.id == node.id,
            ),
        ),
      );
    } catch (e, str) {
      _reportError("Could not remove node.", e, str);
    }
  }

  Future<void> load() async {
    try {
      emit(const TranslationTreeState.loading());
      final result = await _isar
          .collection<TranslationNodeCollection>()
          .filter()
          .parentIsNull()
          .build()
          .findAll();
      emit(
        TranslationTreeState.loaded(
          nodes: result.map((value) => value.toNode()).toList(),
        ),
      );
    } catch (e, str) {
      _reportError("Could not load translations.", e, str);
    }
  }

  void _checkState() {
    state.maybeWhen(
      orElse: () {
        throw StateError('State is not loaded');
      },
      loaded: (_) {},
    );
  }

  List<TranslationNode> getChildren(String parentId) {
    try {
      _checkState();
      final result = _isar
          .collection<TranslationNodeCollection>()
          .filter()
          .parentEqualTo(parentId)
          .build()
          .findAllSync();
      return result.map((value) => value.toNode()).toList();
    } catch (e, str) {
      _reportError("Could not get children translations.", e, str);
      return [];
    }
  }

  TranslationNode? getNode(String nodeId) {
    try {
      return _nodeRepository.getNode(nodeId);
    } catch (e, str) {
      _reportError("Could not get translation.", e, str);
      return null;
    }
  }

  TranslationNode getNodeOrThrow(String nodeId) {
    return _nodeRepository.getNodeOrThrow(nodeId);
  }

  String? getParentId(String nodeId) {
    return getNode(nodeId)?.parent;
  }

  Future<bool> updateNode(TranslationNode node) async {
    try {
      _checkState();
      final List<String> children = node.parent != null
          ? _nodeRepository.getNodeOrThrow(node.parent!).children
          : state.whenOrNull(
              loaded: (nodes) => nodes.map((e) => e.id).toList(),
            )!;
      final keyOccurrences = children.where((element) =>
          getNodeOrThrow(element).data.translationKey ==
          node.data.translationKey);
      if (keyOccurrences.isNotEmpty) {
        showErrorNotification("Key already exists.");
        return false;
      }

      await _nodeRepository.updateNode(node);
      return true;
    } catch (e, str) {
      _reportError("Could not update translation.", e, str);
      return false;
    }
  }

  Future<TranslationNode?> addNode(
    String? parentId,
    String translationKey,
  ) async {
    try {
      _checkState();
      // Update db
      final newNode = (await _nodeRepository.addNode(
        parentId,
        translationKey,
      ))!;

      // Update locale state
      state.whenOrNull(
        loaded: (nodes) {
          if (parentId == null) {
            emit(
              TranslationTreeState.loaded(
                nodes: [...nodes, newNode],
              ),
            );
          } else {
            // dont do anything here because the children will automatically be fetched

          }
        },
      );
      showSuccessNotification(
        "Successfully added new translation entry.",
      );
      return newNode;
    } catch (e, str) {
      _reportError("Could not add new translation entry.", e, str);
    }
    return null;
  }
}
