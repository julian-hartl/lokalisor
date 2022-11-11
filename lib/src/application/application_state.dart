part of 'application_cubit.dart';

@freezed
class ApplicationStateValue with _$ApplicationStateValue {
  const ApplicationStateValue._();
  const factory ApplicationStateValue({
    required List<Application> applications,
    required int? currentApplicationId,
  }) = _ApplicationStateValue;

  Application? get currentApplication => applications.firstWhereOrNull((element) => element.id == currentApplicationId);
}
