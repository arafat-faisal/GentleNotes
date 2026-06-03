import 'package:flutter/material.dart';

class ClassicBottomBar extends StatelessWidget {
  final Widget child;
  const ClassicBottomBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Center(
        child: child,
      ),
    );
  }
}
