import 'dart:async';

import 'package:async_dart/async_dart.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_lokalisor/src/di/get_it.dart';

import '../../translation_node_repository.dart';
import '../translation_node.dart';

typedef TranslationTreeTileState = AsyncState<List<TranslationNode>>;

class TranslationTreeTileCubit extends AsyncCubit<List<TranslationNode>> {
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
