import 'package:flutter/material.dart';

class BridgeRouteObserver extends NavigatorObserver {
  final GlobalKey<NavigatorState> navigatorKey;
  bool _isShowing = false;
  static bool _showOnNextNavigation = false;

  BridgeRouteObserver({required this.navigatorKey});

  static void requestLogoForNextNavigation() {
    _showOnNextNavigation = true;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (_isPageTransition(route, previousRoute) && _consumeShowFlag()) {
      _showLogoOverlay();
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (_isPageTransition(newRoute, oldRoute) && _consumeShowFlag()) {
      _showLogoOverlay();
    }
  }

  bool _isPageTransition(Route<dynamic>? route, Route<dynamic>? previousRoute) {
    return route is PageRoute<dynamic> && previousRoute is PageRoute<dynamic>;
  }

  bool _consumeShowFlag() {
    if (_showOnNextNavigation) {
      _showOnNextNavigation = false;
      return true;
    }
    return false;
  }

  void _showLogoOverlay() {
    if (_isShowing) return;

    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _isShowing = true;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return IgnorePointer(
          child: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: Colors.white)),
              Center(
                child: _LogoHoldFade(
                  onComplete: () {
                    entry.remove();
                    _isShowing = false;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(entry);
  }
}

class _LogoHoldFade extends StatefulWidget {
  final VoidCallback onComplete;

  const _LogoHoldFade({required this.onComplete});

  @override
  State<_LogoHoldFade> createState() => _LogoHoldFadeState();
}

class _LogoHoldFadeState extends State<_LogoHoldFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  static const Duration _totalDuration = Duration(milliseconds: 2000);
  static const Duration _fadeDuration = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _fadeDuration);
    _startSequence();
  }

  Future<void> _startSequence() async {
    final holdDuration = _totalDuration - _fadeDuration;
    await Future.delayed(holdDuration);
    if (!mounted) return;
    await _controller.forward();
    widget.onComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _controller.value;
        final opacity = 1.0 - value;
        final scale = 1.0 - (0.1 * value);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Image.asset(
              'lib/01-images/bridge-logo.png',
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }
}
