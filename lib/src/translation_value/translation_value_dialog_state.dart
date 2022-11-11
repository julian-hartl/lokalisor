part of 'translation_value_dialog_cubit.dart';

@freezed
class TranslationValueDialogModel with _$TranslationValueDialogModel {
  const factory TranslationValueDialogModel({
   required String absoluteTranslationKey,
    required List<TranslationValue> translationValues,
}) = _TranslationValueDialogModel;
}

