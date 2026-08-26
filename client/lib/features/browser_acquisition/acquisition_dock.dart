import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/download_service.dart';

class AcquisitionDock extends ConsumerWidget {
  const AcquisitionDock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadServiceProvider);
    final active = downloads.activeTransfers;
    if (active.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.bottomRight,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 84, left: 16),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surfaceContainerHigh,
            shadowColor: Colors.black54,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.downloading_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Active Downloads (${active.length})',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Tap to view window',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: active.map((transfer) {
                      final title = transfer.track?.title ?? 'Track';
                      final artist = transfer.track?.artist ?? '';
                      final percent = (transfer.progress * 100).round();
                      final isFocused =
                          downloads.focusedTrackId == transfer.trackId &&
                          !transfer.isMinimized;

                      return InkWell(
                        onTap: () {
                          ref
                              .read(downloadServiceProvider.notifier)
                              .focus(transfer.trackId);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isFocused
                                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isFocused
                                  ? theme.colorScheme.primary.withValues(alpha: 0.6)
                                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  value: transfer.progress > 0
                                      ? transfer.progress
                                      : null,
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
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    if (artist.isNotEmpty)
                                      Text(
                                        artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: theme.colorScheme.outline,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$percent%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkResponse(
                                radius: 12,
                                onTap: () {
                                  ref
                                      .read(downloadServiceProvider.notifier)
                                      .cancel(transfer.trackId);
                                },
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
