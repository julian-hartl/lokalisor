import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lokalisor/src/translation_tree/view/tree_view.dart';
import 'package:gap/gap.dart';

import '../../main.dart';
import '../application/add_application_page.dart';
import '../application/application_cubit.dart';
import '../di/get_it.dart';
import '../file_view/json_view.dart';
import '../io/tree_io_service.dart';
import '../locale/supported_locales.dart';
import '../notifications/error_notification.dart';
import '../notifications/success_notification.dart';
import '../widgets/display_error.dart';
import '../widgets/display_loading.dart';
import '../widgets/loading_dialog.dart';
import 'translation_tree_cubit.dart';

class TranslationsPage extends StatelessWidget {
  const TranslationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ApplicationCubit, ApplicationState>(
        builder: (context, state) {
      return state.when(
        error: (message) => DisplayError(
          message: message,
          onTryAgain: () {
            context.read<ApplicationCubit>().loadApplications();
          },
        ),
        loading: displayLoading,
        loaded: (value) {
          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              // leading: CupertinoButton(
              //   padding: EdgeInsets.zero,
              //   child: const Icon(Icons.menu),
              //   onPressed: () {},
              // ),
              middle: const Text('Flutter Lokalisor'),
              trailing: value.currentApplicationId != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoButton(
                          onPressed: () async {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => JsonView(
                                  locale: availableLocales.first,
                                ),
                              ),
                            );
                          },
                          child: const Icon(Icons.video_file_outlined),
                        ),
                      ],
                    )
                  : null,
            ),
            child: value.applications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("You have not added any applications yet."),
                        Gap(10),
                        CupertinoButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (context) =>
                                    const AddApplicationPage(),
                              ),
                            );
                          },
                          child: const Text('Add application'),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      const TranslationTreeView(),
                      const Align(
                        alignment: Alignment.bottomCenter,
                        child: AddTranslationButton(),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: CupertinoButton(
                          child: const Text("Import/Export"),
                          onPressed: () async {
                            await showCupertinoModalPopup(
                              context: context,
                              builder: (context) => CupertinoAlertDialog(
                                title: const Text("Action"),
                                content: const Text(
                                    "Do you want to import or export translations?"),
                                actions: [
                                  CupertinoDialogAction(
                                    onPressed: () async {
                                      await showCupertinoModalPopup(
                                        context: context,
                                        builder: (context) =>
                                            const FileImportDialog(),
                                      );
                                      context
                                          .read<TranslationTreeCubit>()
                                          .reload();
                                      Navigator.pop(context);
                                    },
                                    child: const Text(
                                      "Import",
                                    ),
                                  ),
                                  CupertinoDialogAction(
                                    onPressed: () async {
                                      final currentApplicationId = context
                                          .read<ApplicationCubit>()
                                          .state
                                          .valueOrNull
                                          ?.currentApplicationId as int;
                                      LoadingDialog.show(context);
                                      final result =
                                          await getIt<TreeIOService>()
                                              .export(currentApplicationId)
                                              .run();
                                      result.fold(
                                          (l) => showErrorNotification(l), (r) {
                                        showSuccessNotification(
                                            "Successfully exported localizations.");
                                        Navigator.pop(context);
                                      });

                                      Navigator.pop(context);
                                    },
                                    child: const Text(
                                      "Export",
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      )
                    ],
                  ),
          );
        },
      );
    });
  }
}
