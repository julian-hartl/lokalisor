import 'package:bloc/bloc.dart';
import 'package:flutter_lokalisor/src/translation_tree/translation_node.dart';
import 'package:flutter_lokalisor/src/translation_value/translation_value_repository.dart';
import 'package:injectable/injectable.dart';

import '../translation_tree/translation_node_data.dart';

part 'translation_value_state.dart';

@lazySingleton
class TranslationValueCubit extends Cubit<TranslationValueState> {
  TranslationValueCubit(
    this._translationValueRepository,
  ) : super(
          const TranslationValueState([]),
        );

  final TranslationValueRepository _translationValueRepository;

  /// Gets the translation value for the given [localeId].
  Future<String?> getTranslation(TranslationNode node,
      {required int localeId}) async {
    final translationValues =
        await _translationValueRepository.getTranslationValues(
      nodeId: node.id,
      localeId: localeId,
    );
    for (final value in translationValues) {
      if (value.localeId == localeId) {
        return value.value;
      }
    }
    return null;
  }

  /// Sets the translation for the given locale.
  Future<void> updateTranslation(
    TranslationNode node, {
    required String value,
    required int localeId,
  }) async {
    await _translationValueRepository.updateTranslation(
      translationNodeId: node.id,
      localeId: localeId,
      value: value,
    );
    final updated = await _translationValueRepository.getTranslationValues(
      nodeId: node.id,
    );
    emit(TranslationValueState(updated));
  }
}
