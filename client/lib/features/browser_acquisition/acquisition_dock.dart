import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/download_service.dart';

class AcquisitionDock extends ConsumerStatefulWidget {
  const AcquisitionDock({super.key});

  @override
  ConsumerState<AcquisitionDock> createState() => _AcquisitionDockState();
}

class _AcquisitionDockState extends ConsumerState<AcquisitionDock> {
  static const _edgePadding = 16.0;
  static const _maximumWidth = 460.0;

  final dockKey = GlobalKey();
  Offset? position;
  Size dockSize = Size.zero;
  Size availableSize = Size.zero;

  Offset _clamp(Offset candidate, Size bounds, Size childSize) {
    final maxX = (bounds.width - childSize.width - _edgePadding).clamp(
      _edgePadding,
      double.infinity,
    );
    final maxY = (bounds.height - childSize.height - _edgePadding).clamp(
      _edgePadding,
      double.infinity,
    );
    return Offset(
      candidate.dx.clamp(_edgePadding, maxX),
      candidate.dy.clamp(_edgePadding, maxY),
    );
  }

  Offset _resolvedPosition(Size bounds) {
    final current = position;
    if (current != null) return _clamp(current, bounds, dockSize);
    return _clamp(
      Offset(
        bounds.width - dockSize.width - _edgePadding,
        bounds.height - dockSize.height - _edgePadding,
      ),
      bounds,
      dockSize,
    );
  }

  void _measureAndClamp(Size bounds) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final measured = dockKey.currentContext?.size;
      if (measured == null) return;
      final nextPosition = _resolvedPosition(bounds);
      if (measured == dockSize &&
          bounds == availableSize &&
          position == nextPosition) {
        return;
      }
      setState(() {
        dockSize = measured;
        availableSize = bounds;
        position = _clamp(nextPosition, bounds, measured);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final downloads = ref.watch(downloadServiceProvider);
    final active = downloads.activeTransfers;
    if (active.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final bounds = constraints.biggest;
        _measureAndClamp(bounds);
        final resolved = _resolvedPosition(bounds);

        return Stack(
          children: [
            Positioned(
              left: resolved.dx,
              top: resolved.dy,
              child: ConstrainedBox(
                key: dockKey,
                constraints: BoxConstraints(
                  maxWidth: (bounds.width - (_edgePadding * 2)).clamp(
                    0,
                    _maximumWidth,
                  ),
                  maxHeight: (bounds.height - (_edgePadding * 2)).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.surfaceContainerHigh,
                  shadowColor: Colors.black54,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanUpdate: (details) {
                            setState(() {
                              position = _clamp(
                                resolved + details.delta,
                                bounds,
                                dockSize,
                              );
                            });
                          },
                          child: Semantics(
                            label: 'Drag active downloads dock',
                            child: SizedBox(
                              height: 48,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.drag_indicator_rounded,
                                    size: 20,
                                    color: theme.colorScheme.outline,
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.downloading_rounded,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Active Downloads (${active.length})',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                    ),
                                  ),
                                  Text(
                                    'Drag to move',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: active
                                  .map(
                                    (transfer) => _TransferChip(
                                      transfer: transfer,
                                      isFocused:
                                          downloads.focusedTrackId ==
                                              transfer.trackId &&
                                          !transfer.isMinimized,
                                      onFocus: () => ref
                                          .read(
                                            downloadServiceProvider.notifier,
                                          )
                                          .focus(transfer.trackId),
                                      onCancel: () => ref
                                          .read(
                                            downloadServiceProvider.notifier,
                                          )
                                          .cancel(transfer.trackId),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TransferChip extends StatelessWidget {
  const _TransferChip({
    required this.transfer,
    required this.isFocused,
    required this.onFocus,
    required this.onCancel,
  });

  final TransferState transfer;
  final bool isFocused;
  final VoidCallback onFocus;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = transfer.track?.title ?? 'Track';
    final artist = transfer.track?.artist ?? '';
    final percent = (transfer.progress * 100).round();

    return Material(
      color: isFocused
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onFocus,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsetsDirectional.only(start: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isFocused
                  ? theme.colorScheme.primary.withValues(alpha: 0.6)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  value: transfer.progress > 0 ? transfer.progress : null,
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (artist.isNotEmpty)
                      Text(
                        artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$percent%',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              IconButton(
                tooltip: 'Cancel $title download',
                onPressed: onCancel,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
