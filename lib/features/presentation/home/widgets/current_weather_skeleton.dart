import 'dart:ui';
import 'package:flutter/material.dart';

class CurrentWeatherCardSkeleton extends StatefulWidget {
  const CurrentWeatherCardSkeleton({super.key});

  @override
  State<CurrentWeatherCardSkeleton> createState() =>
      _CurrentWeatherCardSkeletonState();
}

class _CurrentWeatherCardSkeletonState
    extends State<CurrentWeatherCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.25 + (_controller.value * 0.35);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF3A7BD5),
                Color(0xFF00D2FF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withAlpha(20),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 95),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /// LOCATION TEXT SKELETON (icon removed)
                        _SkeletonLine(
                          width: 120,
                          height: 14,
                          opacity: opacity,
                        ),

                        const SizedBox(height: 10),

                        /// TEMPERATURE
                        _SkeletonLine(
                          width: 90,
                          height: 34,
                          opacity: opacity,
                        ),

                        const SizedBox(height: 8),

                        /// DESCRIPTION
                        _SkeletonLine(
                          width: 120,
                          height: 16,
                          opacity: opacity,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// WEATHER DETAILS
                  Row(
                    children: [
                      Expanded(
                        child: _GlassInfoBoxSkeleton(opacity: opacity),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _GlassInfoBoxSkeleton(opacity: opacity),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _GlassInfoBoxSkeleton(opacity: opacity),
                      ),
                    ],
                  ),
                ],
              ),

              /// WEATHER ICON PLACEHOLDER (kept)
              Positioned(
                right: 10,
                top: -8,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((opacity * 255).toInt()),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  final double opacity;

  const _SkeletonLine({
    required this.width,
    required this.height,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((opacity * 255).toInt()),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _GlassInfoBoxSkeleton extends StatelessWidget {
  final double opacity;

  const _GlassInfoBoxSkeleton({
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(38),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withAlpha(58),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 45,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((opacity * 255).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 55,
                height: 15,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((opacity * 255).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}