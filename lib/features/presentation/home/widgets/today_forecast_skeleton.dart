import 'package:flutter/material.dart';

class TodayForecastSkeleton extends StatefulWidget {
  const TodayForecastSkeleton({super.key});

  @override
  State<TodayForecastSkeleton> createState() =>
      _TodayForecastSkeletonState();
}

class _TodayForecastSkeletonState extends State<TodayForecastSkeleton>
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

  Widget _box(double width, double height, double opacity) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.25 + (_controller.value * 0.35);

        return SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return Container(
                width: 75,
                padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFEFF7FF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    /// TIME
                    _box(30, 10, opacity),

                    /// ICON
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: opacity),
                        shape: BoxShape.circle,
                      ),
                    ),

                    /// TEMP
                    _box(28, 12, opacity),

                    /// POP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: opacity),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _box(20, 10, opacity),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}