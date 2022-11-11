import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class Section extends StatelessWidget {
  const Section({
    Key? key,
    required this.header,
    required this.children,
  }) : super(key: key);
  final String header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          header,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Gap(10),
        Column(
          children: children,
        ),
      ],
    );
  }
}
