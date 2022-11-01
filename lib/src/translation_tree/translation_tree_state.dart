part of 'translation_tree_cubit.dart';

@freezed
class TranslationTreeState with _$TranslationTreeState {
  const factory TranslationTreeState.loading() = _Loading;

  const factory TranslationTreeState.error({
    required String message,
  }) = _Error;

  const factory TranslationTreeState.loaded({
    required List<TranslationNode> nodes,
  }) = _loaded;
}
