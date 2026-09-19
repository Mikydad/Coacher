import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/presentation/app_colors.dart';

/// A challenge proof photo, small, tap to view full size (2026-09-19).
class ChallengeProofThumbnail extends StatelessWidget {
  const ChallengeProofThumbnail({super.key, required this.url, this.size = 28});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () => Navigator.of(dialogContext).pop(),
            child: InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 4),
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, _) => Container(
            width: size,
            height: size,
            color: AppColors.surfaceLight,
          ),
          errorWidget: (_, _, _) => Container(
            width: size,
            height: size,
            color: AppColors.surfaceLight,
            child: Icon(
              Icons.broken_image_outlined,
              size: size / 2,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
