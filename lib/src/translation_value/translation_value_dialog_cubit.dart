import 'package:bloc/bloc.dart';
import 'package:flutter_lokalisor/src/di/get_it.dart';
import 'package:flutter_lokalisor/src/translation_tree/translation_node.dart';
import 'package:flutter_lokalisor/src/translation_tree/tree_utils.dart';
import 'package:flutter_lokalisor/src/translation_value/translation_value_repository.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../translation_tree/translation_node_data.dart';

part 'translation_value_dialog_cubit.freezed.dart';

part 'translation_value_dialog_state.dart';

class TranslationValueDialogCubit extends Cubit<TranslationValueDialogState> {
  TranslationValueDialogCubit(this._node)
      : super(const TranslationValueDialogState.loading()) {
    load();
  }

  final TranslationNode _node;
  final TranslationValueRepository _translationValueRepository =
      getIt<TranslationValueRepository>();

  Future<void> load() async {
    emit(const TranslationValueDialogState.loading());
    final absoluteTranslationKey = await getAbsoluteTranslationKey(_node);
    final translationValues =
        await _translationValueRepository.getTranslationValues(
      nodeId: _node.id,
    );
    print(translationValues);
    emit(TranslationValueDialogState.loaded(
      absoluteTranslationKey: absoluteTranslationKey,
      translationValues: translationValues,
    ));
  }
}
