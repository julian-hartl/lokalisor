part of 'translation_value_dialog_cubit.dart';

@freezed
class TranslationValueDialogState with _$TranslationValueDialogState {
  const factory TranslationValueDialogState.loading() = _loading;
  const factory TranslationValueDialogState.loaded({
   required String absoluteTranslationKey,
    required List<TranslationValue> translationValues,
}) = _Loaded;
}
