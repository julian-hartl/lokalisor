import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';

import '../db/isar.dart';

@module
abstract class DIModules {
  @preResolve
  Future<Isar> get isar => connectDb();
}
