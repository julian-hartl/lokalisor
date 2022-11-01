import 'package:bloc/bloc.dart';
import 'package:flutter_lokalisor/src/translation_node_repository.dart';
import 'package:injectable/injectable.dart';

import 'translation_tree/translation_node_data.dart';

part 'translation_value_state.dart';

@lazySingleton
class TranslationValueCubit extends Cubit<TranslationValueState> {
  TranslationValueCubit(
    this._nodeRepository,
  ) : super(
          const TranslationValueState([]),
        );

  final TranslationNodeRepository _nodeRepository;

  /// Gets the translation value for the given [locale].
  String? getTranslation(String nodeId, {required String locale}) {
    final node = _nodeRepository.getNode(nodeId);
    for (final value in node?.data.translationValues ?? <TranslationValue>[]) {
      if (value.locale == locale) {
        return value.value;
      }
    }
    return null;
  }

  /// Sets the translation for the given locale.
  Future<void> updateTranslation(
    String nodeId, {
    required String value,
    required String locale,
  }) async {
    final node = _nodeRepository.getNode(nodeId);
    if (node == null) {
      return;
    }
    final values = [...node.data.translationValues];
    final index = values.indexWhere((element) => element.locale == locale);
    if (index == -1) {
      values.add(
        TranslationValue(
          locale: locale,
          value: value,
        ),
      );
    } else {
      values[index] = TranslationValue(
        locale: locale,
        value: value,
      );
    }
    await _nodeRepository.updateNode(
      node.copyWith(
        data: node.data.copyWith(
          translationValues: values,
        ),
      ),
    );
    emit(TranslationValueState(values));
  }
}
