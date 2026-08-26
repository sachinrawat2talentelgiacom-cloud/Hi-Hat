import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class TrackArtwork extends StatelessWidget {
  const TrackArtwork({
    super.key,
    required this.artworkUrl,
    this.size,
    this.width,
    this.height,
    this.borderRadius,
    this.iconSize,
    this.highRes = false,
    this.heroTag,
  });

  final String? artworkUrl;
  final double? size;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final double? iconSize;
  final bool highRes;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(8);
    final effectiveWidth = width ?? size;
    final effectiveHeight = height ?? size;

    Widget child = _buildImage(context);

    if (heroTag != null) {
      child = Hero(tag: heroTag!, child: child);
    }

    return Container(
      width: effectiveWidth,
      height: effectiveHeight,
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: child,
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final rawUrl = artworkUrl?.trim();
    if (rawUrl == null || rawUrl.isEmpty) {
      return _buildFallback(context);
    }

    if (rawUrl.startsWith('data:image')) {
      return _buildDataUriImage(context, rawUrl);
    }

    if (rawUrl.startsWith('file://')) {
      final path = Uri.parse(rawUrl).toFilePath();
      return _buildFileImage(context, File(path));
    }

    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      var url = rawUrl;
      if (highRes && url.contains('640x640.jpg')) {
        url = url.replaceFirst('640x640.jpg', '1280x1280.jpg');
      }
      return Image.network(
        url,
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return _buildFallback(context, isLoading: true);
        },
        errorBuilder: (_, _, _) => _buildFallback(context),
      );
    }

    // Assume local file path
    final file = File(rawUrl);
    if (file.existsSync()) {
      return _buildFileImage(context, file);
    }

    return _buildFallback(context);
  }

  Widget _buildFileImage(BuildContext context, File file) {
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _buildFallback(context),
    );
  }

  Widget _buildDataUriImage(BuildContext context, String dataUri) {
    try {
      final commaIndex = dataUri.indexOf(',');
      if (commaIndex != -1) {
        final base64Str = dataUri.substring(commaIndex + 1);
        final bytes = base64Decode(base64Str);
        return Image.memory(
          Uint8List.fromList(bytes),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(context),
        );
      }
    } catch (_) {}
    return _buildFallback(context);
  }

  Widget _buildFallback(BuildContext context, {bool isLoading = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark
        ? theme.colorScheme.surfaceContainerHigh
        : theme.colorScheme.surfaceContainer;

    return Container(
      color: baseColor,
      child: Center(
        child: isLoading
            ? SizedBox.square(
                dimension: (iconSize ?? 24) * 0.8,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                ),
              )
            : Icon(
                Icons.album_outlined,
                size: iconSize ?? (size != null ? size! * 0.45 : 28),
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
      ),
    );
  }
}