import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_lokalisor/src/application/add_application_page.dart';
import 'package:flutter_lokalisor/src/application/application_cubit.dart';
import 'package:flutter_lokalisor/src/changes_detector/changes_detector_cubit.dart';
import 'package:flutter_lokalisor/src/db/drift.dart';
import 'package:flutter_lokalisor/src/di/get_it.dart';
import 'package:flutter_lokalisor/src/file_view/json_view.dart';
import 'package:flutter_lokalisor/src/io/tree_io_service.dart';
import 'package:flutter_lokalisor/src/notifications/error_notification.dart';
import 'package:flutter_lokalisor/src/notifications/success_notification.dart';
import 'package:flutter_lokalisor/src/translation_tree/translation_tree_cubit.dart';
import 'package:flutter_lokalisor/src/translation_tree/view/tree_view.dart';
import 'package:flutter_lokalisor/src/widgets/loading_dialog.dart';
import 'package:gap/gap.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:universal_io/io.dart';

import 'src/locale/supported_locales.dart';
import 'src/translation_value/translation_value_cubit.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  // await getIt<Isar>().writeTxn(() async {
  //   await getIt<Isar>().clear();
  // });
  runApp(const FlutterLokalisor());
}

class FlutterLokalisor extends StatelessWidget {
  const FlutterLokalisor({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<TranslationValueCubit>(),
        ),
        BlocProvider(
          create: (context) => getIt<TranslationTreeCubit>(),
        ),
        BlocProvider(
          create: (context) => getIt<ChangesDetectorCubit>(),
        ),
        BlocProvider(
          create: (context) => getIt<ApplicationCubit>(),
        ),
      ],
      child: OverlaySupport.global(
        child: CupertinoApp(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Lokalisor',
          theme: const CupertinoThemeData(
            scaffoldBackgroundColor: Color(0xFFEFEFF4),
            brightness: Brightness.light,
            barBackgroundColor: Color(0xFFEFEFF4),
            primaryContrastingColor: Color(0xFFFFFFFF),
            textTheme: CupertinoTextThemeData(
              primaryColor: Color(0xFF000000),
              textStyle: TextStyle(
                color: Color(0xFF000000),
                fontSize: 17,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.normal,
                letterSpacing: 0.0,
              ),
            ),
            primaryColor: CupertinoColors.activeOrange,
          ),
          home: BlocConsumer<ApplicationCubit, ApplicationState>(
            listener: (context, state) {
              state.whenOrNull(
                loaded: (applications, currentApplicationId) {
                  if (currentApplicationId != null) {
                    context
                        .read<TranslationTreeCubit>()
                        .load(currentApplicationId);
                  }
                },
              );
            },
            builder: (context, state) {
              return state.when(
                loading: () => const CupertinoPageScaffold(
                  child: Center(
                    child: CupertinoActivityIndicator(),
                  ),
                ),
                loaded: (applications, currentApplicationId) => const Home(),
                error: (message) => CupertinoPageScaffold(
                  child: Center(
                    child: Text('Error: $message'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _sideBarController = SidebarXController(
    selectedIndex: 0,
    extended: true,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: CupertinoTheme.of(context).scaffoldBackgroundColor,
          child: SidebarX(
            extendedTheme: const SidebarXTheme(
              width: 200,
            ),
            theme: SidebarXTheme(
              selectedIconTheme: IconThemeData(
                color: CupertinoTheme.of(context).primaryColor,
              ),
              selectedItemPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              selectedTextStyle: TextStyle(
                color: CupertinoTheme.of(context).primaryColor,
              ),
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).scaffoldBackgroundColor,
              ),
            ),
            showToggleButton: true,
            footerItems: [
              const SidebarXItem(
                label: 'Translations',
                icon: Icons.translate,
              ),
              const SidebarXItem(
                label: 'About',
                icon: CupertinoIcons.info,
              ),
              const SidebarXItem(
                label: 'Settings',
                icon: CupertinoIcons.settings,
              ),
              SidebarXItem(
                label: 'Exit',
                icon: CupertinoIcons.power,
                onTap: () => exit(0),
              ),
            ],
            toggleButtonBuilder: (context, extended) => const SizedBox(
              height: 16,
            ),
            controller: _sideBarController,
            headerBuilder: (context, extended) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: extended
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    if (extended) ...[
                      const Gap(16),
                      const Text(
                        'Flutter Lokalisor',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(8),
                      const Text(
                        'v0.0.1',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const Gap(16),
                      const Text(
                        'Manage your localizations',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                    const Gap(16),
                    BlocBuilder<ApplicationCubit, ApplicationState>(
                      builder: (context, state) => Column(
                          crossAxisAlignment: extended
                              ? CrossAxisAlignment.center
                              : CrossAxisAlignment.start,
                          children: state.whenOrNull(
                                loaded: (applications, _) => applications
                                    .map(
                                      (e) => CupertinoButton(
                                        onPressed: () {
                                          context
                                              .read<ApplicationCubit>()
                                              .setCurrentApplicationId(
                                                e.id,
                                              );
                                        },
                                        child: Row(children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.transparent,
                                            backgroundImage: e.logoPath != null
                                                ? FileImage(File(e.logoPath!))
                                                : null,
                                            child: e.logoPath == null
                                                ? const Icon(CupertinoIcons.app)
                                                : null,
                                          ),
                                          if (extended) ...[
                                            const Gap(10),
                                            Text(
                                              e.name,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color:
                                                    CupertinoTheme.of(context)
                                                        .textTheme
                                                        .textStyle
                                                        .color,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ]),
                                      ),
                                    )
                                    .toList(),
                              ) ??
                              []),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.all(0),
                      onPressed: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const AddApplicationPage(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.add_circled),
                          if (extended) ...[
                            const Gap(10),
                            const Text('Add application'),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Expanded(
          child: BlocBuilder<ApplicationCubit, ApplicationState>(
              builder: (context, state) {
            return state.maybeWhen(
              orElse: () => SizedBox(),
              loaded: (applications, currentApplicationId) {
                return CupertinoPageScaffold(
                  navigationBar: CupertinoNavigationBar(
                    // leading: CupertinoButton(
                    //   padding: EdgeInsets.zero,
                    //   child: const Icon(Icons.menu),
                    //   onPressed: () {},
                    // ),
                    middle: const Text('Flutter Lokalisor'),
                    trailing: currentApplicationId != null
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CupertinoButton(
                                onPressed: () async {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => JsonView(
                                        locale: supportedLocales.first,
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
                  child: applications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                  "You have not added any applications yet."),
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
                            Column(
                              children: [
                                const ChangesDetector(),
                                Expanded(
                                    child: HomePageView(
                                  controller: _sideBarController,
                                )),
                              ],
                            ),
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
                                            try {
                                              LoadingDialog.show(context);
                                              for (final locale
                                                  in supportedLocales) {
                                                await getIt<TreeIOService>()
                                                    .outputTreeAsJson(
                                                  locale: locale,
                                                );
                                              }
                                              showSuccessNotification(
                                                  "Successfully exported ${supportedLocales.length} localizations.");
                                            } catch (e) {
                                              print(e);
                                              showErrorNotification(
                                                  "Localization export failed.");
                                            } finally {
                                              Navigator.pop(context);
                                              Navigator.pop(context);
                                            }
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
          }),
        ),
      ],
    );
  }
}

class HomePageView extends StatefulWidget {
  const HomePageView({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final SidebarXController controller;

  @override
  State<HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<HomePageView> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.controller.selectedIndex;
    widget.controller.addListener(() {
      final index = widget.controller.selectedIndex;
      if (currentIndex != index) {
        setState(() {
          currentIndex = index;
        });
      }
    });
  }

  static final pages = [
    const TranslationTreeView(),
    const TranslationTreeView(),
    const TranslationTreeView(),
    const TranslationTreeView(),
  ];

  @override
  Widget build(BuildContext context) {
    return pages[currentIndex];
  }
}

class AddTranslationButton extends HookWidget {
  const AddTranslationButton({
    Key? key,
  }) : super(key: key);

  void _handleTreeUpdate(
    TranslationTreeState state,
    AnimationController animationController,
  ) {
    state.whenOrNull(
      loading: () {
        animationController.reverse();
      },
      loaded: (tree) {
        if (tree.isNotEmpty) {
          animationController.forward();
        } else {
          animationController.reverse();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(
        milliseconds: 500,
      ),
    );
    _handleTreeUpdate(
      context.read<TranslationTreeCubit>().state,
      animationController,
    );
    final offsetTween = Tween<Offset>(
      begin: const Offset(0, 70),
      end: const Offset(0, 0),
    ).animate(animationController);
    return BlocListener<TranslationTreeCubit, TranslationTreeState>(
      listener: (context, state) {
        _handleTreeUpdate(
          state,
          animationController,
        );
      },
      child: AnimatedBuilder(
        animation: offsetTween,
        builder: (context, child) => Transform.translate(
          offset: offsetTween.value,
          child: child,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CupertinoButton(
            color: CupertinoTheme.of(context).primaryColor,
            onPressed: () {
              context.read<TranslationTreeCubit>().addNode(
                    null,
                    "",
                  );
            },
            child: Text(
              "Add another translation",
              style: TextStyle(
                color: CupertinoTheme.of(context).primaryContrastingColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FileImportDialog extends StatefulWidget {
  const FileImportDialog({Key? key}) : super(key: key);

  @override
  State<FileImportDialog> createState() => _FileImportDialogState();
}

class _FileImportDialogState extends State<FileImportDialog> {
  List<File> files = [];

  void pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: true,
    );
    if (result == null) {
      return;
    }
    addFiles(result.files.map((e) => File(e.path!)));
  }

  void addFiles(Iterable<File> files) {
    setState(() {
      this.files.addAll(
            files.where(
              (element) => !this.files.map((e) => e.path).contains(
                    element.path,
                  ),
            ),
          );
    });
  }

  void import() async {
    if (files.isEmpty) {
      showErrorNotification("No files selected.");
      return;
    }
    try {
      List<String> errors = [];
      LoadingDialog.show(context);
      final applicationId = context.read<ApplicationCubit>().state.whenOrNull(
            loaded: (applications, currentApplicationId) =>
                currentApplicationId,
          );
      if (applicationId == null) return;
      for (final file in files) {
        final error = await getIt<TreeIOService>().import(
          File(
            file.path,
          ),
          applicationId: applicationId,
        );
        if (error != null) {
          errors.add(error);
        }
      }
      for (int i = 0; i < errors.length; i++) {
        Future.delayed(const Duration(seconds: 1) * i, () {
          showErrorNotification(errors[i]);
        });
      }
      final imports = files.length - errors.length;
      if (imports > 0) {
        showSuccessNotification(
            "Successfully imported $imports localizations.");
      }

      Navigator.pop(context);
    } catch (e) {
      print(e);
      showErrorNotification("Localization export failed.");
    } finally {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      height: 300,
      color: CupertinoTheme.of(context).scaffoldBackgroundColor,
      child: DropTarget(
        onDragDone: (details) {
          addFiles(
            details.files.map(
              (e) => File(
                e.path,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: CupertinoTheme.of(context).primaryColor,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Drag and drop your json files here or",
                        style: TextStyle(
                          fontSize: 13,
                        ),
                      ),
                      const Gap(3),
                      CupertinoButton(
                        child: const Text("Select files"),
                        onPressed: () {
                          pickFiles();
                        },
                      ),
                      if (files.isNotEmpty) ...[
                        const Gap(10),
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: files.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                files[index].uri.pathSegments.last,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              CupertinoButton(
                color: CupertinoTheme.of(context).primaryColor,
                child: Text(
                  "Import",
                  style: TextStyle(
                    color: CupertinoTheme.of(context).primaryContrastingColor,
                  ),
                ),
                onPressed: () {
                  import();
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ChangesDetector extends StatefulWidget {
  const ChangesDetector({
    Key? key,
  }) : super(key: key);

  @override
  State<ChangesDetector> createState() => _ChangesDetectorState();
}

class _ChangesDetectorState extends State<ChangesDetector> {
  bool isSaving = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChangesDetectorCubit, ChangesDetectorState>(
      builder: (context, state) {
        if (state.hasChanges) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "You have unsaved changes.",
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    CupertinoButton(
                      child: const Text(
                        "Save now",
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      onPressed: () async {
                        if (isSaving) return;
                        try {
                          setState(() {
                            isSaving = true;
                          });
                          await context.read<ChangesDetectorCubit>().save();
                        } catch (e) {
                          print(e);
                        } finally {
                          setState(() {
                            isSaving = false;
                          });
                        }
                      },
                    ),
                    if (isSaving) ...[
                      const Gap(5),
                      const CupertinoActivityIndicator(),
                    ],
                  ],
                )
              ],
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}
