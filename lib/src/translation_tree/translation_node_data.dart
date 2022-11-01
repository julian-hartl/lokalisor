import 'package:freezed_annotation/freezed_annotation.dart';

part 'translation_node_data.freezed.dart';

@freezed
class TranslationNodeData with _$TranslationNodeData {
  const factory TranslationNodeData({
    /// The locale key of the translation.
    required final String translationKey,

    /// Maps locales to their translations.
    required final List<TranslationValue> translationValues,
  }) = _TranslationNodeData;
}

@freezed
class TranslationValue with _$TranslationValue {
  const factory TranslationValue({
    required final String locale,
    required final String value,
  }) = _TranslationValue;

  const TranslationValue._();
}
