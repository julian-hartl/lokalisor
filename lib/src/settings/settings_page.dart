import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lokalisor/src/settings/section.dart';
import 'package:gap/gap.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings'),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Section(
                header: "General",
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Dark Mode",
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      Gap(5),
                      CupertinoSwitch(
                        value: false,
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                ],
              ),
              Gap(15),
            ],
          ),
        ),
      ),
    );
  }
}
