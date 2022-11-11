import 'package:flutter_lokalisor/src/application/application.dart';
import 'package:flutter_lokalisor/src/db/drift.dart';
import 'package:flutter_lokalisor/src/translation_node_repository.dart';
import 'package:injectable/injectable.dart';

extension _ApplicationMapper on ApplicationTableData {
  Application toApplication() => Application(
        id: id,
        name: name,
        description: description,
        logoPath: logoPath,
        path: path,
        supportedLocales: supportedLocales,
      );
}

@lazySingleton
class ApplicationRepository {
  final DriftDb _db;
  final TranslationNodeRepository _translationNodeRepository;

  const ApplicationRepository(this._db, this._translationNodeRepository);

  $ApplicationTableTable get applicationTable => _db.applicationTable;

  /// Returns all applications.
  Future<List<Application>> getApplications() async {
    final apps = await _db.select(applicationTable).get();
    return apps
        .map(
          (app) => app.toApplication(),
        )
        .toList();
  }

  /// Returns the application with the given [id].
  Future<Application?> getApplication(int id) async {
    final query = _db.select(applicationTable)
      ..where((tbl) => tbl.id.equals(id));
    final app = await query.getSingleOrNull();
    if (app == null) {
      return null;
    }
    return app.toApplication();
  }

  /// Adds the given [application] to the database.
  Future<Application> addApplication(
      ApplicationTableCompanion application) async {
    final id = await _db.into(applicationTable).insert(application);
    await _translationNodeRepository.addNode(
      null,
      null,
      id,
    );
    return (await getApplication(id))!;
  }

  /// Updates the given [application] in the database.
  Future<void> updateApplication(Application application) async {
    final app = ApplicationTableData(
      id: application.id,
      name: application.name,
      path: application.path,
      description: application.description,
      logoPath: application.logoPath,
      supportedLocales: application.supportedLocales,
    );
    await _db.update(applicationTable).replace(app);
  }

  /// Deletes the application with the given [id].
  Future<void> deleteApplication(int id) async {
    final query = _db.delete(applicationTable)
      ..where((tbl) => tbl.id.equals(id));
    await query.go();
  }

  Stream<List<Application>> watchApplications() {
    return _db.select(applicationTable).watch().map(
          (apps) => apps
              .map(
                (app) => app.toApplication(),
              )
              .toList(),
        );
  }
}
