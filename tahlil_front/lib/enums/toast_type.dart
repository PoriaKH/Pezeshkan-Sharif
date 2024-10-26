import 'package:flutter/material.dart';

enum ToastType {
  error,
  warning,
  success;

  Color get backgroundColor {
    switch (this) {
      case ToastType.error:
        return Colors.red.shade100;
      case ToastType.warning:
        return Colors.yellow.shade100;
      case ToastType.success:
        return Colors.green.shade100;
    }
  }

  Color get foregroundColor {
    switch (this) {
      case ToastType.error:
        return Colors.red.shade900;
      case ToastType.warning:
        return Colors.yellow.shade900;
      case ToastType.success:
        return Colors.green.shade900;
    }
  }
}
