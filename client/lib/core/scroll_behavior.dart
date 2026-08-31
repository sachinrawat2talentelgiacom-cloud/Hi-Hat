import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class HiHatScrollBehavior extends MaterialScrollBehavior {
  const HiHatScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}

class SmoothScrollController extends ScrollController {
  SmoothScrollController({super.debugLabel});

  static const wheelNotchMultiplier = 0.58;
  static const lerpIntensity = 0.14;
  static const settleTolerance = 0.35;

  static double scaleWheelDelta(double delta) =>
      delta.abs() >= 40 ? delta * wheelNotchMultiplier : delta;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) => _SmoothScrollPosition(
    physics: physics,
    context: context,
    oldPosition: oldPosition,
    debugLabel: debugLabel,
  );
}

class _SmoothScrollPosition extends ScrollPositionWithSingleContext {
  _SmoothScrollPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
    super.debugLabel,
  }) {
    _ticker = context.vsync.createTicker(_tick);
  }

  late final Ticker _ticker;
  double? target;
  Duration? _lastElapsed;

  @override
  void pointerScroll(double delta) {
    if (delta == 0 || !hasContentDimensions) return;
    final scaledDelta = SmoothScrollController.scaleWheelDelta(delta);
    final base = target == null || (target! - pixels).abs() > 900
        ? pixels
        : target!;
    target = (base + scaledDelta).clamp(minScrollExtent, maxScrollExtent);
    if (WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations) {
      _stopSmoothing();
      super.jumpTo(target!);
      return;
    }
    if (!_ticker.isActive) {
      goIdle();
      _lastElapsed = null;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final destination = target;
    if (destination == null || !hasContentDimensions) {
      _stopSmoothing();
      return;
    }

    final previousElapsed = _lastElapsed;
    _lastElapsed = elapsed;
    final frameMilliseconds = previousElapsed == null
        ? 1000 / 60
        : (elapsed - previousElapsed).inMicroseconds / 1000;
    final frameRatio = frameMilliseconds / (1000 / 60);
    final alpha =
        1 - math.pow(1 - SmoothScrollController.lerpIntensity, frameRatio);
    final remaining = destination - pixels;

    if (remaining.abs() <= SmoothScrollController.settleTolerance) {
      forcePixels(destination);
      _stopSmoothing(clearTarget: false);
      return;
    }

    forcePixels(
      (pixels + remaining * alpha).clamp(minScrollExtent, maxScrollExtent),
    );
  }

  void _stopSmoothing({bool clearTarget = true}) {
    if (_ticker.isActive) _ticker.stop();
    _lastElapsed = null;
    if (clearTarget) target = null;
  }

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    _stopSmoothing();
    return super.drag(details, dragCancelCallback);
  }

  @override
  void jumpTo(double value) {
    _stopSmoothing();
    super.jumpTo(value);
  }

  @override
  Future<void> animateTo(
    double to, {
    required Duration duration,
    required Curve curve,
  }) {
    _stopSmoothing();
    return super.animateTo(to, duration: duration, curve: curve);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
