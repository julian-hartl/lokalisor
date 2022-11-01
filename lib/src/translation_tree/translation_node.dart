import 'package:flutter_lokalisor/src/translation_tree/translation_node_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'translation_node.freezed.dart';

@freezed
class TranslationNode with _$TranslationNode {
  const factory TranslationNode({
    /// The children of this [TranslationNode].

    required List<String> children,

    /// The data of this [TranslationNode].

    required TranslationNodeData data,

    /// The parent of this [TranslationNode].
    required String? parent,

    /// The path of this [TranslationNode].
    required String id,
  }) = _TranslationNode;
}
