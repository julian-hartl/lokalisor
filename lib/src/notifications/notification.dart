import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';

class BaseNotification extends StatelessWidget {
  const BaseNotification({
    Key? key,
    required this.child,
    required this.background,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  }) : super(key: key);

  final Widget child;
  final Color background;

  Future<void> show() async {
    final result = showOverlayNotification(
      (context) => build(context),
    );
    return result.dismissed;
  }

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        borderRadius: borderRadius,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: borderRadius,
          ),
          child: child,
        ),
      ),
    );
  }
}
