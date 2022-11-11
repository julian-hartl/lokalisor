import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';

import '../../widgets/loading_dialog.dart';

class ApplicationLogoPicker extends StatelessWidget {
  const ApplicationLogoPicker({
    Key? key,
    required this.logoPath,
    required this.onChanged,
  }) : super(key: key);

  final ValueChanged<String> onChanged;
  final String? logoPath;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: () async {
        try {
          LoadingDialog.show(context);
          final result = await FilePicker.platform.pickFiles(
            allowMultiple: false,
            type: FileType.custom,
            allowedExtensions: ['png', 'jpg', 'jpeg'],
          );
          if (result?.files.firstOrNull?.path != null) {
            onChanged(
              result!.files.first.path!,
            );
          }
        } catch (e) {
          print(e);
        } finally {
          Navigator.pop(context);
        }
      },
      child: CircleAvatar(
        radius: 50,
        backgroundImage:
        logoPath != null ? FileImage(File(logoPath!)) : null,
        child: logoPath == null
            ? const Icon(
          CupertinoIcons.photo,
          size: 50,
        )
            : null,
      ),
    );
  }
}