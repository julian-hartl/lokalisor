import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lokalisor/src/translation_tree/translation_tree_cubit.dart';
import 'package:flutter_lokalisor/src/widgets/display_loading.dart';
import 'package:gap/gap.dart';

import '../translation_node.dart';
import 'tree_tile.dart';

class TranslationTreeView extends StatelessWidget {
  const TranslationTreeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TranslationTreeCubit, TranslationTreeState>(
      builder: (context, state) => state.when(
        error: (message) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const Gap(10),
              CupertinoButton(
                onPressed: () {
                  context.read<TranslationTreeCubit>().reload();
                },
                child: const Text("Try again."),
              ),
            ],
          ),
        ),
        loading: displayLoading,
        loaded: (List<TranslationNode> nodes) => nodes.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No translations found'),
                    const Gap(10),
                    CupertinoButton(
                        onPressed: () {
                          context.read<TranslationTreeCubit>().addNode(
                                null,
                                '',
                              );
                        },
                        child: const Text("Add your first translation"))
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: nodes.length + 1,
                itemBuilder: (context, index) => index == nodes.length
                    ? const SizedBox(
                        height: 80,
                      )
                    : TranslationTreeTile(
                        key: Key(
                          nodes[index].id.toString(),
                        ),
                        node: nodes[index],
                      ),
              ),
      ),
    );
  }
}
