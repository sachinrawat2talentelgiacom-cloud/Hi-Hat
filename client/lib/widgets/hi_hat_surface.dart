import 'package:flutter/material.dart';

import '../core/theme.dart';

enum HiSurfaceRole { quiet, raised, accent }

class HiSurface extends StatefulWidget {
  const HiSurface({
    super.key,
    required this.child,
    this.role = HiSurfaceRole.raised,
    this.onPressed,
    this.padding,
    this.semanticLabel,
    this.selected = false,
  });

  final Widget child;
  final HiSurfaceRole role;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;
  final bool selected;

  @override
  State<HiSurface> createState() => _HiSurfaceState();
}

class _HiSurfaceState extends State<HiSurface> {
  bool hovered = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens =
        Theme.of(context).extension<HiHatTokens>() ?? HiHatTokens.standard;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final background = switch (widget.role) {
      HiSurfaceRole.quiet => Colors.transparent,
      HiSurfaceRole.raised =>
        hovered ? colors.surfaceContainerHigh : colors.surfaceContainer,
      HiSurfaceRole.accent => colors.primaryContainer,
    };
    final surface = AnimatedScale(
      scale: pressed && !reduceMotion ? .96 : 1,
      duration: reduceMotion ? Duration.zero : tokens.motionFast,
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : tokens.motionFast,
        curve: Curves.easeOutCubic,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: widget.selected
              ? Border.all(color: colors.primary, width: 2)
              : null,
        ),
        child: widget.child,
      ),
    );
    if (widget.onPressed == null) return surface;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (value) => setState(() => hovered = value),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onTapDown: (_) => setState(() => pressed = true),
          onTapUp: (_) => setState(() => pressed = false),
          onTapCancel: () => setState(() => pressed = false),
          child: surface,
        ),
      ),
    );
  }
}

class HiHatSkeleton extends StatelessWidget {
  const HiHatSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );
}

class TrackGridSkeleton extends StatelessWidget {
  const TrackGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width < 520
        ? 2
        : width < 980
        ? 3
        : 5;
    return Semantics(
      label: 'Loading discovery tracks',
      child: GridView.builder(
        padding: EdgeInsets.all(width < 700 ? 16 : 28),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: .74,
        ),
        itemCount: columns * 2,
        itemBuilder: (_, _) => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: HiHatSkeleton(
                width: double.infinity,
                height: double.infinity,
                radius: 12,
              ),
            ),
            SizedBox(height: 12),
            HiHatSkeleton(width: 132, height: 14, radius: 4),
            SizedBox(height: 8),
            HiHatSkeleton(width: 88, height: 11, radius: 4),
          ],
        ),
      ),
    );
  }
}

class TrackLedgerSkeleton extends StatelessWidget {
  const TrackLedgerSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading search results',
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: 7,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const SizedBox(
        height: 58,
        child: Row(
          children: [
            HiHatSkeleton(width: 58, height: 58, radius: 8),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HiHatSkeleton(width: 180, height: 14, radius: 4),
                  SizedBox(height: 8),
                  HiHatSkeleton(width: 112, height: 11, radius: 4),
                ],
              ),
            ),
            HiHatSkeleton(width: 42, height: 11, radius: 4),
          ],
        ),
      ),
    ),
  );
}
