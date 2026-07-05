import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/presentation/app_colors.dart';

/// Full-screen viewer for chat/challenge proof images.
///
/// Costs no extra bandwidth: the URL is identical to the thumbnail's, so the
/// bytes come from the disk cache — only the decode is re-run at full size.
/// Pinch to zoom (up to 4x), tap anywhere or use the close button to leave.
class FullScreenImageViewer extends StatelessWidget {
  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  final String imageUrl;
  final Object heroTag;

  static void open(
    BuildContext context, {
    required String imageUrl,
    required Object heroTag,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, _, _) =>
            FullScreenImageViewer(imageUrl: imageUrl, heroTag: heroTag),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: InteractiveViewer(
                maxScale: 4,
                child: Center(
                  child: Hero(
                    tag: heroTag,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      progressIndicatorBuilder: (_, _, progress) => Center(
                        child: CircularProgressIndicator(
                          value: progress.progress,
                          color: AppColors.accent,
                        ),
                      ),
                      errorWidget: (_, _, _) => const Icon(
                        Icons.broken_image_rounded,
                        color: AppColors.textMuted,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
