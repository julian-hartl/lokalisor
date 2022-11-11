import 'package:flutter/cupertino.dart';

Widget displayLoading() => const DisplayLoading();

class DisplayLoading extends StatelessWidget {
  const DisplayLoading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CupertinoActivityIndicator(

      ),
    );
  }
}
