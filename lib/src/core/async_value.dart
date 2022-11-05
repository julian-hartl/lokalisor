import 'package:freezed_annotation/freezed_annotation.dart';

part 'async_value.freezed.dart';

@freezed
class AsyncValue<T> with _$AsyncValue<T> {
  const factory AsyncValue.loading() = _Loading<T>;

  const factory AsyncValue.error({
    required String message,
  }) = _Error<T>;

  const factory AsyncValue.loaded(
    T value,
  ) = _Loaded<T>;
}
