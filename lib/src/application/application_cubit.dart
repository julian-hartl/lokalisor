import 'package:async_dart/async_dart.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_lokalisor/src/application/application_repository.dart';
import 'package:flutter_lokalisor/src/db/drift.dart';
import 'package:flutter_lokalisor/src/logger/logger.dart';
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

  Future<void> loadApplications() async {
    await run(
      () async {
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
    final applications = state.valueOrNull?.applications;
    Application? application;
    String? message;
    await run(
      () async {
        return await _applicationRepository.addApplication(
          ApplicationTableCompanion.insert(
            name: name,
            description: drift.Value(description),
            logoPath: drift.Value(logoPath),
            path: path,
          ),
        );
      },
      after: (value) async {
        if (applications != null && application != null) {
          return ApplicationState.loaded(
            ApplicationStateValue(
              applications: applications,
              currentApplicationId: application.id,
            ),
          );
        } else {
          await loadApplications();
        }
        return null;
      },
      errorMessageFunction: (error, stackTrace) {
        message = "Could not add application: $error";
        return message!;
      },
    );
    return message;
  }
}
