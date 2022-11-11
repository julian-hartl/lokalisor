import 'dart:async';

import 'package:async_dart/async_dart.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_lokalisor/src/application/application_repository.dart';
import 'package:flutter_lokalisor/src/db/drift.dart';
import 'package:flutter_lokalisor/src/logger/logger.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import 'application.dart';

part 'application_cubit.freezed.dart';

part 'application_state.dart';

typedef ApplicationState = AsyncValue<ApplicationStateValue>;

@lazySingleton
class ApplicationCubit extends AsyncCubit<ApplicationStateValue>
    with LoggerProvider {
  ApplicationCubit(this._applicationRepository) {
    loadApplications();
  }

  final ApplicationRepository _applicationRepository;

  int? _currentApplicationId;
  StreamSubscription? _applicationSubscription;

  Future<void> deleteApplication(int id) async {
    await _applicationRepository.deleteApplication(id);
    _currentApplicationId = null;
  }

  TaskEither<String, Unit> updateApplication(Application application) {
    return TaskEither(() async {
      try {
        await _applicationRepository.updateApplication(application);
      } catch (e, str) {
        log("Could not update application", e, str);
        return left("Could not update application: $e");
      }
      return right(unit);
    });
  }

  Future<void> _watch() async {
    await _applicationSubscription?.cancel();
    _applicationSubscription =
        _applicationRepository.watchApplications().listen((applications) {
      _currentApplicationId ??= applications.firstOrNull?.id;
      emit(AsyncValue.loaded(ApplicationStateValue(
        applications: applications,
        currentApplicationId: _currentApplicationId,
      )));
    });
  }

  Future<void> loadApplications() async {
    await run(
      () async {
        await _watch();
        final applications = await _applicationRepository.getApplications();
        return ApplicationStateValue(
          applications: applications,
          currentApplicationId: applications.firstOrNull?.id,
        );
      },
      errorMessageFunction: (error, stackTrace) =>
          "Error while loading applications",
    );
  }

  void setCurrentApplicationId(int? id) {
    final value = state.valueOrNull;
    _currentApplicationId = id;
    if (value != null) {
      emit(
        AsyncValue.loaded(
          value.copyWith(
            currentApplicationId: id,
          ),
        ),
      );
    }
  }

  Future<String?> addApplication({
    required String name,
    required String? description,
    required String? logoPath,
    required String path,
  }) async {
    String? message;
    await run(
      () async {
        final application = await _applicationRepository.addApplication(
          ApplicationTableCompanion.insert(
            name: name,
            description: drift.Value(description),
            logoPath: drift.Value(logoPath),
            path: path,
          ),
        );
        _currentApplicationId = application.id;
      },
      errorMessageFunction: (error, stackTrace) {
        message = "Could not add application: $error";
        return message!;
      },
    );
    return message;
  }

  @override
  Future<void> close() async {
    await _applicationSubscription?.cancel();
    return super.close();
  }
}
