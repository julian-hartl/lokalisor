import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_lokalisor/src/application/application.dart';
import 'package:flutter_lokalisor/src/application/widgets/path_field.dart';
import 'package:flutter_lokalisor/src/notifications/error_notification.dart';
import 'package:flutter_lokalisor/src/widgets/loading_dialog.dart';
import 'package:gap/gap.dart';

import '../locale/supported_locales.dart';
import 'application_cubit.dart';
import 'widgets/logo_picker.dart';

class EditApplicationPage extends HookWidget {
  const EditApplicationPage({Key? key, required this.application})
      : super(key: key);
  final Application application;

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final path = useState(application.path);
    final logoPath = useState(application.logoPath);
    final supportedLocales = useState(application.supportedLocales);
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Edit Application'),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ApplicationLogoPicker(
                  logoPath: logoPath.value,
                  onChanged: (value) {
                    logoPath.value = value;
                  },
                ),
                ApplicationPathField(
                  onChanged: (value) {
                    path.value = value;
                  },
                  initialPath: path.value,
                ),
                Column(
                  children: [
                    const Text(
                      "Supported locales",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(10),
                    Column(
                      children: availableLocales
                          .map((locale) => Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(locale.flag),
                                        const Gap(5),
                                        Text(locale.name),
                                      ],
                                    ),
                                  ),
                                  const Gap(10),
                                  CupertinoSwitch(
                                    value: supportedLocales.value
                                        .contains(locale.id),
                                    onChanged: (value) {
                                      supportedLocales.value = value
                                          ? [
                                              ...supportedLocales.value,
                                              locale.id,
                                            ]
                                          : supportedLocales.value
                                              .where((e) => e != locale.id)
                                              .toList();
                                    },
                                  ),
                                ],
                              ))
                          .toList(),
                    ),
                  ],
                ),
                Gap(10),
                CupertinoButton.filled(
                  child: const Text("Save"),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      showLoadingDialog(context);
                      final result = await context
                          .read<ApplicationCubit>()
                          .updateApplication(
                            application.copyWith(
                              path: path.value,
                              logoPath: logoPath.value,
                              supportedLocales: supportedLocales.value,
                            ),
                          )
                          .run();
                      result.fold((l) {
                        showErrorNotification(l);
                      }, (r) {
                        Navigator.pop(context);
                      });
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
