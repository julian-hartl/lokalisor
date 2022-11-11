import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_lokalisor/src/notifications/error_notification.dart';
import 'package:flutter_lokalisor/src/translation_node_repository.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../notifications/success_notification.dart';
import 'translation_node.dart';

part 'translation_tree_cubit.freezed.dart';

part 'translation_tree_state.dart';

@lazySingleton
class TranslationTreeCubit extends Cubit<TranslationTreeState> {
  TranslationTreeCubit(
    this._nodeRepository,
  ) : super(
          const TranslationTreeState.loading(),
        );

  final TranslationNodeRepository _nodeRepository;
  StreamSubscription? _nodesSub;

  int? _latestApplicationId;

  Future<void> reload() async {
    if (_latestApplicationId != null) {
      return load(_latestApplicationId!);
    }
  }

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

  Future<void> removeNode(int nodeId) async {
    try {
      _checkState();
      final nodes = state.whenOrNull(
        loaded: (nodes) => nodes,
      )!;
      emit(const TranslationTreeState.loading());

      final hasDeleted = await _nodeRepository.deleteNode(nodeId);
      if (!hasDeleted) {
        _reportError(
          "Deleted row does not exist.",
          Exception("No rows affected"),
        );
        return;
      }

      showSuccessNotification(
        "Successfully removed translation entry.",
      );
    } catch (e, str) {
      _reportError("Could not remove node.", e, str);
    }
  }

  Future<void> load(int applicationId) async {
    try {
      emit(const TranslationTreeState.loading());
      _latestApplicationId = applicationId;
      await _nodesSub?.cancel();
      _nodesSub = _nodeRepository
          .watchNodes(
            applicationId: applicationId,
            parentId: (await _nodeRepository.getRootId(applicationId))!,
          )
          .listen(
            (event) => emit(
              TranslationTreeState.loaded(
                nodes: event,
              ),
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

  Future<List<TranslationNode>> getChildren(int parentId) async {
    try {
      _checkState();
      final children = await _nodeRepository.getNodes(
        parent: parentId,
      );
      return children;
    } catch (e, str) {
      _reportError("Could not get children translations.", e, str);
      return [];
    }
  }

  Future<TranslationNode?> getNode(int nodeId) async {
    try {
      return await _nodeRepository.getNode(nodeId);
    } catch (e, str) {
      _reportError("Could not get translation.", e, str);
      return null;
    }
  }

  Future<TranslationNode> getNodeOrThrow(int nodeId) async {
    return await _nodeRepository.getNodeOrThrow(nodeId);
  }

  Future<int?> getParentId(int nodeId) async {
    return (await getNode(nodeId))?.parent;
  }

  Future<bool> updateNode(TranslationNode node) async {
    try {
      _checkState();

      await _nodeRepository.updateNode(node);
      return true;
    } catch (e, str) {
      _reportError("Could not update translation.", e, str);
      return false;
    }
  }

  Future<TranslationNode?> addNode(
    int? parentId,
    String translationKey,
  ) async {
    try {
      _checkState();
      // Update db
      final newNode = (await _nodeRepository.addNode(
        parentId,
        translationKey,
        _latestApplicationId!,
      ))!;

      showSuccessNotification(
        "Successfully added new translation entry.",
      );
      return newNode;
    } catch (e, str) {
      _reportError("Could not add new translation entry.", e, str);
    }
    return null;
  }

  @override
  Future<void> close() async {
    await _nodesSub?.cancel();
    return super.close();
  }
}
