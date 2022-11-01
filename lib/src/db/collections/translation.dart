import 'package:flutter_lokalisor/src/translation_tree/translation_node.dart';
import 'package:flutter_lokalisor/src/translation_tree/translation_node_data.dart';
import 'package:isar/isar.dart';

part 'translation.g.dart';

@collection
class TranslationNodeCollection {
  Id id;

  List<String> children = [];

  String? parent;

  String? translationKey;

  List<EmbeddedTranslationValue> values = [];

  TranslationNodeCollection({
    this.children = const [],
    this.id = Isar.autoIncrement,
    required this.parent,
    required this.translationKey,
    this.values = const [],
  });

  factory TranslationNodeCollection.fromNode(TranslationNode node) {
    return TranslationNodeCollection(
      children: node.children,
      translationKey: node.data.translationKey,
      parent: node.parent,
      id: int.parse(node.id),
      values: node.data.translationValues
          .map(
            (value) => EmbeddedTranslationValue(
              locale: value.locale,
              value: value.value,
            ),
          )
          .toList(),
    );
  }

  TranslationNode toNode() => TranslationNode(
        children: children,
        data: TranslationNodeData(
          translationKey: translationKey!,
          translationValues: values
              .map(
                (value) => TranslationValue(
                  locale: value.locale!,
                  value: value.value!,
                ),
              )
              .toList(),
        ),
        parent: parent,
        id: id.toString(),
      );
}

@embedded
class EmbeddedTranslationValue {
  EmbeddedTranslationValue({
    this.locale,
    this.value,
  });

  String? locale;

  String? value;
}
