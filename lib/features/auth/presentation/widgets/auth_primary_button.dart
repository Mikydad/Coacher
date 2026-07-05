import 'package:flutter/material.dart';

import '../../../../core/presentation/app_colors.dart';

/// Full-width primary action button for auth screens.
///
/// `#B2ED00` background, bold black text.
/// Shows a `CircularProgressIndicator` (black) when [isLoading] is true.
/// Visually disabled (opacity 0.4) when [onPressed] is null or [isLoading].
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;

  /// Pass `null` to disable the button.
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentDim,
            foregroundColor: Colors.black,
            disabledBackgroundColor: AppColors.accentDim,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.4,
                  ),
                ),
        ),
      ),
    );
  }
}
