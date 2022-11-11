import 'package:flutter_lokalisor/src/db/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@module
abstract class DIModules {
  @lazySingleton
  final DriftDb db = DriftDb();

  @lazySingleton
  Logger get logger => Logger();
}
