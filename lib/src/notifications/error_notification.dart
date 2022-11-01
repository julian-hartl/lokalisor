import 'package:flutter/material.dart';

import 'notification.dart';

void showErrorNotification(String message) {
  final notification = BaseNotification(
    background: Colors.red,
    child: Text(
      message,
      style: const TextStyle(
        color: Colors.white,
      ),
    ),
  );
  notification.show();
}
