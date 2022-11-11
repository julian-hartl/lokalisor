import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter_lokalisor/src/logger/logger.dart';
import 'package:flutter_lokalisor/src/translation_locale.dart';
import 'package:flutter_lokalisor/src/translation_tree/translation_node.dart';
import 'package:flutter_lokalisor/src/translation_value/translation_value_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:universal_io/io.dart';

import '../db/drift.dart';
import '../locale/locale_repository.dart';
import '../locale/supported_locales.dart';
import '../translation_node_repository.dart';

@lazySingleton
class TreeIOService with LoggerProvider {
  final TranslationNodeRepository _nodeRepository;
  final TranslationValueRepository _valueRepository;
  final LocaleRepository _localeRepository;
  final DriftDb _db;

  TreeIOService(
    this._nodeRepository,
    this._localeRepository,
    this._valueRepository,
    this._db,
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

  Future<dynamic> _nodeToJson(TranslationNode node,
      {required int localeId}) async {
    dynamic value;
    final List<TranslationNode> children =
        await _nodeRepository.getChildren(node.id);
    if (children.isNotEmpty) {
      value = {};
      for (final child in children) {
        final node = await _nodeRepository.getNodeOrThrow(child.id);
        value[node.translationKey] =
            await _nodeToJson(node, localeId: localeId);
      }
    } else {
      final translationValues = await _valueRepository.getTranslationValues(
        nodeId: node.id,
        localeId: localeId,
      );
      value = translationValues.firstOrNull?.value ?? "";
    }

    return value;
  }

  /// Returns all translations for the given [locale] and [applicationId] in a json format.
  Future<Map<String, dynamic>> getTreeAsJson({
    required int applicationId,
    required int localeId,
  }) async {
    final nodes = await _nodeRepository.getNodes(
      applicationId: applicationId,
      parent: (await _nodeRepository.getRootId(applicationId))!,
    );
    final Map<String, dynamic> json = {};
    for (final node in nodes) {
      json[node.translationKey] = await _nodeToJson(
        node,
        localeId: localeId,
      );
    }
    return json;
  }

  /// Outputs the current translation json tree to a local file.
  Future<void> outputTreeAsJson({
    required TranslationLocale locale,
    required int applicationId,
  }) async {
    final localeCode = locale.code;
    final file = await _getTranslationsFile(localeCode);
    final json = await getTreeAsJson(
      localeId: locale.id,
      applicationId: applicationId,
    );
    await file.writeAsString(jsonEncode(json));
    print("Wrote output to ${file.path}");
  }

  Future<void> _parseJson(
    Map<String, dynamic> json,
    int? parent,
    TranslationLocale locale,
    int applicationId,
  ) async {
    log("Parsing json $json...");
    for (final key in json.keys) {
      final value = json[key];

      final node = (await _nodeRepository.addNode(
        parent,
        key,
        applicationId,
      ))!;

      if (value is String) {
        await _valueRepository.updateTranslation(
          localeId: locale.id,
          value: value,
          translationNodeId: node.id,
        );
      }
      if (value is Map<String, dynamic>) {
        await _parseJson(value, node.id, locale, applicationId);
      }
    }
  }

  /// Parses the given [file] as json and inserts it into the database.
  /// Returns a [String] containing the message in case of an error.
  Future<String?> import(File file, {required int applicationId}) async {
    try {
      log("Importing file ${file.path}");
      final json = jsonDecode(await file.readAsString());
      final fileName = file.uri.pathSegments.last.split(".").first;
      final locale = supportedLocales
          .firstWhereOrNull((element) => element.code == fileName);

      if (locale == null) {
        return "Locale $fileName is not supported";
      }
      await _db.transaction(() async {
        await _parseJson(json, null, locale, applicationId);
      });

      return null;
    } on FormatException catch (e) {
      return e.message;
    } catch (e, str) {
      log("Error importing file ${file.path}", e, str);
      return "Error importing file: $e.";
    }
  }
}
