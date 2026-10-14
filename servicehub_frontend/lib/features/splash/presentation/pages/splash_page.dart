import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _scaleIn = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardLight,
      body: Stack(
        children: [
          // Cream wash background — full screen for splash
          Positioned.fill(
            child: Container(
              color: AppColors.cream.withValues(alpha: 0.20),
            ),
          ),

          // Centered brand mark
          Center(
            child: FadeTransition(
              opacity: _fadeIn,
              child: ScaleTransition(
                scale: _scaleIn,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Connection Nexus logo
                    SvgPicture.asset(
                      'assets/brand/logo_symbol.svg',
                      width: 112,
                      height: 112,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Wordmark
                    RichText(
                      text: TextSpan(
                        style: AppTypography.h1.copyWith(
                          fontSize: 26,
                          letterSpacing: -0.02,
                        ),
                        children: [
                          TextSpan(
                            text: 'Service',
                            style: TextStyle(color: AppColors.primary),
                          ),
                          TextSpan(
                            text: 'HUB',
                            style: TextStyle(color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxxl),

                    // Subtle loading indicator — thin ochre line
                    const _LoadingIndicator(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingIndicator extends StatefulWidget {
  const _LoadingIndicator();

  @override
  State<_LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<_LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9999),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                // Track
                Container(
                  width: 40,
                  height: 3,
                  color: AppColors.borderLight,
                ),
                // Moving ochre segment
                Positioned(
                  left: (_controller.value * 80) - 40,
                  top: 0,
                  child: Container(
                    width: 40,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.secondary.withValues(alpha: 0.0),
                          AppColors.secondary,
                          AppColors.secondary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}