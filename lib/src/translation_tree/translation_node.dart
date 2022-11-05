import 'package:flutter_lokalisor/src/translation_tree/translation_node_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'translation_node.freezed.dart';

@freezed
class TranslationNode with _$TranslationNode {
  const factory TranslationNode({
    required int applicationId,
    required String translationKey,

    /// The parent of this [TranslationNode].
    required int? parent,

    /// The path of this [TranslationNode].
    required int id,
  }) = _TranslationNode;
}
