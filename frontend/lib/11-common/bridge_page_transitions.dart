import 'package:flutter/material.dart';

class BridgeLogoPageTransitionsBuilder extends PageTransitionsBuilder {
  const BridgeLogoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    final logoCurve = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    return Stack(
      children: [
        FadeTransition(opacity: fade, child: child),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              if (animation.status != AnimationStatus.forward) {
                return const SizedBox.shrink();
              }

              final double opacity = 1.0 - logoCurve.value;
              final double scale = 1.0 - (0.1 * logoCurve.value);

              return Center(
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Image.asset(
                      'lib/01-images/bridge-logo.png',
                      width: 140,
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
