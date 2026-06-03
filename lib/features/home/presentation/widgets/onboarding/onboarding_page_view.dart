import 'package:flutter/material.dart';
import 'onboarding_content.dart';
import 'onboarding_page.dart';

class OnboardingPageView extends StatelessWidget {
  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final Widget profileSelectionPage;

  const OnboardingPageView({
    super.key,
    required this.controller,
    required this.onPageChanged,
    required this.profileSelectionPage,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      onPageChanged: onPageChanged,
      itemCount: onboardingPages.length + 1,
      itemBuilder: (context, index) {
        if (index == onboardingPages.length) {
          return profileSelectionPage;
        }
        final page = onboardingPages[index];
        return OnboardingPage(page: page);
      },
    );
  }
}
