import 'package:flutter/cupertino.dart';
import 'package:gap/gap.dart';

class DisplayError extends StatelessWidget {
  const DisplayError({
    Key? key,
    required this.message,
    this.tryAgainMessage,
    this.onTryAgain,
  }) : super(key: key);

  final String message;
  final String? tryAgainMessage;
  final VoidCallback? onTryAgain;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(message),
          const Gap(10),
          CupertinoButton(
            onPressed: () {
              onTryAgain?.call();
            },
            child: Text(tryAgainMessage ?? 'Try again'),
          ),
        ],
      ),
    );
  }
}
