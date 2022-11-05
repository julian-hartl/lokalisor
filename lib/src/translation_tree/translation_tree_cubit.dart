import 'package:bloc/bloc.dart';
import 'package:flutter_lokalisor/src/application/application_repository.dart';
import 'package:flutter_lokalisor/src/core/async_value.dart';
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
    this._applicationRepository,
  ) : super(
          const TranslationTreeState.loading(),
        );

  final TranslationNodeRepository _nodeRepository;
  final ApplicationRepository _applicationRepository;

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

      await _nodeRepository.deleteNode(nodeId);

      showSuccessNotification(
        "Successfully removed translation entry.",
      );
      emit(
        TranslationTreeState.loaded(
          nodes: [...nodes]..removeWhere(
              (element) => element.id == nodeId,
            ),
        ),
      );
    } catch (e, str) {
      _reportError("Could not remove node.", e, str);
    }
  }

  Future<void> load(int applicationId) async {
    try {
      emit(const TranslationTreeState.loading());
      final result =
          await _nodeRepository.getNodes(applicationId: applicationId);
      _latestApplicationId = applicationId;
      emit(
        TranslationTreeState.loaded(
          nodes: result,
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
      final children = await _nodeRepository.getNodes(parent: parentId);
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
