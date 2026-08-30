import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/download_service.dart';

class DownloadsButton extends ConsumerWidget {
  const DownloadsButton({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCount = ref.watch(downloadServiceProvider).activeTransfers.length;
    return Badge(
      isLabelVisible: activeCount > 0,
      label: Text('$activeCount'),
      child: compact
          ? IconButton(
              tooltip: 'Downloads',
              onPressed: () => _showDownloads(context),
              icon: const Icon(Icons.download_rounded),
            )
          : OutlinedButton.icon(
              onPressed: () => _showDownloads(context),
              icon: Icon(activeCount > 0
                  ? Icons.downloading_rounded
                  : Icons.download_done_rounded),
              label: const Text('Downloads'),
            ),
    );
  }

  void _showDownloads(BuildContext context) {
    showDialog<void>(context: context, builder: (_) => const _DownloadsDialog());
  }
}

class _DownloadsDialog extends ConsumerWidget {
  const _DownloadsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadServiceProvider);
    final transfers = downloads.allTransfers.reversed.toList();
    final theme = Theme.of(context);
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 12, 12),
      title: Row(children: [
        const Icon(Icons.download_rounded),
        const SizedBox(width: 10),
        const Expanded(child: Text('Downloads')),
        IconButton(
          tooltip: 'Close downloads',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ]),
      contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      content: SizedBox(
        width: 520,
        child: transfers.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.download_done_rounded,
                      size: 40, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  Text('No downloads yet', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Tracks you download will appear here.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.outline)),
                ]),
              )
            : ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 520),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: transfers.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final transfer = transfers[index];
                    return _DownloadListTile(
                      transfer: transfer,
                      onOpen: transfer.isActive
                          ? () {
                              ref.read(downloadServiceProvider.notifier)
                                  .focus(transfer.trackId);
                              Navigator.of(context).pop();
                            }
                          : null,
                      onCancel: transfer.isActive
                          ? () => ref.read(downloadServiceProvider.notifier)
                              .cancel(transfer.trackId)
                          : null,
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _DownloadListTile extends StatelessWidget {
  const _DownloadListTile({
    required this.transfer,
    required this.onOpen,
    required this.onCancel,
  });

  final TransferState transfer;
  final VoidCallback? onOpen;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = transfer.track?.title ?? 'Track';
    final artist = transfer.track?.artist ?? '';
    final status = _statusLabel(transfer);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      leading: SizedBox.square(
        dimension: 36,
        child: transfer.isActive
            ? CircularProgressIndicator(
                value: transfer.progress > 0 ? transfer.progress : null,
                strokeWidth: 3,
              )
            : Icon(
                transfer.isCompleted
                    ? Icons.check_circle_rounded
                    : transfer.isFailed
                        ? Icons.error_rounded
                        : Icons.cancel_rounded,
                color: transfer.isCompleted
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(artist.isEmpty ? status : '$artist · $status',
          maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onOpen,
      trailing: onCancel == null
          ? null
          : IconButton(
              tooltip: 'Cancel $title download',
              onPressed: onCancel,
              icon: const Icon(Icons.close_rounded),
            ),
    );
  }

  String _statusLabel(TransferState transfer) {
    if (transfer.isCompleted) return 'Completed';
    if (transfer.isFailed) return 'Failed';
    if (transfer.isCancelled) return 'Cancelled';
    final phase = (transfer.phase ?? 'Preparing').replaceAll('_', ' ');
    return '$phase · ${(transfer.progress * 100).round()}%';
  }
}
