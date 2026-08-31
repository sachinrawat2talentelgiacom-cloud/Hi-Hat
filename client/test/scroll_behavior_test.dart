import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hi_hat/core/scroll_behavior.dart';

void main() {
  testWidgets('wheel input continuously interpolates toward one target', (
    tester,
  ) async {
    final controller = SmoothScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const HiHatScrollBehavior(),
        home: ListView.builder(
          controller: controller,
          itemExtent: 80,
          itemCount: 30,
          itemBuilder: (_, index) => Text('Item $index'),
        ),
      ),
    );

    await tester.sendEventToBinding(
      const PointerScrollEvent(
        position: Offset(200, 200),
        scrollDelta: Offset(0, 120),
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));

    expect(controller.offset, greaterThan(0));
    expect(controller.offset, lessThan(20));

    final firstFrameOffset = controller.offset;
    await tester.sendEventToBinding(
      const PointerScrollEvent(
        position: Offset(200, 200),
        scrollDelta: Offset(0, 120),
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(controller.offset, greaterThan(firstFrameOffset));
    expect(controller.offset, lessThan(139.2));

    await tester.pump(const Duration(milliseconds: 1200));
    expect(controller.offset, closeTo(139.2, 1));
    expect(SmoothScrollController.scaleWheelDelta(120), closeTo(69.6, .01));
    expect(SmoothScrollController.scaleWheelDelta(12), 12);
  });
}
