import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_lokalisor/src/application/application_cubit.dart';
import 'package:flutter_lokalisor/src/changes_detector/changes_detector.dart';
import 'package:flutter_lokalisor/src/changes_detector/changes_detector_cubit.dart';
import 'package:flutter_lokalisor/src/di/get_it.dart';
import 'package:flutter_lokalisor/src/io/tree_io_service.dart';
import 'package:flutter_lokalisor/src/notifications/error_notification.dart';
import 'package:flutter_lokalisor/src/notifications/success_notification.dart';
import 'package:flutter_lokalisor/src/settings/settings_page.dart';
import 'package:flutter_lokalisor/src/translation_tree/translation_tree_cubit.dart';
import 'package:flutter_lokalisor/src/translation_tree/translations_page.dart';
import 'package:flutter_lokalisor/src/widgets/display_error.dart';
import 'package:flutter_lokalisor/src/widgets/display_loading.dart';
import 'package:flutter_lokalisor/src/widgets/loading_dialog.dart';
import 'package:gap/gap.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:universal_io/io.dart';

import 'src/page_view_panel.dart';
import 'src/translation_value/translation_value_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
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
                loaded: (value) {
                  if (value.currentApplicationId != null) {
                    context
                        .read<TranslationTreeCubit>()
                        .load(value.currentApplicationId!);
                  }
                },
              );
            },
            builder: (context, state) {
              return state.when(
                loading: () => const CupertinoPageScaffold(
                  child: DisplayLoading(),
                ),
                loaded: (_) => const Home(),
                error: (message) => CupertinoPageScaffold(
                  child: DisplayError(
                    message: message,
                    onTryAgain: () {
                      context.read<ApplicationCubit>().loadApplications();
                    },
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
        PageViewPanel(sideBarController: _sideBarController),
        Expanded(
          child: Column(
            children: [
              const ChangesDetector(),
              Expanded(
                child: HomePageView(
                  controller: _sideBarController,
                ),
              ),
            ],
          ),
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
    const TranslationsPage(),
    const TranslationsPage(),
    const SettingsPage(),
    const TranslationsPage(),
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
      final applicationId = context
          .read<ApplicationCubit>()
          .state
          .valueOrNull
          ?.currentApplicationId;
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
