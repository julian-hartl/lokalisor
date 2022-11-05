import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_lokalisor/src/application/application_repository.dart';
import 'package:flutter_lokalisor/src/db/drift.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import 'application.dart';

part 'application_cubit.freezed.dart';

part 'application_state.dart';

@lazySingleton
class ApplicationCubit extends Cubit<ApplicationState> {
  ApplicationCubit(this._applicationRepository)
      : super(const ApplicationState.loading()) {
    loadApplications();
  }

  final ApplicationRepository _applicationRepository;

  Future<void> loadApplications() async {
    try {
      emit(const ApplicationState.loading());
      final applications = await _applicationRepository.getApplications();
      emit(
        ApplicationState.loaded(
          applications: applications,
          currentApplicationId: applications.firstOrNull?.id,
        ),
      );
    } catch (e) {
      print(e);
      emit(ApplicationState.error(e.toString()));
    }
  }

  void setCurrentApplicationId(int? id) {
    emit(
      state.when(
        loading: () => const ApplicationState.loading(),
        loaded: (applications, _) => ApplicationState.loaded(
          applications: applications,
          currentApplicationId: id,
        ),
        error: (message) => ApplicationState.error(message),
      ),
    );
  }

  Future<String?> addApplication({
    required String name,
    required String? description,
    required String? logoPath,
    required String path,
  }) async {
    final applications = state.whenOrNull(
      loaded: (applications, currentApplicationId) => applications,
    );
    Application? application;
    try {
      emit(const ApplicationState.loading());
      application = await _applicationRepository.addApplication(
        ApplicationTableCompanion.insert(
          name: name,
          description: drift.Value(description),
          logoPath: drift.Value(logoPath),
          path: path,
        ),
      );
    } catch (e) {
      return "Could not add application: $e";
    } finally {
      if (applications != null && application != null) {
        emit(
          ApplicationState.loaded(
            applications: [...applications, application],
            currentApplicationId: application.id,
          ),
        );
      } else {
        await loadApplications();
      }
    }
  }
}
