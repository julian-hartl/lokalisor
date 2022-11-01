import 'package:flutter/cupertino.dart';

class LoadingDialog extends StatelessWidget {
  const LoadingDialog({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showCupertinoDialog(
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
