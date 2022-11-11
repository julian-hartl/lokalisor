import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lokalisor/src/application/application_cubit.dart';
import 'package:flutter_lokalisor/src/notifications/error_notification.dart';
import 'package:flutter_lokalisor/src/notifications/success_notification.dart';
import 'package:flutter_lokalisor/src/translation_locale.dart';
import 'package:flutter_lokalisor/src/translation_tree/translation_node.dart';
import 'package:flutter_lokalisor/src/translation_value/translation_value_dialog_cubit.dart';
import 'package:gap/gap.dart';

import '../locale/supported_locales.dart';
import 'translation_value_cubit.dart';

class TranslationValueDialog extends StatelessWidget {
  const TranslationValueDialog({
    Key? key,
    required this.node,
  }) : super(key: key);

  final TranslationNode node;

  @override
  Widget build(BuildContext context) {
    final locales = context
        .read<ApplicationCubit>()
        .state
        .valueOrThrow
        .currentApplication!
        .supportedLocales;
    return BlocProvider(
      create: (context) => TranslationValueDialogCubit(node),
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
                      loaded: (model) {
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
                                  " (${model.absoluteTranslationKey})",
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
                                  itemBuilder: (context, index) {
                                    final localeId = locales[index];

                                    return LocaleListTile(
                                        locale: availableLocales.firstWhere(
                                          (element) => element.id == localeId,
                                        ),
                                        onChanged: (String value) {
                                          context
                                              .read<
                                                  TranslationValueDialogCubit>()
                                              .markLocaleAsChanged(
                                                localeId,
                                                value,
                                              );
                                        },
                                        node: node,
                                        value: model.translationValues
                                                .firstWhereOrNull((element) =>
                                                    element.localeId ==
                                                    localeId)
                                                ?.value ??
                                            "");
                                  },
                                  itemCount: locales.length,
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
                                    final result = await context
                                        .read<TranslationValueDialogCubit>()
                                        .save()
                                        .run();
                                    result.fold((error) {
                                      showErrorNotification(
                                        error,
                                      );
                                    }, (updatedTranslations) {
                                      if (updatedTranslations > 0) {
                                        showSuccessNotification(
                                            "Successfully updated translations...");
                                      }
                                      Navigator.pop(context);
                                    });
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                      error: (String message) {
                        return Center(
                          child: Text(message),
                        );
                      }),
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
