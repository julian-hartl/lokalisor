import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/a11y-light.dart';
import 'package:flutter_lokalisor/src/application/application_cubit.dart';
import 'package:flutter_lokalisor/src/logger/logger.dart';
import 'package:flutter_lokalisor/src/notifications/error_notification.dart';
import 'package:flutter_lokalisor/src/notifications/success_notification.dart';
import 'package:flutter_lokalisor/src/translation_locale.dart';
import 'package:flutter_lokalisor/src/utils.dart';

import '../di/get_it.dart';
import '../io/tree_io_service.dart';
import '../locale/supported_locales.dart';

class JsonView extends StatefulWidget {
  const JsonView({
    Key? key,
    required this.locale,
  }) : super(key: key);

  final TranslationLocale locale;

  @override
  State<JsonView> createState() => _JsonViewState();
}

class _JsonViewState extends State<JsonView> with LoggerProvider {
  Map<String, dynamic> json = {};

  void _copyToClipboard() async {
    try {
      final json = jsonEncode(this.json);
      await Clipboard.setData(
        ClipboardData(text: json),
      );
      showSuccessNotification("Copied json to clipboard.");
    } catch (e, str) {
      print(e);
      print(str);
      showErrorNotification("Could not copy json to clipboard.");
    }
  }

  late TranslationLocale locale;

  void _updateJson() async {
    final applicationId = context
        .read<ApplicationCubit>()
        .state
        .valueOrNull
        ?.currentApplicationId;
    if (applicationId == null) {
      log("Cannot update json: No application selected.");
      return;
    }
    final value = await getIt<TreeIOService>().getTreeAsJson(
      localeId: locale.id,
      applicationId: applicationId,
    );
    setState(() => json = value);
  }

  @override
  void initState() {
    super.initState();
    locale = widget.locale;
    _updateJson();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
          middle: const Text('JSON'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                onPressed: () {
                  _copyToClipboard();
                },
                child: const Icon(Icons.copy),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () async {
                  final newLocale =
                      await showCupertinoModalPopup<TranslationLocale>(
                    context: context,
                    builder: (context) => _SelectLocaleDialog(
                      initialLocale: locale,
                    ),
                  );
                  if (newLocale != null) {
                    setState(() => locale = newLocale);
                    _updateJson();
                  }
                },
                child: Text(
                  locale.flag,
                ),
              ),
            ],
          )),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: HighlightView(
                // The original code to be highlighted
                prettifyJson(
                  jsonEncode(
                    json,
                  ),
                ),

                // Specify language
                // It is recommended to give it a value for performance
                language: 'json',

                // Specify highlight theme
                // All available themes are listed in `themes` folder
                theme: a11yLightTheme,

                // Specify padding
                padding: const EdgeInsets.all(12),

                // Specify text style
                textStyle: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectLocaleDialog extends StatefulWidget {
  const _SelectLocaleDialog({
    Key? key,
    required this.initialLocale,
  }) : super(key: key);

  final TranslationLocale initialLocale;

  @override
  State<_SelectLocaleDialog> createState() => _SelectLocaleDialogState();
}

class _SelectLocaleDialogState extends State<_SelectLocaleDialog> {
  late TranslationLocale locale;

  @override
  void initState() {
    super.initState();
    locale = widget.initialLocale;
    locales = availableLocales
        .where((element) => context
            .read<ApplicationCubit>()
            .state
            .valueOrThrow
            .currentApplication!
            .supportedLocales
            .contains(element.id))
        .toList();
  }

  late final List<TranslationLocale> locales;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      // Provide a background color for the popup.
      color: CupertinoColors.systemBackground.resolveFrom(context),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Select locale"),
            const SizedBox(
              height: 16,
            ),
            Expanded(
              child: CupertinoPicker(
                magnification: 1.22,
                squeeze: 1.2,
                useMagnifier: true,
                itemExtent: 30,
                onSelectedItemChanged: (value) {
                  setState(() {
                    locale = locales[value];
                  });
                },
                scrollController: FixedExtentScrollController(
                  initialItem: availableLocales.indexOf(widget.initialLocale),
                ),
                children: locales
                    .map((e) => Text(
                          "${e.flag} ${e.name}",
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            CupertinoButton(
              onPressed: () {
                Navigator.of(context).pop(locale);
              },
              child: const Text("Close"),
            ),
          ],
        ),
      ),
    );
  }
}
