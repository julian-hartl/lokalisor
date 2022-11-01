import 'package:flutter_lokalisor/src/application/application.dart';
import 'package:isar/isar.dart';

part 'application.g.dart';

@collection
class ApplicationCollection {
  Id id;

  String name;
  String? description;
  String? logoPath;
  String? version;
  String path;

  ApplicationCollection({
    this.id = Isar.autoIncrement,
    required this.name,
    required this.description,
    required this.logoPath,
    required this.version,
    required this.path,
  });

  factory ApplicationCollection.fromApplication(Application app) {
    return ApplicationCollection(
      name: app.name,
      description: app.description,
      logoPath: app.logoPath,
      version: app.version,
      path: app.path,
      id: app.id,
    );
  }

  Application toApplication() => Application(
        name: name,
        description: description,
        logoPath: logoPath,
        version: version,
        path: path,
        id: id,
      );
}
