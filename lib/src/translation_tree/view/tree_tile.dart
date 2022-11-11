import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lokalisor/src/translation_tree/view/translation_tree_tile_cubit.dart';
import 'package:flutter_lokalisor/src/widgets/display_error.dart';
import 'package:flutter_lokalisor/src/widgets/display_loading.dart';

import '../../changes_detector/changes_detector_cubit.dart';
import '../../notifications/error_notification.dart';
import '../../translation_value/translation_value_dialog.dart';
import '../translation_node.dart';
import '../translation_tree_cubit.dart';

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
  static const openTileIconSize = 20.0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TranslationTreeTileCubit(widget.node),
      child: Builder(
        builder: (context) {
          return BlocBuilder<TranslationTreeTileCubit,
              TranslationTreeTileState>(
            builder: (context, state) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                height: open ? null : 60,
                child: Column(
                  children: state.when(
                    loading: () => [
                      displayLoading(),
                    ],
                    error: (message) => [
                      DisplayError(
                        message: message,
                      ),
                    ],
                    loaded: (children) {
                      return [
                        Row(
                          children: [
                            Expanded(
                              child: CupertinoTextField(
                                controller: keyController,
                                placeholder: 'Key',
                                onEditingComplete: () {
                                  context.read<ChangesDetectorCubit>().save();
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
                                child: _ValueTextField(node: node),
                              ),
                            CupertinoButton(
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
                              child: const Icon(
                                Icons.add,
                              ),
                            ),
                            _RemoveNodeButton(node: node),
                            if (children.isNotEmpty)
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                child: Icon(
                                  open
                                      ? Icons.keyboard_arrow_down
                                      : Icons.keyboard_arrow_left,
                                  size: openTileIconSize,
                                ),
                                onPressed: () {
                                  setState(() {
                                    open = !open;
                                  });
                                },
                              )
                            else
                              const SizedBox(
                                width: openTileIconSize * 2.2,
                              ),
                          ],
                        ),
                        if (open)
                          _ChildrenListView(
                            children: children,
                          ),
                      ];
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ChildrenListView extends StatelessWidget {
  const _ChildrenListView({
    Key? key,
    required this.children,
  }) : super(key: key);

  final List<TranslationNode> children;
  static const double treeLevelPadding = 20;

  @override
  Widget build(BuildContext context) {
    return children.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(left: treeLevelPadding),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: children.length,
              itemBuilder: (context, index) => TranslationTreeTile(
                node: children[index],
              ),
            ),
          )
        : const SizedBox();
  }
}

class _RemoveNodeButton extends StatelessWidget {
  const _RemoveNodeButton({
    Key? key,
    required this.node,
  }) : super(key: key);

  final TranslationNode node;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: () async {
        // remove node
        await context.read<TranslationTreeCubit>().removeNode(
              node.id,
            );
      },
      child: const Icon(
        Icons.remove,
      ),
    );
  }
}

class _ValueTextField extends StatelessWidget {
  const _ValueTextField({
    Key? key,
    required this.node,
  }) : super(key: key);

  final TranslationNode node;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      onTap: () {
        showCupertinoDialog(
          barrierDismissible: true,
          context: context,
          builder: (context) => TranslationValueDialog(
            node: node,
          ),
        );
      },
      readOnly: true,
      placeholder: 'Value',
    );
  }
}
