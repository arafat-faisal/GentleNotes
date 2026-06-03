import 'package:flutter/material.dart';

class OnboardingActions extends StatelessWidget {
  final bool isLastPage;
  final VoidCallback onNextPressed;

  const OnboardingActions({
    super.key,
    required this.isLastPage,
    required this.onNextPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton(
      onPressed: onNextPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isLastPage ? 'Get Started' : 'Next',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Icon(
            isLastPage ? Icons.check : Icons.arrow_forward,
            size: 18,
          ),
        ],
      ),
    );
  }
}
