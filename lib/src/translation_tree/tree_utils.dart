import 'package:flutter_lokalisor/src/di/get_it.dart';
import 'package:flutter_lokalisor/src/translation_tree/translation_tree_cubit.dart';

import '../translation_node_repository.dart';
import 'translation_node.dart';



/// Returns the absolute translation key for the given [node].
Future<String> getAbsoluteTranslationKey(TranslationNode node) async {
  final translationKey = node.translationKey;
  if (node.parent == null) return translationKey;
  return '${await getAbsoluteTranslationKey(await getIt<TranslationNodeRepository>().getNodeOrThrow(node.parent!))}.$translationKey';
}
