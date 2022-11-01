import 'package:flutter_lokalisor/src/di/get_it.dart';
import 'package:flutter_lokalisor/src/translation_tree/translation_tree_cubit.dart';

import '../translation_node_repository.dart';
import 'translation_node.dart';

/// Returns the absolute translation key for the given [node].
String getAbsoluteTranslationKeySync(TranslationNode node) {
  final translationKey = node.data.translationKey;
  if (node.parent == null) return translationKey;
  return '${getAbsoluteTranslationKeySync(getIt<TranslationTreeCubit>().getNode(node.parent!)!)}.$translationKey';
}

/// Returns the absolute translation key for the given [node].
Future<String> getAbsoluteTranslationKey(TranslationNode node) async {
  final translationKey = node.data.translationKey;
  if (node.parent == null) return translationKey;
  return '${await getAbsoluteTranslationKey(await getIt<TranslationNodeRepository>().getNodeAsyncOrThrow(node.parent!))}.$translationKey';
}
