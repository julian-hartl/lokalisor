import 'package:flutter_lokalisor/src/db/collections/application.dart';
import 'package:isar/isar.dart';

import 'collections/translation.dart';

Future<Isar> connectDb() async {
  final isar = await Isar.open([
    TranslationNodeCollectionSchema,
    ApplicationCollectionSchema,
  ]);
  return isar;
}
