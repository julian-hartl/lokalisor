import 'package:flutter/material.dart';
import 'package:flutter_lokalisor/src/notifications/notification.dart';

void showSuccessNotification(String message) {
  final notification = BaseNotification(
    background: Colors.green,
    child: Text(
      message,
      style: const TextStyle(
        color: Colors.white,
      ),
    ),
  );
  notification.show();
}
