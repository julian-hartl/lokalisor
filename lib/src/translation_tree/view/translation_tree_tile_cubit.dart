import 'dart:async';

import 'package:async_dart/async_dart.dart';
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
    await run(() async {
      final children = await _nodeRepository.getChildren(_node.id);
      _watch();
      return children;
    });
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
