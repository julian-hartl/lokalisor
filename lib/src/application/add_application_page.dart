import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_lokalisor/src/application/application_cubit.dart';
import 'package:flutter_lokalisor/src/application/widgets/logo_picker.dart';
import 'package:flutter_lokalisor/src/notifications/error_notification.dart';
import 'package:flutter_lokalisor/src/notifications/success_notification.dart';
import 'package:flutter_lokalisor/src/widgets/loading_dialog.dart';
import 'package:universal_io/io.dart';

import 'widgets/path_field.dart';

class AddApplicationPage extends StatelessWidget {
  const AddApplicationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Add Application'),
      ),
      child: Center(
        child: AddApplicationForm(),
      ),
    );
  }
}

/// A [Widget] that represents a form to create a new application.
/// Is contains text fields for the name and the description of the application.
/// It also contains a circular image selector to select a logo for the application.
/// The form is validated and the application is created when the user presses the save button.
/// Furthermore, the user can select the path of the application with the help of a file picker.
/// The user can cancel the creation of the application by pressing the cancel button.
///
class AddApplicationForm extends HookWidget {
  const AddApplicationForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final logoPath = useState<String?>(null);
    final path = useState<String?>(null);
    return Form(
      key: formKey,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ApplicationLogoPicker(
              logoPath: logoPath.value,
              onChanged: (value) {
                logoPath.value = value;
              },
            ),
            const Text('Logo'),
            const SizedBox(height: 16),
            CupertinoTextFormFieldRow(
              placeholder: 'Name',
              controller: nameController,
              validator: (value) => value == null || value.isEmpty
                  ? 'Please enter a name for the application'
                  : null,
            ),
            const SizedBox(height: 16),
            CupertinoTextFormFieldRow(
              controller: descriptionController,
              placeholder: 'Description',
            ),
            const SizedBox(height: 16),
            ApplicationPathField(
              initialPath: path.value ?? "",
              onChanged: (value) {
                path.value = value;
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CupertinoButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                CupertinoButton(
                  color: CupertinoTheme.of(context).primaryColor,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }
                    try {
                      LoadingDialog.show(context);
                      final name = nameController.text;
                      final description = descriptionController.text;
                      final logo = logoPath.value;
                      final pathValue = path.value;
                      if (pathValue == null || pathValue.isEmpty) {
                        showErrorNotification(
                            "You must select a path for the application.");
                        return;
                      }
                      final logoDir =
                          "${Directory.current.path}/application_logos";
                      await Directory(logoDir).create(recursive: true);
                      final persistedLogoPath = '$logoDir/$name.png';
                      if (logo != null) {
                        await File(logo).copy(persistedLogoPath);
                      }
                      final error =
                          await context.read<ApplicationCubit>().addApplication(
                                name: name,
                                description: description,
                                logoPath: persistedLogoPath,
                                path: pathValue,
                              );
                      if (error != null) {
                        showErrorNotification(error);
                      } else {
                        showSuccessNotification("Added application.");
                        Navigator.pop(context);
                      }
                    } finally {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: CupertinoTheme.of(context).primaryContrastingColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
