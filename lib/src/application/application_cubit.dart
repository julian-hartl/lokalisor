import 'package:bloc/bloc.dart';
import 'package:flutter_lokalisor/src/application/application_repository.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import 'application.dart';

part 'application_cubit.freezed.dart';

part 'application_state.dart';

@lazySingleton
class ApplicationCubit extends Cubit<ApplicationState> {
  ApplicationCubit(this._applicationRepository)
      : super(const ApplicationState.loading());

  final ApplicationRepository _applicationRepository;

  Future<void> loadApplications() async {
    try {
      emit(const ApplicationState.loading());
      final applications = await _applicationRepository.getApplications();
      emit(ApplicationState.loaded(applications));
    } catch (e) {
      emit(ApplicationState.error(e.toString()));
    }
  }
}
