import 'package:flutter/material.dart';
import 'package:tahlil_front/enums/toast_type.dart';

class CustomToast extends StatefulWidget {
  final String text;
  final ToastType toastType;

  const CustomToast({super.key, required this.text, required this.toastType});

  @override
  State<CustomToast> createState() => _CustomToastState();
}

class _CustomToastState extends State<CustomToast> {
  String get text => widget.text;

  ToastType get toastType => widget.toastType;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: toastType.backgroundColor,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: toastType.foregroundColor),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 1)],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: toastType.foregroundColor,
          ),
        ),
      ),
    );
  }
}
