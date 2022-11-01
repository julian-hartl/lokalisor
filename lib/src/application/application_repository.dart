import 'package:flutter_lokalisor/src/application/application.dart';
import 'package:flutter_lokalisor/src/db/collections/application.dart';
import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';

@lazySingleton
class ApplicationRepository {
  final Isar _isar;

  const ApplicationRepository(this._isar);

  /// Returns all applications.
  Future<List<Application>> getApplications() async {
    final apps = await _isar.applicationCollections.where().findAll();
    return apps
        .map(
          (app) => app.toApplication(),
        )
        .toList();
  }
}
