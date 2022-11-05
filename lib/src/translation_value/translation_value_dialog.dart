import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lokalisor/src/translation_locale.dart';
import 'package:flutter_lokalisor/src/translation_tree/translation_node.dart';
import 'package:flutter_lokalisor/src/translation_value/translation_value_dialog_cubit.dart';
import 'package:flutter_lokalisor/src/widgets/loading_dialog.dart';
import 'package:gap/gap.dart';

import '../locale/supported_locales.dart';
import 'translation_value_cubit.dart';

class TranslationValueDialog extends StatefulWidget {
  const TranslationValueDialog({
    Key? key,
    required this.node,
  }) : super(key: key);

  final TranslationNode node;

  @override
  State<TranslationValueDialog> createState() => _TranslationValueDialogState();
}

class _TranslationValueDialogState extends State<TranslationValueDialog> {
  final Map<int, String> localesToUpdate = {};

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TranslationValueDialogCubit(widget.node),
      child: Builder(builder: (context) {
        return BlocBuilder<TranslationValueDialogCubit,
            TranslationValueDialogState>(
          builder: (context, state) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: FractionallySizedBox(
                heightFactor: 0.7,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: state.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    loaded: (absoluteTranslationKey, translationValues) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.language),
                              const SizedBox(
                                width: 10,
                              ),
                              const Text("Localization Values"),
                              Text(
                                " ($absoluteTranslationKey)",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.grey,
                                ),
                              ),
                              child: ListView.builder(
                                itemBuilder: (context, index) => LocaleListTile(
                                    locale: supportedLocales[index],
                                    onChanged: (String value) {
                                      localesToUpdate[
                                          supportedLocales[index].id] = value;
                                      print(supportedLocales[index].id);
                                    },
                                    node: widget.node,
                                    value: translationValues
                                            .firstWhereOrNull((element) =>
                                                element.localeId ==
                                                supportedLocales[index].id)
                                            ?.value ??
                                        ""),
                                itemCount: supportedLocales.length,
                              ),
                            ),
                          ),
                          const Gap(10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              CupertinoButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancel'),
                              ),
                              CupertinoButton(
                                onPressed: () async {
                                  LoadingDialog.show(context);
                                  for (final entry in localesToUpdate.entries) {
                                    await context
                                        .read<TranslationValueCubit>()
                                        .updateTranslation(
                                          widget.node,
                                          value: entry.value,
                                          localeId: entry.key,
                                        );
                                  }
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class LocaleListTile extends StatefulWidget {
  const LocaleListTile({
    Key? key,
    required this.locale,
    required this.onChanged,
    required this.node,
    required this.value,
  }) : super(key: key);

  final TranslationLocale locale;
  final TranslationNode node;
  final ValueChanged<String> onChanged;
  final String value;

  @override
  State<LocaleListTile> createState() => _LocaleListTileState();
}

class _LocaleListTileState extends State<LocaleListTile> {
  final TextEditingController valueController = TextEditingController();

  TranslationValueCubit get translationValueCubit =>
      context.read<TranslationValueCubit>();

  @override
  void initState() {
    super.initState();

    valueController.text = widget.value;
  }

  @override
  void dispose() {
    valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListTile(
        title: Row(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.2,
              child: Row(
                children: [
                  Text(widget.locale.flag),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(widget.locale.name),
                ],
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: CupertinoTextField(
                placeholder: 'Value',
                onChanged: widget.onChanged,
                controller: valueController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
