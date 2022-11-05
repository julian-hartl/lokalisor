import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_lokalisor/src/di/get_it.dart';

import '../../core/async_value.dart';
import '../../translation_node_repository.dart';
import '../translation_node.dart';

typedef TranslationTreeTileState = AsyncValue<List<TranslationNode>>;

class TranslationTreeTileCubit extends Cubit<TranslationTreeTileState> {
  final TranslationNode _node;
  final TranslationNodeRepository _nodeRepository =
      getIt<TranslationNodeRepository>();

  StreamSubscription? _subscription;

  TranslationTreeTileCubit(this._node) : super(const AsyncValue.loading()) {
    load();
  }

  void _watch() {
    _subscription = _nodeRepository.watchChildren(_node.id).listen((event) {
      emit(AsyncValue.loaded(event));
    });
  }

  Future<void> load() async {
    emit(const AsyncValue.loading());
    final children = await _nodeRepository.getChildren(_node.id);
    _watch();
    emit(AsyncValue.loaded(children));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
