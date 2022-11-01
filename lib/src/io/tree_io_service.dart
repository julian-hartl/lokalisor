import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter_lokalisor/src/db/collections/translation.dart';
import 'package:flutter_lokalisor/src/translation_locale.dart';
import 'package:flutter_lokalisor/src/translation_tree/translation_node.dart';
import 'package:flutter_lokalisor/src/translation_tree/tree_utils.dart';
import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';
import 'package:universal_io/io.dart';

import '../translation_node_repository.dart';

@lazySingleton
class TreeIOService {
  final TranslationNodeRepository _nodeRepository;
  final Isar _isar;

  TreeIOService(
    this._nodeRepository,
    this._isar,
  );

  /// Returns the translation file.
  Future<File> _getTranslationsFile(String locale) async {
    final dir = Directory.current;
    final file = File('${dir.path}/$locale.json');
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    return file;
  }

  dynamic _nodeToJson(TranslationNode node, {required String locale}) {
    dynamic value;
    if (node.children.isNotEmpty) {
      value = {};
      for (final child in node.children) {
        final node = _nodeRepository.getNodeOrThrow(child);
        value[node.data.translationKey] = _nodeToJson(node, locale: locale);
      }
    } else {
      value = node.data.translationValues
              .firstWhereOrNull(
                (element) => element.locale == locale,
              )
              ?.value ??
          "";
    }

    return value;
  }

  Future<Map<String, dynamic>> getTreeAsJson(String locale) async {
    final nodes = await _nodeRepository.getAllNodes();
    final Map<String, dynamic> json = {};
    for (final node in nodes.where((element) => element.parent == null)) {
      json[node.data.translationKey] = _nodeToJson(
        node,
        locale: locale,
      );
    }
    return json;
  }

  Future<void> outputTreeAsJson({
    required TranslationLocale locale,
  }) async {
    final localeCode = locale.code;
    final file = await _getTranslationsFile(localeCode);
    final json = await getTreeAsJson(localeCode);
    await file.writeAsString(jsonEncode(json));
    print("Wrote output to ${file.path}");
  }

  Future<List<TranslationNodeCollection>> _parseJson(
    Map<String, dynamic> json,
    String? parent,
    TranslationLocale locale,
  ) async {
    final nodes = <TranslationNodeCollection>[];
    for (final key in json.keys) {
      final value = json[key];

      final node = TranslationNodeCollection(
        translationKey: key,
        parent: parent,
      );
      final absoluteKey = await getAbsoluteTranslationKey(node.toNode());
      final matchingNodes = await _isar.translationNodeCollections
          .filter()
          .translationKeyEqualTo(key)
          .parentEqualTo(parent)
          .findAll();
       TranslationNodeCollection? matchingNode;
      for (final node in matchingNodes) {
        if (await getAbsoluteTranslationKey(node.toNode()) == absoluteKey) {
          matchingNode = node;
          break;
        }
      }
      if (matchingNode != null) {
        node.id = matchingNode.id;
      }

      final List<EmbeddedTranslationValue> values = value is String
          ? [
              EmbeddedTranslationValue(
                locale: locale.code,
                value: value,
              ),
              ...(matchingNode?.values
                      .where((element) => element.locale != locale.code) ??
                  []),
            ]
          : [];

      node.values = values;

      final createdNodeId = await _isar.translationNodeCollections.put(node);
      node.id = createdNodeId;
      if (value is Map<String, dynamic>) {
        final children = await _parseJson(value, node.id.toString(), locale);
        if (children.toSet().length != children.length) {
          throw Exception("Duplicate translation keys found");
        }
        node.children = children.map((e) => e.id.toString()).toList();
        await _isar.translationNodeCollections.put(node);
      }
      nodes.add(node);
    }
    return nodes;
  }

  Future<String?> import(File file) async {
    try {
      final json = jsonDecode(await file.readAsString());
      final fileName = file.uri.pathSegments.last.split(".").first;
      final locale = supportedLocales
          .firstWhereOrNull((element) => element.code == fileName);

      if (locale == null) {
        return "Locale $fileName is not supported";
      }
      await _isar.writeTxn(() async {
        final nodes = await _parseJson(json, null, locale);
        final nodeIds = nodes.map((e) => e.id);
        if (nodeIds.toSet().length != nodeIds.length) {
          throw Exception("Duplicate translation keys found");
        }
        for (final node in nodes) {
          if (await _isar.translationNodeCollections
                  .filter()
                  .translationKeyEqualTo(node.translationKey)
                  .parentIsNull()
                  .count() >
              1) {
            throw Exception("Duplicate translation keys found");
          }
        }
      });
      return null;
    } on FormatException catch (e) {
      return e.message;
    } catch (e) {
      print("Error importing file: $e");
      return "Error importing file: $e.";
    }
  }
}
