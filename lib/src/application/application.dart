import 'package:freezed_annotation/freezed_annotation.dart';

part 'application.freezed.dart';

@freezed
class Application with _$Application {
  const factory Application({
    required String name,
    required String? logoPath,
    required String? description,
    required String? version,
    required String path,
    required int id,
  }) = _Application;
}
