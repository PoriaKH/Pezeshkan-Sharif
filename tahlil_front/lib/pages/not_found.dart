import 'package:flutter/material.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset('assets/not-found.png', width: 600),
    );
  }
}
