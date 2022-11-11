part of 'application_cubit.dart';

@freezed
class ApplicationStateValue with _$ApplicationStateValue {
  const factory ApplicationStateValue({
    required List<Application> applications,
    required int? currentApplicationId,
  }) = _ApplicationStateValue;
}
