import 'package:flutter/material.dart';

/// The project logo. It is black on transparent, so it is tinted with the
/// current text color to stay visible in dark mode.
class Logo extends StatelessWidget {
  const Logo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.onSurface,
      colorBlendMode: BlendMode.srcIn,
      semanticLabel: 'Simplications Logo',
    );
  }
}
