import 'package:flutter_lokalisor/src/di/get_it.dart';
import 'package:logger/logger.dart';

mixin LoggerProvider {
  Logger get logger => getIt<Logger>();

  void log(String message, [Object? error, StackTrace? stackTrace]) {
    logger.d(message, error, stackTrace);
  }
}
