import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

class BottomNavBar extends StatefulWidget {
  final ValueChanged<int>? onItemTapped;
  final int initialIndex;

  const BottomNavBar({
    super.key,
    this.onItemTapped,
    this.initialIndex = 0,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with TickerProviderStateMixin {
  late int selectedIndex;

  final List<String> labels = const [
    'Home',
    'Forecast',
    'Insights',
    'Schedule',
    'Profile',
  ];

  final List<IconData> icons = const [
    Iconsax.home_outline,
    Iconsax.cloud_sunny_outline,
    Iconsax.graph_outline,
    Iconsax.calendar_2_outline,
    Iconsax.profile_circle_outline,
  ];

  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;

    _controllers = List.generate(
      labels.length,
          (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );

    _fadeAnimations = _controllers
        .map(
          (controller) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      ),
    )
        .toList();

    _slideAnimations = _controllers
        .map(
          (controller) => Tween<Offset>(
        begin: const Offset(-0.2, 0.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      ),
    )
        .toList();

    _controllers[selectedIndex].forward();
  }

  @override
  void didUpdateWidget(covariant BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialIndex != widget.initialIndex &&
        widget.initialIndex != selectedIndex) {
      _animateToIndex(widget.initialIndex);
    }
  }

  void _animateToIndex(int index) {
    setState(() {
      selectedIndex = index;
    });

    for (int i = 0; i < _controllers.length; i++) {
      if (i == index) {
        _controllers[i].forward();
      } else {
        _controllers[i].reverse();
      }
    }
  }

  void _onTap(int index) {
    if (index == selectedIndex) {
      widget.onItemTapped?.call(index);
      return;
    }

    _animateToIndex(index);
    widget.onItemTapped?.call(index);
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      color: const Color(0xFFF6F6F6),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  offset: const Offset(0, 8),
                  blurRadius: 24,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(labels.length, (index) {
                final isSelected = selectedIndex == index;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 12 : 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.lightBlue.withValues(alpha: 0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icons[index],
                          size: 22,
                          color: isSelected
                              ? Colors.lightBlue.shade700
                              : const Color(0xFF6B7280),
                        ),
                        if (isSelected) const SizedBox(width: 6),
                        if (isSelected)
                          ClipRect(
                            child: SlideTransition(
                              position: _slideAnimations[index],
                              child: FadeTransition(
                                opacity: _fadeAnimations[index],
                                child: Text(
                                  labels[index],
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  style: TextStyle(
                                    color: Colors.lightBlue.shade700,
                                    fontSize: isSmallScreen ? 13 : 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}