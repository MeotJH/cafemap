import 'package:flutter/material.dart';
import 'package:front/core/constants/app_colors.dart';

class WriteCafeReviewButton extends StatelessWidget {
  const WriteCafeReviewButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDisabled ? const Color(0xFF9CA3AF) : AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (!isDisabled)
              const BoxShadow(
                color: Color.fromRGBO(111, 78, 55, 0.25),
                offset: Offset(0, 6),
                blurRadius: 12,
              ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isLoading
                ? Row(
                    key: const ValueKey('review-submit-loading'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text('제출 중'),
                    ],
                  )
                : Text(
                    text,
                    key: ValueKey(text),
                  ),
          ),
        ),
      ),
    );
  }
}
