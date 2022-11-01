import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'changes_detector_cubit.freezed.dart';

part 'changes_detector_state.dart';

typedef OnSave = FutureOr<void> Function();

@lazySingleton
class ChangesDetectorCubit extends Cubit<ChangesDetectorState> {
  ChangesDetectorCubit()
      : super(
          const ChangesDetectorState(
            hasChanges: false,
          ),
        );

  final Map<String, OnSave> _onSaveCallbacks = {};

  Future<void> save() async {
    final callbacks = [..._onSaveCallbacks.entries];
    for (final entry in callbacks) {
      try {
        await entry.value();
        _onSaveCallbacks.remove(entry.key);
      } catch (e, str) {
        print(e);
        print(str);
        return;
      }
    }
    emit(
      state.copyWith(
        hasChanges: false,
      ),
    );
  }

  void removeChanges(String id) {
    _onSaveCallbacks.remove(id);
    if (_onSaveCallbacks.isEmpty) {
      emit(
        state.copyWith(
          hasChanges: false,
        ),
      );
    }
  }

  void reportChange(String id, OnSave onSave) {
    _onSaveCallbacks[id] = onSave;
    emit(
      state.copyWith(
        hasChanges: true,
      ),
    );
  }
}
