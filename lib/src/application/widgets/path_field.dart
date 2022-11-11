import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';

import '../../notifications/error_notification.dart';
import '../../widgets/loading_dialog.dart';

class ApplicationPathField extends StatelessWidget {
  const ApplicationPathField({
    Key? key,
    required this.onChanged,
    required this.initialPath,
  }) : super(key: key);

  final ValueChanged<String> onChanged;

  final String initialPath;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextFormFieldRow(
      placeholder: 'Path',
      initialValue: initialPath,
      readOnly: true,
      onTap: () async {
        try {
          LoadingDialog.show(context);
          final result = await FilePicker.platform.pickFiles(
            allowMultiple: false,
            type: FileType.custom,
            allowedExtensions: ['yaml'],
          );
          final filePath = result?.files.firstOrNull?.path;
          if (filePath != null) {
            if (filePath.endsWith('pubspec.yaml')) {
              onChanged(filePath);
            } else {
              showErrorNotification("Please select a pubspec.yaml file");
            }
          }
        } catch (e) {
          print(e);
        } finally {
          Navigator.pop(context);
        }
      },
    );
  }
}
