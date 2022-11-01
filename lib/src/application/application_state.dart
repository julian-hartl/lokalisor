part of 'application_cubit.dart';

@freezed
class ApplicationState with _$ApplicationState {
  const factory ApplicationState.loading() = ApplicationLoading;

  const factory ApplicationState.loaded(List<Application> applications) =
      ApplicationLoaded;

  const factory ApplicationState.error(String message) = ApplicationError;
}
