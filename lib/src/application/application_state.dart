part of 'application_cubit.dart';

@freezed
class ApplicationState with _$ApplicationState {
  const factory ApplicationState.loading() = ApplicationLoading;

  const factory ApplicationState.loaded({
    required List<Application> applications,
    required int? currentApplicationId,
  }) = ApplicationLoaded;

  const factory ApplicationState.error(String message) = ApplicationError;
}
