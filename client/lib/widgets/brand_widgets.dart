import 'package:flutter/material.dart';

import '../core/theme.dart';

class HiHatMark extends StatelessWidget {
  const HiHatMark({super.key, this.size = 36, this.semanticLabel});

  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final mark = CustomPaint(
      size: Size.square(size),
      painter: const _HiHatMarkPainter(),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: mark);
    return Semantics(label: semanticLabel, image: true, child: mark);
  }
}

class HiHatLockup extends StatelessWidget {
  const HiHatLockup({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      HiHatMark(
        size: compact ? 30 : 36,
        semanticLabel: compact ? 'Hi Hat' : null,
      ),
      if (!compact) ...[
        const SizedBox(width: 12),
        Text(
          'HI HAT',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 2.6,
            color: HiHatColors.brandLight,
          ),
        ),
      ],
    ],
  );
}

class HiHatEyebrow extends StatelessWidget {
  const HiHatEyebrow(this.label, {super.key, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      fontFamily: 'Poppins',
      color: color ?? HiHatColors.signal,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.7,
    ),
  );
}

class HiHatStatusChip extends StatelessWidget {
  const HiHatStatusChip({
    super.key,
    required this.label,
    required this.icon,
    this.live = false,
  });
  final String label;
  final IconData icon;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final color = live ? HiHatColors.signal : HiHatColors.brandMid;
    return Semantics(
      label: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: .42)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 7),
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: .8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HiHatMarkPainter extends CustomPainter {
  const _HiHatMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final disc = Size(size.width * .84, size.height * .20);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, size.height * .32),
        width: disc.width,
        height: disc.height,
      ),
      Paint()..color = HiHatColors.signal,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, size.height * .68),
        width: disc.width,
        height: disc.height,
      ),
      Paint()..color = HiHatColors.brandLight,
    );
    final wave = Path()..moveTo(size.width * .16, center.dy);
    const samples = <double>[0, -.08, .16, -.24, .34, -.14, .08, 0];
    for (var i = 0; i < samples.length; i++) {
      wave.lineTo(
        size.width * (.16 + (.68 * i / (samples.length - 1))),
        center.dy + size.height * samples[i],
      );
    }
    canvas.drawPath(
      wave,
      Paint()
        ..color = HiHatColors.brandLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .055
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: size.width * .09,
          height: size.height * .82,
        ),
        Radius.circular(size.width),
      ),
      Paint()..color = HiHatColors.brandDark,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
