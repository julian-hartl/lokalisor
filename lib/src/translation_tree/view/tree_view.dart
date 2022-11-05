import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lokalisor/src/changes_detector/changes_detector_cubit.dart';
import 'package:flutter_lokalisor/src/notifications/error_notification.dart';
import 'package:flutter_lokalisor/src/translation_tree/translation_tree_cubit.dart';
import 'package:flutter_lokalisor/src/translation_tree/view/translation_tree_tile_cubit.dart';
import 'package:flutter_lokalisor/src/translation_value/translation_value_dialog.dart';
import 'package:gap/gap.dart';

import '../translation_node.dart';

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
        loading: () => const Center(
          child: CupertinoActivityIndicator(),
        ),
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
                        node: nodes[index],
                      ),
              ),
      ),
    );
  }
}

class TranslationTreeTile extends StatefulWidget {
  const TranslationTreeTile({
    Key? key,
    required this.node,
  }) : super(key: key);

  final TranslationNode node;

  @override
  State<TranslationTreeTile> createState() => _TranslationTreeTileState();
}

class _TranslationTreeTileState extends State<TranslationTreeTile> {
  final TextEditingController keyController = TextEditingController();

  static const double treeLevelPadding = 0;

  late TranslationNode node;

  @override
  void initState() {
    super.initState();
    node = widget.node;
    keyController.text = node.translationKey;
  }

  @override
  void dispose() {
    keyController.dispose();

    super.dispose();
  }

  final id = UniqueKey().toString();

  bool open = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TranslationTreeTileCubit(widget.node),
      child: Builder(
        builder: (context) {
          return BlocBuilder<TranslationTreeTileCubit,
              TranslationTreeTileState>(
            builder: (context, state) {
              return state.when(
                loading: () => const SizedBox(),
                error: (message) {
                  print(message);
                  return const SizedBox();
                },
                loaded: (children) {
                  return Material(
                    child: ListTile(
                      trailing: children.isNotEmpty
                          ? CupertinoButton(
                              child: Icon(open
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_left),
                              onPressed: () {
                                setState(() {
                                  open = !open;
                                });
                              },
                            )
                          : null,
                      leading: Text(
                        node.id.toString(),
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FractionallySizedBox(
                            widthFactor: 0.5,
                            child: Row(
                              children: [
                                Expanded(
                                  child: CupertinoTextField(
                                    controller: keyController,
                                    placeholder: 'Key',
                                    onEditingComplete: () {
                                      context
                                          .read<ChangesDetectorCubit>()
                                          .save();
                                    },
                                    onChanged: (value) {
                                      if (value == node.translationKey) {
                                        context
                                            .read<ChangesDetectorCubit>()
                                            .removeChanges(id);
                                      } else {
                                        context
                                            .read<ChangesDetectorCubit>()
                                            .reportChange(id, () async {
                                          node = node.copyWith(
                                            translationKey: keyController.text,
                                          );
                                          final success = await context
                                              .read<TranslationTreeCubit>()
                                              .updateNode(node);
                                          if (!success) {
                                            keyController.text =
                                                widget.node.translationKey;
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                if (children.isEmpty)
                                  Expanded(
                                    child: CupertinoTextField(
                                      onTap: () {
                                        showCupertinoDialog(
                                          context: context,
                                          builder: (context) =>
                                              TranslationValueDialog(
                                            node: node,
                                          ),
                                        );
                                      },
                                      readOnly: true,
                                      placeholder: 'Value',
                                    ),
                                  ),
                                IconButton(
                                  onPressed: () async {
                                    await context
                                        .read<ChangesDetectorCubit>()
                                        .save();
                                    if (keyController.text.isEmpty) {
                                      showErrorNotification(
                                          "Parent key can't be empty.");
                                      return;
                                    }
                                    // add node
                                    final newNode = await context
                                        .read<TranslationTreeCubit>()
                                        .addNode(
                                          node.id,
                                          '',
                                        );
                                    if (newNode != null) {
                                      // update node
                                      node = await context
                                          .read<TranslationTreeCubit>()
                                          .getNodeOrThrow(node.id);
                                      setState(() {
                                        open = true;
                                      });
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.add,
                                  ),
                                ),
                                CupertinoButton(
                                  onPressed: () async {
                                    // remove node
                                    await context
                                        .read<TranslationTreeCubit>()
                                        .removeNode(
                                          node.id,
                                        );
                                  },
                                  child: const Icon(
                                    Icons.remove,
                                  ),
                                )
                              ],
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOut,
                            child: children.isNotEmpty && open
                                ? Builder(
                                    builder: (context) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            left: treeLevelPadding),
                                        child: ListView.builder(
                                          padding: EdgeInsets.zero,
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: children.length,
                                          itemBuilder: (context, index) =>
                                              TranslationTreeTile(
                                            node: children[index],
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : const SizedBox(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
