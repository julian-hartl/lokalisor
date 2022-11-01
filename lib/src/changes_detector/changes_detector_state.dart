part of 'changes_detector_cubit.dart';

@freezed
class ChangesDetectorState with _$ChangesDetectorState {
  const factory ChangesDetectorState({
    required bool hasChanges,
  }) = _ChangesDetectorState;
}
