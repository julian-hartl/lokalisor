import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lokalisor/src/application/application.dart';
import 'package:flutter_lokalisor/src/application/edit_application_page.dart';
import 'package:flutter_lokalisor/src/notifications/error_notification.dart';
import 'package:flutter_lokalisor/src/notifications/success_notification.dart';
import 'package:flutter_lokalisor/src/widgets/loading_dialog.dart';
import 'package:gap/gap.dart';
import 'package:native_context_menu/native_context_menu.dart' as ncm;
import 'package:sidebarx/sidebarx.dart';

import 'application/add_application_page.dart';
import 'application/application_cubit.dart';

class PageViewPanel extends StatelessWidget {
  const PageViewPanel({
    Key? key,
    required SidebarXController sideBarController,
  })  : _sideBarController = sideBarController,
        super(key: key);

  final SidebarXController _sideBarController;

  @override
  Widget build(BuildContext context) {
    return Material(
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
                _ApplicationList(
                  extended: extended,
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
    );
  }
}

class _ApplicationList extends StatelessWidget {
  const _ApplicationList({
    Key? key,
    required this.extended,
  }) : super(key: key);

  final bool extended;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ApplicationCubit, ApplicationState>(
      builder: (context, state) => Column(
          crossAxisAlignment:
              extended ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: state.whenOrNull(
                loaded: (value) => value.applications
                    .map(
                      (e) => _ApplicationTile(
                        extended: extended,
                        application: e,
                      ),
                    )
                    .toList(),
              ) ??
              []),
    );
  }
}

class _ApplicationTile extends StatelessWidget {
  const _ApplicationTile({
    Key? key,
    required this.extended,
    required this.application,
  }) : super(key: key);

  final bool extended;
  final Application application;

  @override
  Widget build(BuildContext context) {
    return ncm.ContextMenuRegion(
      onItemSelected: (item) {
        if (item.title == 'Delete') {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Delete application'),
              content:  Text(
                  'Are you sure you want to delete ${application.name}?'),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: () async {
                    try {
                      showLoadingDialog(context);
                      await context
                          .read<ApplicationCubit>()
                          .deleteApplication(application.id);
                      showSuccessNotification("Successfully deleted ${application.name}");
                      Navigator.of(context).pop();
                    } catch(e){
                      showErrorNotification("Could not delete ${application.name}: $e");
                  } finally{
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        } else if(item.title == 'Edit'){
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => EditApplicationPage(
                application: application,
              ),
            ),
          );
        }
      },
      menuItems: [
        ncm.MenuItem(
          title: 'Edit',
          action: const Icon(Icons.edit),
          onSelected: () {},
        ),
        ncm.MenuItem(
          title: 'Delete',
          action: const Icon(Icons.delete),

        ),
      ],
      child: CupertinoButton(
        onPressed: () {
          context.read<ApplicationCubit>().setCurrentApplicationId(
                application.id,
              );
        },
        child: Row(children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.transparent,
            backgroundImage: application.logoPath != null
                ? FileImage(File(application.logoPath!))
                : null,
            child: application.logoPath == null
                ? const Icon(CupertinoIcons.app)
                : null,
          ),
          if (extended) ...[
            const Gap(10),
            Text(
              application.name,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoTheme.of(context).textTheme.textStyle.color,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
