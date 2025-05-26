import 'package:flutter/material.dart';

class ConstrainedWidthWidget extends StatelessWidget {
  final Widget? child;
  const ConstrainedWidthWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.sizeOf(context).width;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 500),
      child: SizedBox(width: mediaWidth * 0.8, child: child),
    );
  }
}
