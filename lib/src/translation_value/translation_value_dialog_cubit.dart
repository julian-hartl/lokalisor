import 'package:async_dart/async_dart.dart';
import 'package:flutter_lokalisor/src/di/get_it.dart';
import 'package:flutter_lokalisor/src/translation_tree/translation_node.dart';
import 'package:flutter_lokalisor/src/translation_tree/tree_utils.dart';
import 'package:flutter_lokalisor/src/translation_value/translation_value_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../translation_tree/translation_node_data.dart';

part 'translation_value_dialog_cubit.freezed.dart';

part 'translation_value_dialog_state.dart';

typedef TranslationValueDialogState = AsyncValue<TranslationValueDialogModel>;

class TranslationValueDialogCubit
    extends AsyncCubit<TranslationValueDialogModel> {
  TranslationValueDialogCubit(this._node) : super(const AsyncValue.loading()) {
    load();
  }

  final TranslationNode _node;
  final TranslationValueRepository _translationValueRepository =
  getIt<TranslationValueRepository>();

  final Map<int, String> _localesToUpdate = {};

  void markLocaleAsChanged(int localeId, String value) {
    _localesToUpdate[localeId] = value;
  }

  void unmarkLocaleAsChanged(int localeId) {
    _localesToUpdate.remove(localeId);
  }

  TaskEither<String, int> save() {
    return TaskEither(() async {
      late Either<String, int> result;
      await run(
            () async {
          try {
            if (_localesToUpdate.isEmpty) {
              result = right(0);
              return;
            }
            for (final entry in _localesToUpdate.entries) {
              await _translationValueRepository.updateTranslation(
                translationNodeId: _node.id,
                localeId: entry.key,
                value: entry.value,
              );
            }
            result = right(_localesToUpdate.length);
          } catch (e) {
            result = left("Could not update translation values: $e");
            rethrow;
          }
        },
        errorMessageFunction: (error, stackTrace) =>
        "Error occurred while updating translations: $error.",
      );
      return result;
    });
  }

  Future<void> load() async {
    await run(() async {
      final absoluteTranslationKey = await getAbsoluteTranslationKey(_node);
      final translationValues =
      await _translationValueRepository.getTranslationValues(
        nodeId: _node.id,
      );
      return TranslationValueDialogModel(
        translationValues: translationValues,
        absoluteTranslationKey: absoluteTranslationKey,
      );
    });
  }
}
