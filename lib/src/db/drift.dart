import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_lokalisor/src/db/tables/locale.dart';
import 'package:flutter_lokalisor/src/locale/locale_repository.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

import 'tables/application.dart';
import 'tables/translation_node.dart';
import 'tables/translation_value.dart';

part 'drift.g.dart';

@DriftDatabase(tables: [
  ApplicationTable,
  TranslationNodeTable,
  TranslationValueTable,
  LocaleTable,
])
class DriftDb extends _$DriftDb {
  @override
  int get schemaVersion => 1;

  DriftDb.connect(DatabaseConnection connection) : super.connect(connection);

  DriftDb() : super(_openConnection());

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll(); // create all tables
        },
        beforeOpen: (m) async {
          await executor.runCustom("PRAGMA foreign_keys = ON");
          await populateSupportedLocales();
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final docDir = await getApplicationDocumentsDirectory();
    final dbFolder = docDir.path;
    final file = File(p.join(dbFolder, 'db.sqlite'));
    return NativeDatabase(
      file,
      logStatements: kDebugMode,
    );
  });
}

Future<DriftIsolate> _createDriftIsolate() async {
  // this method is called from the main isolate. Since we can't use
  // getApplicationDocumentsDirectory on a background isolate, we calculate
  // the database path in the foreground isolate and then inform the
  // background isolate about the path.
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'db.sqlite'));
  final receivePort = ReceivePort();

  await Isolate.spawn(
    _startBackground,
    _IsolateStartRequest(
      receivePort.sendPort,
      file.path,
    ),
  );

  // _startBackground will send the DriftIsolate to this ReceivePort
  return await receivePort.first as DriftIsolate;
}

void _startBackground(_IsolateStartRequest request) {
  // this is the entry point from the background isolate! Let's create
  // the database from the path we received
  final executor = NativeDatabase(File(request.targetPath));
  // we're using DriftIsolate.inCurrent here as this method already runs on a
  // background isolate. If we used DriftIsolate.spawn, a third isolate would be
  // started which is not what we want!
  final driftIsolate = DriftIsolate.inCurrent(
    () => DatabaseConnection(executor),
  );
  // inform the starting isolate about this, so that it can call .connect()
  request.sendDriftIsolate.send(driftIsolate);
}

// used to bundle the SendPort and the target path, since isolate entry point
// functions can only take one parameter.
class _IsolateStartRequest {
  final SendPort sendDriftIsolate;
  final String targetPath;

  _IsolateStartRequest(this.sendDriftIsolate, this.targetPath);
}

DatabaseConnection openDbConnection() {
  return DatabaseConnection.delayed(Future.sync(() async {
    final isolate = await _createDriftIsolate();
    return await isolate.connect();
  }));
}
