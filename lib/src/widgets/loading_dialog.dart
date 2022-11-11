import 'package:flutter/cupertino.dart';

Future<void> showLoadingDialog(BuildContext context) =>
    LoadingDialog.show(context);

class LoadingDialog extends StatelessWidget {
  const LoadingDialog({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) async {
    await showCupertinoDialog(
      context: context,
      builder: (context) => const LoadingDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CupertinoActivityIndicator(),
    );
  }
}
