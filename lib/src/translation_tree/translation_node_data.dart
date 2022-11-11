import 'package:freezed_annotation/freezed_annotation.dart';

part 'translation_node_data.freezed.dart';

@freezed
class TranslationValue with _$TranslationValue {
  const factory TranslationValue({
    required final int localeId,
    required final String value,
    required final int translationNodeId,
  }) = _TranslationValue;

  const TranslationValue._();
}
