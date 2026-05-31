import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Wait for Splash animation
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // 3. Check if onboarding completed
    final prefs = await SharedPreferences.getInstance();
    final bool seenOnboarding = prefs.getBool('seen_onboarding_v1') ?? false;

    if (seenOnboarding) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Icon Container
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: accentColor.withOpacity(0.2), width: 2),
                      ),
                      child: Icon(
                        Icons.edit_note_rounded,
                        size: 64,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // App Name
                    Text(
                      'Gentle Notes',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onBackground,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Subtitle / Tagline
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Organize your learning, ideas, and projects beautifully.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onBackground.withOpacity(0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Loading indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.5,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
