import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CustomLoadingAnimation extends StatefulWidget {
  final double size;

  const CustomLoadingAnimation({
    super.key,
    this.size = 80,
  });

  @override
  State<CustomLoadingAnimation> createState() => _CustomLoadingAnimationState();
}

class _CustomLoadingAnimationState extends State<CustomLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const double speedMultiplier = 0.33;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/lottie/Clouds.json',
      controller: _controller,
      width: widget.size,
      height: widget.size,
      onLoaded: (composition) {
        _controller.duration = Duration(
          milliseconds:
          (composition.duration.inMilliseconds * speedMultiplier).round(),
        );
        _controller.repeat();
      },
    );
  }
}